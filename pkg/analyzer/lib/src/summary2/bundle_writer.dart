// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

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
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/element_flags.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:collection/collection.dart';

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
    sink: ByteSink(),
    stringIndexer: _stringIndexer,
  );

  /// The resolution sink - any data that references elements, so can only
  /// be read after elements are created and available via its [Reference]s.
  late final ResolutionSink _resolutionSink = ResolutionSink(
    sink: ByteSink(),
    stringIndexer: _stringIndexer,
    references: _references,
  );

  /// [_writeClassElement] remembers the length of data written into [_sink]
  /// while writing members. So, when we read, we can skip members initially,
  /// and read them later on demand.
  List<int> _classMembersLengths = [];

  /// [_writePropertyAccessorElement] adds augmentations here, so that after
  /// reading the library we can read them, and while doing this, update
  /// `getter` and `setter` of augmented variables.
  List<PropertyAccessorElementImpl> _accessorAugmentations = [];

  /// [_writeFieldElement] adds augmentations here, so that after
  /// reading the library we can read them, and while doing this, update
  /// getters and setter to point at this property augmentation, and set
  /// `getter` and `setter` of the augmentation.
  List<PropertyInducingElementImpl> _propertyAugmentations = [];

  final StringIndexer _stringIndexer = StringIndexer();

  final List<_Library> _libraries = [];

  BundleWriter(Reference dynamicReference) {
    _references = _BundleWriterReferences(dynamicReference);
  }

  BundleWriterResult finish() {
    var baseResolutionOffset = _sink.offset;
    _sink.addBytes(_resolutionSink.flushAndTake());

    var librariesOffset = _sink.offset;
    _sink.writeList<_Library>(_libraries, (library) {
      _sink._writeStringReference(library.uriStr);
      _sink.writeUInt30(library.offset);
      _sink.writeUint30List(library.classMembersOffsets);
      _sink.writeOptionalObject(library.macroGenerated, (it) {
        _sink.writeStringUtf8(it.code);
      });
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

    var bytes = _sink.flushAndTake();
    return BundleWriterResult(
      resolutionBytes: bytes,
    );
  }

  void writeLibraryElement(LibraryElementImpl libraryElement) {
    var libraryOffset = _sink.offset;
    _classMembersLengths = [];
    _accessorAugmentations = [];
    _propertyAugmentations = [];

    _sink.writeUInt30(_resolutionSink.offset);
    _sink._writeStringReference(libraryElement.name);
    _writeFeatureSet(libraryElement.featureSet);
    _writeLanguageVersion(libraryElement.languageVersion);
    _writeLibraryOrAugmentationElement(libraryElement);
    for (final partElement in libraryElement.parts) {
      _resolutionSink._writeAnnotationList(partElement.metadata);
    }
    _resolutionSink.writeElement(libraryElement.entryPoint);
    _writeFieldNameNonPromotabilityInfo(
        libraryElement.fieldNameNonPromotabilityInfo);
    LibraryElementFlags.write(_sink, libraryElement);
    _writeUnitElement(libraryElement.definingCompilationUnit);
    _writeList(libraryElement.parts, _writePartElement);

    _writeExportedReferences(libraryElement.exportedReferences);

    _sink.writeUint30List(libraryElement.nameUnion.mask);

    _writePropertyAccessorAugmentations();

    final lastAugmentation = libraryElement.augmentations.lastOrNull;
    final macroGenerated = lastAugmentation?.macroGenerated;

    _libraries.add(
      _Library(
        uriStr: '${libraryElement.source.uri}',
        offset: libraryOffset,
        classMembersOffsets: _classMembersLengths,
        macroGenerated: macroGenerated,
      ),
    );
  }

  void _writeAugmentationElement(LibraryAugmentationElementImpl augmentation) {
    _sink.writeOptionalObject(augmentation.macroGenerated, (macroGenerated) {
      _sink.writeStringUtf8(macroGenerated.code);
      _sink.writeUint8List(macroGenerated.informativeBytes);
    });
    _writeUnitElement(augmentation.definingCompilationUnit);
    // The offset where resolution for the augmentation starts.
    // We need it to skip resolution information from the unit.
    _sink.writeUInt30(_resolutionSink.offset);
    _writeLibraryOrAugmentationElement(augmentation);
  }

  void _writeAugmentationImportElement(AugmentationImportElementImpl element) {
    _resolutionSink._writeAnnotationList(element.metadata);
    _writeDirectiveUri(element.uri);
  }

  void _writeClassElement(ClassElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);

    _writeReference(element);
    ClassElementFlags.write(_sink, element);

    _sink.writeList<MacroApplicationError>(
      element.macroApplicationErrors,
      (x) => x.write(_sink),
    );

    _resolutionSink._writeAnnotationList(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _resolutionSink.writeType(element.supertype);
      _resolutionSink._writeTypeList(element.mixins);
      _resolutionSink._writeTypeList(element.interfaces);
      _resolutionSink.writeElement(element.augmentation);
      if (element.isAugmentation) {
        _resolutionSink.writeElement(element.augmentationTarget);
      } else {
        _resolutionSink.writeIfType<AugmentedClassElementImpl>(
          element.augmented,
          (augmented) {
            _resolutionSink._writeTypeList(augmented.mixins);
            _resolutionSink._writeTypeList(augmented.interfaces);
            _resolutionSink._writeElementList(augmented.fields);
            _resolutionSink._writeElementList(augmented.constructors);
            _resolutionSink._writeElementList(augmented.accessors);
            _resolutionSink._writeElementList(augmented.methods);
          },
        );
      }

      if (!element.isMixinApplication) {
        var membersOffset = _sink.offset;
        _writeList(
          element.fields.where((e) => !e.isSynthetic).toList(),
          _writeFieldElement,
        );
        _writeList(
          element.accessors.where((e) => !e.isSynthetic).toList(),
          _writePropertyAccessorElement,
        );
        _writeList(element.constructors, _writeConstructorElement);
        _writeList(element.methods, _writeMethodElement);
        _classMembersLengths.add(_sink.offset - membersOffset);
      }
    });
  }

  void _writeConstructorElement(ConstructorElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    ConstructorElementFlags.write(_sink, element);
    _resolutionSink._writeAnnotationList(element.metadata);

    _resolutionSink.localElements.withElements(element.parameters, () {
      _writeList(element.parameters, _writeParameterElement);
      _resolutionSink.writeElement(element.superConstructor);
      _resolutionSink.writeElement(element.redirectedConstructor);
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

    if (element is DirectiveUriWithAugmentationImpl) {
      _sink.writeByte(DirectiveUriKind.withAugmentation.index);
      writeWithSource(element);
      _writeAugmentationElement(element.augmentation);
    } else if (element is DirectiveUriWithLibrary) {
      _sink.writeByte(DirectiveUriKind.withLibrary.index);
      writeWithSource(element);
    } else if (element is DirectiveUriWithUnitImpl) {
      _sink.writeByte(DirectiveUriKind.withUnit.index);
      writeWithSource(element);
      _writeUnitElement(element.unit);
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

  void _writeEnumElement(EnumElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    EnumElementFlags.write(_sink, element);
    _resolutionSink._writeAnnotationList(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _resolutionSink.writeType(element.supertype);
      _resolutionSink._writeTypeList(element.mixins);
      _resolutionSink._writeTypeList(element.interfaces);

      _writeList(
        element.fields.where((e) {
          return !e.isSynthetic || e.isSyntheticEnumField;
        }).toList(),
        _writeFieldElement,
      );
      _writeList(
        element.accessors.where((e) => !e.isSynthetic).toList(),
        _writePropertyAccessorElement,
      );
      _writeList(element.constructors, _writeConstructorElement);
      _writeList(element.methods, _writeMethodElement);
    });
  }

  void _writeExportedReferences(List<ExportedReference> elements) {
    _writeList<ExportedReference>(elements, (exported) {
      final index = _references._indexOfReference(exported.reference);
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

  void _writeExportElement(LibraryExportElementImpl element) {
    _resolutionSink._writeAnnotationList(element.metadata);
    _sink.writeList(element.combinators, _writeNamespaceCombinator);
    _writeDirectiveUri(element.uri);
  }

  void _writeExportLocation(ExportLocation location) {
    _sink.writeUInt30(location.containerIndex);
    _sink.writeUInt30(location.exportIndex);
  }

  void _writeExtensionElement(ExtensionElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);

    _writeReference(element);
    _sink.writeBool(element.name != null);

    _resolutionSink._writeAnnotationList(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _resolutionSink.writeType(element.extendedType);

      _writeList(
        element.accessors.where((e) => !e.isSynthetic).toList(),
        _writePropertyAccessorElement,
      );
      _writeList(
        element.fields.where((e) => !e.isSynthetic).toList(),
        _writeFieldElement,
      );
      _writeList(element.methods, _writeMethodElement);
    });
  }

  void _writeExtensionTypeElement(ExtensionTypeElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    ExtensionTypeElementFlags.write(_sink, element);
    _resolutionSink._writeAnnotationList(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _resolutionSink.writeType(element.typeErasure);
      _resolutionSink._writeTypeList(element.interfaces);
      _writeList(
        element.fields.where((e) => !e.isSynthetic).toList(),
        _writeFieldElement,
      );
      _writeList(
        element.accessors.where((e) => !e.isSynthetic).toList(),
        _writePropertyAccessorElement,
      );
      _writeList(element.constructors, _writeConstructorElement);
      _writeList(element.methods, _writeMethodElement);
    });
  }

  void _writeFeatureSet(FeatureSet featureSet) {
    var experimentStatus = featureSet as ExperimentStatus;
    var encoded = experimentStatus.toStorage();
    _sink.writeUint8List(encoded);
  }

  void _writeFieldElement(FieldElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    _writeOptionalReference(element.getter);
    _writeOptionalReference(element.setter);
    _sink.writeBool(element is ConstFieldElementImpl);
    FieldElementFlags.write(_sink, element);
    _sink._writeTopLevelInferenceError(element.typeInferenceError);
    _resolutionSink._writeAnnotationList(element.metadata);
    _resolutionSink.writeType(element.type);

    _resolutionSink.writeElement(element.augmentationTarget);
    if (element.isAugmentation) {
      _propertyAugmentations.add(element);
    }

    _resolutionSink._writeOptionalNode(element.constantInitializer);
  }

  void _writeFieldNameNonPromotabilityInfo(
      Map<String, FieldNameNonPromotabilityInfo>? info) {
    // The summary format for `LibraryElementImpl.fieldNameNonPromotabilityInfo`
    // is as follows:
    // - bool: `true` if field name non-promotability information is present,
    //   `false` if not.
    // - If information is present:
    //   - Uint30: number of entries in the map.
    //   - For each map entry:
    //     - String reference: key
    //     - Element list: `FieldNameNonPromotabilityInfo.conflictingFields`
    //     - Element list: `FieldNameNonPromotabilityInfo.conflictingGetters`
    //     - Element list: `FieldNameNonPromotabilityInfo.conflictingNsmClasses`
    _resolutionSink.writeBool(info != null);
    if (info == null) {
      return;
    }
    _resolutionSink.writeUInt30(info.length);
    for (var MapEntry(:key, :value) in info.entries) {
      _resolutionSink._writeStringReference(key);
      _resolutionSink._writeElementList(value.conflictingFields);
      _resolutionSink._writeElementList(value.conflictingGetters);
      _resolutionSink._writeElementList(value.conflictingNsmClasses);
    }
  }

  void _writeFunctionElement(FunctionElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    FunctionElementFlags.write(_sink, element);

    _resolutionSink._writeAnnotationList(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _resolutionSink.writeType(element.returnType);
      _writeList(element.parameters, _writeParameterElement);
    });

    _resolutionSink.writeElement(element.augmentation);
    _resolutionSink.writeElement(element.augmentationTarget);
  }

  void _writeImportElement(LibraryImportElementImpl element) {
    _resolutionSink._writeAnnotationList(element.metadata);
    _sink.writeList(element.combinators, _writeNamespaceCombinator);
    _writeImportElementPrefix(element.prefix);
    _writeDirectiveUri(element.uri);
    LibraryImportElementFlags.write(_sink, element);
  }

  void _writeImportElementPrefix(ImportElementPrefix? prefix) {
    if (prefix is DeferredImportElementPrefix) {
      _sink.writeByte(ImportElementPrefixKind.isDeferred.index);
      _sink._writeStringReference(prefix.element.name);
    } else if (prefix is ImportElementPrefix) {
      _sink.writeByte(ImportElementPrefixKind.isNotDeferred.index);
      _sink._writeStringReference(prefix.element.name);
    } else {
      _sink.writeByte(ImportElementPrefixKind.isNull.index);
    }
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

  void _writeLibraryOrAugmentationElement(
    LibraryOrAugmentationElementImpl container,
  ) {
    _resolutionSink._writeAnnotationList(container.metadata);
    _writeList(container.libraryImports, _writeImportElement);
    _writeList(container.libraryExports, _writeExportElement);
    _writeList(
      container.augmentationImports,
      _writeAugmentationImportElement,
    );
  }

  void _writeList<T>(List<T> elements, void Function(T) writeElement) {
    _sink.writeUInt30(elements.length);
    for (var element in elements) {
      writeElement(element);
    }
  }

  void _writeMethodElement(MethodElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    MethodElementFlags.write(_sink, element);

    _resolutionSink._writeAnnotationList(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _writeList(element.parameters, _writeParameterElement);
      _sink._writeTopLevelInferenceError(element.typeInferenceError);
      _resolutionSink.writeType(element.returnType);
      _resolutionSink.writeElement(element.augmentation);
      _resolutionSink.writeElement(element.augmentationTarget);
    });
  }

  void _writeMixinElement(MixinElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);

    _writeReference(element);
    MixinElementFlags.write(_sink, element);
    _resolutionSink._writeAnnotationList(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _resolutionSink._writeTypeList(element.superclassConstraints);
      _resolutionSink._writeTypeList(element.interfaces);
      _resolutionSink.writeElement(element.augmentation);
      if (element.isAugmentation) {
        _resolutionSink.writeElement(element.augmentationTarget);
      } else {
        _resolutionSink.writeIfType<AugmentedMixinElementImpl>(
          element.augmented,
          (augmented) {
            _resolutionSink._writeTypeList(augmented.superclassConstraints);
            _resolutionSink._writeTypeList(augmented.interfaces);
            _resolutionSink._writeElementList(augmented.fields);
            _resolutionSink._writeElementList(augmented.accessors);
            _resolutionSink._writeElementList(augmented.methods);
          },
        );
      }

      _writeList(
        element.fields.where((e) => !e.isSynthetic).toList(),
        _writeFieldElement,
      );
      _writeList(
        element.accessors.where((e) => !e.isSynthetic).toList(),
        _writePropertyAccessorElement,
      );
      _writeList(element.constructors, _writeConstructorElement);
      _writeList(element.methods, _writeMethodElement);
      _sink._writeStringList(element.superInvokedNames);
    });
  }

  void _writeNamespaceCombinator(NamespaceCombinator combinator) {
    if (combinator is HideElementCombinator) {
      _sink.writeByte(Tag.HideCombinator);
      _sink.writeList<String>(combinator.hiddenNames, (name) {
        _sink._writeStringReference(name);
      });
    } else if (combinator is ShowElementCombinator) {
      _sink.writeByte(Tag.ShowCombinator);
      _sink.writeList<String>(combinator.shownNames, (name) {
        _sink._writeStringReference(name);
      });
    } else {
      throw UnimplementedError('${combinator.runtimeType}');
    }
  }

  /// Write the reference of a non-local element.
  void _writeOptionalReference(ElementImpl? element) {
    _sink.writeOptionalObject(element, (element) {
      _writeReference(element);
    });
  }

  /// TODO(scheglov) Deduplicate parameter writing implementation.
  void _writeParameterElement(ParameterElement element) {
    element as ParameterElementImpl;
    _sink._writeStringReference(element.name);
    _sink.writeBool(element is ConstVariableElement);
    _sink.writeBool(element.isInitializingFormal);
    _sink.writeBool(element.isSuperFormal);
    _writeReference(element);
    _sink._writeFormalParameterKind(element);
    ParameterElementFlags.write(_sink, element);

    _resolutionSink._writeAnnotationList(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _writeList(element.parameters, _writeParameterElement);
      _resolutionSink.writeType(element.type);

      if (element is ConstVariableElement) {
        var constElement = element as ConstVariableElement;
        _resolutionSink._writeOptionalNode(constElement.constantInitializer);
      }
      if (element is FieldFormalParameterElementImpl) {
        _resolutionSink.writeElement(element.field);
      }
    });
  }

  void _writePartElement(PartElement element) {
    _writeDirectiveUri(element.uri);
  }

  /// Write information to update `getter` and `setter` properties of
  /// augmented variables to use the corresponding augmentations.
  void _writePropertyAccessorAugmentations() {
    final offset = _resolutionSink.offset;
    _resolutionSink._writeElementList(_accessorAugmentations);
    _resolutionSink._writeElementList(_propertyAugmentations);
    _sink.writeUInt30(offset);
  }

  void _writePropertyAccessorElement(PropertyAccessorElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    PropertyAccessorElementFlags.write(_sink, element);

    _resolutionSink._writeAnnotationList(element.metadata);
    _resolutionSink.writeType(element.returnType);
    _writeList(element.parameters, _writeParameterElement);

    _resolutionSink.writeElement(element.augmentationTarget);
    if (element.isAugmentation) {
      _accessorAugmentations.add(element);
    }
  }

  /// Write the reference of a non-local element.
  void _writeReference(ElementImpl element) {
    final reference = element.reference;
    final index = _references._indexOfReference(reference);
    _sink.writeUInt30(index);
  }

  void _writeTopLevelVariableElement(TopLevelVariableElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);
    _writeReference(element);
    _writeOptionalReference(element.getter);
    _writeOptionalReference(element.setter);
    _sink.writeBool(element.isConst);
    TopLevelVariableElementFlags.write(_sink, element);
    _sink._writeTopLevelInferenceError(element.typeInferenceError);
    _resolutionSink._writeAnnotationList(element.metadata);
    _resolutionSink.writeType(element.type);
    _resolutionSink._writeOptionalNode(element.constantInitializer);
  }

  void _writeTypeAliasElement(TypeAliasElementImpl element) {
    _sink.writeUInt30(_resolutionSink.offset);

    _writeReference(element);
    _sink.writeBool(element.isFunctionTypeAliasBased);
    TypeAliasElementFlags.write(_sink, element);

    _resolutionSink._writeAnnotationList(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _resolutionSink._writeAliasedElement(element.aliasedElement);
      _resolutionSink.writeType(element.aliasedType);
    });
  }

  void _writeTypeParameterElement(TypeParameterElement typeParameter) {
    typeParameter as TypeParameterElementImpl;
    _sink._writeStringReference(typeParameter.name);
    _sink.writeByte(_encodeVariance(typeParameter).index);
    _resolutionSink._writeAnnotationList(typeParameter.metadata);
    _resolutionSink.writeType(typeParameter.bound);
    _resolutionSink.writeType(typeParameter.defaultType);
  }

  /// Add [typeParameters] to the indexing scope, so make them available
  /// when writing types that might reference them, and write the elements.
  void _writeTypeParameters(
    List<TypeParameterElement> typeParameters,
    void Function() f,
  ) {
    _resolutionSink.localElements.withElements(typeParameters, () {
      _sink.writeList(typeParameters, _writeTypeParameterElement);
      f();
    });
  }

  void _writeUnitElement(CompilationUnitElementImpl unitElement) {
    _sink.writeUInt30(_resolutionSink.offset);

    _sink._writeOptionalStringReference(unitElement.uri);
    _sink.writeBool(unitElement.isSynthetic);
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
  }

  static TypeParameterVarianceTag _encodeVariance(
      TypeParameterElementImpl element) {
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

  BundleWriterResult({
    required this.resolutionBytes,
  });
}

