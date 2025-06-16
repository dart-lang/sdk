// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/info_declaration_store.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/name_union.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/element_flags.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:pub_semver/pub_semver.dart';

class BundleReader {
  final SummaryDataReader _reader;
  final Map<Uri, Uint8List> _unitsInformativeBytes;
  final InfoDeclarationStore _infoDeclarationStore;

  final Map<Uri, LibraryReader> libraryMap = {};

  BundleReader({
    required LinkedElementFactory elementFactory,
    required Uint8List resolutionBytes,
    Map<Uri, Uint8List> unitsInformativeBytes = const {},
    required InfoDeclarationStore infoDeclarationStore,
    required Map<Uri, LibraryManifest> libraryManifests,
  }) : _reader = SummaryDataReader(resolutionBytes),
       _unitsInformativeBytes = unitsInformativeBytes,
       _infoDeclarationStore = infoDeclarationStore {
    const bytesOfU32 = 4;
    const countOfU32 = 4;
    _reader.offset = _reader.bytes.length - bytesOfU32 * countOfU32;
    var baseResolutionOffset = _reader.readUInt32();
    var librariesOffset = _reader.readUInt32();
    var referencesOffset = _reader.readUInt32();
    var stringsOffset = _reader.readUInt32();
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
        offset: _reader.readUInt30(),
        classMembersLengths: _reader.readUInt30List(),
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
        classMembersLengths: libraryHeader.classMembersLengths,
        infoDeclarationStore: _infoDeclarationStore,
        manifest: libraryManifests[uri],
      );
    }
  }
}

class ClassElementLinkedData extends ElementLinkedData<ClassFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;
  void Function()? _readMembers;
  void Function()? applyInformativeDataToMembers;

  ClassElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void readMembers(covariant ClassFragmentImpl fragment) {
    // Read members of all fragments, in order.
    // So we always read a method augmentation after its target.
    for (var fragment in fragment.element.fragments) {
      var linkedData = fragment.linkedData;
      if (linkedData is ClassElementLinkedData) {
        linkedData._readSingleFragmentMembers(fragment);
      }
    }
  }

  @override
  void _clearLinkedDataOnRead(ClassFragmentImpl element) {
    // Don't clear yet, we use it to read members on demand.
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readMetadata(unitElement: unitElement);
    _readTypeParameters(reader, element.typeParameters);
    element.supertype = reader._readOptionalInterfaceType();
    element.mixins = reader._readInterfaceTypeList();
    element.interfaces = reader._readInterfaceTypeList();

    applyConstantOffsets?.perform();
  }

  void _readSingleFragmentMembers(ClassFragmentImpl element) {
    // We might read class members before other properties.
    element.linkedData?.read(element);
    element.linkedData = null;

    if (element.isMixinApplication) {
      element.constructors;
    } else {
      _readMembers?.call();
      _readMembers = null;

      applyInformativeDataToMembers?.call();
      applyInformativeDataToMembers = null;
    }
  }
}

class CompilationUnitElementLinkedData
    extends ElementLinkedData<LibraryFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  CompilationUnitElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(LibraryFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    for (var import in element.libraryImports) {
      import.metadata = reader._readMetadata(unitElement: unitElement);
      var uri = import.uri;
      if (uri is DirectiveUriWithLibraryImpl) {
        uri.library2 = reader.libraryOfUri(uri.source.uri);
      }
    }

    for (var export in element.libraryExports) {
      export.metadata = reader._readMetadata(unitElement: unitElement);
      var uri = export.uri;
      if (uri is DirectiveUriWithLibraryImpl) {
        uri.library2 = reader.libraryOfUri(uri.source.uri);
      }
    }

    for (var part in element.parts) {
      part.metadata = reader._readMetadata(unitElement: unitElement);
    }

    applyConstantOffsets?.perform();
  }
}

class ConstructorElementLinkedData
    extends ElementLinkedData<ConstructorFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  ConstructorElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(ConstructorFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);

    element.metadata = reader._readMetadata(unitElement: unitElement);
    reader._addFormalParameters(element.parameters);
    _readFormalParameters(reader, element.parameters);
    element.superConstructor =
        reader.readFragmentOrMember() as ConstructorElementMixin?;
    element.redirectedConstructor =
        reader.readFragmentOrMember() as ConstructorElementMixin?;
    element.constantInitializers = reader._readNodeList();
    applyConstantOffsets?.perform();
  }
}

/// Lazy reader of resolution information.
abstract class ElementLinkedData<E> {
  final Reference reference;
  final LibraryReader _libraryReader;
  final LibraryFragmentImpl unitElement;

  /// When this object is created, this offset is the offset of the resolution
  /// information in the [_libraryReader]. After reading is done, this offset
  /// is set to `-1`.
  int _offset;

  ElementLinkedData(
    this.reference,
    LibraryReader libraryReader,
    this.unitElement,
    int offset,
  ) : _libraryReader = libraryReader,
      _offset = offset;

  void read(E element) {
    _clearLinkedDataOnRead(element);
    if (_offset == -1) {
      return;
    }

    var dataReader = _libraryReader._reader.fork(_offset);
    _offset = -1;

    var reader = ResolutionReader(
      _libraryReader._elementFactory,
      _libraryReader._referenceReader,
      dataReader,
    );

    _read(element, reader);
  }

  /// Ensure that all members of the [element] are available. This includes
  /// being able to ask them for example using [ClassElement.methods], and
  /// as well access them through their [Reference]s. For a class declaration
  /// this means reading them, for a named mixin application this means
  /// computing constructors.
  void readMembers(InstanceFragmentImpl element) {}

