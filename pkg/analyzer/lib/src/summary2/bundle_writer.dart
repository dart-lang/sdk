// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/element_flags.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

class BundleWriter {
  late final _BundleWriterReferences _references;

  /// The declaration sink - any data that can be read without a need to
  /// have any other elements to be available. For example declarations of
  /// classes, methods, functions, etc. But not supertypes of classes, or
  /// return types of methods - these might reference other classes that we
  /// have not read yet. Such resolution data is stored into [_resolutionSink].
  ///
  /// Some resolution data is still written into this sink, if it does not
  /// require any other declaration read it later. For example type inference
  /// errors, or whether a parameter inherits `covariant`, or a class is
  /// simply bounded.
  late final _SummaryDataWriter _sink = _SummaryDataWriter(
    stringIndexer: _stringIndexer,
  );

  /// The resolution sink - any data that references elements, so can only
  /// be read after elements are created and available via its [Reference]s.
  late final ResolutionSink _resolutionSink = ResolutionSink(
    stringIndexer: _stringIndexer,
    references: _references,
  );

  /// [_writeClassElement] remembers the length of data written into [_sink]
  /// while writing members. So, when we read, we can skip members initially,
  /// and read them later on demand.
  List<int> _classMembersLengths = [];

  final StringIndexer _stringIndexer = StringIndexer();

  final List<_Library> _libraries = [];

  BundleWriter(Reference dynamicReference) {
    _references = _BundleWriterReferences(dynamicReference);
  }

  BundleWriterResult finish() {
    var baseResolutionOffset = _sink.offset;
    _sink.writeBytes(_resolutionSink.takeBytes());

    var librariesOffset = _sink.offset;
    _sink.writeList<_Library>(_libraries, (library) {
      _sink._writeStringReference(library.uriStr);
      _sink.writeUInt30(library.offset);
      _sink.writeUint30List(library.classMembersOffsets);
    });

    var referencesOffset = _sink.offset;
    _sink.writeUint30List(_references._referenceParents);
    _sink._writeStringList(_references._referenceNames);
    _references._clearIndexes();

    var stringTableOffset = _stringIndexer.write(_sink);

    // Write as Uint32 so that we know where it is.
    _sink.writeUInt32(baseResolutionOffset);
    _sink.writeUInt32(librariesOffset);
    _sink.writeUInt32(referencesOffset);
    _sink.writeUInt32(stringTableOffset);

    var bytes = _sink.takeBytes();
    return BundleWriterResult(resolutionBytes: bytes);
  }

  void writeLibraryElement(LibraryElementImpl libraryElement) {
    var libraryOffset = _sink.offset;
    _classMembersLengths = [];

    // Write non-resolution data for the library.
    _sink._writeStringReference(libraryElement.name);
    _writeFeatureSet(libraryElement.featureSet);
    LibraryElementFlags.write(_sink, libraryElement);
    _writeLanguageVersion(libraryElement.languageVersion);
    _writeExportedReferences(libraryElement.exportedReferences);
    _sink.writeUint30List(libraryElement.nameUnion.mask);
    _writeLoadLibraryFunctionReferences(libraryElement);

    // Write the library units.
    // This will write also resolution data, e.g. for classes.
    _writeUnitElement(libraryElement.definingCompilationUnit);

    // Write resolution data for the library.
    _sink.writeUInt30(_resolutionSink.offset);
    _resolutionSink._writeMetadata(libraryElement.metadata);
    _resolutionSink.writeElement(libraryElement.entryPoint2);
    _writeFieldNameNonPromotabilityInfo(
      libraryElement.fieldNameNonPromotabilityInfo,
    );

    _libraries.add(
      _Library(
        uriStr: '${libraryElement.source.uri}',
        offset: libraryOffset,
        classMembersOffsets: _classMembersLengths,
      ),
    );
  }

  void _writeClassElement(ClassFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);

    _writeReference(fragment);
    _writeReference2(fragment.element.reference);
    _writeFragmentName(fragment);
    ClassElementFlags.write(_sink, fragment);

    _resolutionSink._writeMetadata(fragment.metadata);