class ResolutionSink extends _SummaryDataWriter {
  final _BundleWriterReferences _references;
  final _LocalElementIndexer localElements = _LocalElementIndexer();

  ResolutionSink({
    required super.sink,
    required super.stringIndexer,
    required _BundleWriterReferences references,
  }) : _references = references;

  /// TODO(scheglov) Triage places where we write elements.
  /// Some of then cannot be members, e.g. type names.
  void writeElement(Element? element) {
    if (element is Member) {
      var declaration = element.declaration;
      var isLegacy = element.isLegacy;

      var typeArguments = _enclosingClassTypeArguments(
        declaration,
        element.substitution.map,
      );

      if (isLegacy) {
        if (typeArguments.isEmpty) {
          writeByte(Tag.MemberLegacyWithoutTypeArguments);
          _writeElement(declaration);
        } else {
          writeByte(Tag.MemberLegacyWithTypeArguments);
          _writeElement(declaration);
          _writeTypeList(typeArguments);
        }
      } else {
        writeByte(Tag.MemberWithTypeArguments);
        _writeElement(declaration);
        _writeTypeList(typeArguments);
      }
    } else {
      writeByte(Tag.RawElement);
      _writeElement(element);
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
    } else if (type is DynamicType) {
      writeByte(Tag.DynamicType);
      _writeTypeAliasElementArguments(type);
    } else if (type is FunctionType) {
      _writeFunctionType(type);
      _writeTypeAliasElementArguments(type);
    } else if (type is InterfaceType) {
      var typeArguments = type.typeArguments;
      var nullabilitySuffix = type.nullabilitySuffix;
      if (typeArguments.isEmpty) {
        if (nullabilitySuffix == NullabilitySuffix.none) {
          writeByte(Tag.InterfaceType_noTypeArguments_none);
        } else if (nullabilitySuffix == NullabilitySuffix.question) {
          writeByte(Tag.InterfaceType_noTypeArguments_question);
        } else if (nullabilitySuffix == NullabilitySuffix.star) {
          writeByte(Tag.InterfaceType_noTypeArguments_star);
        }
        // TODO(scheglov) Write raw
        writeElement(type.element);
      } else {
        writeByte(Tag.InterfaceType);
        // TODO(scheglov) Write raw
        writeElement(type.element);
        writeUInt30(typeArguments.length);
        for (var i = 0; i < typeArguments.length; ++i) {
          writeType(typeArguments[i]);
        }
        _writeNullabilitySuffix(nullabilitySuffix);
      }
      _writeTypeAliasElementArguments(type);
    } else if (type is InvalidType) {
      writeByte(Tag.InvalidType);
      _writeTypeAliasElementArguments(type);
    } else if (type is NeverType) {
      writeByte(Tag.NeverType);
      _writeNullabilitySuffix(type.nullabilitySuffix);
      _writeTypeAliasElementArguments(type);
    } else if (type is RecordTypeImpl) {
      _writeRecordType(type);
      _writeTypeAliasElementArguments(type);
    } else if (type is TypeParameterType) {
      writeByte(Tag.TypeParameterType);
      writeElement(type.element);
      _writeNullabilitySuffix(type.nullabilitySuffix);
      _writeTypeAliasElementArguments(type);
    } else if (type is VoidType) {
      writeByte(Tag.VoidType);
      _writeTypeAliasElementArguments(type);
    } else {
      throw UnimplementedError('${type.runtimeType}');
    }
  }