  void _addEnclosingElementTypeParameters(
    ResolutionReader reader,
    FragmentImpl element,
  ) {
    var enclosing = element.enclosingElement3;
    if (enclosing is InstanceFragmentImpl) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is LibraryFragmentImpl) {
      // Nothing.
    } else if (enclosing is EnumFragmentImpl) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is ExtensionFragmentImpl) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is MixinFragmentImpl) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else {
      throw UnimplementedError('${enclosing.runtimeType}');
    }
  }

  void _clearLinkedDataOnRead(E element);

  void _read(E element, ResolutionReader reader);

  void _readFormalParameters(
    ResolutionReader reader,
    List<FormalParameterFragmentImpl> parameters,
  ) {
    for (var parameter in parameters) {
      parameter.metadata = reader._readMetadata(unitElement: unitElement);
      _readTypeParameters(reader, parameter.typeParameters);
      _readFormalParameters(reader, parameter.parameters);
      parameter.type = reader.readRequiredType();
      if (parameter is ConstVariableFragment) {
        var defaultParameter = parameter as ConstVariableFragment;
        var initializer = reader._readOptionalExpression();
        if (initializer != null) {
          defaultParameter.constantInitializer = initializer;
        }
      }
      if (parameter is FieldFormalParameterFragmentImpl) {
        parameter.field = reader.readFragmentOrMember() as FieldFragmentImpl?;
      }
    }
  }

  void _readTypeParameters(
    ResolutionReader reader,
    List<TypeParameterFragmentImpl> typeParameters,
  ) {
    reader._addTypeParameters(typeParameters);
    for (var typeParameter in typeParameters) {
      typeParameter.metadata = reader._readMetadata(unitElement: unitElement);
      typeParameter.bound = reader.readType();
      typeParameter.defaultType = reader.readType();
    }
  }
}

class EnumElementLinkedData extends ElementLinkedData<EnumFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  EnumElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(EnumFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readMetadata(
      unitElement: element.enclosingElement3,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.supertype = reader._readOptionalInterfaceType();
    element.mixins = reader._readInterfaceTypeList();
    element.interfaces = reader._readInterfaceTypeList();
    applyConstantOffsets?.perform();
  }
}

class ExtensionElementLinkedData
    extends ElementLinkedData<ExtensionFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  ExtensionElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(ExtensionFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readMetadata(
      unitElement: element.enclosingElement3,
    );
    _readTypeParameters(reader, element.typeParameters);
    var extendedType = reader.readRequiredType();
    var augmented = element.augmentedInternal;
    augmented.extendedType = extendedType;

    applyConstantOffsets?.perform();
  }
}

class ExtensionTypeElementLinkedData
    extends ElementLinkedData<ExtensionTypeFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  ExtensionTypeElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(ExtensionTypeFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readMetadata(
      unitElement: element.enclosingElement3,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.interfaces = reader._readInterfaceTypeList();
    element.typeErasure = reader.readRequiredType();
    applyConstantOffsets?.perform();
  }
}

class FieldElementLinkedData extends ElementLinkedData<FieldFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  FieldElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(FieldFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);
    element.metadata = reader._readMetadata(unitElement: unitElement);
    element.type = reader.readRequiredType();

    if (element is ConstFieldFragmentImpl) {
      var initializer = reader._readOptionalExpression();
      if (initializer != null) {
        element.constantInitializer = initializer;
        ConstantContextForExpressionImpl(element, initializer);
      }
    }
    applyConstantOffsets?.perform();
  }
}

class FunctionElementLinkedData
    extends ElementLinkedData<FunctionFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  FunctionElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(FunctionFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readMetadata(unitElement: unitElement);
    _readTypeParameters(reader, element.typeParameters);
    element.returnType = reader.readRequiredType();
    _readFormalParameters(reader, element.parameters);
    applyConstantOffsets?.perform();
  }
}

/// Not an [ElementLinkedData], just a bundle with data.
class LibraryAugmentationElementLinkedData {
  final int offset;
  ApplyConstantOffsets? applyConstantOffsets;

  LibraryAugmentationElementLinkedData({required this.offset});
}