    _writeTypeParameters(fragment.typeParameters, () {
      _resolutionSink.writeType(fragment.supertype);
      _resolutionSink._writeTypeList(fragment.mixins);
      _resolutionSink._writeTypeList(fragment.interfaces);

      if (!fragment.isMixinApplication) {
        var membersOffset = _sink.offset;
        _writeList(
          fragment.fields.where((e) => !e.isSynthetic).toList(),
          _writeFieldElement,
        );
        _writeList(
          fragment.accessors.where((e) => !e.isSynthetic).toList(),
          _writePropertyAccessorElement,
        );
        _writeList(fragment.constructors, _writeConstructorElement);
        _writeList(fragment.methods, _writeMethodElement);
        _classMembersLengths.add(_sink.offset - membersOffset);
      }
    });
  }

  void _writeConstructorElement(ConstructorFragmentImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    _writeReference2(element.element.reference);
    _sink._writeOptionalStringReference(element.typeName);
    _sink._writeStringReference(element.name2);
    ConstructorElementFlags.write(_sink, element);
    _resolutionSink._writeMetadata(element.metadata);

    _resolutionSink.localElements.withElements(element.parameters, () {
      _writeList(element.parameters, _writeParameterElement);
      _resolutionSink.writeFragmentOrMember(element.superConstructor);
      _resolutionSink.writeFragmentOrMember(element.redirectedConstructor);
      _resolutionSink._writeNodeList(element.constantInitializers);
    });
  }

  void _writeDirectiveUri(DirectiveUri element) {
    void writeWithUriString(DirectiveUriWithRelativeUriString element) {
      _sink._writeStringReference(element.relativeUriString);
    }

    void writeWithRelativeUri(DirectiveUriWithRelativeUri element) {
      writeWithUriString(element);
      _sink._writeStringReference('${element.relativeUri}');
    }

    void writeWithSource(DirectiveUriWithSource element) {
      writeWithRelativeUri(element);
      _sink._writeStringReference('${element.source.uri}');
    }

    if (element is DirectiveUriWithLibrary) {
      _sink.writeByte(DirectiveUriKind.withLibrary.index);
      writeWithSource(element);
    } else if (element is DirectiveUriWithUnitImpl) {
      _sink.writeByte(DirectiveUriKind.withUnit.index);
      writeWithSource(element);
      _writeUnitElement(element.libraryFragment);
    } else if (element is DirectiveUriWithSource) {
      _sink.writeByte(DirectiveUriKind.withSource.index);
      writeWithSource(element);
    } else if (element is DirectiveUriWithRelativeUri) {
      _sink.writeByte(DirectiveUriKind.withRelativeUri.index);
      writeWithRelativeUri(element);
    } else if (element is DirectiveUriWithRelativeUriString) {
      _sink.writeByte(DirectiveUriKind.withRelativeUriString.index);
      writeWithUriString(element);
    } else {
      _sink.writeByte(DirectiveUriKind.withNothing.index);
    }
  }

  void _writeEnumElement(EnumFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(fragment);
    _writeReference2(fragment.element.reference);
    _writeFragmentName(fragment);
    EnumElementFlags.write(_sink, fragment);

    _resolutionSink._writeMetadata(fragment.metadata);

    _writeTypeParameters(fragment.typeParameters, () {
      _resolutionSink.writeType(fragment.supertype);
      _resolutionSink._writeTypeList(fragment.mixins);
      _resolutionSink._writeTypeList(fragment.interfaces);

      _writeList(
        fragment.fields.where((e) {
          return !e.isSynthetic || e.isSyntheticEnumField;
        }).toList(),
        _writeFieldElement,
      );
      _writeList(
        fragment.accessors.where((e) => !e.isSynthetic).toList(),
        _writePropertyAccessorElement,
      );
      _writeList(fragment.constructors, _writeConstructorElement);
      _writeList(fragment.methods, _writeMethodElement);
    });
  }

  void _writeExportedReferences(List<ExportedReference> elements) {
    _writeList<ExportedReference>(elements, (exported) {
      var index = _references._indexOfReference(exported.reference);
      if (exported is ExportedReferenceDeclared) {
        _sink.writeByte(0);
        _sink.writeUInt30(index);
      } else if (exported is ExportedReferenceExported) {
        _sink.writeByte(1);
        _sink.writeUInt30(index);
        _sink.writeList(exported.locations, _writeExportLocation);
      } else {
        throw UnimplementedError('(${exported.runtimeType}) $exported');
      }
    });
  }

  void _writeExportLocation(ExportLocation location) {
    _sink.writeUInt30(location.fragmentIndex);
    _sink.writeUInt30(location.exportIndex);
  }

  void _writeExtensionElement(ExtensionFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);

    _writeReference(fragment);
    _writeReference2(fragment.element.reference);
    _writeFragmentName(fragment);
    ExtensionElementFlags.write(_sink, fragment);

    _resolutionSink._writeMetadata(fragment.metadata);

    _writeTypeParameters(fragment.typeParameters, () {
      var element = fragment.element;
      _resolutionSink.writeType(element.extendedType);

      _writeList(
        fragment.accessors.where((e) => !e.isSynthetic).toList(),
        _writePropertyAccessorElement,
      );
      _writeList(
        fragment.fields.where((e) => !e.isSynthetic).toList(),
        _writeFieldElement,
      );
      _writeList(fragment.methods, _writeMethodElement);
    });
  }

  void _writeExtensionTypeElement(ExtensionTypeFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(fragment);
    _writeReference2(fragment.element.reference);
    _writeFragmentName(fragment);
    ExtensionTypeElementFlags.write(_sink, fragment);

    _resolutionSink._writeMetadata(fragment.metadata);

    _writeTypeParameters(fragment.typeParameters, () {
      _resolutionSink._writeTypeList(fragment.interfaces);
      _resolutionSink.writeType(fragment.typeErasure);

      _writeList(
        fragment.fields.where((e) => !e.isSynthetic).toList(),
        _writeFieldElement,
      );
      _writeList(
        fragment.accessors.where((e) => !e.isSynthetic).toList(),
        _writePropertyAccessorElement,
      );
      _writeList(fragment.constructors, _writeConstructorElement);
      _writeList(fragment.methods, _writeMethodElement);
    });
  }

  void _writeFeatureSet(FeatureSet featureSet) {
    var experimentStatus = featureSet as ExperimentStatus;
    var encoded = experimentStatus.toStorage();
    _sink.writeUint8List(encoded);
  }

  void _writeFieldElement(FieldFragmentImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    _writeReference2(element.element.reference);
    _writeOptionalReference(element.getter?.reference);
    _writeOptionalReference(element.setter?.reference);
    _writeFragmentName(element);
    _sink.writeBool(element is ConstFieldFragmentImpl);
    FieldElementFlags.write(_sink, element);
    _sink._writeTopLevelInferenceError(element.typeInferenceError);
    _resolutionSink._writeMetadata(element.metadata);
    _resolutionSink.writeType(element.type);
    _resolutionSink._writeOptionalNode(element.constantInitializer);
  }

  void _writeFieldNameNonPromotabilityInfo(
    Map<String, FieldNameNonPromotabilityInfo>? info,
  ) {
    _resolutionSink.writeOptionalObject(info, (info) {
      _resolutionSink.writeMap(
        info,
        writeKey: (key) {
          _resolutionSink._writeStringReference(key);
        },
        writeValue: (value) {
          _resolutionSink._writeElementList(value.conflictingFields);
          _resolutionSink._writeElementList(value.conflictingGetters);
          _resolutionSink._writeElementList(value.conflictingNsmClasses);
        },
      );
    });
  }

  void _writeFragmentName(Fragment fragment) {
    _sink._writeOptionalStringReference(fragment.name2);
  }

  void _writeFunctionElement(TopLevelFunctionFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);

    var element = fragment.element;

    _writeReference(fragment);
    _writeReference2(element.reference);
    _writeFragmentName(fragment);
    FunctionElementFlags.write(_sink, fragment);

    _resolutionSink._writeMetadata(fragment.metadata);

    _writeTypeParameters(fragment.typeParameters, () {
      _resolutionSink.writeType(fragment.returnType);
      _writeList(fragment.parameters, _writeParameterElement);
    });
  }

  void _writeLanguageVersion(LibraryLanguageVersion version) {
    _sink.writeUInt30(version.package.major);
    _sink.writeUInt30(version.package.minor);

    var override = version.override;
    if (override != null) {
      _sink.writeBool(true);
      _sink.writeUInt30(override.major);
      _sink.writeUInt30(override.minor);
    } else {
      _sink.writeBool(false);
    }
  }

  void _writeLibraryExport(LibraryExportImpl element) {
    _resolutionSink._writeMetadata(element.metadata);
    _sink.writeList(element.combinators, _writeNamespaceCombinator);
    _writeDirectiveUri(element.uri);
  }

  void _writeLibraryImport(LibraryImportImpl element) {
    _resolutionSink._writeMetadata(element.metadata);
    _sink.writeBool(element.isSynthetic);
    _sink.writeList(element.combinators, _writeNamespaceCombinator);
    _writeLibraryImportPrefixFragment(element.prefix2);
    _writeDirectiveUri(element.uri);
  }

  void _writeLibraryImportPrefixFragment(PrefixFragmentImpl? fragment) {
    _sink.writeOptionalObject(fragment, (fragment) {
      _writeFragmentName(fragment);
      _writeReference2(fragment.element.reference);
      _sink.writeBool(fragment.isDeferred);
    });
  }

  void _writeList<T>(List<T> elements, void Function(T) writeElement) {
    _sink.writeUInt30(elements.length);
    for (var element in elements) {
      writeElement(element);
    }
  }

  void _writeLoadLibraryFunctionReferences(LibraryElementImpl library) {
    var element = library.loadLibraryFunction2;
    _writeReference2(element.firstFragment.reference);
    _writeReference2(element.reference);
  }

  void _writeMethodElement(MethodFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(fragment);
    _writeReference2(fragment.element.reference);
    _writeFragmentName(fragment);
    MethodElementFlags.write(_sink, fragment);

    _resolutionSink._writeMetadata(fragment.metadata);

    _writeTypeParameters(fragment.typeParameters, () {
      _writeList(fragment.parameters, _writeParameterElement);
      _sink._writeTopLevelInferenceError(fragment.typeInferenceError);
      _resolutionSink.writeType(fragment.returnType);
    });
  }

  void _writeMixinElement(MixinFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);

    _writeReference(fragment);
    _writeReference2(fragment.element.reference);
    _writeFragmentName(fragment);
    MixinElementFlags.write(_sink, fragment);

    _resolutionSink._writeMetadata(fragment.metadata);

    _writeTypeParameters(fragment.typeParameters, () {
      _resolutionSink._writeTypeList(fragment.superclassConstraints);
      _resolutionSink._writeTypeList(fragment.interfaces);

      _writeList(
        fragment.fields.where((e) => !e.isSynthetic).toList(),
        _writeFieldElement,
      );
      _writeList(
        fragment.accessors.where((e) => !e.isSynthetic).toList(),
        _writePropertyAccessorElement,
      );
      _writeList(fragment.constructors, _writeConstructorElement);
      _writeList(fragment.methods, _writeMethodElement);
      _sink._writeStringList(fragment.superInvokedNames);
    });
  }

  void _writeNamespaceCombinator(NamespaceCombinator combinator) {
    switch (combinator) {
      case HideElementCombinator():
        _sink.writeByte(Tag.HideCombinator);
        _sink.writeList<String>(combinator.hiddenNames, (name) {
          _sink._writeStringReference(name);
        });
      case ShowElementCombinator():
        _sink.writeByte(Tag.ShowCombinator);
        _sink.writeList<String>(combinator.shownNames, (name) {
          _sink._writeStringReference(name);
        });
    }
  }

  void _writeOptionalReference(Reference? reference) {
    _sink.writeOptionalObject(reference, (reference) {
      var index = _references._indexOfReference(reference);
      _sink.writeUInt30(index);
    });
  }

  // TODO(scheglov): Deduplicate parameter writing implementation.
  void _writeParameterElement(FormalParameterFragmentImpl element) {
    _writeFragmentName(element);
    _sink.writeBool(element is ConstVariableFragment);
    _sink.writeBool(element.isInitializingFormal);
    _sink.writeBool(element.isSuperFormal);
    _writeOptionalReference(element.reference);
    _sink._writeFormalParameterKind(element);
    ParameterElementFlags.write(_sink, element);

    _resolutionSink._writeMetadata(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _writeList(element.parameters, _writeParameterElement);
      _resolutionSink.writeType(element.type);

      if (element is ConstVariableFragment) {
        var constElement = element as ConstVariableFragment;
        _resolutionSink._writeOptionalNode(constElement.constantInitializer);
      }
      if (element is FieldFormalParameterFragmentImpl) {
        _resolutionSink.writeFragmentOrMember(element.field);
      }
    });
  }

  /// We write metadata here, to keep it inside [unitElement] resolution
  /// data, because [_writePartInclude] recursively writes included unit
  /// elements. But the bundle reader wants all metadata for `parts`
  /// sequentially.
  void _writePartElementsMetadata(LibraryFragmentImpl unitElement) {
    for (var element in unitElement.parts) {
      _resolutionSink._writeMetadata(element.metadata);
    }
  }

  void _writePartInclude(PartIncludeImpl element) {
    _writeDirectiveUri(element.uri);
  }

  void _writePropertyAccessorElement(PropertyAccessorFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(fragment);
    _writeFragmentName(fragment);
    PropertyAccessorElementFlags.write(_sink, fragment);

    _resolutionSink._writeMetadata(fragment.metadata);
    _resolutionSink.writeType(fragment.returnType);
    _writeList(fragment.parameters, _writeParameterElement);

    // Write the reference for the variable, the reader will use it.
    if (!fragment.isAugmentation) {
      var variableFragment = fragment.variable2!;
      _writeReference(variableFragment);
      switch (variableFragment) {
        case FieldFragmentImpl fieldFragment:
          _writeReference2(fieldFragment.element.reference);
        case TopLevelVariableFragmentImpl topFragment:
          _writeReference2(topFragment.element.reference);
      }
      switch (variableFragment) {
        case FieldFragmentImpl fieldFragment:
          var field = fieldFragment.element;
          _sink.writeBool(field.isPromotable);
      }
    }
  }

  /// Write the reference of a non-local element.
  void _writeReference(FragmentImpl element) {
    _writeReference2(element.reference);
  }

  void _writeReference2(Reference? reference) {
    var index = _references._indexOfReference(reference);
    _sink.writeUInt30(index);
  }

  void _writeTopLevelVariableElement(TopLevelVariableFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(fragment);
    _writeReference2(fragment.element.reference);
    _writeOptionalReference(fragment.getter?.reference);
    _writeOptionalReference(fragment.setter?.reference);
    _writeFragmentName(fragment);
    _sink.writeBool(fragment.isConst);
    TopLevelVariableElementFlags.write(_sink, fragment);
    _sink._writeTopLevelInferenceError(fragment.typeInferenceError);
    _resolutionSink._writeMetadata(fragment.metadata);
    _resolutionSink.writeType(fragment.type);

    _resolutionSink._writeOptionalNode(fragment.constantInitializer);
  }

  void _writeTypeAliasElement(TypeAliasFragmentImpl fragment) {
    _sink.writeUInt30(_resolutionSink.offset);

    _writeReference(fragment);
    _writeReference2(fragment.element.reference);
    _writeFragmentName(fragment);
    _sink.writeBool(fragment.isFunctionTypeAliasBased);
    TypeAliasElementFlags.write(_sink, fragment);

    _resolutionSink._writeMetadata(fragment.metadata);

    _writeTypeParameters(fragment.typeParameters, () {
      _resolutionSink._writeAliasedElement(fragment.aliasedElement);
      _resolutionSink.writeType(fragment.aliasedType);
    });
  }

  void _writeTypeParameterElement(TypeParameterFragmentImpl element) {
    _writeFragmentName(element);
    _sink.writeByte(_encodeVariance(element).index);
    _resolutionSink._writeMetadata(element.metadata);
    _resolutionSink.writeType(element.bound);
    _resolutionSink.writeType(element.defaultType);
  }

  /// Add [typeParameters] to the indexing scope, so make them available
  /// when writing types that might reference them, and write the elements.
  void _writeTypeParameters(
    List<TypeParameterFragmentImpl> typeParameters,
    void Function() f,
  ) {
    _resolutionSink.localElements.withElements(typeParameters, () {
      _sink.writeList(typeParameters, _writeTypeParameterElement);
      f();
    });
  }

  void _writeUnitElement(LibraryFragmentImpl unitElement) {
    _sink.writeUInt30(_resolutionSink.offset);

    _sink.writeBool(unitElement.isSynthetic);

    _writeList(unitElement.libraryImports, _writeLibraryImport);
    _writeList(unitElement.libraryExports, _writeLibraryExport);

    // Write the metadata for parts here, even though we write parts below.
    // The reason is that resolution data must be in a single chunk.
    _writePartElementsMetadata(unitElement);

    _writeList(unitElement.classes, _writeClassElement);
    _writeList(unitElement.enums, _writeEnumElement);
    _writeList(unitElement.extensions, _writeExtensionElement);
    _writeList(unitElement.extensionTypes, _writeExtensionTypeElement);
    _writeList(unitElement.functions, _writeFunctionElement);
    _writeList(unitElement.mixins, _writeMixinElement);
    _writeList(unitElement.typeAliases, _writeTypeAliasElement);

    _writeList(
      unitElement.topLevelVariables
          .where((element) => !element.isSynthetic)
          .toList(),
      _writeTopLevelVariableElement,
    );
    _writeList(
      unitElement.accessors.where((e) => !e.isSynthetic).toList(),
      _writePropertyAccessorElement,
    );

    // Write parts after this library fragment, so that when we read, we
    // process fragments of declarations in the same order as we build them.
    _writeList(unitElement.parts, _writePartInclude);
  }

  static TypeParameterVarianceTag _encodeVariance(
    TypeParameterFragmentImpl element,
  ) {
    if (element.isLegacyCovariant) {
      return TypeParameterVarianceTag.legacy;
    }

    var variance = element.variance;
    if (variance == Variance.unrelated) {
      return TypeParameterVarianceTag.unrelated;
    } else if (variance == Variance.covariant) {
      return TypeParameterVarianceTag.covariant;
    } else if (variance == Variance.contravariant) {
      return TypeParameterVarianceTag.contravariant;
    } else if (variance == Variance.invariant) {
      return TypeParameterVarianceTag.invariant;
    } else {
      throw UnimplementedError('$variance');
    }
  }
}

