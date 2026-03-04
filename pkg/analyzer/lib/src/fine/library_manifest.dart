// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

/// The manifest of a single library.
class LibraryManifest {
  final String? name;
  final bool isOriginNotExistingFile;
  final bool isSynthetic;
  final Uint8List featureSet;
  final ManifestLibraryLanguageVersion languageVersion;
  final LibraryMetadataItem libraryMetadata;

  final List<Uri> exportedLibraryUris;

  /// The names that are re-exported by this library.
  /// This does not include names that are declared in this library.
  final Map<LookupName, ManifestItemId> reExportMap;

  /// The names that re-exported exclusively via deprecated exports.
  final Set<LookupName> reExportDeprecatedOnly;

  /// The names of duplicate or otherwise conflicting top-level declarations,
  /// for example two classes with the same name, or a class and a top-level
  /// function.
  ///
  /// These names are not in other `declaredXyz` maps.
  final Map<LookupName, ManifestItemId> declaredConflicts;

  final Map<LookupName, ClassItem> declaredClasses;
  final Map<LookupName, EnumItem> declaredEnums;
  final Map<LookupName, ExtensionItem> declaredExtensions;
  final Map<LookupName, ExtensionTypeItem> declaredExtensionTypes;
  final Map<LookupName, MixinItem> declaredMixins;
  final Map<LookupName, TypeAliasItem> declaredTypeAliases;
  final Map<LookupName, GetterItem> declaredGetters;
  final Map<LookupName, SetterItem> declaredSetters;
  final Map<LookupName, TopLevelFunctionItem> declaredFunctions;
  final Map<LookupName, TopLevelVariableItem> declaredVariables;

  /// Map from exported public top-level names to manifest IDs.
  ///
  /// Includes names declared in this library and names re-exported from other
  /// libraries. Excludes private names. If both a local declaration and a
  /// re-export define the same name, the local declaration is used.
  final Map<LookupName, ManifestItemId> exportMap;

  /// Identifier that summarizes the contents of [exportMap].
  ///
  /// Each build generates a fresh ID. If the computed [exportMap] is equal to
  /// the previous manifest's map for the same library, the previous ID is
  /// reused. Equal IDs imply equal export maps; unequal IDs are inconclusive
  /// and require an entry-by-entry comparison.
  ManifestItemId exportMapId;

  /// All exported (declared or re-exported) extensions.
  ManifestItemIdList exportedExtensions;

  /// Stable, order-independent hash for the requirements.
  ///
  /// Derived from exactly the parts of the library manifest that
  /// [RequirementsManifest.isSatisfied] reads. Used as a fast path: if
  /// the current manifest hash matches a previously observed one, the
  /// outcome of the requirements check is unchanged and the detailed check
  /// can be skipped; if it differs, the check must be re-run.
  Hash hashForRequirements;

  LibraryManifest({
    required this.name,
    required this.isOriginNotExistingFile,
    required this.isSynthetic,
    required this.featureSet,
    required this.languageVersion,
    required this.libraryMetadata,
    required this.exportedLibraryUris,
    required this.reExportMap,
    required this.reExportDeprecatedOnly,
    required this.declaredConflicts,
    required this.declaredClasses,
    required this.declaredEnums,
    required this.declaredExtensions,
    required this.declaredExtensionTypes,
    required this.declaredMixins,
    required this.declaredTypeAliases,
    required this.declaredGetters,
    required this.declaredSetters,
    required this.declaredFunctions,
    required this.declaredVariables,
    required this.exportMap,
    required this.exportMapId,
    required this.exportedExtensions,
    required this.hashForRequirements,
  });

  factory LibraryManifest.fromBytes(Uint8List bytes) {
    var reader = BinaryReader(bytes);
    reader.initFromTableTrailer();
    return LibraryManifest.read(reader);
  }

  factory LibraryManifest.read(BinaryReader reader) {
    return LibraryManifest(
      name: reader.readOptionalStringUtf8(),
      isOriginNotExistingFile: reader.readBool(),
      isSynthetic: reader.readBool(),
      featureSet: reader.readUint8List(),
      languageVersion: ManifestLibraryLanguageVersion.read(reader),
      libraryMetadata: LibraryMetadataItem.read(reader),
      exportedLibraryUris: reader.readUriList(),
      reExportMap: reader.readLookupNameToIdMap(),
      reExportDeprecatedOnly: reader.readLookupNameSet(),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredClasses: reader.readLookupNameMap(
        readValue: () => ClassItem.read(reader),
      ),
      declaredEnums: reader.readLookupNameMap(
        readValue: () => EnumItem.read(reader),
      ),
      declaredExtensions: reader.readLookupNameMap(
        readValue: () => ExtensionItem.read(reader),
      ),
      declaredExtensionTypes: reader.readLookupNameMap(
        readValue: () => ExtensionTypeItem.read(reader),
      ),
      declaredMixins: reader.readLookupNameMap(
        readValue: () => MixinItem.read(reader),
      ),
      declaredTypeAliases: reader.readLookupNameMap(
        readValue: () => TypeAliasItem.read(reader),
      ),
      declaredGetters: reader.readLookupNameMap(
        readValue: () => GetterItem.read(reader),
      ),
      declaredSetters: reader.readLookupNameMap(
        readValue: () => SetterItem.read(reader),
      ),
      declaredFunctions: reader.readLookupNameMap(
        readValue: () => TopLevelFunctionItem.read(reader),
      ),
      declaredVariables: reader.readLookupNameMap(
        readValue: () => TopLevelVariableItem.read(reader),
      ),
      exportMap: reader.readLookupNameToIdMap(),
      exportMapId: ManifestItemId.read(reader),
      exportedExtensions: ManifestItemIdList.read(reader),
      hashForRequirements: Hash.read(reader),
    );
  }

  Map<LookupName, ManifestItemId> get exportedIds {
    return Map.fromEntries([
      ...reExportMap.entries,
      ...declaredConflicts.entries,
      ...<Map<LookupName, ManifestItem>>[
            declaredClasses,
            declaredEnums,
            declaredExtensions,
            declaredExtensionTypes,
            declaredMixins,
            declaredTypeAliases,
            declaredGetters,
            declaredSetters,
            declaredFunctions,
          ]
          .expand((map) => map.entries)
          .whereNot((entry) => entry.key.isPrivate)
          .mapValue((item) => item.id),
    ]);
  }

  /// Returns the ID of a declared top-level element, or `null` if there is no
  /// such element.
  ManifestItemId? getDeclaredId(LookupName name) {
    return declaredConflicts[name] ??
        declaredClasses[name]?.id ??
        declaredEnums[name]?.id ??
        declaredExtensions[name]?.id ??
        declaredExtensionTypes[name]?.id ??
        declaredMixins[name]?.id ??
        declaredTypeAliases[name]?.id ??
        declaredGetters[name]?.id ??
        declaredSetters[name]?.id ??
        declaredFunctions[name]?.id;
  }

  /// Returns the ID of a top-level element either declared or re-exported,
  /// or `null` if there is no such element.
  ManifestItemId? getExportedId(LookupName name) {
    return exportMap[name];
  }

  Uint8List toBytes() {
    var writer = BinaryWriter();
    write(writer);
    writer.writeTableTrailer();
    return writer.takeBytes();
  }