class LibraryElementLinkedData extends ElementLinkedData<LibraryElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  /// When we are applying offsets to a library, we want to lock it.
  bool _isLocked = false;

  LibraryElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  LinkedElementFactory get elementFactory {
    return _libraryReader._elementFactory;
  }

  void lock() {
    assert(!_isLocked);
    _isLocked = true;
  }

  @override
  void read(LibraryElementImpl element) {
    if (!_isLocked) {
      super.read(element);
    }
  }

  void unlock() {
    assert(_isLocked);
    _isLocked = false;
  }

  @override
  void _clearLinkedDataOnRead(LibraryElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readMetadata(unitElement: unitElement);

    element.entryPoint2 = reader.readElement() as TopLevelFunctionElementImpl?;

    element.fieldNameNonPromotabilityInfo = _readFieldNameNonPromotabilityInfo(
      reader,
    );

    element.exportNamespace = elementFactory.buildExportNamespace(
      element.source.uri,
      element.exportedReferences,
    );

    applyConstantOffsets?.perform();
  }

  Map<String, FieldNameNonPromotabilityInfo>?
  _readFieldNameNonPromotabilityInfo(ResolutionReader reader) {
    return reader.readOptionalObject(() {
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
    });
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
  final InfoDeclarationStore _deserializedDataStore;
  final LibraryManifest? manifest;

  final Uint32List _classMembersLengths;
  int _classMembersLengthsIndex = 0;

  late final LibraryElementImpl _libraryElement;

  LibraryReader._({
    required LinkedElementFactory elementFactory,
    required SummaryDataReader reader,
    required this.uri,
    required Map<Uri, Uint8List> unitsInformativeBytes,
    required int baseResolutionOffset,
    required _ReferenceReader referenceReader,
    required Reference reference,
    required int offset,
    required Uint32List classMembersLengths,
    required InfoDeclarationStore infoDeclarationStore,
    required this.manifest,
  }) : _elementFactory = elementFactory,
       _reader = reader,
       _unitsInformativeBytes = unitsInformativeBytes,
       _baseResolutionOffset = baseResolutionOffset,
       _referenceReader = referenceReader,
       _reference = reference,
       _offset = offset,
       _classMembersLengths = classMembersLengths,
       _deserializedDataStore = infoDeclarationStore;

  LibraryElementImpl readElement({required Source librarySource}) {
    var analysisContext = _elementFactory.analysisContext;
    var analysisSession = _elementFactory.analysisSession;

    _reader.offset = _offset;

    // TODO(scheglov): https://github.com/dart-lang/sdk/issues/51855
    // This should not be needed.
    // But I have a suspicion that we attempt to read the library twice.
    _classMembersLengthsIndex = 0;

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
    _reference.element2 = _libraryElement;
    _libraryElement.reference = _reference;

    // Read the rest of non-resolution data for the library.
    LibraryElementFlags.read(_reader, _libraryElement);
    _libraryElement.languageVersion = _readLanguageVersion();

    _libraryElement.exportedReferences = _reader.readTypedList(
      _readExportedReference,
    );

    _libraryElement.nameUnion = ElementNameUnion.read(_reader.readUInt30List());

    _libraryElement.manifest = manifest;

    _libraryElement.loadLibraryProvider = LoadLibraryFunctionProvider(
      fragmentReference: _readReference(),
      elementReference: _readReference(),
    );

    // Read the library units.
    _libraryElement.definingCompilationUnit = _readUnitElement(
      containerUnit: null,
      unitSource: librarySource,
    );

    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    _libraryElement.linkedData = LibraryElementLinkedData(
      reference: _reference,
      libraryReader: this,
      unitElement: _libraryElement.definingCompilationUnit,
      offset: resolutionOffset,
    );

    _declareDartCoreDynamicNever();

    InformativeDataApplier(
      _elementFactory,
      _unitsInformativeBytes,
      _deserializedDataStore,
    ).applyTo(_libraryElement);

    return _libraryElement;
  }

  /// These elements are implicitly declared in `dart:core`.
  void _declareDartCoreDynamicNever() {
    if (_reference.name == 'dart:core') {
      _reference.getChild('dynamic').element = DynamicFragmentImpl.instance;
      _reference.getChild('Never').element = NeverFragmentImpl.instance;
    }
  }

  ClassFragmentImpl _readClassElement(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();

    var fragment = ClassFragmentImpl(name2: fragmentName, nameOffset: -1);

    if (reference2.element2 case ClassElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = ClassElementImpl2(reference2, fragment);
      _libraryElement.classes.add(element);
    }

    var linkedData = ClassElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    ClassElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    if (!fragment.isMixinApplication) {
      var membersOffset = _reader.offset;
      linkedData._readMembers = () {
        _reader.offset = membersOffset;
        _readClassElementMembers(fragment, reference);
      };
      _reader.offset += _classMembersLengths[_classMembersLengthsIndex++];
    }

    return fragment;
  }

  void _readClassElementMembers(
    ClassFragmentImpl fragment,
    Reference reference,
  ) {
    var unitElement = fragment.enclosingElement3;

    var fields = <FieldFragmentImpl>[];
    var getters = <GetterFragmentImpl>[];
    var setters = <SetterFragmentImpl>[];
    _readFields(unitElement, fragment, reference, fields, getters, setters);
    _readPropertyAccessors(
      unitElement,
      fragment,
      reference,
      getters,
      setters,
      fields,
      '@field',
    );
    fragment.fields = fields.toFixedList();
    fragment.getters = getters.toFixedList();
    fragment.setters = setters.toFixedList();

    fragment.constructors = _readConstructors(unitElement, fragment, reference);
    fragment.methods = _readMethods(unitElement, fragment, reference);
  }

  void _readClasses(LibraryFragmentImpl unitElement, Reference unitReference) {
    unitElement.classes = _reader.readTypedList(() {
      return _readClassElement(unitElement, unitReference);
    });
  }

  List<ConstructorFragmentImpl> _readConstructors(
    LibraryFragmentImpl unitElement,
    InterfaceFragmentImpl classElement,
    Reference classReference,
  ) {
    return _reader.readTypedList(() {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var reference = _readReference();
      var reference2 = _readReference();
      var typeName = _reader.readOptionalStringReference();
      var fragmentName = _reader.readStringReference();
      var element = ConstructorFragmentImpl(
        name2: fragmentName,
        nameOffset: -1,
      );
      element.typeName = typeName;
      var linkedData = ConstructorElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      );
      element.setLinkedData(reference, linkedData);
      ConstructorElementFlags.read(_reader, element);
      element.parameters = _readParameters();

      ConstructorElementImpl2(
        name3: element.name2,
        reference: reference2,
        firstFragment: element,
      );

      return element;
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

  EnumFragmentImpl _readEnumElement(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();

    var fragment = EnumFragmentImpl(name2: fragmentName, nameOffset: -1);

    if (reference2.element2 case EnumElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = EnumElementImpl2(reference2, fragment);
      _libraryElement.enums.add(element);
    }

    var linkedData = EnumElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    EnumElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    var fields = <FieldFragmentImpl>[];
    var getters = <GetterFragmentImpl>[];
    var setters = <SetterFragmentImpl>[];

    _readFields(unitElement, fragment, reference, fields, getters, setters);
    _readPropertyAccessors(
      unitElement,
      fragment,
      reference,
      getters,
      setters,
      fields,
      '@field',
    );
    fragment.fields = fields.toFixedList();
    fragment.getters = getters.toFixedList();
    fragment.setters = setters.toFixedList();

    fragment.constructors = _readConstructors(unitElement, fragment, reference);
    fragment.methods = _readMethods(unitElement, fragment, reference);

    return fragment;
  }

  void _readEnums(LibraryFragmentImpl unitElement, Reference unitReference) {
    unitElement.enums = _reader.readTypedList(() {
      return _readEnumElement(unitElement, unitReference);
    });
  }

  ExportedReference _readExportedReference() {
    var kind = _reader.readByte();
    if (kind == 0) {
      var index = _reader.readUInt30();
      var reference = _referenceReader.referenceOfIndex(index);
      return ExportedReferenceDeclared(reference: reference);
    } else if (kind == 1) {
      var index = _reader.readUInt30();
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
      fragmentIndex: _reader.readUInt30(),
      exportIndex: _reader.readUInt30(),
    );
  }

  ExtensionFragmentImpl _readExtensionElement(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();

    var fragment = ExtensionFragmentImpl(name2: fragmentName, nameOffset: -1);

    if (reference2.element2 case ExtensionElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = ExtensionElementImpl2(reference2, fragment);
      _libraryElement.extensions.add(element);
    }

    fragment.setLinkedData(
      reference,
      ExtensionElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      ),
    );

    ExtensionElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    var fields = <FieldFragmentImpl>[];
    var getters = <GetterFragmentImpl>[];
    var setters = <SetterFragmentImpl>[];
    _readPropertyAccessors(
      unitElement,
      fragment,
      reference,
      getters,
      setters,
      fields,
      '@field',
    );
    _readFields(unitElement, fragment, reference, fields, getters, setters);
    fragment.fields = fields;
    fragment.getters = getters;
    fragment.setters = setters;

    fragment.methods = _readMethods(unitElement, fragment, reference);

    return fragment;
  }

  void _readExtensions(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.extensions = _reader.readTypedList(() {
      return _readExtensionElement(unitElement, unitReference);
    });
  }

  ExtensionTypeFragmentImpl _readExtensionTypeElement(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();

    var fragment = ExtensionTypeFragmentImpl(
      name2: fragmentName,
      nameOffset: -1,
    );

    if (reference2.element2 case ExtensionTypeElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = ExtensionTypeElementImpl2(reference2, fragment);
      _libraryElement.extensionTypes.add(element);
    }

    fragment.setLinkedData(
      reference,
      ExtensionTypeElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      ),
    );

    ExtensionTypeElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    var fields = <FieldFragmentImpl>[];
    var getters = <GetterFragmentImpl>[];
    var setters = <SetterFragmentImpl>[];
    _readFields(unitElement, fragment, reference, fields, getters, setters);
    _readPropertyAccessors(
      unitElement,
      fragment,
      reference,
      getters,
      setters,
      fields,
      '@field',
    );
    fragment.fields = fields;
    fragment.getters = getters;
    fragment.setters = setters;

    fragment.constructors = _readConstructors(unitElement, fragment, reference);
    fragment.methods = _readMethods(unitElement, fragment, reference);

    return fragment;
  }

  void _readExtensionTypes(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.extensionTypes = _reader.readTypedList(() {
      return _readExtensionTypeElement(unitElement, unitReference);
    });
  }

  FeatureSet _readFeatureSet() {
    var featureSetEncoded = _reader.readUint8List();
    return ExperimentStatus.fromStorage(featureSetEncoded);
  }

  FieldFragmentImpl _readFieldElement(
    LibraryFragmentImpl unitElement,
    FragmentImpl classElement,
    Reference classReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();
    var reference2 = _readReference();
    var getterReference = _readOptionalReference();
    var setterReference = _readOptionalReference();
    var fragmentName = _readFragmentName();
    var isConstElement = _reader.readBool();

    FieldFragmentImpl element;
    if (isConstElement) {
      element = ConstFieldFragmentImpl(name2: fragmentName, nameOffset: -1);
    } else {
      element = FieldFragmentImpl(name2: fragmentName, nameOffset: -1);
    }

    var linkedData = FieldElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    element.setLinkedData(reference, linkedData);

    FieldElementFlags.read(_reader, element);
    element.typeInferenceError = _readTopLevelInferenceError();

    if (!element.isAugmentation) {
      if (getterReference != null) {
        var getter = element.createImplicitGetter(getterReference);
        getter.hasEnclosingTypeParameterReference =
            element.hasEnclosingTypeParameterReference;
      }
      if (element.hasSetter && setterReference != null) {
        var setter = element.createImplicitSetter(setterReference);
        setter.hasEnclosingTypeParameterReference =
            element.hasEnclosingTypeParameterReference;
      }
    }

    FieldElementImpl2(reference: reference2, firstFragment: element);

    return element;
  }

  void _readFields(
    LibraryFragmentImpl unitElement,
    FragmentImpl classElement,
    Reference classReference,
    List<FieldFragmentImpl> variables,
    List<GetterFragmentImpl> getters,
    List<SetterFragmentImpl> setters,
  ) {
    var fieldCount = _reader.readUInt30();
    for (var i = 0; i < fieldCount; i++) {
      var field = _readFieldElement(unitElement, classElement, classReference);
      variables.add(field);

      var getter = field.getter;
      if (getter != null) {
        getters.add(getter);
      }

      var setter = field.setter;
      if (setter != null) {
        setters.add(setter);
      }
    }
  }

  String? _readFragmentName() {
    return _reader.readOptionalStringReference();
  }

  void _readFunctions(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.functions = _reader.readTypedList(() {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var reference = _readReference();
      var reference2 = _readReference();
      var fragmentName = _readFragmentName();

      var fragment = TopLevelFunctionFragmentImpl(
        name2: fragmentName,
        nameOffset: -1,
      );

      if (reference2.element2 case TopLevelFunctionElementImpl element?) {
        fragment.element = element;
      } else {
        var element = TopLevelFunctionElementImpl(reference2, fragment);
        _libraryElement.topLevelFunctions.add(element);
      }

      var linkedData = FunctionElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      );
      fragment.setLinkedData(reference, linkedData);

      FunctionElementFlags.read(_reader, fragment);
      fragment.typeParameters = _readTypeParameters();
      fragment.parameters = _readParameters();

      return fragment;
    });
  }

  LibraryLanguageVersion _readLanguageVersion() {
    var packageMajor = _reader.readUInt30();
    var packageMinor = _reader.readUInt30();
    var package = Version(packageMajor, packageMinor, 0);

    Version? override;
    if (_reader.readBool()) {
      var overrideMajor = _reader.readUInt30();
      var overrideMinor = _reader.readUInt30();
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
      prefix2: _readLibraryImportPrefixFragment(libraryFragment: containerUnit),
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
        enclosingFragment: libraryFragment,
        name2: fragmentName,
        nameOffset2: null,
        isDeferred: isDeferred,
      );

      var element = reference.element2 as PrefixElementImpl2?;
      if (element == null) {
        element = PrefixElementImpl2(
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

  List<MethodFragmentImpl> _readMethods(
    LibraryFragmentImpl unitElement,
    FragmentImpl enclosingElement,
    Reference enclosingReference,
  ) {
    return _reader.readTypedList(() {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var reference = _readReference();
      var reference2 = _readReference();
      var fragmentName = _readFragmentName();
      var fragment = MethodFragmentImpl(name2: fragmentName, nameOffset: -1);

      var linkedData = MethodElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      );
      fragment.setLinkedData(reference, linkedData);
      MethodElementFlags.read(_reader, fragment);
      fragment.typeParameters = _readTypeParameters();
      fragment.parameters = _readParameters();
      fragment.typeInferenceError = _readTopLevelInferenceError();

      MethodElementImpl2(
        name3: fragmentName,
        reference: reference2,
        firstFragment: fragment,
      );

      return fragment;
    });
  }

  MixinFragmentImpl _readMixinElement(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();

    var fragment = MixinFragmentImpl(name2: fragmentName, nameOffset: -1);

    if (reference2.element2 case MixinElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = MixinElementImpl2(reference2, fragment);
      _libraryElement.mixins.add(element);
    }

    var linkedData = MixinElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    MixinElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    var fields = <FieldFragmentImpl>[];
    var getters = <GetterFragmentImpl>[];
    var setters = <SetterFragmentImpl>[];
    _readFields(unitElement, fragment, reference, fields, getters, setters);
    _readPropertyAccessors(
      unitElement,
      fragment,
      reference,
      getters,
      setters,
      fields,
      '@field',
    );
    fragment.fields = fields.toFixedList();
    fragment.getters = getters.toFixedList();
    fragment.setters = setters.toFixedList();

    fragment.constructors = _readConstructors(unitElement, fragment, reference);
    fragment.methods = _readMethods(unitElement, fragment, reference);
    fragment.superInvokedNames = _reader.readStringReferenceList();

    return fragment;
  }

  void _readMixins(LibraryFragmentImpl unitElement, Reference unitReference) {
    unitElement.mixins = _reader.readTypedList(() {
      return _readMixinElement(unitElement, unitReference);
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
      var fragmentName = _readFragmentName();
      var isDefault = _reader.readBool();
      var isInitializingFormal = _reader.readBool();
      var isSuperFormal = _reader.readBool();
      var reference = _readOptionalReference();

      var kindIndex = _reader.readByte();
      var kind = ResolutionReader._formalParameterKind(kindIndex);

      FormalParameterFragmentImpl element;
      if (!isDefault) {
        if (isInitializingFormal) {
          element = FieldFormalParameterFragmentImpl(
            nameOffset: -1,
            name2: fragmentName,
            nameOffset2: null,
            parameterKind: kind,
          );
        } else if (isSuperFormal) {
          element = SuperFormalParameterFragmentImpl(
            nameOffset: -1,
            name2: fragmentName,
            nameOffset2: null,
            parameterKind: kind,
          );
        } else {
          element = FormalParameterFragmentImpl(
            nameOffset: -1,
            name2: fragmentName,
            nameOffset2: null,
            parameterKind: kind,
          );
        }
      } else {
        if (isInitializingFormal) {
          element = DefaultFieldFormalParameterElementImpl(
            nameOffset: -1,
            name2: fragmentName,
            nameOffset2: null,
            parameterKind: kind,
          );
        } else if (isSuperFormal) {
          element = DefaultSuperFormalParameterElementImpl(
            nameOffset: -1,
            name2: fragmentName,
            nameOffset2: null,
            parameterKind: kind,
          );
        } else {
          element = DefaultParameterFragmentImpl(
            nameOffset: -1,
            name2: fragmentName,
            nameOffset2: null,
            parameterKind: kind,
          );
        }
        if (reference != null) {
          element.reference = reference;
          reference.element = element;
        }
      }
      ParameterElementFlags.read(_reader, element);
      element.typeParameters = _readTypeParameters();
      element.parameters = _readParameters();
      return element;
    });
  }

  PartIncludeImpl _readPartInclude({
    required LibraryFragmentImpl containerUnit,
  }) {
    var uri = _readDirectiveUri(containerUnit: containerUnit);

    return PartIncludeImpl(uri: uri);
  }

  PropertyAccessorFragmentImpl _readPropertyAccessorElement(
    LibraryFragmentImpl unitElement,
    FragmentImpl classElement,
    Reference classReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();
    var fragmentName = _readFragmentName();
    var flags = _reader.readUInt30();

    var fragment =
        PropertyAccessorElementFlags.isGetter(flags)
            ? GetterFragmentImpl(name2: fragmentName, nameOffset: -1)
            : SetterFragmentImpl(name2: fragmentName, nameOffset: -1);

    var linkedData = PropertyAccessorElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    PropertyAccessorElementFlags.setFlagsBasedOnFlagByte(fragment, flags);
    fragment.parameters = _readParameters();
    return fragment;
  }

  void _readPropertyAccessors(
    LibraryFragmentImpl unitElement,
    FragmentImpl enclosingElement,
    Reference enclosingReference,
    List<GetterFragmentImpl> gettersFragments,
    List<SetterFragmentImpl> settersFragments,
    List<PropertyInducingFragmentImpl> propertyFragments,
    String containerRefName, {
    List<TopLevelVariableElementImpl2>? variables2,
  }) {
    var accessorCount = _reader.readUInt30();
    for (var i = 0; i < accessorCount; i++) {
      var accessor = _readPropertyAccessorElement(
        unitElement,
        enclosingElement,
        enclosingReference,
      );
      switch (accessor) {
        case GetterFragmentImpl getter:
          gettersFragments.add(getter);
        case SetterFragmentImpl setter:
          settersFragments.add(setter);
      }

      if (accessor.isAugmentation) {
        continue;
      }

      // Read the property references.
      var propertyFragmentReference = _readReference();
      var propertyElementReference = _readReference();

      bool canUseExisting(PropertyInducingFragmentImpl property) {
        return property.isSynthetic ||
            accessor.isSetter && property.setter == null;
      }

      PropertyInducingFragmentImpl propertyFragment;
      var existing = propertyFragmentReference.element;
      if (enclosingElement is LibraryFragmentImpl) {
        if (existing is TopLevelVariableFragmentImpl &&
            canUseExisting(existing)) {
          propertyFragment = existing;
        } else {
          var variableFragment =
              TopLevelVariableFragmentImpl(
                  name2: accessor.name2,
                  nameOffset: -1,
                )
                ..enclosingElement3 = enclosingElement
                ..reference = propertyFragmentReference
                ..isSynthetic = true;
          propertyFragment = variableFragment;
          propertyFragmentReference.element ??= propertyFragment;
          propertyFragments.add(variableFragment);

          var variableElement = TopLevelVariableElementImpl2(
            propertyElementReference,
            variableFragment,
          );
          variables2!.add(variableElement);
        }
      } else {
        var isPromotable = _reader.readBool();
        if (existing is FieldFragmentImpl && canUseExisting(existing)) {
          propertyFragment = existing;
        } else {
          var fieldFragment =
              FieldFragmentImpl(name2: accessor.name2, nameOffset: -1)
                ..enclosingElement3 = enclosingElement
                ..reference = propertyFragmentReference
                ..isStatic = accessor.isStatic
                ..isSynthetic = true
                ..isPromotable = isPromotable
                ..hasEnclosingTypeParameterReference =
                    accessor.hasEnclosingTypeParameterReference;
          propertyFragment = fieldFragment;
          propertyFragmentReference.element ??= propertyFragment;
          propertyFragments.add(propertyFragment);

          FieldElementImpl2(
            reference: propertyElementReference,
            firstFragment: fieldFragment,
          );
        }
      }

      accessor.variable2 = propertyFragment;
      switch (accessor) {
        case GetterFragmentImpl():
          propertyFragment.getter = accessor;
        case SetterFragmentImpl():
          propertyFragment.setter = accessor;
          if (propertyFragment.isSynthetic) {
            propertyFragment.isFinal = false;
          }
      }
    }
  }

  /// Read the reference of a non-local element.
  Reference _readReference() {
    var referenceIndex = _reader.readUInt30();
    return _referenceReader.referenceOfIndex(referenceIndex);
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

  TopLevelVariableFragmentImpl _readTopLevelVariableElement(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();
    var reference2 = _readReference();
    var getterReference = _readOptionalReference();
    var setterReference = _readOptionalReference();
    var fragmentName = _readFragmentName();
    var isConst = _reader.readBool();

    TopLevelVariableFragmentImpl fragment;
    if (isConst) {
      fragment = ConstTopLevelVariableFragmentImpl(
        name2: fragmentName,
        nameOffset: -1,
      );
    } else {
      fragment = TopLevelVariableFragmentImpl(
        name2: fragmentName,
        nameOffset: -1,
      );
    }

    if (reference2.element2 case TopLevelVariableElementImpl2 element) {
      fragment.element = element;
    } else {
      var element = TopLevelVariableElementImpl2(reference2, fragment);
      _libraryElement.topLevelVariables.add(element);
    }

    var linkedData = TopLevelVariableElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    fragment.isConst = isConst;
    TopLevelVariableElementFlags.read(_reader, fragment);
    fragment.typeInferenceError = _readTopLevelInferenceError();

    if (getterReference != null) {
      var getter = fragment.createImplicitGetter(getterReference);
      getter.hasEnclosingTypeParameterReference = false;
    }
    if (fragment.hasSetter && setterReference != null) {
      var getter = fragment.createImplicitSetter(setterReference);
      getter.hasEnclosingTypeParameterReference = false;
    }

    return fragment;
  }

  void _readTopLevelVariables(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
    List<GetterFragmentImpl> getters,
    List<SetterFragmentImpl> setters,
    List<TopLevelVariableFragmentImpl> variables,
  ) {
    var variableElementCount = _reader.readUInt30();
    for (var i = 0; i < variableElementCount; i++) {
      var variable = _readTopLevelVariableElement(unitElement, unitReference);
      variables.add(variable);

      var getter = variable.getter;
      if (getter is GetterFragmentImpl) {
        getters.add(getter);
      }

      var setter = variable.setter;
      if (setter is SetterFragmentImpl) {
        setters.add(setter);
      }
    }
  }

  TypeAliasFragmentImpl _readTypeAliasElement(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var reference = _readReference();
    var reference2 = _readReference();
    var fragmentName = _readFragmentName();

    var isFunctionTypeAliasBased = _reader.readBool();

    TypeAliasFragmentImpl fragment;
    if (isFunctionTypeAliasBased) {
      fragment = TypeAliasFragmentImpl(name2: fragmentName, nameOffset: -1);
      fragment.isFunctionTypeAliasBased = true;
    } else {
      fragment = TypeAliasFragmentImpl(name2: fragmentName, nameOffset: -1);
    }

    if (reference2.element2 case TypeAliasElementImpl2 element) {
      fragment.element = element;
    } else {
      var element = TypeAliasElementImpl2(reference2, fragment);
      _libraryElement.typeAliases.add(element);
    }

    var linkedData = TypeAliasElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    fragment.isFunctionTypeAliasBased = isFunctionTypeAliasBased;
    TypeAliasElementFlags.read(_reader, fragment);

    fragment.typeParameters = _readTypeParameters();

    return fragment;
  }

  void _readTypeAliases(
    LibraryFragmentImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.typeAliases = _reader.readTypedList(() {
      return _readTypeAliasElement(unitElement, unitReference);
    });
  }

  List<TypeParameterFragmentImpl> _readTypeParameters() {
    return _reader.readTypedList(() {
      var fragmentName = _readFragmentName();
      var varianceEncoding = _reader.readByte();
      var variance = _decodeVariance(varianceEncoding);
      var element = TypeParameterFragmentImpl(
        name2: fragmentName,
        nameOffset: -1,
      );
      element.variance = variance;
      return element;
    });
  }

  LibraryFragmentImpl _readUnitElement({
    required LibraryFragmentImpl? containerUnit,
    required Source unitSource,
  }) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var unitElement = LibraryFragmentImpl(
      library: _libraryElement,
      source: unitSource,
      lineInfo: LineInfo([0]),
    );

    var unitReference = _reference
        .getChild('@fragment')
        .getChild('${unitSource.uri}');
    unitElement.setLinkedData(
      unitReference,
      CompilationUnitElementLinkedData(
        reference: unitReference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      ),
    );

    unitElement.isSynthetic = _reader.readBool();

    unitElement.libraryImports = _reader.readTypedList(() {
      return _readLibraryImport(containerUnit: unitElement);
    });

    unitElement.libraryExports = _reader.readTypedList(() {
      return _readLibraryExport(containerUnit: unitElement);
    });

    _readClasses(unitElement, unitReference);
    _readEnums(unitElement, unitReference);
    _readExtensions(unitElement, unitReference);
    _readExtensionTypes(unitElement, unitReference);
    _readFunctions(unitElement, unitReference);
    _readMixins(unitElement, unitReference);
    _readTypeAliases(unitElement, unitReference);

    var variableFragments = <TopLevelVariableFragmentImpl>[];
    var getters = <GetterFragmentImpl>[];
    var setters = <SetterFragmentImpl>[];
    _readTopLevelVariables(
      unitElement,
      unitReference,
      getters,
      setters,
      variableFragments,
    );
    _readPropertyAccessors(
      unitElement,
      unitElement,
      unitReference,
      getters,
      setters,
      variableFragments,
      '@topLevelVariable',
      variables2: _libraryElement.topLevelVariables,
    );
    unitElement.topLevelVariables = variableFragments.toFixedList();
    unitElement.getters = getters.toFixedList();
    unitElement.setters = setters.toFixedList();

    unitElement.parts = _reader.readTypedList(() {
      return _readPartInclude(containerUnit: unitElement);
    });

    return unitElement;
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

class MethodElementLinkedData extends ElementLinkedData<MethodFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  MethodElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(MethodFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);
    element.metadata = reader._readMetadata(unitElement: unitElement);
    _readTypeParameters(reader, element.typeParameters);
    _readFormalParameters(reader, element.parameters);
    element.returnType = reader.readRequiredType();
    applyConstantOffsets?.perform();
  }
}

class MixinElementLinkedData extends ElementLinkedData<MixinFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  MixinElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(MixinFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readMetadata(
      unitElement: element.enclosingElement3,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.superclassConstraints = reader._readInterfaceTypeList();
    element.interfaces = reader._readInterfaceTypeList();

    applyConstantOffsets?.perform();
  }
}

class PropertyAccessorElementLinkedData
    extends ElementLinkedData<PropertyAccessorFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  PropertyAccessorElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(PropertyAccessorFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);

    element.metadata = reader._readMetadata(unitElement: unitElement);

    element.returnType = reader.readRequiredType();
    _readFormalParameters(reader, element.parameters);

    applyConstantOffsets?.perform();
  }
}

