// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/name_union.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:pub_semver/pub_semver.dart';

class BundleReader {
  final SummaryDataReader _reader;
  final Map<Uri, Uint8List> _unitsInformativeBytes;

  final Map<Uri, LibraryReader> libraryMap = {};

  BundleReader({
    required LinkedElementFactory elementFactory,
    required Uint8List resolutionBytes,
    Map<Uri, Uint8List> unitsInformativeBytes = const {},
    required Map<Uri, LibraryManifest> libraryManifests,
  }) : _reader = SummaryDataReader(resolutionBytes),
       _unitsInformativeBytes = unitsInformativeBytes {
    const bytesOfU32 = 4;
    const countOfU32 = 4;
    _reader.offset = _reader.bytes.length - bytesOfU32 * countOfU32;
    var baseResolutionOffset = _reader.readUint32();
    var librariesOffset = _reader.readUint32();
    var referencesOffset = _reader.readUint32();
    var stringsOffset = _reader.readUint32();
    _reader.createStringTable(stringsOffset);

    var referenceReader = _ReferenceReader(
      elementFactory,
      _reader,
      referencesOffset,
    );

    _reader.offset = librariesOffset;
    var libraryHeaderList = _reader.readTypedList(() {
      return _LibraryHeader(
        uri: uriCache.parse(_reader.readStringReference()),
        offset: _reader.readUint30(),
      );
    });

    for (var libraryHeader in libraryHeaderList) {
      var uri = libraryHeader.uri;
      var reference = elementFactory.rootReference.getChild('$uri');
      libraryMap[uri] = LibraryReader._(
        elementFactory: elementFactory,
        reader: _reader,
        uri: uri,
        unitsInformativeBytes: _unitsInformativeBytes,
        baseResolutionOffset: baseResolutionOffset,
        referenceReader: referenceReader,
        reference: reference,
        offset: libraryHeader.offset,
        manifest: libraryManifests[uri],
      );
    }
  }
}

class LibraryReader {
  final LinkedElementFactory _elementFactory;
  final SummaryDataReader _reader;
  final Uri uri;
  final Map<Uri, Uint8List> _unitsInformativeBytes;
  final int _baseResolutionOffset;
  final _ReferenceReader _referenceReader;
  final Reference _reference;
  final int _offset;
  final LibraryManifest? manifest;

  late final LibraryElementImpl _libraryElement;

  /// Map of unique (in the bundle) IDs to fragments.
  final Map<int, FragmentImpl> idFragmentMap = {};

  LibraryReader._({
    required LinkedElementFactory elementFactory,
    required SummaryDataReader reader,
    required this.uri,
    required Map<Uri, Uint8List> unitsInformativeBytes,
    required int baseResolutionOffset,
    required _ReferenceReader referenceReader,
    required Reference reference,
    required int offset,
    required this.manifest,
  }) : _elementFactory = elementFactory,
       _reader = reader,
       _unitsInformativeBytes = unitsInformativeBytes,
       _baseResolutionOffset = baseResolutionOffset,
       _referenceReader = referenceReader,
       _reference = reference,
       _offset = offset;

  LibraryElementImpl readElement({required Source librarySource}) {
    var analysisContext = _elementFactory.analysisContext;
    var analysisSession = _elementFactory.analysisSession;

    _reader.offset = _offset;

    // Read enough data to create the library.
    var name = _reader.readStringReference();
    var featureSet = _readFeatureSet();

    // Create the library, link to the reference.
    _libraryElement = LibraryElementImpl(
      analysisContext,
      analysisSession,
      name,
      -1,
      0,
      featureSet,
    );
    _reference.element = _libraryElement;
    _libraryElement.reference = _reference;

    // Read the rest of non-resolution data for the library.
    _libraryElement.readModifiers(_reader);
    _libraryElement.languageVersion = _readLanguageVersion();

    _libraryElement.exportedReferences = _reader.readTypedList(
      _readExportedReference,
    );

    _libraryElement.nameUnion = ElementNameUnion.read(_reader.readUint30List());

    _libraryElement.manifest = manifest;

    _libraryElement.loadLibraryProvider = LoadLibraryFunctionProvider(
      elementReference: _readReference(),
    );

    // Read the library units.
    _libraryElement.firstFragment = _readUnitElement(
      containerUnit: null,
      unitSource: librarySource,
    );

    _readClassElements();
    _readEnumElements();
    _readExtensionElements();
    _readExtensionTypeElements();
    _readTopLevelFunctionElements();
    _readMixinElements();
    _readTypeAliasElements();
    _readTopLevelVariableElements();
    _libraryElement.getters = _readGetterElements();
    _libraryElement.setters = _readSetterElements();
    _readVariableGetterSetterLinking();

    var resolutionOffset = _baseResolutionOffset + _reader.readUint30();
    _libraryElement.deferReadResolution(() {
      var unitElement = _libraryElement.internal.firstFragment;
      var reader = ResolutionReader(
        _elementFactory,
        _referenceReader,
        _reader.fork(resolutionOffset),
      );
      reader.currentLibraryFragment = unitElement;

      _libraryElement.metadata = reader._readMetadata();

      _libraryElement.entryPoint =
          reader.readElement() as TopLevelFunctionElementImpl?;

      _libraryElement.fieldNameNonPromotabilityInfo = reader.readOptionalObject(
        () {
          return reader.readMap(
            readKey: () => reader.readStringReference(),
            readValue: () {
              return FieldNameNonPromotabilityInfo(
                conflictingFields: reader.readElementList(),
                conflictingGetters: reader.readElementList(),
                conflictingNsmClasses: reader.readElementList(),
              );
            },
          );
        },
      );

      _libraryElement.exportNamespace = _elementFactory.buildExportNamespace(
        _libraryElement.uri,
        _libraryElement.exportedReferences,
      );
    });

    _declareDartCoreDynamicNever();

    InformativeDataApplier().applyToLibrary(
      _elementFactory,
      _libraryElement,
      _unitsInformativeBytes,
    );

    return _libraryElement;
  }

  void Function() _createDeferredReadResolutionCallback(
    void Function(ResolutionReader reader) callback,
  ) {
    var offset = _baseResolutionOffset + _reader.readUint30();
    return () {
      var reader = ResolutionReader(
        _elementFactory,
        _referenceReader,
        _reader.fork(offset),
      );
      callback(reader);
    };
  }

  /// These elements are implicitly declared in `dart:core`.
  void _declareDartCoreDynamicNever() {
    if (_reference.name == 'dart:core') {
      _reference.getChild('dynamic').element = DynamicElementImpl.instance;
      _reference.getChild('Never').element = NeverElementImpl.instance;
    }
  }