  int _indexOfElement(Element? element) {
    if (element == null) return 0;
    if (element is MultiplyDefinedElement) return 0;
    assert(element is! Member);

    // Positional parameters cannot be referenced outside of their scope,
    // so don't have a reference, so are stored as local elements.
    if (element is ParameterElementImpl && element.reference == null) {
      return localElements[element] << 1 | 0x1;
    }

    // Type parameters cannot be referenced outside of their scope,
    // so don't have a reference, so are stored as local elements.
    if (element is TypeParameterElement) {
      return localElements[element] << 1 | 0x1;
    }

    if (identical(element, DynamicElementImpl.instance)) {
      return _references._dynamicReferenceIndex << 1;
    }

    var reference = (element as ElementImpl).reference;
    return _references._indexOfReference(reference) << 1;
  }

  void _writeAliasedElement(Element? element) {
    if (element == null) {
      writeByte(AliasedElementTag.nothing);
    } else if (element is GenericFunctionTypeElement) {
      writeByte(AliasedElementTag.genericFunctionElement);
      _writeTypeParameters(element.typeParameters, () {
        _writeFormalParameters(element.parameters, withAnnotations: true);
        writeType(element.returnType);
      }, withAnnotations: true);
    } else {
      throw UnimplementedError('${element.runtimeType}');
    }
  }