class BundleWriterResult {
  final Uint8List resolutionBytes;

  BundleWriterResult({required this.resolutionBytes});
}

class ResolutionSink extends _SummaryDataWriter {
  final _BundleWriterReferences _references;
  final _LocalElementIndexer localElements = _LocalElementIndexer();

  ResolutionSink({
    required super.stringIndexer,
    required _BundleWriterReferences references,
  }) : _references = references;

  void writeElement(Element? element) {
    switch (element) {
      case null:
        writeEnum(ElementTag.null_);
      case DynamicElementImpl2():
        writeEnum(ElementTag.dynamic_);
      case NeverElementImpl2():
        writeEnum(ElementTag.never_);
      case MultiplyDefinedElementImpl2():
        writeEnum(ElementTag.multiplyDefined);
      case Member element:
        writeEnum(ElementTag.memberWithTypeArguments);

        var baseElement = element.baseElement;
        writeElement(baseElement);

        var typeArguments = _enclosingClassTypeArguments(
          baseElement,
          element.substitution.map,
        );
        _writeTypeList(typeArguments);
      // TODO(scheglov): give reference to each element below
      case FormalParameterElementImpl():
      case GetterElementImpl():
      case SetterElementImpl():
      case TypeParameterElementImpl2():
        // TODO(scheglov): eventually stop using fragments here.
        writeEnum(ElementTag.viaFragment);
        writeByte(Tag.RawElement);
        _writeElement(element);
      case ElementImpl2():
        writeEnum(ElementTag.elementImpl);
        var reference = element.reference!;
        var referenceIndex = _references._indexOfReference(reference);
        writeUInt30(referenceIndex);
      default:
        throw StateError('${element.runtimeType}');
    }
  }