  /// Configures to read lazy data with [operation].
  ///
  /// Expected state of the reader:
  ///   - length of data to read lazily
  ///   - data to read lazily
  ///   - data to continue reading eagerly
  void _lazyRead(void Function(int offset) operation) {
    var length = _reader.readUint30();
    var offset = _reader.offset;
    _reader.offset += length;
    operation(offset);
  }

  void _readClassElements() {
    _libraryElement.classes = _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<ClassFragmentImpl>();
      var element = ClassElementImpl(reference, fragments.first);
      element.linkFragments(fragments);

      element.readModifiers(_reader);
      element.hasNonFinalField = _reader.readBool();

      // Configure for reading members lazily.
      _lazyRead((offset) {
        element.deferReadMembers(() {
          _reader.runAtOffset(offset, () {
            element.ensureReadMembersForFragments();
            element.fields = _readFieldElements();
            element.getters = _readGetterElements();
            element.setters = _readSetterElements();
            _readVariableGetterSetterLinking();
            element.methods = _readMethodElements();
            if (element.isMixinApplication) {
              // Create synthetic constructors and associate with references.
              element.constructors;
            } else {
              element.constructors = _readConstructorElements();
            }
          });
        });
      });

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          reader._addTypeParameters2(element.typeParameters);
          element.supertype = reader._readOptionalInterfaceType();
          element.mixins = reader._readInterfaceTypeList();
          element.interfaces = reader._readInterfaceTypeList();
          element.interfaceCycle = reader.readOptionalElementList();
        }),
      );

      return element;
    });
  }

  List<ClassFragmentImpl> _readClassFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = ClassFragmentImpl(name: name);
          fragment.readModifiers(_reader);
          fragment.typeParameters = _readTypeParameters();

          _lazyRead((membersOffset) {
            fragment.deferReadMembers(() {
              _reader.runAtOffset(membersOffset, () {
                fragment.fields = _readFieldFragments();
                fragment.getters = _readGetterFragments();
                fragment.setters = _readSetterFragments();
                fragment.methods = _readMethodFragments();
                if (!fragment.isMixinApplication) {
                  fragment.constructors = _readConstructorFragments();
                }
              });
            });
          });
          return fragment;
        },
        readResolution: (fragment, reader) {
          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          fragment.metadata = reader._readMetadata();
        },
      );
    });
  }

  List<ConstructorElementImpl> _readConstructorElements() {
    return _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<ConstructorFragmentImpl>();
      var element = ConstructorElementImpl(
        name: fragments.first.name,
        reference: reference,
        firstFragment: fragments.first,
      );
      element.linkFragments(fragments);
      element.readModifiers(_reader);

      // TODO(scheglov): type parameters
      // TODO(scheglov): formal parameters
      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          var enclosingElement = element.enclosingElement;
          reader._addTypeParameters2(enclosingElement.typeParameters);
          element.returnType = reader.readRequiredType();
          element.superConstructor = reader.readConstructorElementMixin();
          element.redirectedConstructor = reader.readConstructorElementMixin();
        }),
      );

      return element;
    });
  }

  List<ConstructorFragmentImpl> _readConstructorFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = ConstructorFragmentImpl(name: name!);

          fragment.readModifiers(_reader);
          fragment.typeName = _reader.readOptionalStringReference();
          fragment.typeParameters = _readTypeParameters();
          fragment.formalParameters = _readParameters();

          return fragment;
        },
        readResolution: (fragment, reader) {
          var enclosingElement = fragment.element.enclosingElement;
          reader._addTypeParameters2(enclosingElement.typeParameters);

          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          _readFormalParameters2(
            fragment.libraryFragment,
            reader,
            fragment.formalParameters,
          );
          fragment.metadata = reader._readMetadata();
          fragment.constantInitializers = reader.readNodeList();
        },
      );
    });
  }

  DirectiveUriImpl _readDirectiveUri({
    required LibraryFragmentImpl containerUnit,
  }) {
    DirectiveUriWithRelativeUriStringImpl readWithRelativeUriString() {
      var relativeUriString = _reader.readStringReference();
      return DirectiveUriWithRelativeUriStringImpl(
        relativeUriString: relativeUriString,
      );
    }

    DirectiveUriWithRelativeUriImpl readWithRelativeUri() {
      var parent = readWithRelativeUriString();
      var relativeUri = uriCache.parse(_reader.readStringReference());
      return DirectiveUriWithRelativeUriImpl(
        relativeUriString: parent.relativeUriString,
        relativeUri: relativeUri,
      );
    }

    DirectiveUriWithSourceImpl readWithSource() {
      var parent = readWithRelativeUri();

      var analysisContext = _elementFactory.analysisContext;
      var sourceFactory = analysisContext.sourceFactory;

      var sourceUriStr = _reader.readStringReference();
      var sourceUri = uriCache.parse(sourceUriStr);
      var source = sourceFactory.forUri2(sourceUri);

      // TODO(scheglov): https://github.com/dart-lang/sdk/issues/49431
      var fixedSource = source ?? sourceFactory.forUri('dart:math')!;

      return DirectiveUriWithSourceImpl(
        relativeUriString: parent.relativeUriString,
        relativeUri: parent.relativeUri,
        source: fixedSource,
      );
    }

    var kindIndex = _reader.readByte();
    var kind = DirectiveUriKind.values[kindIndex];
    switch (kind) {
      case DirectiveUriKind.withLibrary:
        var parent = readWithSource();
        return DirectiveUriWithLibraryImpl.read(
          relativeUriString: parent.relativeUriString,
          relativeUri: parent.relativeUri,
          source: parent.source,
        );
      case DirectiveUriKind.withUnit:
        var parent = readWithSource();
        var unitElement = _readUnitElement(
          containerUnit: containerUnit,
          unitSource: parent.source,
        );
        return DirectiveUriWithUnitImpl(
          relativeUriString: parent.relativeUriString,
          relativeUri: parent.relativeUri,
          libraryFragment: unitElement,
        );
      case DirectiveUriKind.withSource:
        return readWithSource();
      case DirectiveUriKind.withRelativeUri:
        return readWithRelativeUri();
      case DirectiveUriKind.withRelativeUriString:
        return readWithRelativeUriString();
      case DirectiveUriKind.withNothing:
        return DirectiveUriImpl();
    }
  }

  void _readEnumElements() {
    _libraryElement.enums = _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<EnumFragmentImpl>();
      var element = EnumElementImpl(reference, fragments.first);
      element.linkFragments(fragments);
      element.readModifiers(_reader);

      // TODO(scheglov): consider reading lazily
      globalResultRequirements.untracked(
        reason: 'elementModelReading',
        operation: () {
          for (var fragment in element.fragments) {
            fragment.ensureReadMembers();
          }
        },
      );

      element.fields = _readFieldElements();
      element.getters = _readGetterElements();
      element.setters = _readSetterElements();
      _readVariableGetterSetterLinking();
      element.constructors = _readConstructorElements();
      element.methods = _readMethodElements();

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          reader._addTypeParameters2(element.typeParameters);
          element.supertype = reader._readOptionalInterfaceType();
          element.mixins = reader._readInterfaceTypeList();
          element.interfaces = reader._readInterfaceTypeList();
          element.interfaceCycle = reader.readOptionalElementList();
        }),
      );

      return element;
    });
  }

  List<EnumFragmentImpl> _readEnumFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = EnumFragmentImpl(name: name);
          fragment.readModifiers(_reader);
          fragment.typeParameters = _readTypeParameters();

          // TODO(scheglov): consider reading lazily
          fragment.fields = _readFieldFragments();
          fragment.getters = _readGetterFragments();
          fragment.setters = _readSetterFragments();
          fragment.constructors = _readConstructorFragments();
          fragment.methods = _readMethodFragments();
          return fragment;
        },
        readResolution: (fragment, reader) {
          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          fragment.metadata = reader._readMetadata();
        },
      );
    });
  }

  ExportedReference _readExportedReference() {
    var kind = _reader.readByte();
    if (kind == 0) {
      var index = _reader.readUint30();
      var reference = _referenceReader.referenceOfIndex(index);
      return ExportedReferenceDeclared(reference: reference);
    } else if (kind == 1) {
      var index = _reader.readUint30();
      var reference = _referenceReader.referenceOfIndex(index);
      return ExportedReferenceExported(
        reference: reference,
        locations: _reader.readTypedList(_readExportLocation),
      );
    } else {
      throw StateError('kind: $kind');
    }
  }

  ExportLocation _readExportLocation() {
    return ExportLocation(
      fragmentIndex: _reader.readUint30(),
      exportIndex: _reader.readUint30(),
    );
  }

  void _readExtensionElements() {
    _libraryElement.extensions = _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<ExtensionFragmentImpl>();
      var element = ExtensionElementImpl(reference, fragments.first);
      element.linkFragments(fragments);
      element.readModifiers(_reader);

      globalResultRequirements.untracked(
        reason: 'elementModelReading',
        operation: () {
          for (var fragment in element.fragments) {
            fragment.ensureReadMembers();
          }
        },
      );

      // TODO(scheglov): consider reading lazily
      element.fields = _readFieldElements();
      element.getters = _readGetterElements();
      element.setters = _readSetterElements();
      _readVariableGetterSetterLinking();
      element.methods = _readMethodElements();

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          reader._addTypeParameters2(element.typeParameters);
          element.extendedType = reader.readRequiredType();
          // TODO(scheglov): read resolution information
        }),
      );

      return element;
    });
  }

  List<ExtensionFragmentImpl> _readExtensionFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = ExtensionFragmentImpl(name: name);
          fragment.readModifiers(_reader);
          fragment.typeParameters = _readTypeParameters();
          fragment.fields = _readFieldFragments();
          fragment.getters = _readGetterFragments();
          fragment.setters = _readSetterFragments();
          fragment.methods = _readMethodFragments();
          return fragment;
        },
        readResolution: (fragment, reader) {
          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          fragment.metadata = reader._readMetadata();
        },
      );
    });
  }

  void _readExtensionTypeElements() {
    _libraryElement.extensionTypes = _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<ExtensionTypeFragmentImpl>();
      var element = ExtensionTypeElementImpl(reference, fragments.first);
      element.linkFragments(fragments);
      element.readModifiers(_reader);

      element.hasRepresentationSelfReference = _reader.readBool();
      element.hasImplementsSelfReference = _reader.readBool();

      // TODO(scheglov): consider reading lazily
      globalResultRequirements.untracked(
        reason: 'elementModelReading',
        operation: () {
          for (var fragment in element.fragments) {
            fragment.ensureReadMembers();
          }
        },
      );

      element.fields = _readFieldElements();
      element.getters = _readGetterElements();
      element.setters = _readSetterElements();
      _readVariableGetterSetterLinking();
      element.constructors = _readConstructorElements();
      element.methods = _readMethodElements();

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          reader._addTypeParameters2(element.typeParameters);
          element.typeErasure = reader.readRequiredType();
          element.interfaces = reader._readInterfaceTypeList();
          element.interfaceCycle = reader.readOptionalElementList();
        }),
      );

      return element;
    });
  }

  List<ExtensionTypeFragmentImpl> _readExtensionTypeFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = ExtensionTypeFragmentImpl(name: name);
          fragment.readModifiers(_reader);
          fragment.typeParameters = _readTypeParameters();

          // TODO(scheglov): consider reading lazily
          fragment.fields = _readFieldFragments();
          fragment.getters = _readGetterFragments();
          fragment.setters = _readSetterFragments();
          fragment.constructors = _readConstructorFragments();
          fragment.methods = _readMethodFragments();
          return fragment;
        },
        readResolution: (fragment, reader) {
          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          fragment.metadata = reader._readMetadata();
        },
      );
    });
  }

  FeatureSet _readFeatureSet() {
    var featureSetEncoded = _reader.readUint8List();
    return ExperimentStatus.fromStorage(featureSetEncoded);
  }

  List<FieldElementImpl> _readFieldElements() {
    return _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<FieldFragmentImpl>();
      var element = FieldElementImpl(
        reference: reference,
        firstFragment: fragments.first,
      );
      element.linkFragments(fragments);
      element.readModifiers(_reader);

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          var enclosingElement = element.enclosingElement;
          reader._addTypeParameters2(enclosingElement.typeParameters);
          element.type = reader.readRequiredType();
        }),
      );

      return element;
    });
  }

  List<FieldFragmentImpl> _readFieldFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = FieldFragmentImpl(name: name);
          fragment.readModifiers(_reader);
          return fragment;
        },
        readResolution: (fragment, reader) {
          var enclosingElement = fragment.element.enclosingElement;
          reader._addTypeParameters2(enclosingElement.typeParameters);

          fragment.metadata = reader._readMetadata();
          if (reader.readOptionalExpression() case var initializer?) {
            fragment.constantInitializer = initializer;
            ConstantContextForExpressionImpl(fragment, initializer);
          }
        },
      );
    });
  }

  void _readFormalParameters2(
    LibraryFragmentImpl unitElement,
    ResolutionReader reader,
    List<FormalParameterFragmentImpl> parameters,
  ) {
    for (var parameter in parameters) {
      parameter.metadata = reader._readMetadata();
      _readTypeParameters2(unitElement, reader, parameter.typeParameters);
      _readFormalParameters2(unitElement, reader, parameter.formalParameters);
      parameter.element.inheritsCovariant = reader.readBool();
      var type = reader.readType() ?? InvalidTypeImpl.instance;
      parameter.element.type = type;
      parameter.constantInitializer = reader.readOptionalExpression();
      if (parameter is FieldFormalParameterFragmentImpl) {
        parameter.element.field = reader.readElement() as FieldElementImpl?;
      }
    }
  }

  T _readFragmentById<T extends FragmentImpl>() {
    var id = _readFragmentId();
    return idFragmentMap[id] as T;
  }

  int _readFragmentId() {
    return _reader.readUint30();
  }

  String? _readFragmentName() {
    return _reader.readOptionalStringReference();
  }

  List<T> _readFragmentsById<T extends FragmentImpl>() {
    return _reader.readTypedList(_readFragmentById);
  }

  List<GetterElementImpl> _readGetterElements() {
    return _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<GetterFragmentImpl>();
      var element = GetterElementImpl(reference, fragments.first);
      element.linkFragments(fragments);
      element.readModifiers(_reader);

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          var enclosingElement = element.enclosingElement;
          if (enclosingElement is InstanceElementImpl) {
            reader._addTypeParameters2(enclosingElement.typeParameters);
          }

          element.returnType = reader.readRequiredType();
        }),
      );

      return element;
    });
  }

  List<GetterFragmentImpl> _readGetterFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = GetterFragmentImpl(name: name);

          fragment.readModifiers(_reader);
          fragment.typeParameters = _readTypeParameters();
          fragment.formalParameters = _readParameters();
          return fragment;
        },
        readResolution: (fragment, reader) {
          var enclosingElement = fragment.element.enclosingElement;
          if (enclosingElement is InstanceElementImpl) {
            reader._addTypeParameters2(enclosingElement.typeParameters);
          }

          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          _readFormalParameters2(
            fragment.libraryFragment,
            reader,
            fragment.formalParameters,
          );
          fragment.metadata = reader._readMetadata();
        },
      );
    });
  }

  LibraryLanguageVersion _readLanguageVersion() {
    var packageMajor = _reader.readUint30();
    var packageMinor = _reader.readUint30();
    var package = Version(packageMajor, packageMinor, 0);

    Version? override;
    if (_reader.readBool()) {
      var overrideMajor = _reader.readUint30();
      var overrideMinor = _reader.readUint30();
      override = Version(overrideMajor, overrideMinor, 0);
    }

    return LibraryLanguageVersion(package: package, override: override);
  }

  LibraryExportImpl _readLibraryExport({
    required LibraryFragmentImpl containerUnit,
  }) {
    return LibraryExportImpl(
      combinators: _reader.readTypedList(_readNamespaceCombinator),
      exportKeywordOffset: -1,
      uri: _readDirectiveUri(containerUnit: containerUnit),
    );
  }

  LibraryImportImpl _readLibraryImport({
    required LibraryFragmentImpl containerUnit,
  }) {
    var element = LibraryImportImpl(
      isSynthetic: _reader.readBool(),
      combinators: _reader.readTypedList(_readNamespaceCombinator),
      importKeywordOffset: -1,
      prefix: _readLibraryImportPrefixFragment(libraryFragment: containerUnit),
      uri: _readDirectiveUri(containerUnit: containerUnit),
    );
    return element;
  }

  PrefixFragmentImpl? _readLibraryImportPrefixFragment({
    required LibraryFragmentImpl libraryFragment,
  }) {
    return _reader.readOptionalObject(() {
      var fragmentName = _readFragmentName();
      var reference = _readReference();
      var isDeferred = _reader.readBool();
      var fragment = PrefixFragmentImpl(
        name: fragmentName,
        firstTokenOffset: null,
        nameOffset: null,
        isDeferred: isDeferred,
      );
      fragment.enclosingFragment = libraryFragment;

      var element = reference.element as PrefixElementImpl?;
      if (element == null) {
        element = PrefixElementImpl(
          reference: reference,
          firstFragment: fragment,
        );
      } else {
        element.addFragment(fragment);
      }

      fragment.element = element;
      return fragment;
    });
  }

  List<MethodElementImpl> _readMethodElements() {
    return _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<MethodFragmentImpl>();
      var element = MethodElementImpl(
        name: fragments.first.name,
        reference: reference,
        firstFragment: fragments.first,
      );
      element.linkFragments(fragments);

      element.readModifiers(_reader);
      element.typeInferenceError = _readTopLevelInferenceError();

      // TODO(scheglov): type parameters
      // TODO(scheglov): formal parameters
      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          var enclosingElement = element.enclosingElement;
          reader._addTypeParameters2(enclosingElement.typeParameters);

          reader._addTypeParameters2(element.typeParameters);

          element.returnType = reader.readRequiredType();
        }),
      );

      return element;
    });
  }

  List<MethodFragmentImpl> _readMethodFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = MethodFragmentImpl(name: name);

          fragment.readModifiers(_reader);
          fragment.typeParameters = _readTypeParameters();
          fragment.formalParameters = _readParameters();
          return fragment;
        },
        readResolution: (fragment, reader) {
          var enclosingElement = fragment.element.enclosingElement;
          reader._addTypeParameters2(enclosingElement.typeParameters);

          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          _readFormalParameters2(
            fragment.libraryFragment,
            reader,
            fragment.formalParameters,
          );
          fragment.metadata = reader._readMetadata();
        },
      );
    });
  }

  void _readMixinElements() {
    _libraryElement.mixins = _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<MixinFragmentImpl>();
      var element = MixinElementImpl(reference, fragments.first);
      element.linkFragments(fragments);

      element.readModifiers(_reader);
      element.hasNonFinalField = _reader.readBool();

      // TODO(scheglov): consider reading lazily
      globalResultRequirements.untracked(
        reason: 'elementModelReading',
        operation: () {
          for (var fragment in element.fragments) {
            fragment.ensureReadMembers();
          }
        },
      );

      element.fields = _readFieldElements();
      element.getters = _readGetterElements();
      element.setters = _readSetterElements();
      _readVariableGetterSetterLinking();
      element.constructors = _readConstructorElements();
      element.methods = _readMethodElements();

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          reader._addTypeParameters2(element.typeParameters);
          element.superclassConstraints = reader._readInterfaceTypeList();
          element.interfaces = reader._readInterfaceTypeList();
          element.interfaceCycle = reader.readOptionalElementList();
        }),
      );

      return element;
    });
  }

  List<MixinFragmentImpl> _readMixinFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = MixinFragmentImpl(name: name);
          fragment.readModifiers(_reader);
          fragment.superInvokedNames = _reader.readStringReferenceList();
          fragment.typeParameters = _readTypeParameters();

          // TODO(scheglov): consider reading lazily
          fragment.fields = _readFieldFragments();
          fragment.getters = _readGetterFragments();
          fragment.setters = _readSetterFragments();
          fragment.constructors = _readConstructorFragments();
          fragment.methods = _readMethodFragments();
          return fragment;
        },
        readResolution: (fragment, reader) {
          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          fragment.metadata = reader._readMetadata();
        },
      );
    });
  }

  NamespaceCombinator _readNamespaceCombinator() {
    var tag = _reader.readByte();
    if (tag == Tag.HideCombinator) {
      var combinator = HideElementCombinatorImpl();
      combinator.hiddenNames = _reader.readStringReferenceList();
      return combinator;
    } else if (tag == Tag.ShowCombinator) {
      var combinator = ShowElementCombinatorImpl();
      combinator.shownNames = _reader.readStringReferenceList();
      return combinator;
    } else {
      throw UnimplementedError('tag: $tag');
    }
  }

  /// Read the reference of a non-local element.
  Reference? _readOptionalReference() {
    return _reader.readOptionalObject(() => _readReference());
  }

  // TODO(scheglov): Deduplicate parameter reading implementation.
  List<FormalParameterFragmentImpl> _readParameters() {
    return _reader.readTypedList(() {
      var id = _readFragmentId();
      var fragmentName = _readFragmentName();
      var isInitializingFormal = _reader.readBool();
      var isSuperFormal = _reader.readBool();

      var kindIndex = _reader.readByte();
      var kind = ResolutionReader._formalParameterKind(kindIndex);

      FormalParameterFragmentImpl element;
      if (isInitializingFormal) {
        element = FieldFormalParameterFragmentImpl(
          name: fragmentName,
          nameOffset: null,
          parameterKind: kind,
        );
      } else if (isSuperFormal) {
        element = SuperFormalParameterFragmentImpl(
          name: fragmentName,
          nameOffset: null,
          parameterKind: kind,
        );
      } else {
        element = FormalParameterFragmentImpl(
          name: fragmentName,
          nameOffset: null,
          parameterKind: kind,
        );
      }
      idFragmentMap[id] = element;
      element.readModifiers(_reader);
      element.typeParameters = _readTypeParameters();
      element.formalParameters = _readParameters();
      return element;
    });
  }

  PartIncludeImpl _readPartInclude({
    required LibraryFragmentImpl containerUnit,
  }) {
    var uri = _readDirectiveUri(containerUnit: containerUnit);

    return PartIncludeImpl(partKeywordOffset: -1, uri: uri);
  }

  /// Read the reference of a non-local element.
  Reference _readReference() {
    var referenceIndex = _reader.readUint30();
    return _referenceReader.referenceOfIndex(referenceIndex);
  }

  List<SetterElementImpl> _readSetterElements() {
    return _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<SetterFragmentImpl>();
      var element = SetterElementImpl(reference, fragments.first);
      element.linkFragments(fragments);
      element.readModifiers(_reader);

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          element.returnType = reader.readRequiredType();
          // TODO(scheglov): other properties?
        }),
      );

      return element;
    });
  }

  List<SetterFragmentImpl> _readSetterFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = SetterFragmentImpl(name: name);

          fragment.readModifiers(_reader);
          fragment.typeParameters = _readTypeParameters();
          fragment.formalParameters = _readParameters();
          return fragment;
        },
        readResolution: (fragment, reader) {
          var enclosingElement = fragment.element.enclosingElement;
          if (enclosingElement is InstanceElementImpl) {
            reader._addTypeParameters2(enclosingElement.typeParameters);
          }

          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          _readFormalParameters2(
            fragment.libraryFragment,
            reader,
            fragment.formalParameters,
          );
          fragment.metadata = reader._readMetadata();
        },
      );
    });
  }

  /// [T] must also implement [DeferredResolutionReadingMixin], we configure
  /// it with [readResolution].
  T _readTemplateFragment<T extends FragmentImpl>({
    required T Function(String? name) create,
    required void Function(T fragment, ResolutionReader reader) readResolution,
  }) {
    var id = _readFragmentId();
    var name = _readFragmentName();
    var resolutionOffset = _baseResolutionOffset + _reader.readUint30();
    var fragment = create(name);
    idFragmentMap[id] = fragment;

    if (fragment case DeferredResolutionReadingMixin deferred) {
      deferred.deferReadResolution(() {
        var reader = ResolutionReader(
          _elementFactory,
          _referenceReader,
          _reader.fork(resolutionOffset),
        );

        // TODO(scheglov): type casts are not good :-(
        reader.currentLibraryFragment =
            fragment.libraryFragment as LibraryFragmentImpl;

        readResolution(fragment, reader);
      });
    }

    return fragment;
  }

  void _readTopLevelFunctionElements() {
    _libraryElement.topLevelFunctions = _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<TopLevelFunctionFragmentImpl>();
      var element = TopLevelFunctionElementImpl(reference, fragments.first);
      element.linkFragments(fragments);
      element.readModifiers(_reader);

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          reader._addTypeParameters2(element.typeParameters);

          element.returnType = reader.readRequiredType();
        }),
      );

      return element;
    });
  }

  List<TopLevelFunctionFragmentImpl> _readTopLevelFunctionFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = TopLevelFunctionFragmentImpl(name: name);

          fragment.readModifiers(_reader);
          fragment.typeParameters = _readTypeParameters();
          fragment.formalParameters = _readParameters();
          return fragment;
        },
        readResolution: (fragment, reader) {
          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          _readFormalParameters2(
            fragment.libraryFragment,
            reader,
            fragment.formalParameters,
          );
          fragment.metadata = reader._readMetadata();
        },
      );
    });
  }

  TopLevelInferenceError? _readTopLevelInferenceError() {
    var kindIndex = _reader.readByte();
    var kind = TopLevelInferenceErrorKind.values[kindIndex];
    if (kind == TopLevelInferenceErrorKind.none) {
      return null;
    }
    return TopLevelInferenceError(
      kind: kind,
      arguments: _reader.readStringReferenceList(),
    );
  }

  void _readTopLevelVariableElements() {
    _libraryElement.topLevelVariables = _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<TopLevelVariableFragmentImpl>();
      var element = TopLevelVariableElementImpl(reference, fragments.first);
      element.linkFragments(fragments);
      element.readModifiers(_reader);

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          element.type = reader.readRequiredType();
        }),
      );

      return element;
    });
  }

  List<TopLevelVariableFragmentImpl> _readTopLevelVariableFragments() {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = TopLevelVariableFragmentImpl(name: name);
          fragment.readModifiers(_reader);
          return fragment;
        },
        readResolution: (fragment, reader) {
          reader.currentLibraryFragment = fragment.libraryFragment;
          fragment.metadata = reader._readMetadata();
          if (reader.readOptionalExpression() case var initializer?) {
            fragment.constantInitializer = initializer;
            ConstantContextForExpressionImpl(fragment, initializer);
          }
        },
      );
    });
  }

  void _readTypeAliasElements() {
    _libraryElement.typeAliases = _reader.readTypedList(() {
      var reference = _readReference();
      var fragments = _readFragmentsById<TypeAliasFragmentImpl>();
      var element = TypeAliasElementImpl(reference, fragments.first);
      element.readModifiers(_reader);

      element.deferReadResolution(
        _createDeferredReadResolutionCallback((reader) {
          reader._addTypeParameters2(element.typeParameters);
          element.aliasedType = reader.readRequiredType();
        }),
      );

      return element;
    });
  }

  List<TypeAliasFragmentImpl> _readTypeAliasFragments(
    LibraryFragmentImpl unitElement,
  ) {
    return _reader.readTypedList(() {
      return _readTemplateFragment(
        create: (name) {
          var fragment = TypeAliasFragmentImpl(
            name: name,
            firstTokenOffset: null,
          );

          fragment.readModifiers(_reader);
          fragment.isFunctionTypeAliasBased = _reader.readBool();
          fragment.typeParameters = _readTypeParameters();
          return fragment;
        },
        readResolution: (fragment, reader) {
          _readTypeParameters2(
            fragment.libraryFragment,
            reader,
            fragment.typeParameters,
          );
          fragment.metadata = reader._readMetadata();
          fragment.aliasedElement = reader._readAliasedElement(unitElement);
        },
      );
    });
  }

  List<TypeParameterFragmentImpl> _readTypeParameters() {
    return _reader.readTypedList(() {
      var fragmentName = _readFragmentName();
      var varianceEncoding = _reader.readByte();
      var variance = _decodeVariance(varianceEncoding);
      var fragment = TypeParameterFragmentImpl(name: fragmentName);
      fragment.element.variance = variance;
      return fragment;
    });
  }

  void _readTypeParameters2(
    LibraryFragmentImpl unitElement,
    ResolutionReader reader,
    List<TypeParameterFragmentImpl> typeParameters,
  ) {
    reader._addTypeParameters(typeParameters);
    for (var typeParameter in typeParameters) {
      typeParameter.metadata = reader._readMetadata();
      typeParameter.element.bound = reader.readType();
      typeParameter.element.defaultType = reader.readType();
    }
  }

  LibraryFragmentImpl _readUnitElement({
    required LibraryFragmentImpl? containerUnit,
    required Source unitSource,
  }) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUint30();

    var unitElement = LibraryFragmentImpl(
      library: _libraryElement,
      source: unitSource,
      lineInfo: LineInfo([0]),
    );

    unitElement.deferReadResolution(() {
      var reader = ResolutionReader(
        _elementFactory,
        _referenceReader,
        _reader.fork(resolutionOffset),
      );

      reader.currentLibraryFragment = unitElement;

      for (var import in unitElement.libraryImports) {
        import.metadata = reader._readMetadata();
        var uri = import.uri;
        if (uri is DirectiveUriWithLibraryImpl) {
          uri.library = reader.libraryOfUri(uri.source.uri);
        }
      }

      for (var export in unitElement.libraryExports) {
        export.metadata = reader._readMetadata();
        var uri = export.uri;
        if (uri is DirectiveUriWithLibraryImpl) {
          uri.library = reader.libraryOfUri(uri.source.uri);
        }
      }

      for (var part in unitElement.parts) {
        part.metadata = reader._readMetadata();
      }
    });

    unitElement.isSynthetic = _reader.readBool();

    unitElement.libraryImports = _reader.readTypedList(() {
      return _readLibraryImport(containerUnit: unitElement);
    });

    unitElement.libraryExports = _reader.readTypedList(() {
      return _readLibraryExport(containerUnit: unitElement);
    });

    unitElement.classes = _readClassFragments();
    unitElement.enums = _readEnumFragments();
    unitElement.extensions = _readExtensionFragments();
    unitElement.extensionTypes = _readExtensionTypeFragments();
    unitElement.functions = _readTopLevelFunctionFragments();
    unitElement.mixins = _readMixinFragments();
    unitElement.typeAliases = _readTypeAliasFragments(unitElement);

    unitElement.topLevelVariables = _readTopLevelVariableFragments();
    unitElement.getters = _readGetterFragments();
    unitElement.setters = _readSetterFragments();

    unitElement.parts = _reader.readTypedList(() {
      return _readPartInclude(containerUnit: unitElement);
    });

    return unitElement;
  }

  void _readVariableGetterSetterLinking() {
    _reader.readTypedList(() {
      var variable = _readReference().element as PropertyInducingElementImpl;

      var optionalGetter = _readOptionalReference()?.element;
      if (optionalGetter != null) {
        var getter = optionalGetter as GetterElementImpl;
        variable.getter = getter;
        getter.variable = variable;
      }

      var optionalSetter = _readOptionalReference()?.element;
      if (optionalSetter != null) {
        var setter = optionalSetter as SetterElementImpl;
        variable.setter = setter;
        setter.variable = variable;
      }
    });
  }

  static Variance? _decodeVariance(int index) {
    var tag = TypeParameterVarianceTag.values[index];
    switch (tag) {
      case TypeParameterVarianceTag.legacy:
        return null;
      case TypeParameterVarianceTag.unrelated:
        return Variance.unrelated;
      case TypeParameterVarianceTag.covariant:
        return Variance.covariant;
      case TypeParameterVarianceTag.contravariant:
        return Variance.contravariant;
      case TypeParameterVarianceTag.invariant:
        return Variance.invariant;
    }
  }
}