  void _writeAnnotationList(List<ElementAnnotation> annotations) {
    writeUInt30(annotations.length);
    for (var annotation in annotations) {
      annotation as ElementAnnotationImpl;
      _writeNode(annotation.annotationAst);
    }
  }

  void _writeElement(Element? element) {
    assert(element is! Member, 'Use writeMemberOrElement()');
    var elementIndex = _indexOfElement(element);
    writeUInt30(elementIndex);
  }

  void _writeElementList(List<Element> elements) {
    writeUInt30(elements.length);
    for (final element in elements) {
      writeElement(element);
    }
  }

  void _writeFormalParameters(
    List<ParameterElement> parameters, {
    required bool withAnnotations,
  }) {
    writeUInt30(parameters.length);
    for (var parameter in parameters) {
      _writeFormalParameterKind(parameter);
      writeBool(parameter is ConstVariableElement);
      writeBool(parameter.hasImplicitType);
      writeBool(parameter.isInitializingFormal);
      _writeTypeParameters(parameter.typeParameters, () {
        writeType(parameter.type);
        _writeStringReference(parameter.name);
        _writeFormalParameters(
          parameter.parameters,
          withAnnotations: withAnnotations,
        );
      }, withAnnotations: withAnnotations);
      if (withAnnotations) {
        _writeAnnotationList(parameter.metadata);
      }
    }
  }