  // TODO(scheglov): Triage places where we write elements.
  // Some of then cannot be members, e.g. type names.
  void writeFragmentOrMember(FragmentOrMember? element) {
    if (element == null) {
      writeByte(Tag.RawElement);
      writeUInt30(0);
    } else if (element is Member) {
      var declaration = element.declaration;

      var typeArguments = _enclosingClassTypeArguments(
        declaration.asElement2!,
        element.substitution.map,
      );

      writeByte(Tag.MemberWithTypeArguments);
      _writeFragmentImpl(declaration);
      _writeTypeList(typeArguments);
    } else {
      writeByte(Tag.RawElement);
      _writeFragmentImpl(element as FragmentImpl);
    }
  }

  void writeOptionalTypeList(List<DartType>? types) {
    if (types != null) {
      writeBool(true);
      _writeTypeList(types);
    } else {
      writeBool(false);
    }
  }

  void writeType(DartType? type) {
    if (type == null) {
      writeByte(Tag.NullType);
    } else if (type is DynamicTypeImpl) {
      writeByte(Tag.DynamicType);
      _writeTypeAliasElementArguments(type);
    } else if (type is FunctionTypeImpl) {
      _writeFunctionType(type);
      _writeTypeAliasElementArguments(type);
    } else if (type is InterfaceTypeImpl) {
      var typeArguments = type.typeArguments;
      var nullabilitySuffix = type.nullabilitySuffix;
      if (typeArguments.isEmpty) {
        if (nullabilitySuffix == NullabilitySuffix.none) {
          writeByte(Tag.InterfaceType_noTypeArguments_none);
        } else if (nullabilitySuffix == NullabilitySuffix.question) {
          writeByte(Tag.InterfaceType_noTypeArguments_question);
        }
        // TODO(scheglov): Write raw
        writeElement(type.element3);
      } else {
        writeByte(Tag.InterfaceType);
        // TODO(scheglov): Write raw
        writeElement(type.element3);
        writeUInt30(typeArguments.length);
        for (var i = 0; i < typeArguments.length; ++i) {
          writeType(typeArguments[i]);
        }
        _writeNullabilitySuffix(nullabilitySuffix);
      }
      _writeTypeAliasElementArguments(type);
    } else if (type is InvalidTypeImpl) {
      writeByte(Tag.InvalidType);
      _writeTypeAliasElementArguments(type);
    } else if (type is NeverTypeImpl) {
      writeByte(Tag.NeverType);
      _writeNullabilitySuffix(type.nullabilitySuffix);
      _writeTypeAliasElementArguments(type);
    } else if (type is RecordTypeImpl) {
      _writeRecordType(type);
      _writeTypeAliasElementArguments(type);
    } else if (type is TypeParameterTypeImpl) {
      writeByte(Tag.TypeParameterType);
      writeElement(type.element3);
      _writeNullabilitySuffix(type.nullabilitySuffix);
      _writeTypeAliasElementArguments(type);
    } else if (type is VoidTypeImpl) {
      writeByte(Tag.VoidType);
      _writeTypeAliasElementArguments(type);
    } else {
      throw UnimplementedError('${type.runtimeType}');
    }
  }