/// Helper for reading elements and types from their binary encoding.
class ResolutionReader {
  final LinkedElementFactory _elementFactory;
  final _ReferenceReader _referenceReader;
  final SummaryDataReader _reader;

  late LibraryFragmentImpl currentLibraryFragment;

  /// The stack of [TypeParameterElementImpl]s and [FormalParameterElementImpl]s
  /// that are available in the scope of [readElement] and [readType].
  ///
  /// This stack is shared with the client of the reader, and update mostly
  /// by the client. However it is also updated during [_readFunctionType].
  final List<ElementImpl> _localElements = [];

  ResolutionReader(this._elementFactory, this._referenceReader, this._reader);

  LibraryElementImpl libraryOfUri(Uri uri) {
    return _elementFactory.libraryOfUri2(uri);
  }

  bool readBool() {
    return _reader.readBool();
  }

  int readByte() {
    return _reader.readByte();
  }

  InternalConstructorElement? readConstructorElementMixin() {
    return readElement() as InternalConstructorElement?;
  }

  double readDouble() {
    return _reader.readDouble();
  }

  Element? readElement() {
    var kind = readEnum(ElementTag.values);
    switch (kind) {
      case ElementTag.null_:
        return null;
      case ElementTag.dynamic_:
        return DynamicElementImpl.instance;
      case ElementTag.never_:
        return NeverElementImpl.instance;
      case ElementTag.multiplyDefined:
        return null;
      case ElementTag.memberWithTypeArguments:
        var elementImpl = readElement() as ElementImpl;
        var enclosing = elementImpl.enclosingElement as InstanceElementImpl;

        var typeArguments = _readTypeList();
        var substitution = Substitution.fromPairs2(
          enclosing.typeParameters,
          typeArguments,
        );

        if (elementImpl is ExecutableElementImpl) {
          return SubstitutedExecutableElementImpl.from(
            elementImpl,
            substitution,
          );
        } else {
          elementImpl as FieldElementImpl;
          return SubstitutedFieldElementImpl.from(elementImpl, substitution);
        }
      case ElementTag.elementImpl:
        var referenceIndex = _reader.readUint30();
        var reference = _referenceReader.referenceOfIndex(referenceIndex);
        return _elementFactory.elementOfReference3(reference);
      case ElementTag.typeParameter:
        var index = _reader.readUint30();
        return _localElements[index] as TypeParameterElementImpl;
      case ElementTag.formalParameter:
        var enclosing = readElement() as FunctionTypedElementImpl;
        var index = _reader.readUint30();
        return enclosing.formalParameters[index];
    }
  }