  void write(BinaryWriter writer) {
    writer.writeOptionalStringUtf8(name);
    writer.writeBool(isOriginNotExistingFile);
    writer.writeBool(isSynthetic);
    writer.writeUint8List(featureSet);
    languageVersion.write(writer);
    libraryMetadata.write(writer);
    writer.writeUriList(exportedLibraryUris);
    reExportMap.write(writer);
    reExportDeprecatedOnly.write(writer);
    declaredConflicts.write(writer);
    declaredClasses.write(writer);
    declaredEnums.write(writer);
    declaredExtensions.write(writer);
    declaredExtensionTypes.write(writer);
    declaredMixins.write(writer);
    declaredTypeAliases.write(writer);
    declaredGetters.write(writer);
    declaredSetters.write(writer);
    declaredFunctions.write(writer);
    declaredVariables.write(writer);
    exportMap.write(writer);
    exportMapId.write(writer);
    exportedExtensions.write(writer);
    hashForRequirements.write(writer);
  }

  void _fillExportMap() {
    exportMap.addAll(reExportMap);
    exportMap.addAll(declaredConflicts);

    void addDeclared<T extends ManifestItem>(Map<LookupName, T> items) {
      for (var entry in items.entries) {
        exportMap[entry.key] = entry.value.id;
      }
    }

    addDeclared(declaredClasses);
    addDeclared(declaredEnums);
    addDeclared(declaredExtensions);
    addDeclared(declaredExtensionTypes);
    addDeclared(declaredMixins);
    addDeclared(declaredTypeAliases);
    addDeclared(declaredGetters);
    addDeclared(declaredSetters);
    addDeclared(declaredFunctions);
  }
}

class LibraryManifestBuilder {
  final LinkedElementFactory elementFactory;
  final List<LibraryFileKind> inputLibraries;
  late final List<LibraryElementImpl> libraryElements;

  /// The previous manifests for libraries.
  ///
  /// For correctness it does not matter what is in these manifests, they
  /// can be absent at all for any library (and they are for new libraries).
  /// But it does matter for performance, because we will give a new ID for any
  /// element that is not in the manifest, or have different "meaning". This
  /// will cause cascading changes to items that referenced these elements,
  /// new IDs for them, etc.
  final Map<Uri, LibraryManifest> inputManifests;

  /// The top-level elements that are declared in this library, but conflict
  /// with other top-level elements in the same library. For example, a class
  /// and a top-level function with the same name.
  final Set<Element> conflictingTopLevelElements = {};

  /// Key: an element from [inputLibraries].
  /// Value: the item from [inputManifests], or newly build.
  ///
  /// We attempt to reuse the same item, most importantly its ID.
  ///
  /// It is filled initially during matching element structures.
  /// Then we remove those that affected by changed elements.
  ///
  /// Then we iterate over the elements in [libraryElements], and build new
  /// items for declared elements that don't have items in this map.
  final Map<Element, ManifestItem> declaredItems = Map.identity();

  LibraryManifestBuilder({
    required this.elementFactory,
    required this.inputLibraries,
    required this.inputManifests,
  }) {
    libraryElements = inputLibraries
        .map((kind) {
          return elementFactory.libraryOfUri2(kind.file.uri);
        })
        .toList(growable: false);
  }

  Map<Uri, LibraryManifestHandle> computeManifests({
    required OperationPerformanceImpl performance,
  }) {
    performance.getDataInt('libraryCount').add(inputLibraries.length);

    performance.run('matchInputManifests', (performance) {
      _fillItemMapFromInputManifests(performance: performance);
    });

    performance.run('buildItems', (performance) {
      _buildManifests();
    });

    _addExportedExtensions();
    _addReExports();
    _fillExportMaps();

    performance.run('computeHashForRequirements', (_) {
      _computeHashForRequirements();
    });

    assert(_assertSerialization());

    return {
      for (var libraryElement in libraryElements)
        libraryElement.uri: libraryElement.manifest!,
    };
  }