/// Helper for reading elements and types from their binary encoding.
class ResolutionReader {
  final LinkedElementFactory _elementFactory;
  final _ReferenceReader _referenceReader;
  final SummaryDataReader _reader;

  /// The stack of [TypeParameterFragmentImpl]s and [FormalParameterFragmentImpl] that are
  /// available in the scope of [readFragmentOrMember] and [readType].
  ///
  /// This stack is shared with the client of the reader, and update mostly
  /// by the client. However it is also updated during [_readFunctionType].
  final List<FragmentImpl> _localElements = [];

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

  double readDouble() {
    return _reader.readDouble();
  }

  Element? readElement() {
    var kind = readEnum(ElementTag.values);
    switch (kind) {
      case ElementTag.null_:
        return null;
      case ElementTag.dynamic_:
        return DynamicElementImpl2.instance;
      case ElementTag.never_:
        return NeverElementImpl2.instance;
      case ElementTag.multiplyDefined:
        return null;
      case ElementTag.memberWithTypeArguments:
        var elementImpl = readElement() as ElementImpl2;
        var enclosing = elementImpl.enclosingElement as InstanceElementImpl2;

        var typeArguments = _readTypeList();
        var substitution = Substitution.fromPairs2(
          enclosing.typeParameters2,
          typeArguments,
        );

        if (elementImpl is ExecutableElementImpl2) {
          return ExecutableMember.from(elementImpl, substitution);
        } else {
          elementImpl as FieldElementImpl2;
          return FieldMember.from(elementImpl, substitution);
        }
      case ElementTag.elementImpl:
        var referenceIndex = _reader.readUInt30();
        var reference = _referenceReader.referenceOfIndex(referenceIndex);
        return _elementFactory.elementOfReference3(reference);
      case ElementTag.viaFragment:
        // TODO(scheglov): eventually stop using fragments here.
        var fragment = readFragmentOrMember();
        switch (fragment) {
          case null:
            return null;
          case FragmentImpl():
            return fragment.asElement2;
          case ExecutableMember():
            return fragment;
          default:
            throw UnimplementedError('${fragment.runtimeType}');
        }
    }
  }