  void _writeFunctionType(FunctionType type) {
    type = _toSyntheticFunctionType(type);

    writeByte(Tag.FunctionType);

    _writeTypeParameters(type.typeFormals, () {
      writeType(type.returnType);
      _writeFormalParameters(type.parameters, withAnnotations: false);
    }, withAnnotations: false);
    _writeNullabilitySuffix(type.nullabilitySuffix);
  }

  void _writeNode(AstNode node) {
    var astWriter = AstBinaryWriter(
      sink: this,
      stringIndexer: _stringIndexer,
    );
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

  void _writeTypeAliasElementArguments(DartType type) {
    var alias = type.alias;
    _writeElement(alias?.element);
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
    List<TypeParameterElement> typeParameters,
    void Function() f, {
    required bool withAnnotations,
  }) {
    localElements.withElements(typeParameters, () {
      writeUInt30(typeParameters.length);
      for (var typeParameter in typeParameters) {
        _writeStringReference(typeParameter.name);
      }
      for (var typeParameter in typeParameters) {
        writeType(typeParameter.bound);
        if (withAnnotations) {
          _writeAnnotationList(typeParameter.metadata);
        }
      }
      f();
    });
  }

  static List<DartType> _enclosingClassTypeArguments(
    Element declaration,
    Map<TypeParameterElement, DartType> substitution,
  ) {
    // TODO(scheglov) Just keep it null in class Member?
    if (substitution.isEmpty) {
      return const [];
    }

    var enclosing = declaration.enclosingElement;
    if (enclosing is InstanceElement) {
      var typeParameters = enclosing.typeParameters;
      if (typeParameters.isEmpty) {
        return const <DartType>[];
      }

      return typeParameters
          .map((typeParameter) => substitution[typeParameter])
          .whereNotNull()
          .toList(growable: false);
    }

    return const <DartType>[];
  }

  static FunctionType _toSyntheticFunctionType(FunctionType type) {
    var typeParameters = type.typeFormals;
    if (typeParameters.isEmpty) return type;

    var fresh = getFreshTypeParameters(typeParameters);
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
        sink.addByte(codeUnit);
      } else if (codeUnit < 0x800) {
        // Two-byte sequence (11-bit unicode value).
        sink.addByte(0xC0 | (codeUnit >> 6));
        sink.addByte(0x80 | (codeUnit & 0x3f));
      } else if ((codeUnit & 0xFC00) == 0xD800 &&
          i < end &&
          (source.codeUnitAt(i) & 0xFC00) == 0xDC00) {
        // Surrogate pair -> four-byte sequence (non-BMP unicode value).
        int codeUnit2 = source.codeUnitAt(i++);
        int unicode =
            0x10000 + ((codeUnit & 0x3FF) << 10) + (codeUnit2 & 0x3FF);
        sink.addByte(0xF0 | (unicode >> 18));
        sink.addByte(0x80 | ((unicode >> 12) & 0x3F));
        sink.addByte(0x80 | ((unicode >> 6) & 0x3F));
        sink.addByte(0x80 | (unicode & 0x3F));
      } else {
        // Three-byte sequence (16-bit unicode value), including lone
        // surrogates.
        sink.addByte(0xE0 | (codeUnit >> 12));
        sink.addByte(0x80 | ((codeUnit >> 6) & 0x3f));
        sink.addByte(0x80 | (codeUnit & 0x3f));
      }
    } while (i < end);
  }
}

class UnitToWriteAst {
  final CompilationUnit node;

  UnitToWriteAst({
    required this.node,
  });
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

  /// The only (if any) macro generated augmentation.
  final MacroGeneratedAugmentationLibrary? macroGenerated;

  _Library({
    required this.uriStr,
    required this.offset,
    required this.classMembersOffsets,
    required this.macroGenerated,
  });
}

class _LocalElementIndexer {
  final Map<Element, int> _index = Map.identity();
  int _stackHeight = 0;

  int operator [](Element element) {
    return _index[element] ??
        (throw ArgumentError('Unexpectedly not indexed: $element'));
  }

  void withElements(List<Element> elements, void Function() f) {
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

  _SummaryDataWriter({
    required ByteSink sink,
    required StringIndexer stringIndexer,
  })  : _stringIndexer = stringIndexer,
        super(sink);

  void _writeFormalParameterKind(ParameterElement p) {
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