  int _indexOfElement(FragmentImpl element) {
    // Positional parameters cannot be referenced outside of their scope,
    // so don't have a reference, so are stored as local elements.
    if (element is FormalParameterFragmentImpl && element.reference == null) {
      return localElements[element] << 1 | 0x1;
    }

    // Type parameters cannot be referenced outside of their scope,
    // so don't have a reference, so are stored as local elements.
    if (element is TypeParameterFragmentImpl) {
      return localElements[element] << 1 | 0x1;
    }

    if (identical(element, DynamicFragmentImpl.instance)) {
      return _references._dynamicReferenceIndex << 1;
    }

    var reference = element.reference;
    return _references._indexOfReference(reference) << 1;
  }

  void _writeAliasedElement(FragmentImpl? element) {
    if (element == null) {
      writeByte(AliasedElementTag.nothing);
    } else if (element is GenericFunctionTypeFragmentImpl) {
      writeByte(AliasedElementTag.genericFunctionElement);
      _writeTypeParameters(element.typeParameters, () {
        _writeFormalParameters(element.parameters, withAnnotations: true);
        writeType(element.returnType);
      }, withAnnotations: true);
    } else {
      throw UnimplementedError('${element.runtimeType}');
    }
  }

  void _writeElement(Element? element) {
    switch (element) {
      case null:
      case MultiplyDefinedElementImpl2():
        writeUInt30(0);
      case DynamicElementImpl2():
        _writeFragmentImpl(DynamicFragmentImpl.instance);
      case ExecutableElementImpl2 element:
        _writeFragmentImpl(element.asElement as FragmentImpl);
      case FieldElementImpl2 element:
        _writeFragmentImpl(element.asElement);
      case FormalParameterElementImpl element:
        _writeFragmentImpl(element.asElement);
      case InstanceElementImpl2 element:
        _writeFragmentImpl(element.asElement);
      case NeverElementImpl2():
        _writeFragmentImpl(NeverFragmentImpl.instance);
      case TopLevelVariableElementImpl2 element:
        _writeFragmentImpl(element.asElement);
      case TypeAliasElementImpl2 element:
        _writeFragmentImpl(element.asElement);
      case TypeParameterElementImpl2 element:
        _writeFragmentImpl(element.asElement);
      default:
        throw UnimplementedError('${element.runtimeType}');
    }
  }

