// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/binary/string_table.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/reference.dart';

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
  late _SummaryDataWriter _sink = _SummaryDataWriter(
    stringIndexer: _stringIndexer,
  );

  /// The resolution sink - any data that references elements, so can only
  /// be read after elements are created and available via its [Reference]s.
  late final ResolutionSink _resolutionSink = ResolutionSink(
    stringIndexer: _stringIndexer,
    references: _references,
  );

  /// We fill this map before writing the library.
  ///
  /// When we write getter / setter fragments, we write non-synthetic
  /// fragments as full data objects. But for synthetic getter / setter
  /// fragments we write only the ID of the non-synthetic variable fragment,
  /// from this map.
  ///
  /// When we write property fragments, we write non-synthetic fragments as
  /// full data objects. But for synthetic property fragments we write the
  /// pair of getter / setter fragments IDs, from this map.
  final Map<FragmentImpl, int> _fragmentIds = Map.identity();

  final StringIndexer _stringIndexer = StringIndexer();

  final List<_Library> _libraries = [];

  BundleWriter() {
    _references = _BundleWriterReferences();
  }

  BundleWriterResult finish() {
    var baseResolutionOffset = _sink.offset;
    _sink.writeBytes(_resolutionSink.takeBytes());

    var librariesOffset = _sink.offset;
    _sink.writeList<_Library>(_libraries, (library) {
      _sink._writeStringReference(library.uriStr);
      _sink.writeUint30(library.offset);
    });

    var referencesOffset = _sink.offset;
    _sink.writeUint30List(_references._referenceParents);
    _sink._writeStringList(_references._referenceNames);
    _references._clearIndexes();

    var stringTableOffset = _stringIndexer.write(_sink);

    // Write as Uint32 so that we know where it is.
    _sink.writeUint32(baseResolutionOffset);
    _sink.writeUint32(librariesOffset);
    _sink.writeUint32(referencesOffset);
    _sink.writeUint32(stringTableOffset);

    var bytes = _sink.takeBytes();
    return BundleWriterResult(resolutionBytes: bytes);
  }

  void writeLibraryElement(LibraryElementImpl libraryElement) {
    var libraryOffset = _sink.offset;

    // Write non-resolution data for the library.
    _sink._writeStringReference(libraryElement.name);
    _writeFeatureSet(libraryElement.featureSet);
    libraryElement.writeModifiers(_sink);
    _writeLanguageVersion(libraryElement.languageVersion);
    _writeExportedReferences(libraryElement.exportedReferences);
    _sink.writeUint30List(libraryElement.nameUnion.mask);
    _writeLoadLibraryFunctionReferences(libraryElement);

    // Write the library units.
    // This will write also resolution data, e.g. for classes.
    _writeUnitElement(libraryElement.firstFragment);

    _writeClassElements(libraryElement.classes);
    _writeEnumElements(libraryElement.enums);
    _writeExtensionElements(libraryElement.extensions);
    _writeExtensionTypeElements(libraryElement.extensionTypes);
    _writeTopLevelFunctionElements(libraryElement.topLevelFunctions);
    _writeMixinElements(libraryElement.mixins);
    _writeTypeAliasElements(libraryElement.typeAliases);
    _writeTopLevelVariableElements(libraryElement.topLevelVariables);
    _writeGetterElements(libraryElement.getters);
    _writeSetterElements(libraryElement.setters);
    _writeVariableGetterSetterLinking(libraryElement.topLevelVariables);

    // Write resolution data for the library.
    _writeResolutionOffset();
    _resolutionSink._writeMetadata(libraryElement.metadata);
    _resolutionSink.writeElement(libraryElement.entryPoint);
    _writeFieldNameNonPromotabilityInfo(
      libraryElement.fieldNameNonPromotabilityInfo,
    );

    _libraries.add(
      _Library(uriStr: '${libraryElement.uri}', offset: libraryOffset),
    );
  }

  void _writeClassElements(List<ClassElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);
      _sink.writeBool(element.hasNonFinalField);

      // We read members lazily.
      _writeForLazyRead(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _writeFieldElements(element.fields);
          _writeGetterElements(element.getters);
          _writeSetterElements(element.setters);
          _writeVariableGetterSetterLinking(element.fields);
          _writeMethodElements(element.methods);
          if (!element.isMixinApplication) {
            _writeConstructorElements(element.constructors);
          }
        });
      });

      _writeElementResolution(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _resolutionSink.writeType(element.supertype);
          _resolutionSink._writeTypeList(element.mixins);
          _resolutionSink._writeTypeList(element.interfaces);
          _resolutionSink.writeOptionalElementList(element.interfaceCycle);
        });
      });
    });
  }

  void _writeClassFragment(ClassFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _writeTypeParameters(fragment.typeParameters, () {
        _resolutionSink._writeMetadata(fragment.metadata);

        _writeForLazyRead(() {
          _sink.writeList(fragment.fields, _writeFieldFragment);
          _sink.writeList(fragment.getters, _writeGetterFragment);
          _sink.writeList(fragment.setters, _writeSetterFragment);
          _sink.writeList(fragment.methods, _writeMethodFragment);
          if (!fragment.isMixinApplication) {
            _sink.writeList(fragment.constructors, _writeConstructorFragment);
          }
        });
      });
    });
  }

  void _writeConstructorElements(List<ConstructorElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);

      _writeElementResolution(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _resolutionSink.writeType(element.returnType);
          _resolutionSink.writeElement(element.superConstructor);
          _resolutionSink.writeElement(element.redirectedConstructor);
          // TODO(scheglov): formal parameters
        });
      });
    });
  }

  void _writeConstructorFragment(ConstructorFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _sink._writeOptionalStringReference(fragment.typeName);
      _writeTypeParameters(fragment.typeParameters, () {
        _sink.writeList(fragment.formalParameters, _writeParameterElement);
        _resolutionSink._writeMetadata(fragment.metadata);
        _resolutionSink.writeList(
          fragment.constantInitializers,
          _resolutionSink._writeNode,
        );
      });
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

  void _writeElementResolution(void Function() operation) {
    _writeResolutionOffset();
    operation();
  }

  void _writeEnumElements(List<EnumElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);

      // TODO(scheglov): consider reading lazily
      _resolutionSink.withTypeParameters(element.typeParameters, () {
        _writeFieldElements(element.fields);
        _writeGetterElements(element.getters);
        _writeSetterElements(element.setters);
        _writeVariableGetterSetterLinking(element.fields);
        _writeConstructorElements(element.constructors);
        _writeMethodElements(element.methods);
      });

      _writeElementResolution(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _resolutionSink.writeType(element.supertype);
          _resolutionSink._writeTypeList(element.mixins);
          _resolutionSink._writeTypeList(element.interfaces);
          _resolutionSink.writeOptionalElementList(element.interfaceCycle);
        });
      });
    });
  }

  void _writeEnumFragment(EnumFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _writeTypeParameters(fragment.typeParameters, () {
        _resolutionSink._writeMetadata(fragment.metadata);

        // TODO(scheglov): consider reading lazily
        _sink.writeList(fragment.fields, _writeFieldFragment);
        _sink.writeList(fragment.getters, _writeGetterFragment);
        _sink.writeList(fragment.setters, _writeSetterFragment);
        _sink.writeList(fragment.constructors, _writeConstructorFragment);
        _sink.writeList(fragment.methods, _writeMethodFragment);
      });
    });
  }

  void _writeExportedReferences(List<ExportedReference> elements) {
    _sink.writeList(elements, (exported) {
      var index = _references._indexOfReference(exported.reference);
      switch (exported) {
        case ExportedReferenceDeclared():
          _sink.writeByte(0);
          _sink.writeUint30(index);
        case ExportedReferenceExported():
          _sink.writeByte(1);
          _sink.writeUint30(index);
          _sink.writeList(exported.locations, _writeExportLocation);
      }
    });
  }

  void _writeExportLocation(ExportLocation location) {
    _sink.writeUint30(location.fragmentIndex);
    _sink.writeUint30(location.exportIndex);
  }

  void _writeExtensionElements(List<ExtensionElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);

      // TODO(scheglov): consider reading lazily
      _resolutionSink.withTypeParameters(element.typeParameters, () {
        _writeFieldElements(element.fields);
        _writeGetterElements(element.getters);
        _writeSetterElements(element.setters);
        _writeVariableGetterSetterLinking(element.fields);
        _writeMethodElements(element.methods);
      });

      _writeElementResolution(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _resolutionSink.writeType(element.extendedType);
        });
      });
    });
  }

  void _writeExtensionFragment(ExtensionFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _writeTypeParameters(fragment.typeParameters, () {
        _resolutionSink._writeMetadata(fragment.metadata);
        _sink.writeList(fragment.fields, _writeFieldFragment);
        _sink.writeList(fragment.getters, _writeGetterFragment);
        _sink.writeList(fragment.setters, _writeSetterFragment);
        _sink.writeList(fragment.methods, _writeMethodFragment);
      });
    });
  }

  void _writeExtensionTypeElements(List<ExtensionTypeElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);

      // TODO(fshcheglov): Put these separate flags into modifiers
      _sink.writeBool(element.hasRepresentationSelfReference);
      _sink.writeBool(element.hasImplementsSelfReference);

      // TODO(scheglov): consider reading lazily
      _resolutionSink.withTypeParameters(element.typeParameters, () {
        _writeFieldElements(element.fields);
        _writeGetterElements(element.getters);
        _writeSetterElements(element.setters);
        _writeVariableGetterSetterLinking(element.fields);
        _writeConstructorElements(element.constructors);
        _writeMethodElements(element.methods);
      });

      _writeElementResolution(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _resolutionSink.writeType(element.typeErasure);
          _resolutionSink._writeTypeList(element.interfaces);
          _resolutionSink.writeOptionalElementList(element.interfaceCycle);
        });
      });
    });
  }

  void _writeExtensionTypeFragment(ExtensionTypeFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _writeTypeParameters(fragment.typeParameters, () {
        _resolutionSink._writeMetadata(fragment.metadata);

        // TODO(scheglov): consider reading lazily
        _sink.writeList(fragment.fields, _writeFieldFragment);
        _sink.writeList(fragment.getters, _writeGetterFragment);
        _sink.writeList(fragment.setters, _writeSetterFragment);
        _sink.writeList(fragment.constructors, _writeConstructorFragment);
        _sink.writeList(fragment.methods, _writeMethodFragment);
      });
    });
  }

  void _writeFeatureSet(FeatureSet featureSet) {
    var experimentStatus = featureSet as ExperimentStatus;
    var encoded = experimentStatus.toStorage();
    _sink.writeUint8List(encoded);
  }

  void _writeFieldElements(List<FieldElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);

      _writeElementResolution(() {
        _resolutionSink.writeType(element.type);
      });
    });
  }

  void _writeFieldFragment(FieldFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _resolutionSink._writeMetadata(fragment.metadata);
      _resolutionSink._writeOptionalNode(fragment.constantInitializer);
    });
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

  /// Support for writing data that can be read lazily.
  ///
  /// Resulting state of [_sink].
  ///   - length of data to read lazily
  ///   - data to read lazily, written by [operation]
  ///   - after return new data is written here
  void _writeForLazyRead(void Function() operation) {
    var newSink = _sink.clone();

    var savedSink = _sink;
    _sink = newSink;
    operation();
    _sink = savedSink;

    var bytes = newSink.takeBytes();
    _sink.writeUint30(bytes.length);
    _sink.writeBytes(bytes);
  }

  void _writeFragmentId(FragmentImpl fragment) {
    var id = _fragmentIds.getId(fragment);
    _sink.writeUint30(id);
  }

  void _writeFragmentName(Fragment fragment) {
    _sink._writeOptionalStringReference(fragment.name);
  }

  void _writeFragments(List<FragmentImpl> fragments) {
    _sink.writeList(fragments, _writeFragmentId);
  }

  void _writeGetterElements(List<GetterElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);

      _writeElementResolution(() {
        _resolutionSink.writeType(element.returnType);
      });
    });
  }

  void _writeGetterFragment(GetterFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _writeTypeParameters(fragment.typeParameters, () {
        _sink.writeList(fragment.formalParameters, _writeParameterElement);
        _resolutionSink._writeMetadata(fragment.metadata);
      });
    });
  }

  void _writeLanguageVersion(LibraryLanguageVersion version) {
    _sink.writeUint30(version.package.major);
    _sink.writeUint30(version.package.minor);

    var override = version.override;
    if (override != null) {
      _sink.writeBool(true);
      _sink.writeUint30(override.major);
      _sink.writeUint30(override.minor);
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
    _writeLibraryImportPrefixFragment(element.prefix);
    _writeDirectiveUri(element.uri);
  }

  void _writeLibraryImportPrefixFragment(PrefixFragmentImpl? fragment) {
    _sink.writeOptionalObject(fragment, (fragment) {
      _writeFragmentName(fragment);
      _writeReference(fragment.element.reference);
      _sink.writeBool(fragment.isDeferred);
    });
  }

  void _writeLoadLibraryFunctionReferences(LibraryElementImpl library) {
    var element = library.loadLibraryFunction;
    _writeReference(element.reference);
  }

  void _writeMethodElements(List<MethodElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);
      _sink._writeTopLevelInferenceError(element.typeInferenceError);

      _writeElementResolution(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _resolutionSink.writeType(element.returnType);
          // TODO(scheglov): formal parameters
        });
      });
    });
  }

  void _writeMethodFragment(MethodFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _writeTypeParameters(fragment.typeParameters, () {
        _sink.writeList(fragment.formalParameters, _writeParameterElement);
        _resolutionSink._writeMetadata(fragment.metadata);
      });
    });
  }

  void _writeMixinElements(List<MixinElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);
      _sink.writeBool(element.hasNonFinalField);

      // TODO(scheglov): consider reading lazily
      _resolutionSink.withTypeParameters(element.typeParameters, () {
        _writeFieldElements(element.fields);
        _writeGetterElements(element.getters);
        _writeSetterElements(element.setters);
        _writeVariableGetterSetterLinking(element.fields);
        _writeConstructorElements(element.constructors);
        _writeMethodElements(element.methods);
      });

      _writeElementResolution(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _resolutionSink._writeTypeList(element.superclassConstraints);
          _resolutionSink._writeTypeList(element.interfaces);
          _resolutionSink.writeOptionalElementList(element.interfaceCycle);
        });
      });
    });
  }

  void _writeMixinFragment(MixinFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _sink._writeStringList(fragment.superInvokedNames);

      _writeTypeParameters(fragment.typeParameters, () {
        _resolutionSink._writeMetadata(fragment.metadata);

        // TODO(scheglov): consider reading lazily
        _sink.writeList(fragment.fields, _writeFieldFragment);
        _sink.writeList(fragment.getters, _writeGetterFragment);
        _sink.writeList(fragment.setters, _writeSetterFragment);
        _sink.writeList(fragment.constructors, _writeConstructorFragment);
        _sink.writeList(fragment.methods, _writeMethodFragment);
      });
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
    _sink.writeOptionalObject(reference, _writeReference);
  }

  // TODO(scheglov): Deduplicate parameter writing implementation.
  void _writeParameterElement(FormalParameterFragmentImpl element) {
    _writeFragmentId(element);
    _writeFragmentName(element);
    _sink.writeBool(element.isInitializingFormal);
    _sink.writeBool(element.isSuperFormal);
    _sink._writeFormalParameterKind(element);
    element.writeModifiers(_sink);

    _resolutionSink._writeMetadata(element.metadata);

    _writeTypeParameters(element.typeParameters, () {
      _sink.writeList(element.formalParameters, _writeParameterElement);
      _resolutionSink.writeBool(element.element.inheritsCovariant);
      _resolutionSink.writeType(element.element.type);
      _resolutionSink._writeOptionalNode(element.constantInitializer);

      if (element is FieldFormalParameterFragmentImpl) {
        // TODO(scheglov): formal parameter types? Anything else?
        _resolutionSink.writeElement(element.element.field);
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

  void _writeReference(Reference reference) {
    var index = _references._indexOfReference(reference);
    _sink.writeUint30(index);
  }

  /// Invoke this after writing enough information to create an element, but
  /// before writing any resolution data.
  void _writeResolutionOffset() {
    _sink.writeUint30(_resolutionSink.offset);
  }

  void _writeSetterElements(List<SetterElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);

      _writeElementResolution(() {
        _resolutionSink.writeType(element.returnType);
        // TODO(scheglov): formal parameter types? Anything else?
      });
    });
  }

  void _writeSetterFragment(SetterFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _writeTypeParameters(fragment.typeParameters, () {
        _sink.writeList(fragment.formalParameters, _writeParameterElement);
        _resolutionSink._writeMetadata(fragment.metadata);
      });
    });
  }

  void _writeTemplateFragment<T extends FragmentImpl>(
    T fragment,
    void Function() writeFragmentBody,
  ) {
    _writeFragmentId(fragment);
    _writeFragmentName(fragment);
    _writeResolutionOffset();
    fragment.writeModifiers(_sink);
    writeFragmentBody();
  }

  void _writeTopLevelFunctionElements(
    List<TopLevelFunctionElementImpl> elements,
  ) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);

      _writeElementResolution(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _resolutionSink.writeType(element.returnType);
        });
      });
    });
  }

  void _writeTopLevelFunctionFragment(TopLevelFunctionFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _writeTypeParameters(fragment.typeParameters, () {
        _sink.writeList(fragment.formalParameters, _writeParameterElement);
        _resolutionSink._writeMetadata(fragment.metadata);
      });
    });
  }

  void _writeTopLevelVariableElements(
    List<TopLevelVariableElementImpl> elements,
  ) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);
      _writeElementResolution(() {
        _resolutionSink.writeType(element.type);
      });
    });
  }

  void _writeTopLevelVariableFragment(TopLevelVariableFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _resolutionSink._writeMetadata(fragment.metadata);
      _resolutionSink._writeOptionalNode(fragment.constantInitializer);
    });
  }

  void _writeTypeAliasElements(List<TypeAliasElementImpl> elements) {
    _sink.writeList(elements, (element) {
      _writeReference(element.reference);
      _writeFragments(element.fragments);
      element.writeModifiers(_sink);

      _writeElementResolution(() {
        _resolutionSink.withTypeParameters(element.typeParameters, () {
          _resolutionSink.writeType(element.aliasedType);
        });
      });
    });
  }

  void _writeTypeAliasFragment(TypeAliasFragmentImpl fragment) {
    _writeTemplateFragment(fragment, () {
      _sink.writeBool(fragment.isFunctionTypeAliasBased);
      _writeTypeParameters(fragment.typeParameters, () {
        _resolutionSink._writeMetadata(fragment.metadata);
        _resolutionSink._writeAliasedElement(fragment.aliasedElement);
      });
    });
  }

  void _writeTypeParameterElement(TypeParameterFragmentImpl fragment) {
    _writeFragmentName(fragment);
    _sink.writeByte(_encodeVariance(fragment.element).index);
    _resolutionSink._writeMetadata(fragment.metadata);
    _resolutionSink.writeType(fragment.element.bound);
    _resolutionSink.writeType(fragment.element.defaultType);
  }

  /// Add [typeParameters] to the indexing scope, so make them available
  /// when writing types that might reference them, and write the elements.
  void _writeTypeParameters(
    List<TypeParameterFragmentImpl> typeParameterFragments,
    void Function() f,
  ) {
    // TODO(scheglov): review
    var typeParameters = typeParameterFragments.map((f) => f.element).toList();
    _resolutionSink.localElements.withElements(typeParameters, () {
      _sink.writeList(typeParameterFragments, _writeTypeParameterElement);
      f();
    });
  }

  void _writeUnitElement(LibraryFragmentImpl unitElement) {
    _writeResolutionOffset();

    _sink.writeBool(unitElement.isSynthetic);

    _sink.writeList(unitElement.libraryImports, _writeLibraryImport);
    _sink.writeList(unitElement.libraryExports, _writeLibraryExport);

    // Write the metadata for parts here, even though we write parts below.
    // The reason is that resolution data must be in a single chunk.
    _writePartElementsMetadata(unitElement);

    _sink.writeList(unitElement.classes, _writeClassFragment);
    _sink.writeList(unitElement.enums, _writeEnumFragment);
    _sink.writeList(unitElement.extensions, _writeExtensionFragment);
    _sink.writeList(unitElement.extensionTypes, _writeExtensionTypeFragment);
    _sink.writeList(unitElement.functions, _writeTopLevelFunctionFragment);
    _sink.writeList(unitElement.mixins, _writeMixinFragment);
    _sink.writeList(unitElement.typeAliases, _writeTypeAliasFragment);

    _sink.writeList(
      unitElement.topLevelVariables,
      _writeTopLevelVariableFragment,
    );
    _sink.writeList(unitElement.getters, _writeGetterFragment);
    _sink.writeList(unitElement.setters, _writeSetterFragment);

    // Write parts after this library fragment, so that when we read, we
    // process fragments of declarations in the same order as we build them.
    _sink.writeList(unitElement.parts, _writePartInclude);
  }

  void _writeVariableGetterSetterLinking(
    List<PropertyInducingElementImpl> variables,
  ) {
    _sink.writeList(variables, (variable) {
      _writeReference(variable.reference);
      _writeOptionalReference(variable.getter?.reference);
      _writeOptionalReference(variable.setter?.reference);
    });
  }

  static TypeParameterVarianceTag _encodeVariance(
    TypeParameterElementImpl element,
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

  void withTypeParameters(
    List<TypeParameterElementImpl> typeParameters,
    void Function() operation,
  ) {
    localElements.withElements(typeParameters, operation);
  }

  void writeElement(Element? element) {
    switch (element) {
      case null:
        writeEnum(ElementTag.null_);
      case DynamicElementImpl():
        writeEnum(ElementTag.dynamic_);
      case NeverElementImpl():
        writeEnum(ElementTag.never_);
      case MultiplyDefinedElementImpl():
        writeEnum(ElementTag.multiplyDefined);
      case SubstitutedElementImpl element:
        writeEnum(ElementTag.memberWithTypeArguments);

        var baseElement = element.baseElement;
        writeElement(baseElement);

        var typeArguments = _enclosingClassTypeArguments(
          baseElement,
          element.substitution.map,
        );
        _writeTypeList(typeArguments);
      case TypeParameterElementImpl():
        writeEnum(ElementTag.typeParameter);
        var localIndex = localElements[element];
        writeUint30(localIndex);
      case FormalParameterElementImpl():
        writeEnum(ElementTag.formalParameter);
        var enclosingElement = element.enclosingElement;
        enclosingElement as ExecutableElement;
        writeElement(enclosingElement);
        var index = enclosingElement.formalParameters.indexOf(element);
        assert(index >= 0);
        writeUint30(index);
      case ElementImpl():
        writeEnum(ElementTag.elementImpl);
        var reference = element.reference!;
        var referenceIndex = _references._indexOfReference(reference);
        writeUint30(referenceIndex);
      default:
        throw StateError('${element.runtimeType}');
    }
  }

  void writeOptionalElementList(List<Element>? elements) {
    writeOptionalObject(elements, (it) => _writeElementList(it));
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
      writeEnum(TypeTag.NullType);
    } else if (type is DynamicTypeImpl) {
      writeEnum(TypeTag.DynamicType);
      _writeTypeAliasElementArguments(type);
    } else if (type is FunctionTypeImpl) {
      _writeFunctionType(type);
      _writeTypeAliasElementArguments(type);
    } else if (type is InterfaceTypeImpl) {
      var typeArguments = type.typeArguments;
      var nullabilitySuffix = type.nullabilitySuffix;
      if (typeArguments.isEmpty) {
        if (nullabilitySuffix == NullabilitySuffix.none) {
          writeEnum(TypeTag.InterfaceType_noTypeArguments_none);
        } else if (nullabilitySuffix == NullabilitySuffix.question) {
          writeEnum(TypeTag.InterfaceType_noTypeArguments_question);
        }
        // TODO(scheglov): Write raw
        writeElement(type.element);
      } else {
        writeEnum(TypeTag.InterfaceType);
        // TODO(scheglov): Write raw
        writeElement(type.element);
        _writeTypeList(typeArguments);
        _writeNullabilitySuffix(nullabilitySuffix);
      }
      _writeTypeAliasElementArguments(type);
    } else if (type is InvalidTypeImpl) {
      writeEnum(TypeTag.InvalidType);
      _writeTypeAliasElementArguments(type);
    } else if (type is NeverTypeImpl) {
      writeEnum(TypeTag.NeverType);
      _writeNullabilitySuffix(type.nullabilitySuffix);
      _writeTypeAliasElementArguments(type);
    } else if (type is RecordTypeImpl) {
      _writeRecordType(type);
      _writeTypeAliasElementArguments(type);
    } else if (type is TypeParameterTypeImpl) {
      writeEnum(TypeTag.TypeParameterType);
      writeElement(type.element);
      _writeNullabilitySuffix(type.nullabilitySuffix);
      _writeTypeAliasElementArguments(type);
    } else if (type is VoidTypeImpl) {
      writeEnum(TypeTag.VoidType);
      _writeTypeAliasElementArguments(type);
    } else {
      throw UnimplementedError('${type.runtimeType}');
    }
  }

  void _writeAliasedElement(FragmentImpl? element) {
    if (element == null) {
      writeByte(AliasedElementTag.nothing);
    } else if (element is GenericFunctionTypeFragmentImpl) {
      writeByte(AliasedElementTag.genericFunctionElement);
      _writeTypeParameters(element.typeParameters, () {
        _writeFormalParameters(element.formalParameters, withAnnotations: true);
        writeType(element.returnType);
      }, withAnnotations: true);
    } else {
      throw UnimplementedError('${element.runtimeType}');
    }
  }

  void _writeElementList(List<Element> elements) {
    writeList(elements, writeElement);
  }

  void _writeElementName(Element element) {
    _writeOptionalStringReference(element.name);
  }

  void _writeFormalParameters(
    List<FormalParameterFragmentImpl> parameters, {
    required bool withAnnotations,
  }) {
    writeList(parameters, (parameter) {
      _writeFormalParameterKind(parameter);
      writeBool(parameter.hasImplicitType);
      writeBool(parameter.isInitializingFormal);
      _writeTypeParameters(parameter.typeParameters, () {
        writeType(parameter.element.type);
        _writeFragmentName(parameter);
        _writeFormalParameters(
          parameter.formalParameters,
          withAnnotations: withAnnotations,
        );
      }, withAnnotations: withAnnotations);
      if (withAnnotations) {
        _writeMetadata(parameter.metadata);
      }
    });
  }

  void _writeFormalParameters2(
    List<InternalFormalParameterElement> parameters, {
    required bool withAnnotations,
  }) {
    writeList(parameters, (parameter) {
      _writeFormalParameterKind2(parameter);
      writeBool(parameter.hasImplicitType);
      writeBool(parameter.isInitializingFormal);
      _writeTypeParameters2(parameter.typeParameters, () {
        writeType(parameter.type);
        _writeElementName(parameter);
        _writeFormalParameters2(
          parameter.formalParameters.cast(),
          withAnnotations: withAnnotations,
        );
      }, withAnnotations: withAnnotations);
      if (withAnnotations) {
        _writeMetadata(parameter.metadata);
      }
    });
  }

  void _writeFragmentName(Fragment fragment) {
    _writeOptionalStringReference(fragment.name);
  }

  void _writeFunctionType(FunctionTypeImpl type) {
    type = _toSyntheticFunctionType(type);

    writeEnum(TypeTag.FunctionType);

    _writeTypeParameters2(type.typeParameters, () {
      writeType(type.returnType);
      _writeFormalParameters2(type.formalParameters, withAnnotations: false);
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
    writeEnum(TypeTag.RecordType);

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
    writeElement(alias?.element);
    if (alias != null) {
      _writeTypeList(alias.typeArguments);
    }
  }

  void _writeTypeList(List<DartType> types) {
    writeList(types, writeType);
  }

  void _writeTypeParameters(
    List<TypeParameterFragmentImpl> typeParameterFragments,
    void Function() f, {
    required bool withAnnotations,
  }) {
    var typeParameters = typeParameterFragments.map((f) => f.element).toList();
    localElements.withElements(typeParameters, () {
      writeList(typeParameterFragments, _writeFragmentName);
      for (var typeParameter in typeParameterFragments) {
        writeType(typeParameter.element.bound);
        if (withAnnotations) {
          _writeMetadata(typeParameter.metadata);
        }
      }
      f();
    });
  }

  void _writeTypeParameters2(
    List<TypeParameterElementImpl> typeParameters,
    void Function() f, {
    required bool withAnnotations,
  }) {
    localElements.withElements(typeParameters, () {
      writeList(typeParameters, _writeElementName);
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
      var typeParameters = enclosing.typeParameters;
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
    var typeParameters = type.typeParameters;
    if (typeParameters.isEmpty) return type;

    var fresh = getFreshTypeParameters(typeParameters);
    return fresh.applyToFunctionType(type);
  }
}

class UnitToWriteAst {
  final CompilationUnit node;

  UnitToWriteAst({required this.node});
}

class _BundleWriterReferences {
  /// References used in all libraries being linked.
  /// Element references in nodes are indexes in this list.
  final List<Reference?> _references = [null];

  final List<int> _referenceParents = [0];
  final List<String> _referenceNames = [''];

  /// We need indexes for references during linking, but once we are done,
  /// we must clear indexes to make references ready for linking a next bundle.
  void _clearIndexes() {
    for (var reference in _references) {
      if (reference != null) {
        reference.index = null;
      }
    }
  }

  int _indexOfReference(Reference reference) {
    var index = reference.index;
    if (index != null) return index;

    if (reference.parent case var parent?) {
      var parentIndex = _indexOfReference(parent);
      _referenceParents.add(parentIndex);
      _referenceNames.add(reference.name);

      index = _references.length;
      reference.index = index;
      _references.add(reference);
      return index;
    } else {
      return 0;
    }
  }
}

class _Library {
  final String uriStr;
  final int offset;

  _Library({required this.uriStr, required this.offset});
}

class _LocalElementIndexer {
  final Map<ElementImpl, int> _index = Map.identity();
  int _stackHeight = 0;

  int operator [](ElementImpl element) {
    return _index[element] ??
        (throw ArgumentError('Unexpectedly not indexed: $element'));
  }

  void withElements(List<ElementImpl> elements, void Function() f) {
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

  _SummaryDataWriter clone() {
    return _SummaryDataWriter(stringIndexer: _stringIndexer);
  }

  void _writeFormalParameterKind(FormalParameterFragmentImpl p) {
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

  void _writeFormalParameterKind2(InternalFormalParameterElement p) {
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
    writeList(values, _writeStringReference);
  }

  void _writeStringReference(String string) {
    var index = _stringIndexer[string];
    writeUint30(index);
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

extension on Map<FragmentImpl, int> {
  int getId(FragmentImpl fragment) {
    return this[fragment] ??= length;
  }
}