  void _addClass({
    required EncodeContext encodingContext,
    required Map<LookupName, ClassItem> newItems,
    required ClassElementImpl element,
    required LookupName lookupName,
  }) {
    var classItem = _getOrBuildElementItem(element, () {
      return ClassItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    classItem.hasNonFinalField = element.hasNonFinalField;
    newItems[lookupName] = classItem;

    encodingContext.withTypeParameters(element.typeParameters, (
      typeParameters,
    ) {
      classItem.beforeUpdatingMembers();
      _addInterfaceElementMembers(
        encodingContext: encodingContext,
        instanceElement: element,
        interfaceItem: classItem,
      );
    });
  }

  /// Class type aliases like `class B = A with M;` cannot explicitly declare
  /// any members. They have constructors, but these are based on the
  /// constructors of the supertype, and change if the supertype constructors
  /// change. So, it is enough to record that supertype constructors into
  /// the manifest.
  void _addClassTypeAliasConstructors() {
    var librarySet = libraryElements.toSet();
    var hasConstructors = <ClassElementImpl>{};
    var inheritedMap = <ConstructorElementImpl, ManifestItemId>{};

    void addForElement(ClassElementImpl element) {
      if (!element.isMixinApplication) {
        return;
      }

      // Skip external libraries, already done.
      if (!librarySet.contains(element.library)) {
        return;
      }

      // We might have already processed this element due to recursion.
      if (!hasConstructors.add(element)) {
        return;
      }

      // Skip conflicts.
      if (conflictingTopLevelElements.contains(element)) {
        return;
      }

      // SAFETY: all items are already created.
      var item = declaredItems[element] as ClassItem;

      // SAFETY: we set `Object` during linking if it is not a class.
      var superElement = element.supertype!.element;
      superElement as ClassElementImpl;

      // The supertype could be a mixin application itself.
      addForElement(superElement);

      for (var constructor in element.constructors) {
        var lookupName = constructor.lookupName?.asLookupName;
        if (lookupName == null) {
          continue;
        }

        // SAFETY: we build inherited constructors from existing super.
        var superConstructor = constructor.superConstructor!.baseElement;

        // Maybe the super constructor is "inherited" itself.
        var id = inheritedMap[superConstructor];

        // If not inherited, then must be declared.
        id ??= _getInterfaceElementMemberId(superConstructor);

        inheritedMap[constructor] = id;
        item.addInheritedConstructor(lookupName, id);
      }
    }

    for (var libraryElement in libraryElements) {
      for (var element in libraryElement.children) {
        if (element is ClassElementImpl) {
          addForElement(element);
        }
      }
    }
  }

  void _addEnum({
    required EncodeContext encodingContext,
    required Map<LookupName, EnumItem> newItems,
    required EnumElementImpl element,
    required LookupName lookupName,
  }) {
    var enumItem = _getOrBuildElementItem(element, () {
      return EnumItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    enumItem.hasNonFinalField = element.hasNonFinalField;
    newItems[lookupName] = enumItem;

    encodingContext.withTypeParameters(element.typeParameters, (
      typeParameters,
    ) {
      enumItem.beforeUpdatingMembers();
      _addInterfaceElementMembers(
        encodingContext: encodingContext,
        instanceElement: element,
        interfaceItem: enumItem,
      );
    });
  }

  void _addExportedExtensions() {
    for (var libraryElement in libraryElements) {
      var manifest = libraryElement.manifest!.instance;

      var extensionIds = <ManifestItemId>{};

      var exportedExtensionElements = libraryElement
          .exportNamespace
          .definedNames2
          .values
          .whereType<ExtensionElementImpl>();
      for (var extensionElement in exportedExtensionElements) {
        var extensionName = extensionElement.lookupName?.asLookupName;
        var extensionLibraryManifest =
            extensionElement.library.manifest!.instance;
        var extensionItem =
            extensionLibraryManifest.declaredExtensions[extensionName];
        if (extensionItem != null) {
          extensionIds.add(extensionItem.id);
        }
      }

      manifest.exportedExtensions = ManifestItemIdList(
        extensionIds.toList(growable: false)..sort(),
      );
    }
  }

  void _addExtension({
    required EncodeContext encodingContext,
    required Map<LookupName, ExtensionItem> newItems,
    required ExtensionElementImpl element,
    required LookupName lookupName,
  }) {
    var extensionItem = _getOrBuildElementItem(element, () {
      return ExtensionItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    newItems[lookupName] = extensionItem;

    encodingContext.withTypeParameters(element.typeParameters, (
      typeParameters,
    ) {
      extensionItem.beforeUpdatingMembers();
      _addInstanceElementMembers(
        encodingContext: encodingContext,
        instanceElement: element,
        instanceItem: extensionItem,
      );
    });
  }

  void _addExtensionType({
    required EncodeContext encodingContext,
    required Map<LookupName, ExtensionTypeItem> newItems,
    required ExtensionTypeElementImpl element,
    required LookupName lookupName,
  }) {
    var extensionTypeItem = _getOrBuildElementItem(element, () {
      return ExtensionTypeItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    extensionTypeItem.hasNonFinalField = element.hasNonFinalField;
    newItems[lookupName] = extensionTypeItem;

    encodingContext.withTypeParameters(element.typeParameters, (
      typeParameters,
    ) {
      extensionTypeItem.beforeUpdatingMembers();
      _addInterfaceElementMembers(
        encodingContext: encodingContext,
        instanceElement: element,
        interfaceItem: extensionTypeItem,
      );
    });
  }

  void _addInstanceElementField({
    required EncodeContext encodingContext,
    required InstanceItem instanceItem,
    required FieldElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return;
    }

    var item = _getOrBuildElementItem(element, () {
      return FieldItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });

    instanceItem.declaredFields[lookupName] = item;
  }

  void _addInstanceElementGetter({
    required EncodeContext encodingContext,
    required InstanceItem instanceItem,
    required GetterElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return;
    }

    var item = _getOrBuildElementItem(element, () {
      return GetterItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });

    instanceItem.addDeclaredGetter(lookupName, item);
  }

  void _addInstanceElementMembers({
    required EncodeContext encodingContext,
    required InstanceElementImpl instanceElement,
    required InstanceItem instanceItem,
  }) {
    for (var field in instanceElement.fields) {
      _addInstanceElementField(
        encodingContext: encodingContext,
        instanceItem: instanceItem,
        element: field,
      );
    }

    for (var method in instanceElement.methods) {
      _addInstanceElementMethod(
        encodingContext: encodingContext,
        instanceItem: instanceItem,
        element: method,
      );
    }

    for (var getter in instanceElement.getters) {
      _addInstanceElementGetter(
        encodingContext: encodingContext,
        instanceItem: instanceItem,
        element: getter,
      );
    }

    for (var setter in instanceElement.setters) {
      _addInstanceElementSetter(
        encodingContext: encodingContext,
        instanceItem: instanceItem,
        element: setter,
      );
    }
  }

  void _addInstanceElementMethod({
    required EncodeContext encodingContext,
    required InstanceItem instanceItem,
    required MethodElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return;
    }

    var item = _getOrBuildElementItem(element, () {
      return MethodItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });

    instanceItem.addDeclaredMethod(lookupName, item);
  }

  void _addInstanceElementSetter({
    required EncodeContext encodingContext,
    required InstanceItem instanceItem,
    required SetterElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return;
    }

    var item = _getOrBuildElementItem(element, () {
      return SetterItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });

    instanceItem.addDeclaredSetter(lookupName, item);
  }

  void _addInterfaceElementConstructor({
    required EncodeContext encodingContext,
    required InterfaceItem interfaceItem,
    required ConstructorElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return;
    }

    var item = _getOrBuildElementItem(element, () {
      return ConstructorItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });

    interfaceItem.addDeclaredConstructor(lookupName, item);
  }

  void _addInterfaceElementMembers({
    required EncodeContext encodingContext,
    required InterfaceElementImpl instanceElement,
    required InterfaceItem interfaceItem,
  }) {
    // Class type aliases don't have declared members.
    // We don't consider constructors as declared.
    if (instanceElement is ClassElementImpl &&
        instanceElement.isMixinApplication) {
      return;
    }

    for (var constructor in instanceElement.constructors) {
      _addInterfaceElementConstructor(
        encodingContext: encodingContext,
        interfaceItem: interfaceItem,
        element: constructor,
      );
    }

    _addInstanceElementMembers(
      encodingContext: encodingContext,
      instanceElement: instanceElement,
      instanceItem: interfaceItem,
    );
  }

  void _addMixin({
    required EncodeContext encodingContext,
    required Map<LookupName, MixinItem> newItems,
    required MixinElementImpl element,
    required LookupName lookupName,
  }) {
    var mixinItem = _getOrBuildElementItem(element, () {
      return MixinItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    mixinItem.hasNonFinalField = element.hasNonFinalField;
    newItems[lookupName] = mixinItem;

    encodingContext.withTypeParameters(element.typeParameters, (
      typeParameters,
    ) {
      mixinItem.beforeUpdatingMembers();
      _addInterfaceElementMembers(
        encodingContext: encodingContext,
        instanceElement: element,
        interfaceItem: mixinItem,
      );
    });
  }

  void _addReExports() {
    for (var libraryElement in libraryElements) {
      var manifest = libraryElement.manifest!.instance;

      for (var exported in libraryElement.exportedReferences) {
        // We want only re-exports, skip declared.
        if (exported is! ExportedReferenceExported) {
          continue;
        }

        var reference = exported.reference;
        var element = elementFactory.elementOfReference3(reference);

        var lookupName = element.lookupName?.asLookupName;
        if (lookupName == null) {
          continue;
        }

        // Skip elements that exist in nowhere.
        var elementLibrary = element.library;
        if (elementLibrary == null) {
          continue;
        }

        // Every library has a manifest at this point.
        // We already set manifests for the current cycle.
        var elementLibraryManifest = elementLibrary.manifest!.instance;

        // We use the manifest of the library that declares this element.
        // So, the element must be declared in the manifest.
        var id = elementLibraryManifest.getDeclaredId(lookupName)!;
        manifest.reExportMap[lookupName] = id;

        if (libraryElement.isFromDeprecatedExport(exported)) {
          manifest.reExportDeprecatedOnly.add(lookupName);
        }
      }
    }
  }

  void _addTopLevelFunction({
    required EncodeContext encodingContext,
    required Map<LookupName, TopLevelFunctionItem> newItems,
    required TopLevelFunctionElementImpl element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return TopLevelFunctionItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    newItems[lookupName] = item;
  }

  void _addTopLevelGetter({
    required EncodeContext encodingContext,
    required Map<LookupName, GetterItem> newItems,
    required GetterElementImpl element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return GetterItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    newItems[lookupName] = item;
  }

  void _addTopLevelSetter({
    required EncodeContext encodingContext,
    required Map<LookupName, SetterItem> newItems,
    required SetterElementImpl element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return SetterItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    newItems[lookupName] = item;
  }

  void _addTopLevelVariable({
    required EncodeContext encodingContext,
    required Map<LookupName, TopLevelVariableItem> newItems,
    required TopLevelVariableElementImpl element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return TopLevelVariableItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    newItems[lookupName] = item;
  }

  void _addTypeAlias({
    required EncodeContext encodingContext,
    required Map<LookupName, TypeAliasItem> newItems,
    required TypeAliasElementImpl element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return TypeAliasItem.fromElement(
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    newItems[lookupName] = item;
  }

  /// Assert that every manifest can be serialized, and when deserialized
  /// results in the same manifest.
  bool _assertSerialization() {
    for (var libraryElement in libraryElements) {
      var uri = libraryElement.uri;
      var manifest = libraryElement.manifest!.instance;

      var bytes = manifest.toBytes();
      var readManifest = LibraryManifest.fromBytes(bytes);
      var readBytes = readManifest.toBytes();

      if (!const ListEquality<int>().equals(bytes, readBytes)) {
        throw StateError('Library manifest bytes are different: $uri');
      }
    }

    return true;
  }

  /// Fill `result` with new library manifests.
  /// We reuse existing items when they fully match.
  /// We build new items for mismatched elements.
  void _buildManifests() {
    var encodingContext = EncodeContext(elementFactory: elementFactory);

    for (var libraryElement in libraryElements) {
      var declaredNames = <LookupName>{};
      var newConflicts = <LookupName, ManifestItemId>{};

      var newTopLevelVariables = <LookupName, TopLevelVariableItem>{};
      var newTopLevelGetters = <LookupName, GetterItem>{};
      var newTopLevelSetters = <LookupName, SetterItem>{};

      var newClasses = <LookupName, ClassItem>{};
      var newEnums = <LookupName, EnumItem>{};
      var newExtensions = <LookupName, ExtensionItem>{};
      var newExtensionTypes = <LookupName, ExtensionTypeItem>{};
      var newMixins = <LookupName, MixinItem>{};
      var newTypeAliases = <LookupName, TypeAliasItem>{};
      var newTopLevelFunctions = <LookupName, TopLevelFunctionItem>{};

      var libraryMetadataItem = _getOrBuildElementItem(libraryElement, () {
        return LibraryMetadataItem.encode(
          id: ManifestItemId.generate(),
          context: encodingContext,
          metadata: libraryElement.metadata,
        );
      });

      void makeNameConflict(LookupName lookupName) {
        var id = ManifestItemId.generate();
        for (var relatedName in lookupName.relatedNames) {
          newConflicts[relatedName] = id;
          for (var lookupNameToItemMap in [
            newClasses,
            newEnums,
            newExtensions,
            newExtensionTypes,
            newMixins,
            newTypeAliases,
            newTopLevelGetters,
            newTopLevelSetters,
            newTopLevelFunctions,
            newTopLevelVariables,
          ]) {
            lookupNameToItemMap.remove(relatedName);
          }
        }
      }

      // First add top-level variables, and ignore conflicts.
      // If there are conflicts, we will remove them in following loops.
      for (var element in libraryElement.topLevelVariables) {
        var lookupName = element.lookupName?.asLookupName;
        if (lookupName != null) {
          _addTopLevelVariable(
            encodingContext: encodingContext,
            newItems: newTopLevelVariables,
            element: element,
            lookupName: lookupName,
          );
        }
      }

      for (var element in libraryElement.getters) {
        var lookupName = element.lookupName?.asLookupName;
        if (lookupName == null) {
          continue;
        }
        if (newConflicts.containsKey(lookupName)) {
          conflictingTopLevelElements.add(element);
          continue;
        }
        if (declaredNames.contains(lookupName)) {
          conflictingTopLevelElements.add(element);
          makeNameConflict(lookupName);
        } else {
          declaredNames.add(lookupName);
          _addTopLevelGetter(
            encodingContext: encodingContext,
            newItems: newTopLevelGetters,
            element: element,
            lookupName: lookupName,
          );
        }
      }

      for (var element in libraryElement.setters) {
        var lookupName = element.lookupName?.asLookupName;
        if (lookupName == null) {
          continue;
        }
        if (newConflicts.containsKey(lookupName)) {
          conflictingTopLevelElements.add(element);
          continue;
        }
        if (declaredNames.contains(lookupName)) {
          conflictingTopLevelElements.add(element);
          makeNameConflict(lookupName);
        } else {
          declaredNames.add(lookupName);
          _addTopLevelSetter(
            encodingContext: encodingContext,
            newItems: newTopLevelSetters,
            element: element,
            lookupName: lookupName,
          );
        }
      }

      void addNonProperty({
        required ElementImpl element,
        required void Function(LookupName lookupName) addItem,
      }) {
        var lookupName = element.lookupName?.asLookupName;
        if (lookupName == null) {
          return;
        }
        if (newConflicts.containsKey(lookupName)) {
          conflictingTopLevelElements.add(element);
          return;
        }
        if (declaredNames.contains(lookupName) ||
            declaredNames.contains(lookupName.methodToSetter)) {
          conflictingTopLevelElements.add(element);
          makeNameConflict(lookupName);
        } else {
          declaredNames.add(lookupName);
          addItem(lookupName);
        }
      }

      for (var element in libraryElement.classes) {
        addNonProperty(
          element: element,
          addItem: (lookupName) {
            _addClass(
              encodingContext: encodingContext,
              newItems: newClasses,
              element: element,
              lookupName: lookupName,
            );
          },
        );
      }

      for (var element in libraryElement.enums) {
        addNonProperty(
          element: element,
          addItem: (lookupName) {
            _addEnum(
              encodingContext: encodingContext,
              newItems: newEnums,
              element: element,
              lookupName: lookupName,
            );
          },
        );
      }

      for (var element in libraryElement.extensions) {
        addNonProperty(
          element: element,
          addItem: (lookupName) {
            _addExtension(
              encodingContext: encodingContext,
              newItems: newExtensions,
              element: element,
              lookupName: lookupName,
            );
          },
        );
      }

      for (var element in libraryElement.extensionTypes) {
        addNonProperty(
          element: element,
          addItem: (lookupName) {
            _addExtensionType(
              encodingContext: encodingContext,
              newItems: newExtensionTypes,
              element: element,
              lookupName: lookupName,
            );
          },
        );
      }

      for (var element in libraryElement.mixins) {
        addNonProperty(
          element: element,
          addItem: (lookupName) {
            _addMixin(
              encodingContext: encodingContext,
              newItems: newMixins,
              element: element,
              lookupName: lookupName,
            );
          },
        );
      }

      for (var element in libraryElement.topLevelFunctions) {
        addNonProperty(
          element: element,
          addItem: (lookupName) {
            _addTopLevelFunction(
              encodingContext: encodingContext,
              newItems: newTopLevelFunctions,
              element: element,
              lookupName: lookupName,
            );
          },
        );
      }

      for (var element in libraryElement.typeAliases) {
        addNonProperty(
          element: element,
          addItem: (lookupName) {
            _addTypeAlias(
              encodingContext: encodingContext,
              newItems: newTypeAliases,
              element: element,
              lookupName: lookupName,
            );
          },
        );
      }

      var newManifest = LibraryManifest(
        name: libraryElement.name.nullIfEmpty,
        isOriginNotExistingFile: libraryElement.isOriginNotExistingFile,
        isSynthetic: false,
        featureSet: (libraryElement.featureSet as ExperimentStatus).toStorage(),
        languageVersion: ManifestLibraryLanguageVersion.encode(
          libraryElement.languageVersion,
        ),
        libraryMetadata: libraryMetadataItem,
        exportedLibraryUris: libraryElement.exportedLibraries
            .map((e) => e.uri)
            .toList(),
        reExportMap: {},
        reExportDeprecatedOnly: <LookupName>{},
        declaredConflicts: newConflicts,
        declaredClasses: newClasses,
        declaredEnums: newEnums,
        declaredExtensions: newExtensions,
        declaredExtensionTypes: newExtensionTypes,
        declaredMixins: newMixins,
        declaredTypeAliases: newTypeAliases,
        declaredGetters: newTopLevelGetters,
        declaredSetters: newTopLevelSetters,
        declaredFunctions: newTopLevelFunctions,
        declaredVariables: newTopLevelVariables,
        exportMap: {},
        exportMapId: ManifestItemId.generate(),
        exportedExtensions: ManifestItemIdList([]),
        hashForRequirements: Hash.empty,
      );
      libraryElement.manifest = LibraryManifestHandle.fromInstance(newManifest);
    }

    _fillInterfaceElementsInterface();
    _addClassTypeAliasConstructors();
    _fillClassAllSubtypes();
    _fillClassDirectSubtypesOfSealed();
  }

  void _computeHashForRequirements() {
    for (var libraryElement in libraryElements) {
      var manifest = libraryElement.manifest!.instance;
      var builder = ApiSignature();

      List<MapEntry<LookupName, T>> sortedMapEntries<T>(
        Map<LookupName, T> map,
      ) {
        return map.entries.toList()
          ..sort((a, b) => LookupName.compare(a.key, b.key));
      }

      void addLookupName(LookupName name) {
        builder.addString(name.asString);
      }

      void addId(ManifestItemId id) {
        builder.addInt(id.hi32);
        builder.addInt(id.lo32);
      }

      void addIdList(ManifestItemIdList idList) {
        builder.addList(idList.ids, addId);
      }

      void addOptionalIdList(ManifestItemIdList? idList) {
        if (idList != null) {
          builder.addBool(true);
          addIdList(idList);
        } else {
          builder.addBool(false);
        }
      }

      void addVersion(Version? version) {
        if (version != null) {
          builder.addBool(true);
          builder.addInt(version.major);
          builder.addInt(version.minor);
        } else {
          builder.addBool(false);
        }
      }

      void addMapOfItems<T extends ManifestItem>(Map<LookupName, T> map) {
        var entries = sortedMapEntries(map);
        builder.addMapEntryList(entries, (lookupName, item) {
          addLookupName(lookupName);
          addId(item.id);
        });
      }

      void addMapOfIds(Map<LookupName, ManifestItemId> map) {
        var entries = sortedMapEntries(map);
        builder.addMapEntryList(entries, (lookupName, id) {
          addLookupName(lookupName);
          addId(id);
        });
      }

      void addInstanceChildren(InstanceItem instanceItem) {
        addMapOfIds(instanceItem.declaredConflicts);
        addMapOfItems(instanceItem.declaredFields);
        addMapOfItems(instanceItem.declaredGetters);
        addMapOfItems(instanceItem.declaredSetters);
        addMapOfItems(instanceItem.declaredMethods);
        addMapOfItems(instanceItem.declaredConstructors);
        addMapOfIds(instanceItem.inheritedConstructors);
      }

      builder.addString(manifest.name ?? '');
      builder.addBool(manifest.isOriginNotExistingFile);
      builder.addBool(manifest.isSynthetic);
      builder.addBytes(manifest.featureSet);
      addVersion(manifest.languageVersion.packageVersion);
      addVersion(manifest.languageVersion.overrideVersion);
      addId(manifest.libraryMetadata.id);

      builder.addStringList(
        manifest.exportedLibraryUris.map((uri) => '$uri').sorted(),
      );

      builder.addList(
        manifest.reExportDeprecatedOnly.sorted(LookupName.compare),
        addLookupName,
      );

      addMapOfIds(manifest.declaredConflicts);

      void addDeclared(Map<LookupName, ManifestItem> map) {
        var entries = sortedMapEntries(map);
        builder.addMapEntryList(entries, (lookupName, item) {
          addLookupName(lookupName);
          addId(item.id);
          if (item is InstanceItem) {
            addInstanceChildren(item);
            if (item is InterfaceItem) {
              builder.addBool(item.hasNonFinalField);
              addId(item.interface.id);
              if (item is ClassItem) {
                addOptionalIdList(item.allSubtypes);
                addOptionalIdList(item.directSubtypesOfSealed);
              }
            }
          }
        });
      }

      addDeclared(manifest.declaredClasses);
      addDeclared(manifest.declaredEnums);
      addDeclared(manifest.declaredExtensions);
      addDeclared(manifest.declaredExtensionTypes);
      addDeclared(manifest.declaredMixins);
      addDeclared(manifest.declaredTypeAliases);
      addDeclared(manifest.declaredGetters);
      addDeclared(manifest.declaredSetters);
      addDeclared(manifest.declaredFunctions);
      addDeclared(manifest.declaredVariables);

      addId(manifest.exportMapId);
      addMapOfIds(manifest.exportMap);
      addIdList(manifest.exportedExtensions);

      manifest.hashForRequirements = builder.toHash();
    }
  }

  void _fillClassAllSubtypes() {
    for (var libraryElement in libraryElements) {
      for (var classElement in libraryElement.classes) {
        var classItem = declaredItems[classElement];
        if (classItem != null) {
          classItem as ClassItem;
          if (classElement.allSubtypes case var allSubtypes?) {
            var ids = allSubtypes
                .map((type) => declaredItems[type.element])
                .whereType<InterfaceItem>()
                .map((item) => item.id)
                .sorted();
            classItem.allSubtypes = ManifestItemIdList(ids);
          }
        }
      }
    }
  }

  void _fillClassDirectSubtypesOfSealed() {
    for (var libraryElement in libraryElements) {
      for (var classElement in libraryElement.classes) {
        if (classElement.isSealed) {
          var classItem = declaredItems[classElement];
          if (classItem != null) {
            classItem as ClassItem;
            var ids = classElement.directSubtypesOfSealed
                .map((element) => declaredItems[element])
                .whereType<InterfaceItem>()
                .map((item) => item.id)
                .sorted();
            classItem.directSubtypesOfSealed = ManifestItemIdList(ids);
          }
        }
      }
    }
  }

  void _fillExportMaps() {
    const mapEq = MapEquality<LookupName, ManifestItemId>();

    for (var libraryElement in libraryElements) {
      var libraryUri = libraryElement.uri;
      var manifest = libraryElement.manifest!.instance;
      manifest._fillExportMap();

      var inputManifest = _getInputManifest(libraryUri);
      if (mapEq.equals(manifest.exportMap, inputManifest.exportMap)) {
        manifest.exportMapId = inputManifest.exportMapId;
      }
    }
  }

  void _fillInterfaceElementInterface(InterfaceElementImpl element) {
    // We don't create items for elements without name.
    if (element.lookupName == null) {
      return;
    }

    if (conflictingTopLevelElements.contains(element)) {
      return;
    }

    // Must be created already.
    var item = declaredItems[element] as InterfaceItem;
    item.interface.beforeUpdating();

    var inheritance = element.inheritanceManager;
    var interface = inheritance.getInterface(element);

    for (var entry in interface.map.entries) {
      var executable = entry.value.baseElement;

      var lookupName = executable.lookupName?.asLookupName;
      if (lookupName == null) {
        continue;
      }

      // We can see a private member only inside the library.
      // But we reanalyze the library when one of its files changes.
      if (lookupName.isPrivate) {
        continue;
      }

      var combinedCandidates = interface.combinedSignatures[entry.key];
      if (combinedCandidates != null) {
        var candidateElements = combinedCandidates
            .map((candidate) => candidate.baseElement)
            .toSet()
            .toList();
        if (candidateElements.length == 1) {
          executable = candidateElements[0];
        } else {
          var candidateIds = candidateElements.map((candidate) {
            return _getInterfaceElementMemberId(candidate);
          }).toList();
          var idList = ManifestItemIdList(candidateIds);
          var id = item.interface.combinedIdsTemp[idList];
          id ??= ManifestItemId.generate();
          item.interface.map[lookupName] = id;
          item.interface.combinedIds[idList] = id;
          continue;
        }
      }

      var id = _getInterfaceElementMemberId(executable);
      item.interface.map[lookupName] = id;
    }

    for (var entry in interface.implemented.entries) {
      var executable = entry.value.baseElement;
      var lookupName = executable.lookupName?.asLookupName;
      if (lookupName != null && !lookupName.isPrivate) {
        var id = _getInterfaceElementMemberId(executable);
        item.interface.implemented[lookupName] = id;
      }
    }

    for (var superImplemented in interface.superImplemented) {
      var layer = <LookupName, ManifestItemId>{};
      for (var entry in superImplemented.entries) {
        var executable = entry.value.baseElement;
        var lookupName = executable.lookupName?.asLookupName;
        if (lookupName != null && !lookupName.isPrivate) {
          layer[lookupName] = _getInterfaceElementMemberId(executable);
        }
      }
      item.interface.superImplemented.add(layer);
    }

    for (var entry in inheritance.getInheritedMap(element).entries) {
      var executable = entry.value.baseElement;
      var lookupName = executable.lookupName?.asLookupName;
      if (lookupName != null && !lookupName.isPrivate) {
        var id = _getInterfaceElementMemberId(executable);
        item.interface.inherited[lookupName] = id;
      }
    }

    item.interface.afterUpdate();
  }

  void _fillInterfaceElementsInterface() {
    var librarySet = libraryElements.toSet();
    var interfaceSet = <InterfaceElementImpl>{};
    var interfaceList = <InterfaceElementImpl>[];

    void addInterfacesToFill(InterfaceElementImpl element) {
      // If not in this bundle, it has interface ready.
      if (!librarySet.contains(element.library)) {
        return;
      }

      if (!interfaceSet.add(element)) {
        return;
      }

      // Ensure that we have interfaces of supertypes first.
      for (var superType in element.allSupertypes) {
        addInterfacesToFill(superType.element);
      }

      interfaceList.add(element);
    }

    for (var libraryElement in libraryElements) {
      for (var element in libraryElement.children) {
        if (element is InterfaceElementImpl) {
          addInterfacesToFill(element);
        }
      }
    }

    // Fill interfaces of supertypes before interfaces of subtypes.
    // So that if there are synthetic top-merged members in interfaces of
    // supertypes (these members are not included into declared), we can
    // get corresponding IDs.
    for (var element in interfaceList) {
      _fillInterfaceElementInterface(element);
    }
  }

  void _fillItemMapFromInputManifests({
    required OperationPerformanceImpl performance,
  }) {
    // Compare structures of the elements against the existing manifests.
    // At the end `affectedElements` is filled with mismatched by structure.
    // And for matched by structure we have reference maps.
    var refElementsMap = Map<Element, List<Element>>.identity();
    var refExternalIds = Map<Element, ManifestItemId>.identity();
    var affectedElements = Set<Element>.identity();
    for (var libraryElement in libraryElements) {
      var libraryUri = libraryElement.uri;
      var manifest = _getInputManifest(libraryUri);
      _LibraryMatch(
        manifest: manifest,
        library: libraryElement,
        itemMap: declaredItems,
        structureMismatched: affectedElements,
        refElementsMap: refElementsMap,
        refExternalIds: refExternalIds,
      ).compareStructures();
    }

    performance
      ..getDataInt('structureMatchedCount').add(declaredItems.length)
      ..getDataInt('structureMismatchedCount').add(affectedElements.length);

    // Propagate invalidation from referenced elements.
    // Both from external elements, and from input library elements.
    for (var element in refElementsMap.keys.toList()) {
      var refElements = refElementsMap[element];
      if (refElements != null) {
        for (var referencedElement in refElements) {
          // If the referenced element is from this bundle, and is determined
          // to be affected, this makes the current element affected.
          if (affectedElements.contains(referencedElement)) {
            // Move the element to affected.
            // Its dependencies are not interesting anymore.
            affectedElements.add(element);
            declaredItems.remove(element);
            refElementsMap.remove(element);
            break;
          }
          // Maybe has a different external id.
          var requiredExternalId = refExternalIds[referencedElement];
          if (requiredExternalId != null) {
            var currentId = elementFactory.getElementId(referencedElement);
            if (currentId != requiredExternalId) {
              // Move the element to affected.
              // Its dependencies are not interesting anymore.
              affectedElements.add(element);
              declaredItems.remove(element);
              refElementsMap.remove(element);
              break;
            }
          }
        }
      }
    }

    performance
      ..getDataInt('transitiveMatchedCount').add(declaredItems.length)
      ..getDataInt('transitiveAffectedCount').add(affectedElements.length);
  }

  /// Returns the manifest from [inputManifests], empty if absent.
  LibraryManifest _getInputManifest(Uri uri) {
    return inputManifests[uri] ??
        LibraryManifest(
          name: null,
          isOriginNotExistingFile: false,
          isSynthetic: false,
          featureSet: Uint8List(0),
          languageVersion: ManifestLibraryLanguageVersion.empty(),
          libraryMetadata: LibraryMetadataItem.empty(),
          exportedLibraryUris: [],
          reExportMap: {},
          reExportDeprecatedOnly: <LookupName>{},
          declaredConflicts: {},
          declaredClasses: {},
          declaredEnums: {},
          declaredExtensions: {},
          declaredExtensionTypes: {},
          declaredMixins: {},
          declaredTypeAliases: {},
          declaredGetters: {},
          declaredSetters: {},
          declaredFunctions: {},
          declaredVariables: {},
          exportMap: {},
          exportMapId: ManifestItemId.generate(),
          exportedExtensions: ManifestItemIdList([]),
          hashForRequirements: Hash.empty,
        );
  }

  ManifestItemId _getInterfaceElementMemberId(ExecutableElementImpl element) {
    var enclosingElement = element.enclosingElement;
    enclosingElement as InterfaceElementImpl;

    var enclosingItem = declaredItems[enclosingElement];
    if (enclosingItem != null) {
      // SAFETY: if item is in this library, it is for interface.
      enclosingItem as InterfaceItem;

      // SAFETY: any element in interface has a name.
      var lookupName = element.lookupName!.asLookupName;

      // Check for a conflict.
      if (enclosingItem.declaredConflicts[lookupName] case var id?) {
        return id;
      }

      // SAFETY: null asserts are safe, because element is in this library.
      switch (element) {
        case GetterElementImpl():
          var declaredGetter = enclosingItem.declaredGetters[lookupName];
          if (declaredGetter != null) {
            return declaredGetter.id;
          }
          return enclosingItem.interface.map[lookupName]!;
        case SetterElementImpl():
          var declaredSetter = enclosingItem.declaredSetters[lookupName];
          if (declaredSetter != null) {
            return declaredSetter.id;
          }
          return enclosingItem.interface.map[lookupName]!;
        case MethodElementImpl():
          var declaredMethod = enclosingItem.declaredMethods[lookupName];
          if (declaredMethod != null) {
            return declaredMethod.id;
          }
          return enclosingItem.interface.map[lookupName]!;
        case ConstructorElementImpl():
          if (enclosingItem.declaredConstructors[lookupName] case var item?) {
            return item.id;
          }
          return enclosingItem.inheritedConstructors[lookupName]!;
      }
    }

    return elementFactory.getElementId(element)!;
  }

  /// Returns either the existing item from [declaredItems], or builds a new one.
  Item _getOrBuildElementItem<E extends ElementImpl, Item extends ManifestItem>(
    E element,
    Item Function() build,
  ) {
    // We assume that when matching elements against the structure of
    // the item, we put into [itemMap] only the type of the item that
    // corresponds the type of the element.
    var item = declaredItems[element] as Item?;
    if (item == null) {
      item = build();
      // To find IDs of inherited members.
      declaredItems[element] = item;
    }
    return item;
  }
}

/// Handle for [LibraryManifest.hashForRequirements] or [instance].
///
/// Most [RequirementsManifest] can be checked using just [hashForRequirements],
/// so we don't even need to read the whole [instance] from bytes. But we can,
/// if we have to check for details of the manifest.
///
/// This class has several states:
/// 1. Has incomplete [_instance], during building.
/// 2. Has complete [_instance], no bytes, after building.
/// 3. Has [_instance], has bytes, after building and write.
/// 4. No [_instance], has bytes, after [discardInstance] or `read`.
/// 5. Has [instance], has bytes, after [instance] read it.
class LibraryManifestHandle {
  Hash? _hashForRequirements;
  Uint8List? _bytes;
  LibraryManifest? _instance;

  LibraryManifestHandle({
    required Hash? hashForRequirements,
    required Uint8List? bytes,
    required LibraryManifest? instance,
  }) : _hashForRequirements = hashForRequirements,
       _bytes = bytes,
       _instance = instance;

  factory LibraryManifestHandle.fromInstance(LibraryManifest instance) {
    // Note, we don't convert instance to bytes here.
    // The instance is not finished yet in the builder.
    return LibraryManifestHandle(
      bytes: null,
      hashForRequirements: null,
      instance: instance,
    );
  }

  factory LibraryManifestHandle.read(BinaryReader reader) {
    return LibraryManifestHandle(
      hashForRequirements: Hash.read(reader),
      bytes: reader.readUint8List(),
      instance: null,
    );
  }

  Hash get hashForRequirements {
    return _hashForRequirements ?? _instance!.hashForRequirements;
  }

  LibraryManifest get instance {
    return _instance ??= LibraryManifest.fromBytes(_bytes!);
  }

  void discardInstance() {
    if (_instance case var instance?) {
      _hashForRequirements ??= instance.hashForRequirements;
      _bytes ??= instance.toBytes();
    }
    _instance = null;
  }

  void write(BinaryWriter writer) {
    var hashForRequirements =
        _hashForRequirements ?? _instance?.hashForRequirements;
    if (hashForRequirements == null) {
      throw StateError('Missing hashForRequirements');
    }
    hashForRequirements.write(writer);

    var bytes = _bytes ?? _instance?.toBytes();
    if (bytes == null) {
      throw StateError('Missing bytes');
    }
    writer.writeUint8List(bytes);
  }
}

/// Compares structures of [library] children against [manifest].
class _LibraryMatch {
  final LibraryElementImpl library;

  /// A previous manifest for the [library].
  ///
  /// Strictly speaking, it does not have to be the latest manifest, it could
  /// be empty at all (and is empty when this is a new library). It is used
  /// to give the same identifiers to the elements with the same meaning.
  final LibraryManifest manifest;

  /// Elements that have structure matching the corresponding items from
  /// [manifest].
  final Map<Element, ManifestItem> itemMap;

  /// Elements with mismatched structure.
  /// These elements will get new identifiers.
  final Set<Element> structureMismatched;

  /// Key: an element of [library].
  /// Value: the elements that the key references.
  ///
  /// This includes references to elements of this bundle, and of external
  /// bundles. This information allows propagating invalidation from affected
  /// elements to their dependents.
  // TODO(scheglov): hm... maybe store it? And reverse it.
  final Map<Element, List<Element>> refElementsMap;

  /// Key: an element from an external bundle.
  /// Value: the identifier at the time when [manifest] was built.
  ///
  /// If [LibraryManifestBuilder] later finds that some of these elements now
  /// have different identifiers, it propagates invalidation using
  /// [refElementsMap].
  final Map<Element, ManifestItemId> refExternalIds;

  _LibraryMatch({
    required this.manifest,
    required this.library,
    required this.itemMap,
    required this.refElementsMap,
    required this.refExternalIds,
    required this.structureMismatched,
  });

  void compareStructures() {
    if (!_matchLibraryMetadata()) {
      structureMismatched.add(library);
    }

    for (var element in library.children) {
      var name = element.lookupName?.asLookupName;
      switch (element) {
        case ClassElementImpl():
          if (!_matchClass(name: name, element: element)) {
            structureMismatched.add(element);
          }
        case EnumElementImpl():
          if (!_matchEnum(name: name, element: element)) {
            structureMismatched.add(element);
          }
        case ExtensionElementImpl():
          if (name != null) {
            if (!_matchExtension(name: name, element: element)) {
              structureMismatched.add(element);
            }
          }
        case ExtensionTypeElementImpl():
          if (!_matchExtensionType(name: name, element: element)) {
            structureMismatched.add(element);
          }
        case GetterElementImpl():
          if (!_matchTopGetter(name: name, element: element)) {
            structureMismatched.add(element);
          }
        case MixinElementImpl():
          if (!_matchMixin(name: name, element: element)) {
            structureMismatched.add(element);
          }
        case SetterElementImpl():
          if (!_matchTopSetter(name: name, element: element)) {
            structureMismatched.add(element);
          }
        case TopLevelFunctionElementImpl():
          if (!_matchTopFunction(name: name, element: element)) {
            structureMismatched.add(element);
          }
        case TopLevelVariableElementImpl():
          if (!_matchTopVariable(name: name, element: element)) {
            structureMismatched.add(element);
          }
        case TypeAliasElementImpl():
          if (!_matchTypeAlias(name: name, element: element)) {
            structureMismatched.add(element);
          }
      }
    }
  }

  /// Records [item] as matching [element], and stores dependencies.
  ///
  /// The fact that it does match is checked outside.
  void _addMatchingElementItem(
    ElementImpl element,
    ManifestItem item,
    MatchContext matchContext,
  ) {
    itemMap[element] = item;
    refElementsMap[element] = matchContext.elementList;
    refExternalIds.addAll(matchContext.externalIds);
  }

  bool _matchClass({
    required LookupName? name,
    required ClassElementImpl element,
  }) {
    var item = manifest.declaredClasses[name];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);

    _matchInterfaceElementConstructors(
      interfaceElement: element,
      item: item,
      matchContext: matchContext,
    );

    _matchInstanceElementExecutables(
      element: element,
      item: item,
      matchContext: matchContext,
    );

    return true;
  }

  bool _matchEnum({
    required LookupName? name,
    required EnumElementImpl element,
  }) {
    var item = manifest.declaredEnums[name];
    if (item is! EnumItem) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);

    _matchInterfaceElementConstructors(
      matchContext: matchContext,
      interfaceElement: element,
      item: item,
    );

    _matchInstanceElementExecutables(
      matchContext: matchContext,
      element: element,
      item: item,
    );

    return true;
  }

  bool _matchExtension({
    required LookupName? name,
    required ExtensionElementImpl element,
  }) {
    var item = manifest.declaredExtensions[name];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);

    _matchInstanceElementExecutables(
      matchContext: matchContext,
      element: element,
      item: item,
    );

    return true;
  }

  bool _matchExtensionType({
    required LookupName? name,
    required ExtensionTypeElementImpl element,
  }) {
    var item = manifest.declaredExtensionTypes[name];
    if (item is! ExtensionTypeItem) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);

    _matchInterfaceElementConstructors(
      matchContext: matchContext,
      interfaceElement: element,
      item: item,
    );

    _matchInstanceElementExecutables(
      matchContext: matchContext,
      element: element,
      item: item,
    );

    return true;
  }

  void _matchInstanceElementExecutables({
    required InstanceElementImpl element,
    required InstanceItem item,
    required MatchContext matchContext,
  }) {
    for (var field in element.fields) {
      if (!_matchInstanceElementField(
        instanceElement: element,
        instanceItem: item,
        instanceMatchContext: matchContext,
        element: field,
      )) {
        structureMismatched.add(field);
      }
    }

    for (var method in element.methods) {
      if (!_matchInstanceElementMethod(
        instanceElement: element,
        instanceItem: item,
        instanceMatchContext: matchContext,
        element: method,
      )) {
        structureMismatched.add(method);
      }
    }

    for (var getter in element.getters) {
      if (!_matchInstanceElementGetter(
        instanceElement: element,
        instanceItem: item,
        instanceMatchContext: matchContext,
        element: getter,
      )) {
        structureMismatched.add(getter);
      }
    }

    for (var setter in element.setters) {
      if (!_matchInstanceElementSetter(
        instanceElement: element,
        instanceItem: item,
        instanceMatchContext: matchContext,
        element: setter,
      )) {
        structureMismatched.add(setter);
      }
    }
  }

  bool _matchInstanceElementField({
    required InstanceElementImpl instanceElement,
    required InstanceItem instanceItem,
    required MatchContext instanceMatchContext,
    required FieldElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return true;
    }

    var item = instanceItem.declaredFields[lookupName];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: instanceMatchContext);
    if (!item.match(matchContext, element)) {
      return false;
    }

    matchContext.elements.add(instanceElement);
    _addMatchingElementItem(element, item, matchContext);
    return true;
  }

  bool _matchInstanceElementGetter({
    required InstanceElementImpl instanceElement,
    required InstanceItem instanceItem,
    required MatchContext instanceMatchContext,
    required GetterElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return false;
    }

    var item = instanceItem.declaredGetters[lookupName];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: instanceMatchContext);
    if (!item.match(matchContext, element)) {
      return false;
    }

    matchContext.elements.add(instanceElement);
    _addMatchingElementItem(element, item, matchContext);
    return true;
  }

  bool _matchInstanceElementMethod({
    required InstanceElementImpl instanceElement,
    required InstanceItem instanceItem,
    required MatchContext instanceMatchContext,
    required MethodElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return false;
    }

    var item = instanceItem.declaredMethods[lookupName];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: instanceMatchContext);
    if (!item.match(matchContext, element)) {
      return false;
    }

    matchContext.elements.add(instanceElement);
    _addMatchingElementItem(element, item, matchContext);
    return true;
  }

  bool _matchInstanceElementSetter({
    required InstanceElementImpl instanceElement,
    required InstanceItem instanceItem,
    required MatchContext instanceMatchContext,
    required SetterElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return true;
    }

    var item = instanceItem.declaredSetters[lookupName];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: instanceMatchContext);
    if (!item.match(matchContext, element)) {
      return false;
    }

    matchContext.elements.add(instanceElement);
    _addMatchingElementItem(element, item, matchContext);
    return true;
  }

  bool _matchInterfaceElementConstructor({
    required InterfaceElementImpl interfaceElement,
    required InterfaceItem interfaceItem,
    required MatchContext interfaceMatchContext,
    required ConstructorElementImpl element,
  }) {
    var lookupName = element.lookupName?.asLookupName;
    if (lookupName == null) {
      return false;
    }

    var item = interfaceItem.declaredConstructors[lookupName];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: interfaceMatchContext);
    if (!item.match(matchContext, element)) {
      return false;
    }

    matchContext.elements.add(interfaceElement);
    _addMatchingElementItem(element, item, matchContext);
    return true;
  }

  void _matchInterfaceElementConstructors({
    required MatchContext matchContext,
    required InterfaceElementImpl interfaceElement,
    required InterfaceItem item,
  }) {
    for (var constructor in interfaceElement.constructors) {
      if (!_matchInterfaceElementConstructor(
        interfaceElement: interfaceElement,
        interfaceItem: item,
        interfaceMatchContext: matchContext,
        element: constructor,
      )) {
        structureMismatched.add(constructor);
      }
    }
  }

  bool _matchLibraryMetadata() {
    var item = manifest.libraryMetadata;

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, library)) {
      return false;
    }

    _addMatchingElementItem(library, item, matchContext);
    return true;
  }

  bool _matchMixin({
    required LookupName? name,
    required MixinElementImpl element,
  }) {
    var item = manifest.declaredMixins[name];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);

    _matchInstanceElementExecutables(
      element: element,
      item: item,
      matchContext: matchContext,
    );

    return true;
  }

  bool _matchTopFunction({
    required LookupName? name,
    required TopLevelFunctionElementImpl element,
  }) {
    var item = manifest.declaredFunctions[name];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);
    return true;
  }

  bool _matchTopGetter({
    required LookupName? name,
    required GetterElementImpl element,
  }) {
    var item = manifest.declaredGetters[name];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);
    return true;
  }

  bool _matchTopSetter({
    required LookupName? name,
    required SetterElementImpl element,
  }) {
    var item = manifest.declaredSetters[name];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);
    return true;
  }

  bool _matchTopVariable({
    required LookupName? name,
    required TopLevelVariableElementImpl element,
  }) {
    var item = manifest.declaredVariables[name];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);
    return true;
  }

  bool _matchTypeAlias({
    required LookupName? name,
    required TypeAliasElementImpl element,
  }) {
    var item = manifest.declaredTypeAliases[name];
    if (item == null) {
      return false;
    }

    var matchContext = MatchContext(parent: null);
    if (!item.match(matchContext, element)) {
      return false;
    }

    _addMatchingElementItem(element, item, matchContext);

    return true;
  }
}