  void _writeElementList(List<Element> elements) {
    writeUInt30(elements.length);
    for (var element in elements) {
      writeElement(element);
    }
  }

  void _writeFormalParameters(
    List<ParameterElementMixin> parameters, {
    required bool withAnnotations,
  }) {
    writeUInt30(parameters.length);
    for (var parameter in parameters) {
      _writeFormalParameterKind(parameter);
      writeBool(parameter is ConstVariableFragment);
      writeBool(parameter.hasImplicitType);
      writeBool(parameter.isInitializingFormal);
      _writeTypeParameters(parameter.typeParameters, () {
        writeType(parameter.type);
        _writeFragmentName(parameter);
        _writeFormalParameters(
          parameter.parameters,
          withAnnotations: withAnnotations,
        );
      }, withAnnotations: withAnnotations);
      if (withAnnotations) {
        _writeMetadata(parameter.metadata);
      }
    }
  }

  void _writeFragmentImpl(FragmentImpl element) {
    var elementIndex = _indexOfElement(element);
    writeUInt30(elementIndex);
  }

  void _writeFragmentName(Fragment fragment) {
    _writeOptionalStringReference(fragment.name2);
  }

  void _writeFunctionType(FunctionTypeImpl type) {
    type = _toSyntheticFunctionType(type);

    writeByte(Tag.FunctionType);

    _writeTypeParameters(type.typeFormals, () {
      writeType(type.returnType);
      _writeFormalParameters(
        type.parameters.map((e) => e.asElement).toList(),
        withAnnotations: false,
      );
    }, withAnnotations: false);
    _writeNullabilitySuffix(type.nullabilitySuffix);
  }

