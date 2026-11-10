// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';

/// The IDs of a [ClassItem] and its members.
class ClassItemIds extends InterfaceItemIds {
  final ManifestItemIdList? allSubtypes;
  final ManifestItemIdList? directSubtypesOfSealed;

  new({
    required super.id,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required super.hasNonFinalField,
    required super.interfaceId,
    required super.interfaceMembers,
    required super.implementedMembers,
    required super.superImplementedMembers,
    required this.allSubtypes,
    required this.directSubtypesOfSealed,
  });

  new fromItem(ClassItem super.item)
    : allSubtypes = item.allSubtypes,
      directSubtypesOfSealed = item.directSubtypesOfSealed,
      super.fromItem();

  factory read(BinaryReader reader) {
    return ClassItemIds(
      id: ManifestItemId.read(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: reader.readLookupNameToIdMap(),
      declaredGetters: reader.readLookupNameToIdMap(),
      declaredSetters: reader.readLookupNameToIdMap(),
      declaredMethods: reader.readLookupNameToIdMap(),
      declaredConstructors: reader.readLookupNameToIdMap(),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      hasNonFinalField: reader.readBool(),
      interfaceId: ManifestItemId.read(reader),
      interfaceMembers: reader.readLookupNameToIdMap(),
      implementedMembers: reader.readLookupNameToIdMap(),
      superImplementedMembers: reader.readTypedList(
        () => reader.readLookupNameToIdMap(),
      ),
      allSubtypes: ManifestItemIdList.readOptional(reader),
      directSubtypesOfSealed: ManifestItemIdList.readOptional(reader),
    );
  }

  @override
  void write(BinaryWriter writer) {
    super.write(writer);
    allSubtypes.writeOptional(writer);
    directSubtypesOfSealed.writeOptional(writer);
  }
}

/// The IDs of an [InstanceItem] and its members.
class InstanceItemIds {
  final ManifestItemId id;
  final Map<LookupName, ManifestItemId> declaredConflicts;
  final Map<LookupName, ManifestItemId> declaredFields;
  final Map<LookupName, ManifestItemId> declaredGetters;
  final Map<LookupName, ManifestItemId> declaredSetters;
  final Map<LookupName, ManifestItemId> declaredMethods;
  final Map<LookupName, ManifestItemId> declaredConstructors;
  final Map<LookupName, ManifestItemId> inheritedConstructors;

  new({
    required this.id,
    required this.declaredConflicts,
    required this.declaredFields,
    required this.declaredGetters,
    required this.declaredSetters,
    required this.declaredMethods,
    required this.declaredConstructors,
    required this.inheritedConstructors,
  });

  /// The [item] must be fully built. The maps are copied, because the
  /// manifest builder reuses items of the previous manifest.
  new fromItem(InstanceItem item)
    : id = item.id,
      declaredConflicts = Map.of(item.declaredConflicts),
      declaredFields = item.declaredFields.mapValue((item) => item.id),
      declaredGetters = item.declaredGetters.mapValue((item) => item.id),
      declaredSetters = item.declaredSetters.mapValue((item) => item.id),
      declaredMethods = item.declaredMethods.mapValue((item) => item.id),
      declaredConstructors = item.declaredConstructors.mapValue(
        (item) => item.id,
      ),
      inheritedConstructors = Map.of(item.inheritedConstructors);