  List<T> readElementList<T extends Element>() {
    return _reader.readTypedListCast<T>(readElement);
  }

  T readEnum<T extends Enum>(List<T> values) {
    return _reader.readEnum(values);
  }

  FragmentOrMember? readFragmentOrMember() {
    var memberFlags = _reader.readByte();
    var fragment = _readFragmentImpl();

    if (fragment == null) {
      return null;
    }

    if (memberFlags == Tag.RawElement) {
      return fragment;
    }

    if (memberFlags == Tag.MemberWithTypeArguments) {
      var enclosing = fragment.enclosingElement3 as InstanceFragmentImpl;

      var firstFragment = enclosing.element.firstFragment;
      var declarationTypeParameters =
          firstFragment.typeParameters.map((tp) => tp.asElement2).toList();

      var substitution = Substitution.empty;
      var typeArguments = _readTypeList();
      if (typeArguments.isNotEmpty) {
        substitution = Substitution.fromPairs2(
          declarationTypeParameters,
          typeArguments,
        );
      }

      if (fragment is ExecutableFragmentImpl) {
        return ExecutableMember.from2(fragment, substitution);
      } else {
        fragment as FieldFragmentImpl;
        return FieldMember.from2(fragment, substitution);
      }
    }

    throw UnimplementedError('memberFlags: $memberFlags');
  }