  void _writeMetadata(MetadataImpl metadata) {
    writeList(metadata.annotations, (annotation) {
      _writeNode(annotation.annotationAst);
    });
  }

  void _writeNode(AstNode node) {
    var astWriter = AstBinaryWriter(sink: this, stringIndexer: _stringIndexer);
    node.accept(astWriter);
  }

  void _writeNodeList(List<AstNode> nodes) {
    writeUInt30(nodes.length);
    for (var node in nodes) {
      _writeNode(node);
    }
  }

  void _writeNullabilitySuffix(NullabilitySuffix suffix) {
    writeByte(suffix.index);
  }

  void _writeOptionalNode(Expression? node) {
    if (node != null) {
      writeBool(true);
      _writeNode(node);
    } else {
      writeBool(false);
    }
  }

  void _writeRecordType(RecordTypeImpl type) {
    writeByte(Tag.RecordType);

    writeList<RecordTypePositionalField>(type.positionalFields, (field) {
      writeType(field.type);
    });

    writeList<RecordTypeNamedField>(type.namedFields, (field) {
      _writeStringReference(field.name);
      writeType(field.type);
    });

    _writeNullabilitySuffix(type.nullabilitySuffix);
  }

  void _writeTypeAliasElementArguments(TypeImpl type) {
    var alias = type.alias;
    _writeElement(alias?.element2);
    if (alias != null) {
      _writeTypeList(alias.typeArguments);
    }
  }

  void _writeTypeList(List<DartType> types) {
    writeUInt30(types.length);
    for (var type in types) {
      writeType(type);
    }
  }

  void _writeTypeParameters(
    List<TypeParameterFragmentImpl> typeParameters,
    void Function() f, {
    required bool withAnnotations,
  }) {
    localElements.withElements(typeParameters, () {
      writeUInt30(typeParameters.length);
      for (var typeParameter in typeParameters) {
        _writeFragmentName(typeParameter);
      }
      for (var typeParameter in typeParameters) {
        writeType(typeParameter.bound);
        if (withAnnotations) {
          _writeMetadata(typeParameter.metadata);
        }
      }
      f();
    });
  }

  static List<DartType> _enclosingClassTypeArguments(
    Element declaration,
    Map<TypeParameterElement, DartType> substitution,
  ) {
    // TODO(scheglov): Just keep it null in class Member?
    if (substitution.isEmpty) {
      return const [];
    }

    var enclosing = declaration.enclosingElement;
    if (enclosing is InstanceElement) {
      var typeParameters = enclosing.typeParameters2;
      if (typeParameters.isEmpty) {
        return const <DartType>[];
      }

      return typeParameters
          .map((typeParameter) => substitution[typeParameter])
          .nonNulls
          .toList(growable: false);
    }

    return const <DartType>[];
  }

  static FunctionTypeImpl _toSyntheticFunctionType(FunctionTypeImpl type) {
    var typeParameters = [for (var tp in type.typeFormals) tp.asElement2];
    if (typeParameters.isEmpty) return type;

    var fresh = getFreshTypeParameters2(typeParameters);
    return fresh.applyToFunctionType(type);
  }
}

class StringIndexer {
  final Map<String, int> _index = {};

  int operator [](String string) {
    var result = _index[string];

    if (result == null) {
      result = _index.length;
      _index[string] = result;
    }

    return result;
  }

  int write(BufferedSink sink) {
    var bytesOffset = sink.offset;

    var length = _index.length;
    var lengths = Uint32List(length);
    var lengthsIndex = 0;
    for (var key in _index.keys) {
      var stringStart = sink.offset;
      _writeWtf8(sink, key);
      lengths[lengthsIndex++] = sink.offset - stringStart;
    }

    var resultOffset = sink.offset;

    var lengthOfBytes = sink.offset - bytesOffset;
    sink.writeUInt30(lengthOfBytes);
    sink.writeUint30List(lengths);

    return resultOffset;
  }