  factory read(BinaryReader reader) {
    return InstanceItemIds(
      id: ManifestItemId.read(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: reader.readLookupNameToIdMap(),
      declaredGetters: reader.readLookupNameToIdMap(),
      declaredSetters: reader.readLookupNameToIdMap(),
      declaredMethods: reader.readLookupNameToIdMap(),
      declaredConstructors: reader.readLookupNameToIdMap(),
      inheritedConstructors: reader.readLookupNameToIdMap(),
    );
  }

  ManifestItemId? getConstructorId(LookupName name) {
    return declaredConstructors[name] ??
        inheritedConstructors[name] ??
        declaredConflicts[name];
  }

  ManifestItemId? getDeclaredFieldId(LookupName name) {
    return declaredFields[name] ?? declaredConflicts[name];
  }

  ManifestItemId? getDeclaredGetterId(LookupName name) {
    return declaredGetters[name] ?? declaredConflicts[name];
  }

  ManifestItemId? getDeclaredMethodId(LookupName name) {
    return declaredMethods[name] ?? declaredConflicts[name];
  }

  ManifestItemId? getDeclaredSetterId(LookupName name) {
    return declaredSetters[name] ?? declaredConflicts[name];
  }

  void write(BinaryWriter writer) {
    id.write(writer);
    declaredConflicts.write(writer);
    declaredFields.write(writer);
    declaredGetters.write(writer);
    declaredSetters.write(writer);
    declaredMethods.write(writer);
    declaredConstructors.write(writer);
    inheritedConstructors.write(writer);
  }
}

/// The IDs of an [InterfaceItem], its members, and its interface.
class InterfaceItemIds extends InstanceItemIds {
  final bool hasNonFinalField;

  /// See [ManifestInterface.id].
  final ManifestItemId interfaceId;

  /// See [ManifestInterface.map].
  final Map<LookupName, ManifestItemId> interfaceMembers;

  /// See [ManifestInterface.implemented].
  final Map<LookupName, ManifestItemId> implementedMembers;

  /// See [ManifestInterface.superImplemented].
  final List<Map<LookupName, ManifestItemId>> superImplementedMembers;

  new({
    required super.id,
    required super.declaredConflicts,
    required super.declaredFields,
    required super.declaredGetters,
    required super.declaredSetters,
    required super.declaredMethods,
    required super.declaredConstructors,
    required super.inheritedConstructors,
    required this.hasNonFinalField,
    required this.interfaceId,
    required this.interfaceMembers,
    required this.implementedMembers,
    required this.superImplementedMembers,
  });

  new fromItem(InterfaceItem super.item)
    : hasNonFinalField = item.hasNonFinalField,
      interfaceId = item.interface.id,
      interfaceMembers = Map.of(item.interface.map),
      implementedMembers = Map.of(item.interface.implemented),
      superImplementedMembers = item.interface.superImplemented
          .map(Map.of)
          .toList(),
      super.fromItem();

  factory read(BinaryReader reader) {
    return InterfaceItemIds(
      id: ManifestItemId.read(reader),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredFields: reader.readLookupNameToIdMap(),
      declaredGetters: reader.readLookupNameToIdMap(),
      declaredSetters: reader.readLookupNameToIdMap(),
      declaredMethods: reader.readLookupNameToIdMap(),
      declaredConstructors: reader.readLookupNameToIdMap(),
      inheritedConstructors: reader.readLookupNameToIdMap(),
      hasNonFinalField: reader.readBool(),
      interfaceId: ManifestItemId.read(reader),
      interfaceMembers: reader.readLookupNameToIdMap(),
      implementedMembers: reader.readLookupNameToIdMap(),
      superImplementedMembers: reader.readTypedList(
        () => reader.readLookupNameToIdMap(),
      ),
    );
  }

  ManifestItemId? getImplementedMethodId(LookupName name) {
    return implementedMembers[name];
  }

  ManifestItemId? getInterfaceMethodId(LookupName name) {
    return interfaceMembers[name];
  }

  ManifestItemId? getSuperImplementedMethodId(int index, LookupName name) {
    if (index < superImplementedMembers.length) {
      return superImplementedMembers[index][name];
    } else {
      return null;
    }
  }

  @override
  void write(BinaryWriter writer) {
    super.write(writer);
    writer.writeBool(hasNonFinalField);
    interfaceId.write(writer);
    interfaceMembers.write(writer);
    implementedMembers.write(writer);
    writer.writeList(superImplementedMembers, (map) => map.write(writer));
  }
}

/// The IDs of a [LibraryManifest], and the few other properties of it that
/// requirements record and check.
///
/// Requirements compare only IDs, so they never need the types, signatures,
/// metadata, and constant initializers that make up most of a manifest, and
/// that are needed only to build the next manifest. So, reading this view
/// is much cheaper than reading the [LibraryManifest]. This matters, because
/// resolving a library records requirements on every library it uses.
class LibraryManifestIds {
  final String? name;
  final bool isOriginNotExistingFile;
  final bool isSynthetic;
  final Uint8List featureSet;
  final ManifestLibraryLanguageVersion languageVersion;
  final ManifestItemId libraryMetadataId;
  final List<Uri> exportedLibraryUris;