  List<T> readElementList<T extends Element>() {
    return _reader.readTypedListCast<T>(readElement);
  }

  T readEnum<T extends Enum>(List<T> values) {
    return _reader.readEnum(values);
  }

  Map<K, V> readMap<K, V>({
    required K Function() readKey,
    required V Function() readValue,
  }) {
    return _reader.readMap(readKey: readKey, readValue: readValue);
  }

  MetadataImpl readMetadata() {
    return _readMetadata();
  }

  List<T> readNodeList<T>() {
    return _readNodeList();
  }

  List<T>? readOptionalElementList<T extends Element>() {
    return _reader.readOptionalObject(readElementList);
  }

  ExpressionImpl? readOptionalExpression() {
    if (_reader.readBool()) {
      return _readRequiredNode() as ExpressionImpl;
    } else {
      return null;
    }
  }

  FunctionTypeImpl? readOptionalFunctionType() {
    var type = readType();
    return type is FunctionTypeImpl ? type : null;
  }

  T? readOptionalObject<T>(T Function() read) {
    return _reader.readOptionalObject(read);
  }

  List<TypeImpl>? readOptionalTypeList() {
    if (_reader.readBool()) {
      return _readTypeList();
    } else {
      return null;
    }
  }

  TypeImpl readRequiredType() {
    return readType()!;
  }