  /// Write [source] string into [sink].
  static void _writeWtf8(BufferedSink sink, String source) {
    var end = source.length;
    if (end == 0) {
      return;
    }

    int i = 0;
    do {
      var codeUnit = source.codeUnitAt(i++);
      if (codeUnit < 128) {
        // ASCII.
        sink.writeByte(codeUnit);
      } else if (codeUnit < 0x800) {
        // Two-byte sequence (11-bit unicode value).
        sink.writeByte(0xC0 | (codeUnit >> 6));
        sink.writeByte(0x80 | (codeUnit & 0x3f));
      } else if ((codeUnit & 0xFC00) == 0xD800 &&
          i < end &&
          (source.codeUnitAt(i) & 0xFC00) == 0xDC00) {
        // Surrogate pair -> four-byte sequence (non-BMP unicode value).
        int codeUnit2 = source.codeUnitAt(i++);
        int unicode =
            0x10000 + ((codeUnit & 0x3FF) << 10) + (codeUnit2 & 0x3FF);
        sink.writeByte(0xF0 | (unicode >> 18));
        sink.writeByte(0x80 | ((unicode >> 12) & 0x3F));
        sink.writeByte(0x80 | ((unicode >> 6) & 0x3F));
        sink.writeByte(0x80 | (unicode & 0x3F));
      } else {
        // Three-byte sequence (16-bit unicode value), including lone
        // surrogates.
        sink.writeByte(0xE0 | (codeUnit >> 12));
        sink.writeByte(0x80 | ((codeUnit >> 6) & 0x3f));
        sink.writeByte(0x80 | (codeUnit & 0x3f));
      }
    } while (i < end);
  }
}

class UnitToWriteAst {
  final CompilationUnit node;

  UnitToWriteAst({required this.node});
}

class _BundleWriterReferences {
  /// The `dynamic` class is declared in `dart:core`, but is not a class.
  /// Also, it is static, so we cannot set `reference` for it.
  /// So, we have to push it in a separate way.
  final Reference _dynamicReference;

  /// References used in all libraries being linked.
  /// Element references in nodes are indexes in this list.
  final List<Reference?> _references = [null];

  final List<int> _referenceParents = [0];
  final List<String> _referenceNames = [''];

  _BundleWriterReferences(this._dynamicReference);

  /// The index for the `dynamic` element.
  int get _dynamicReferenceIndex {
    return _indexOfReference(_dynamicReference);
  }

  /// We need indexes for references during linking, but once we are done,
  /// we must clear indexes to make references ready for linking a next bundle.
  void _clearIndexes() {
    for (var reference in _references) {
      if (reference != null) {
        reference.index = null;
      }
    }
  }

  int _indexOfReference(Reference? reference) {
    if (reference == null) return 0;
    if (reference.parent == null) return 0;

    var index = reference.index;
    if (index != null) return index;

    var parentIndex = _indexOfReference(reference.parent);
    _referenceParents.add(parentIndex);
    _referenceNames.add(reference.name);

    index = _references.length;
    reference.index = index;
    _references.add(reference);
    return index;
  }
}

class _Library {
  final String uriStr;
  final int offset;
  final List<int> classMembersOffsets;

  _Library({
    required this.uriStr,
    required this.offset,
    required this.classMembersOffsets,
  });
}

class _LocalElementIndexer {
  final Map<FragmentImpl, int> _index = Map.identity();
  int _stackHeight = 0;

  int operator [](FragmentImpl element) {
    return _index[element] ??
        (throw ArgumentError('Unexpectedly not indexed: $element'));
  }

  void withElements(List<FragmentImpl> elements, void Function() f) {
    for (var element in elements) {
      _index[element] = _stackHeight++;
    }

    f();

    _stackHeight -= elements.length;
    for (var element in elements) {
      _index.remove(element);
    }
  }
}

class _SummaryDataWriter extends BufferedSink {
  final StringIndexer _stringIndexer;

  _SummaryDataWriter({required StringIndexer stringIndexer})
    : _stringIndexer = stringIndexer;

  void _writeFormalParameterKind(ParameterElementMixin p) {
    if (p.isRequiredPositional) {
      writeByte(Tag.ParameterKindRequiredPositional);
    } else if (p.isOptionalPositional) {
      writeByte(Tag.ParameterKindOptionalPositional);
    } else if (p.isRequiredNamed) {
      writeByte(Tag.ParameterKindRequiredNamed);
    } else if (p.isOptionalNamed) {
      writeByte(Tag.ParameterKindOptionalNamed);
    } else {
      throw StateError('Unexpected parameter kind: $p');
    }
  }

  void _writeOptionalStringReference(String? value) {
    if (value != null) {
      writeBool(true);
      _writeStringReference(value);
    } else {
      writeBool(false);
    }
  }

  void _writeStringList(List<String> values) {
    writeUInt30(values.length);
    for (var value in values) {
      _writeStringReference(value);
    }
  }

  void _writeStringReference(String string) {
    var index = _stringIndexer[string];
    writeUInt30(index);
  }

  void _writeTopLevelInferenceError(TopLevelInferenceError? error) {
    if (error != null) {
      writeByte(error.kind.index);
      _writeStringList(error.arguments);
    } else {
      writeByte(TopLevelInferenceErrorKind.none.index);
    }
  }
}