  /// See [LibraryManifest.reExportMap].
  final Map<LookupName, ManifestItemId> reExportMap;

  /// See [LibraryManifest.reExportDeprecatedOnly].
  final Set<LookupName> reExportDeprecatedOnly;

  /// See [LibraryManifest.declaredConflicts].
  final Map<LookupName, ManifestItemId> declaredConflicts;

  final Map<LookupName, ClassItemIds> declaredClasses;
  final Map<LookupName, InterfaceItemIds> declaredEnums;
  final Map<LookupName, InstanceItemIds> declaredExtensions;
  final Map<LookupName, InterfaceItemIds> declaredExtensionTypes;
  final Map<LookupName, InterfaceItemIds> declaredMixins;
  final Map<LookupName, ManifestItemId> declaredTypeAliases;
  final Map<LookupName, ManifestItemId> declaredGetters;
  final Map<LookupName, ManifestItemId> declaredSetters;
  final Map<LookupName, ManifestItemId> declaredFunctions;
  final Map<LookupName, ManifestItemId> declaredVariables;

  /// See [LibraryManifest.exportMap].
  final Map<LookupName, ManifestItemId> exportMap;

  /// See [LibraryManifest.exportMapId].
  final ManifestItemId exportMapId;

  /// See [LibraryManifest.exportedExtensions].
  final ManifestItemIdList exportedExtensions;

  /// See [LibraryManifest.hashForRequirements].
  final Hash hashForRequirements;