  Map<K, V> readMap<K, V>({
    required K Function() readKey,
    required V Function() readValue,
  }) {
    return _reader.readMap(readKey: readKey, readValue: readValue);
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
    var offset = readUInt30();
    var length = readUInt30();
    return SourceRange(offset, length);
  }

  String readStringReference() {
    return _reader.readStringReference();
  }

  List<String> readStringReferenceList() {
    return _reader.readStringReferenceList();
  }

  TypeImpl? readType() {
    var tag = _reader.readByte();
    if (tag == Tag.NullType) {
      return null;
    } else if (tag == Tag.DynamicType) {
      var type = DynamicTypeImpl.instance;
      return _readAliasElementArguments(type);
    } else if (tag == Tag.FunctionType) {
      var type = _readFunctionType();
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType) {
      var element = readElement() as InterfaceElementImpl2;
      var typeArguments = _readTypeList();
      var nullability = _readNullability();
      var type = element.instantiateImpl(
        typeArguments: typeArguments,
        nullabilitySuffix: nullability,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_none) {
      var element = readElement() as InterfaceElementImpl2;
      var type = element.instantiateImpl(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.none,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_question) {
      var element = readElement() as InterfaceElementImpl2;
      var type = element.instantiateImpl(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.question,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InvalidType) {
      var type = InvalidTypeImpl.instance;
      return _readAliasElementArguments(type);
    } else if (tag == Tag.NeverType) {
      var nullability = _readNullability();
      var type = NeverTypeImpl.instance.withNullability(nullability);
      return _readAliasElementArguments(type);
    } else if (tag == Tag.RecordType) {
      var type = _readRecordType();
      return _readAliasElementArguments(type);
    } else if (tag == Tag.TypeParameterType) {
      var element = readElement() as TypeParameterElementImpl2;
      var nullability = _readNullability();
      var type = element.instantiate(nullabilitySuffix: nullability);
      return _readAliasElementArguments(type);
    } else if (tag == Tag.VoidType) {
      var type = VoidTypeImpl.instance;
      return _readAliasElementArguments(type);
    } else {
      throw UnimplementedError('$tag');
    }
  }

  List<T> readTypedList<T>(T Function() read) {
    return _reader.readTypedList(read);
  }

  int readUInt30() {
    return _reader.readUInt30();
  }

  int readUInt32() {
    return _reader.readUInt32();
  }

  void setOffset(int offset) {
    _reader.offset = offset;
  }

  void _addFormalParameters(List<FormalParameterFragmentImpl> parameters) {
    for (var parameter in parameters) {
      _localElements.add(parameter);
    }
  }

  void _addTypeParameters(List<TypeParameterFragmentImpl> typeParameters) {
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

      return GenericFunctionTypeFragmentImpl.forOffset(-1)
        ..typeParameters = typeParameters
        ..parameters = formalParameters
        ..returnType = returnType;
    } else {
      throw UnimplementedError('tag: $tag');
    }
  }

  TypeImpl _readAliasElementArguments(TypeImpl type) {
    var aliasFragment = _readFragmentImpl();
    if (aliasFragment is TypeAliasFragmentImpl) {
      var aliasArguments = _readTypeList();
      if (type is DynamicTypeImpl) {
        // TODO(scheglov): add support for `dynamic` aliasing
        return type;
      } else if (type is FunctionTypeImpl) {
        return FunctionTypeImpl(
          typeFormals: type.typeFormals,
          parameters: type.parameters,
          returnType: type.returnType,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element2: aliasFragment.asElement2,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is InterfaceTypeImpl) {
        return InterfaceTypeImpl(
          element: type.element3,
          typeArguments: type.typeArguments,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element2: aliasFragment.asElement2,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is RecordTypeImpl) {
        return RecordTypeImpl(
          positionalFields: type.positionalFields,
          namedFields: type.namedFields,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element2: aliasFragment.asElement2,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is TypeParameterTypeImpl) {
        return TypeParameterTypeImpl(
          element3: type.element3,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element2: aliasFragment.asElement2,
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
      var isDefault = _reader.readBool();
      var hasImplicitType = _reader.readBool();
      var isInitializingFormal = _reader.readBool();
      var typeParameters = _readTypeParameters(unitElement);
      var type = readRequiredType();
      var name = _readFragmentName();
      if (!isDefault) {
        FormalParameterFragmentImpl element;
        if (isInitializingFormal) {
          element = FieldFormalParameterFragmentImpl(
            nameOffset: -1,
            name2: name,
            nameOffset2: null,
            parameterKind: kind,
          )..type = type;
        } else {
          element = FormalParameterFragmentImpl(
            nameOffset: -1,
            name2: name,
            nameOffset2: null,
            parameterKind: kind,
          )..type = type;
        }
        element.hasImplicitType = hasImplicitType;
        element.typeParameters = typeParameters;
        element.parameters = _readFormalParameters(unitElement);
        // TODO(scheglov): reuse for formal parameters
        _localElements.length -= typeParameters.length;
        if (unitElement != null) {
          element.metadata = _readMetadata(unitElement: unitElement);
        }
        return element;
      } else {
        var element = DefaultParameterFragmentImpl(
          nameOffset: -1,
          name2: name,
          nameOffset2: null,
          parameterKind: kind,
        )..type = type;
        element.hasImplicitType = hasImplicitType;
        element.typeParameters = typeParameters;
        element.parameters = _readFormalParameters(unitElement);
        // TODO(scheglov): reuse for formal parameters
        _localElements.length -= typeParameters.length;
        if (unitElement != null) {
          element.metadata = _readMetadata(unitElement: unitElement);
        }
        return element;
      }
    });
  }

  FragmentImpl? _readFragmentImpl() {
    var index = _reader.readUInt30();

    if ((index & 0x1) == 0x1) {
      return _localElements[index >> 1];
    }

    var referenceIndex = index >> 1;
    var reference = _referenceReader.referenceOfIndex(referenceIndex);

    return _elementFactory.elementOfReference(reference);
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
      typeFormals: typeParameters,
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

  MetadataImpl _readMetadata({required LibraryFragmentImpl unitElement}) {
    var annotations = readTypedList(() {
      var ast = _readRequiredNode() as AnnotationImpl;
      return ElementAnnotationImpl(unitElement)
        ..annotationAst = ast
        ..element2 = ast.element2;
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

  ExpressionImpl? _readOptionalExpression() {
    if (_reader.readBool()) {
      return _readRequiredNode() as ExpressionImpl;
    } else {
      return null;
    }
  }

  InterfaceType? _readOptionalInterfaceType() {
    return readType() as InterfaceType?;
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
      var typeParameter = TypeParameterFragmentImpl(
        name2: fragmentName,
        nameOffset: -1,
      );
      _localElements.add(typeParameter);
      return typeParameter;
    });

    for (var typeParameter in typeParameters) {
      typeParameter.bound = readType();
      if (unitElement != null) {
        typeParameter.metadata = _readMetadata(unitElement: unitElement);
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

class TopLevelVariableElementLinkedData
    extends ElementLinkedData<TopLevelVariableFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  TopLevelVariableElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(TopLevelVariableFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readMetadata(unitElement: unitElement);
    element.type = reader.readRequiredType();

    if (element is ConstTopLevelVariableFragmentImpl) {
      var initializer = reader._readOptionalExpression();
      if (initializer != null) {
        element.constantInitializer = initializer;
        ConstantContextForExpressionImpl(element, initializer);
      }
    }
    applyConstantOffsets?.perform();
  }
}

class TypeAliasElementLinkedData
    extends ElementLinkedData<TypeAliasFragmentImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  TypeAliasElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required LibraryFragmentImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(TypeAliasFragmentImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readMetadata(unitElement: unitElement);
    _readTypeParameters(reader, element.typeParameters);
    element.aliasedElement = reader._readAliasedElement(unitElement);
    element.aliasedType = reader.readRequiredType();
    applyConstantOffsets?.perform();
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

  /// We don't read class members when reading libraries, by performance
  /// reasons - in many cases only some classes of a library are used. But
  /// we need to know how much data to skip for each class.
  final Uint32List classMembersLengths;

  _LibraryHeader({
    required this.uri,
    required this.offset,
    required this.classMembersLengths,
  });
}

class _ReferenceReader {
  final LinkedElementFactory elementFactory;
  final SummaryDataReader _reader;
  late final Uint32List _parents;
  late final Uint32List _names;
  late final List<Reference?> _references;

  _ReferenceReader(this.elementFactory, this._reader, int offset) {
    _reader.offset = offset;
    _parents = _reader.readUInt30List();
    _names = _reader.readUInt30List();
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