  SourceRange readSourceRange() {
    var offset = readUint30();
    var length = readUint30();
    return SourceRange(offset, length);
  }

  String readStringReference() {
    return _reader.readStringReference();
  }

  List<String> readStringReferenceList() {
    return _reader.readStringReferenceList();
  }

  TypeImpl? readType() {
    var tag = readEnum(TypeTag.values);
    switch (tag) {
      case TypeTag.NullType:
        return null;
      case TypeTag.DynamicType:
        var type = DynamicTypeImpl.instance;
        return _readAliasElementArguments(type);
      case TypeTag.FunctionType:
        var type = _readFunctionType();
        return _readAliasElementArguments(type);
      case TypeTag.InterfaceType:
        var element = readElement() as InterfaceElementImpl;
        var typeArguments = _readTypeList();
        var nullability = _readNullability();
        var type = element.instantiateImpl(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
        return _readAliasElementArguments(type);
      case TypeTag.InterfaceType_noTypeArguments_none:
        var element = readElement() as InterfaceElementImpl;
        var type = element.instantiateImpl(
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.none,
        );
        return _readAliasElementArguments(type);
      case TypeTag.InterfaceType_noTypeArguments_question:
        var element = readElement() as InterfaceElementImpl;
        var type = element.instantiateImpl(
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.question,
        );
        return _readAliasElementArguments(type);
      case TypeTag.InvalidType:
        var type = InvalidTypeImpl.instance;
        return _readAliasElementArguments(type);
      case TypeTag.NeverType:
        var nullability = _readNullability();
        var type = NeverTypeImpl.instance.withNullability(nullability);
        return _readAliasElementArguments(type);
      case TypeTag.RecordType:
        var type = _readRecordType();
        return _readAliasElementArguments(type);
      case TypeTag.TypeParameterType:
        var element = readElement() as TypeParameterElementImpl;
        var nullability = _readNullability();
        var type = element.instantiate(nullabilitySuffix: nullability);
        return _readAliasElementArguments(type);
      case TypeTag.VoidType:
        var type = VoidTypeImpl.instance;
        return _readAliasElementArguments(type);
    }
  }

  List<T> readTypedList<T>(T Function() read) {
    return _reader.readTypedList(read);
  }

  int readUint30() {
    return _reader.readUint30();
  }

  int readUint32() {
    return _reader.readUint32();
  }

  void setOffset(int offset) {
    _reader.offset = offset;
  }

  void _addTypeParameters(List<TypeParameterFragmentImpl> typeParameters) {
    for (var typeParameter in typeParameters) {
      // TODO(scheglov): review later
      _localElements.add(typeParameter.element);
    }
  }

  void _addTypeParameters2(List<TypeParameterElementImpl> typeParameters) {
    for (var typeParameter in typeParameters) {
      _localElements.add(typeParameter);
    }
  }

  FragmentImpl? _readAliasedElement(LibraryFragmentImpl unitElement) {
    var tag = _reader.readByte();
    if (tag == AliasedElementTag.nothing) {
      return null;
    } else if (tag == AliasedElementTag.genericFunctionElement) {
      var typeParameters = _readTypeParameters(unitElement);
      var formalParameters = _readFormalParameters(unitElement);
      var returnType = readRequiredType();

      _localElements.length -= typeParameters.length;

      var fragment = GenericFunctionTypeFragmentImpl()
        ..typeParameters = typeParameters
        ..formalParameters = formalParameters
        ..returnType = returnType;
      unitElement.encloseElement(fragment);
      return fragment;
    } else {
      throw UnimplementedError('tag: $tag');
    }
  }

  TypeImpl _readAliasElementArguments(TypeImpl type) {
    var aliasElement = readElement();
    if (aliasElement != null) {
      aliasElement as TypeAliasElementImpl;
      var aliasArguments = _readTypeList();
      if (type is DynamicTypeImpl) {
        // TODO(scheglov): add support for `dynamic` aliasing
        return type;
      } else if (type is FunctionTypeImpl) {
        return FunctionTypeImpl(
          typeParameters: type.typeParameters,
          parameters: type.parameters,
          returnType: type.returnType,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element: aliasElement,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is InterfaceTypeImpl) {
        return InterfaceTypeImpl(
          element: type.element,
          typeArguments: type.typeArguments,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element: aliasElement,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is RecordTypeImpl) {
        return RecordTypeImpl(
          positionalFields: type.positionalFields,
          namedFields: type.namedFields,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element: aliasElement,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is TypeParameterTypeImpl) {
        return TypeParameterTypeImpl(
          element: type.element,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element: aliasElement,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is VoidTypeImpl) {
        // TODO(scheglov): add support for `void` aliasing
        return type;
      } else {
        throw UnimplementedError('${type.runtimeType}');
      }
    }
    return type;
  }

  List<FormalParameterFragmentImpl> _readFormalParameters(
    LibraryFragmentImpl? unitElement,
  ) {
    return readTypedList(() {
      var kindIndex = _reader.readByte();
      var kind = _formalParameterKind(kindIndex);
      var hasImplicitType = _reader.readBool();
      var isInitializingFormal = _reader.readBool();
      var typeParameters = _readTypeParameters(unitElement);
      var type = readRequiredType();
      var name = _readFragmentName();
      FormalParameterFragmentImpl element;
      if (isInitializingFormal) {
        element = FieldFormalParameterFragmentImpl(
          name: name,
          nameOffset: null,
          parameterKind: kind,
        );
        element.element.type = type;
      } else {
        element = FormalParameterFragmentImpl(
          name: name,
          nameOffset: null,
          parameterKind: kind,
        );
        element.element.type = type;
      }
      element.hasImplicitType = hasImplicitType;
      element.typeParameters = typeParameters;
      element.formalParameters = _readFormalParameters(unitElement);
      // TODO(scheglov): reuse for formal parameters
      _localElements.length -= typeParameters.length;
      if (unitElement != null) {
        element.metadata = _readMetadata();
      }
      return element;
    });
  }

  String? _readFragmentName() {
    return _reader.readOptionalStringReference();
  }

  // TODO(scheglov): Optimize for write/read of types without type parameters.
  FunctionTypeImpl _readFunctionType() {
    // TODO(scheglov): reuse for formal parameters
    var typeParameters = _readTypeParameters(null);
    var returnType = readRequiredType();
    var formalParameters = _readFormalParameters(null);

    var nullability = _readNullability();

    _localElements.length -= typeParameters.length;

    return FunctionTypeImpl(
      typeParameters: typeParameters.map((f) => f.asElement2).toList(),
      parameters: formalParameters.map((f) => f.asElement2).toList(),
      returnType: returnType,
      nullabilitySuffix: nullability,
    );
  }

  InterfaceTypeImpl _readInterfaceType() {
    return readType() as InterfaceTypeImpl;
  }

  List<InterfaceTypeImpl> _readInterfaceTypeList() {
    return readTypedList(_readInterfaceType);
  }

  MetadataImpl _readMetadata() {
    var annotations = readTypedList(() {
      var ast = _readRequiredNode() as AnnotationImpl;
      return ElementAnnotationImpl(currentLibraryFragment, ast);
    });

    return MetadataImpl(annotations);
  }

  List<T> _readNodeList<T>() {
    return readTypedList(() {
      return _readRequiredNode() as T;
    });
  }

  NullabilitySuffix _readNullability() {
    var index = _reader.readByte();
    return NullabilitySuffix.values[index];
  }

  InterfaceTypeImpl? _readOptionalInterfaceType() {
    return readType() as InterfaceTypeImpl?;
  }

  RecordTypeImpl _readRecordType() {
    var positionalFields = readTypedList(() {
      return RecordTypePositionalFieldImpl(type: readRequiredType());
    });

    var namedFields = readTypedList(() {
      return RecordTypeNamedFieldImpl(
        name: _reader.readStringReference(),
        type: readRequiredType(),
      );
    });

    var nullabilitySuffix = _readNullability();

    return RecordTypeImpl(
      positionalFields: positionalFields,
      namedFields: namedFields,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  AstNode _readRequiredNode() {
    var astReader = AstBinaryReader(reader: this);
    return astReader.readNode();
  }

  List<TypeImpl> _readTypeList() {
    return readTypedList(() {
      return readRequiredType();
    });
  }

  List<TypeParameterFragmentImpl> _readTypeParameters(
    LibraryFragmentImpl? unitElement,
  ) {
    var typeParameters = readTypedList(() {
      var fragmentName = _readFragmentName();
      var typeParameterFragment = TypeParameterFragmentImpl(name: fragmentName);
      var typeParameterElement = TypeParameterElementImpl(
        firstFragment: typeParameterFragment,
      );
      _localElements.add(typeParameterElement);
      // TODO(scheglov): why not element?
      return typeParameterFragment;
    });

    for (var typeParameter in typeParameters) {
      typeParameter.element.bound = readType();
      if (unitElement != null) {
        typeParameter.metadata = _readMetadata();
      }
    }
    return typeParameters;
  }

  static ParameterKind _formalParameterKind(int encoding) {
    if (encoding == Tag.ParameterKindRequiredPositional) {
      return ParameterKind.REQUIRED;
    } else if (encoding == Tag.ParameterKindOptionalPositional) {
      return ParameterKind.POSITIONAL;
    } else if (encoding == Tag.ParameterKindRequiredNamed) {
      return ParameterKind.NAMED_REQUIRED;
    } else if (encoding == Tag.ParameterKindOptionalNamed) {
      return ParameterKind.NAMED;
    } else {
      throw StateError('Unexpected parameter kind encoding: $encoding');
    }
  }
}

/// Information that we need to know about each library before reading it,
/// and without reading it.
///
/// Specifically, the [offset] allows us to know the location of each library,
/// so that when we need to read this library, we know where it starts without
/// reading previous libraries.
class _LibraryHeader {
  final Uri uri;
  final int offset;

  _LibraryHeader({required this.uri, required this.offset});
}

class _ReferenceReader {
  final LinkedElementFactory elementFactory;
  final SummaryDataReader _reader;
  late final Uint32List _parents;
  late final Uint32List _names;
  late final List<Reference?> _references;

  _ReferenceReader(this.elementFactory, this._reader, int offset) {
    _reader.offset = offset;
    _parents = _reader.readUint30List();
    _names = _reader.readUint30List();
    assert(_parents.length == _names.length);

    _references = List.filled(_names.length, null);
  }

  Reference referenceOfIndex(int index) {
    var reference = _references[index];
    if (reference != null) {
      return reference;
    }

    if (index == 0) {
      reference = elementFactory.rootReference;
      _references[index] = reference;
      return reference;
    }

    var nameIndex = _names[index];
    var name = _reader.stringOfIndex(nameIndex);

    var parentIndex = _parents[index];
    var parent = referenceOfIndex(parentIndex);

    reference = parent.getChild(name);
    _references[index] = reference;

    return reference;
  }
}