  new({
    required this.name,
    required this.isOriginNotExistingFile,
    required this.isSynthetic,
    required this.featureSet,
    required this.languageVersion,
    required this.libraryMetadataId,
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

  factory fromBytes(Uint8List bytes) {
    var reader = BinaryReader(bytes);
    reader.initFromTableTrailer();
    return LibraryManifestIds.read(reader);
  }

  /// Returns the IDs of the [manifest], which must be fully built.
  factory fromManifest(LibraryManifest manifest) {
    Map<LookupName, ManifestItemId> idsOf(Map<LookupName, ManifestItem> items) {
      return items.mapValue((item) => item.id);
    }

    return LibraryManifestIds(
      name: manifest.name,
      isOriginNotExistingFile: manifest.isOriginNotExistingFile,
      isSynthetic: manifest.isSynthetic,
      featureSet: manifest.featureSet,
      languageVersion: manifest.languageVersion,
      libraryMetadataId: manifest.libraryMetadata.id,
      exportedLibraryUris: manifest.exportedLibraryUris,
      reExportMap: Map.of(manifest.reExportMap),
      reExportDeprecatedOnly: Set.of(manifest.reExportDeprecatedOnly),
      declaredConflicts: Map.of(manifest.declaredConflicts),
      declaredClasses: manifest.declaredClasses.mapValue(ClassItemIds.fromItem),
      declaredEnums: manifest.declaredEnums.mapValue(InterfaceItemIds.fromItem),
      declaredExtensions: manifest.declaredExtensions.mapValue(
        InstanceItemIds.fromItem,
      ),
      declaredExtensionTypes: manifest.declaredExtensionTypes.mapValue(
        InterfaceItemIds.fromItem,
      ),
      declaredMixins: manifest.declaredMixins.mapValue(
        InterfaceItemIds.fromItem,
      ),
      declaredTypeAliases: idsOf(manifest.declaredTypeAliases),
      declaredGetters: idsOf(manifest.declaredGetters),
      declaredSetters: idsOf(manifest.declaredSetters),
      declaredFunctions: idsOf(manifest.declaredFunctions),
      declaredVariables: idsOf(manifest.declaredVariables),
      exportMap: Map.of(manifest.exportMap),
      exportMapId: manifest.exportMapId,
      exportedExtensions: manifest.exportedExtensions,
      hashForRequirements: manifest.hashForRequirements,
    );
  }

  factory read(BinaryReader reader) {
    return LibraryManifestIds(
      name: reader.readOptionalStringUtf8(),
      isOriginNotExistingFile: reader.readBool(),
      isSynthetic: reader.readBool(),
      featureSet: reader.readUint8List(),
      languageVersion: ManifestLibraryLanguageVersion.read(reader),
      libraryMetadataId: ManifestItemId.read(reader),
      exportedLibraryUris: reader.readUriList(),
      reExportMap: reader.readLookupNameToIdMap(),
      reExportDeprecatedOnly: reader.readLookupNameSet(),
      declaredConflicts: reader.readLookupNameToIdMap(),
      declaredClasses: reader.readLookupNameMap(
        readValue: () => ClassItemIds.read(reader),
      ),
      declaredEnums: reader.readLookupNameMap(
        readValue: () => InterfaceItemIds.read(reader),
      ),
      declaredExtensions: reader.readLookupNameMap(
        readValue: () => InstanceItemIds.read(reader),
      ),
      declaredExtensionTypes: reader.readLookupNameMap(
        readValue: () => InterfaceItemIds.read(reader),
      ),
      declaredMixins: reader.readLookupNameMap(
        readValue: () => InterfaceItemIds.read(reader),
      ),
      declaredTypeAliases: reader.readLookupNameToIdMap(),
      declaredGetters: reader.readLookupNameToIdMap(),
      declaredSetters: reader.readLookupNameToIdMap(),
      declaredFunctions: reader.readLookupNameToIdMap(),
      declaredVariables: reader.readLookupNameToIdMap(),
      exportMap: reader.readLookupNameToIdMap(),
      exportMapId: ManifestItemId.read(reader),
      exportedExtensions: ManifestItemIdList.read(reader),
      hashForRequirements: Hash.read(reader),
    );
  }

  /// The IDs of all exported public top-level names, declared in this
  /// library or re-exported.
  Map<LookupName, ManifestItemId> get exportedIds {
    return Map.fromEntries([
      ...reExportMap.entries,
      ...declaredConflicts.entries,
      ...<Map<LookupName, ManifestItemId>>[
        declaredClasses.mapValue((item) => item.id),
        declaredEnums.mapValue((item) => item.id),
        declaredExtensions.mapValue((item) => item.id),
        declaredExtensionTypes.mapValue((item) => item.id),
        declaredMixins.mapValue((item) => item.id),
        declaredTypeAliases,
        declaredGetters,
        declaredSetters,
        declaredFunctions,
      ].expand((map) => map.entries).whereNot((entry) => entry.key.isPrivate),
    ]);
  }

  /// Returns the ID of a top-level element either declared or re-exported,
  /// or `null` if there is no such element.
  ManifestItemId? getExportedId(LookupName name) {
    return exportMap[name];
  }

  /// Returns the [InstanceItemIds] of the declared instance element with
  /// the [name], or `null` if there is no such element.
  InstanceItemIds? getInstance(LookupName name) {
    return declaredClasses[name] ??
        declaredEnums[name] ??
        declaredExtensions[name] ??
        declaredExtensionTypes[name] ??
        declaredMixins[name];
  }

  /// Returns the [InterfaceItemIds] of the declared interface element with
  /// the [name], or `null` if there is no such element.
  InterfaceItemIds? getInterface(LookupName name) {
    return declaredClasses[name] ??
        declaredEnums[name] ??
        declaredExtensionTypes[name] ??
        declaredMixins[name];
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
    libraryMetadataId.write(writer);
    writer.writeUriList(exportedLibraryUris);
    reExportMap.write(writer);
    reExportDeprecatedOnly.write(writer);
    declaredConflicts.write(writer);
    _writeItemIdsMap(writer, declaredClasses);
    _writeItemIdsMap(writer, declaredEnums);
    _writeItemIdsMap(writer, declaredExtensions);
    _writeItemIdsMap(writer, declaredExtensionTypes);
    _writeItemIdsMap(writer, declaredMixins);
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

  static void _writeItemIdsMap(
    BinaryWriter writer,
    Map<LookupName, InstanceItemIds> map,
  ) {
    writer.writeMap(
      map,
      writeKey: (name) => name.write(writer),
      writeValue: (ids) => ids.write(writer),
    );
  }
}
