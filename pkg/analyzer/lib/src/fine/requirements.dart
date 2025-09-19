// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/requirement_failure.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// When using fine-grained dependencies, this variable might be set to
/// accumulate requirements for the analysis result being computed.
RequirementsManifest? globalResultRequirements;

/// Requirements for a single `export`.
@visibleForTesting
class ExportRequirement {
  final Uri fragmentUri;
  final Uri exportedUri;
  final List<ExportRequirementCombinator> combinators;
  final Map<LookupName, ManifestItemId> exportedIds;

  ExportRequirement({
    required this.fragmentUri,
    required this.exportedUri,
    required this.combinators,
    required this.exportedIds,
  });

  factory ExportRequirement.read(SummaryDataReader reader) {
    return ExportRequirement(
      fragmentUri: reader.readUri(),
      exportedUri: reader.readUri(),
      combinators: reader.readTypedList(
        () => ExportRequirementCombinator.read(reader),
      ),
      exportedIds: reader.readMap(
        readKey: () => LookupName.read(reader),
        readValue: () => ManifestItemId.read(reader),
      ),
    );
  }

  ExportFailure? isSatisfied({
    required LinkedElementFactory elementFactory,
    required Set<LookupName> declaredTopNames,
  }) {
    var libraryElement = elementFactory.libraryOfUri(exportedUri);
    if (libraryElement == null) {
      return ExportLibraryMissing(uri: exportedUri);
    }

    // SAFETY: every library has the manifest.
    var libraryManifest = libraryElement.manifest!;

    // Every now exported ID must be previously exported.
    var actualCount = 0;
    for (var topEntry in libraryManifest.exportedIds.entries) {
      var lookupName = topEntry.key;

      // If declared locally, export is no-op.
      if (declaredTopNames.contains(lookupName)) {
        continue;
      }

      if (!_passCombinators(lookupName)) {
        continue;
      }

      actualCount++;
      var actualId = topEntry.value;
      var expectedId = exportedIds[lookupName];
      if (actualId != expectedId) {
        return ExportIdMismatch(
          fragmentUri: fragmentUri,
          exportedUri: exportedUri,
          name: lookupName,
          expectedId: expectedId,
          actualId: actualId,
        );
      }
    }

    // Every now previously ID must be now exported.
    if (exportedIds.length != actualCount) {
      return ExportCountMismatch(
        fragmentUri: fragmentUri,
        exportedUri: exportedUri,
        expectedCount: exportedIds.length,
        actualCount: actualCount,
      );
    }

    return null;
  }

  void write(BufferedSink sink) {
    sink.writeUri(fragmentUri);
    sink.writeUri(exportedUri);
    sink.writeList(combinators, (combinator) => combinator.write(sink));
    sink.writeMap(
      exportedIds,
      writeKey: (lookupName) => lookupName.write(sink),
      writeValue: (id) => id.write(sink),
    );
  }

  bool _passCombinators(LookupName lookupName) {
    var baseName = lookupName.asBaseName;
    for (var combinator in combinators) {
      switch (combinator) {
        case ExportRequirementHideCombinator():
          if (combinator.hiddenBaseNames.contains(baseName)) {
            return false;
          }
        case ExportRequirementShowCombinator():
          if (!combinator.shownBaseNames.contains(baseName)) {
            return false;
          }
      }
    }
    return true;
  }
}

@visibleForTesting
sealed class ExportRequirementCombinator {
  ExportRequirementCombinator();

  factory ExportRequirementCombinator.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ExportRequirementCombinatorKind.values);
    switch (kind) {
      case _ExportRequirementCombinatorKind.hide:
        return ExportRequirementHideCombinator.read(reader);
      case _ExportRequirementCombinatorKind.show:
        return ExportRequirementShowCombinator.read(reader);
    }
  }

  void write(BufferedSink sink);
}

@visibleForTesting
final class ExportRequirementHideCombinator
    extends ExportRequirementCombinator {
  final Set<BaseName> hiddenBaseNames;

  ExportRequirementHideCombinator({required this.hiddenBaseNames});

  factory ExportRequirementHideCombinator.read(SummaryDataReader reader) {
    return ExportRequirementHideCombinator(
      hiddenBaseNames: reader.readBaseNameSet(),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ExportRequirementCombinatorKind.hide);
    sink.writeBaseNameIterable(hiddenBaseNames);
  }
}

@visibleForTesting
final class ExportRequirementShowCombinator
    extends ExportRequirementCombinator {
  final Set<BaseName> shownBaseNames;

  ExportRequirementShowCombinator({required this.shownBaseNames});

  factory ExportRequirementShowCombinator.read(SummaryDataReader reader) {
    return ExportRequirementShowCombinator(
      shownBaseNames: reader.readBaseNameSet(),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ExportRequirementCombinatorKind.show);
    sink.writeBaseNameIterable(shownBaseNames);
  }
}

class InstanceElementRequirementState {
  RequirementsManifest? _owner;
  _InstanceItemWithRequirements? _instanceResult;
  _InterfaceItemWithRequirements? _interfaceResult;

  void _dispose() {
    _owner = null;
    _instanceResult = null;
    _interfaceResult = null;
  }

  void _ensureFor(RequirementsManifest owner) {
    if (!identical(_owner, owner)) {
      owner._instanceElementStates.add(this);
      _owner = owner;
      _instanceResult = null;
      _interfaceResult = null;
    }
  }
}

/// Requirements for [InstanceElementImpl].
///
/// If [InterfaceElementImpl], there are additional requirements in form
/// of [InterfaceItemRequirements].
class InstanceItemRequirements {
  final Map<LookupName, ManifestItemId?> requestedDeclaredFields;
  final Map<LookupName, ManifestItemId?> requestedDeclaredGetters;
  final Map<LookupName, ManifestItemId?> requestedDeclaredSetters;
  final Map<LookupName, ManifestItemId?> requestedDeclaredMethods;

  ManifestItemIdList? allDeclaredFields;
  ManifestItemIdList? allDeclaredGetters;
  ManifestItemIdList? allDeclaredSetters;
  ManifestItemIdList? allDeclaredMethods;

  InstanceItemRequirements({
    required this.requestedDeclaredFields,
    required this.requestedDeclaredGetters,
    required this.requestedDeclaredSetters,
    required this.requestedDeclaredMethods,
    required this.allDeclaredFields,
    required this.allDeclaredGetters,
    required this.allDeclaredSetters,
    required this.allDeclaredMethods,
  });

  factory InstanceItemRequirements.empty() {
    return InstanceItemRequirements(
      requestedDeclaredFields: {},
      requestedDeclaredGetters: {},
      requestedDeclaredSetters: {},
      requestedDeclaredMethods: {},
      allDeclaredFields: null,
      allDeclaredGetters: null,
      allDeclaredSetters: null,
      allDeclaredMethods: null,
    );
  }

  factory InstanceItemRequirements.read(SummaryDataReader reader) {
    return InstanceItemRequirements(
      requestedDeclaredFields: reader.readNameToOptionalIdMap(),
      requestedDeclaredGetters: reader.readNameToOptionalIdMap(),
      requestedDeclaredSetters: reader.readNameToOptionalIdMap(),
      requestedDeclaredMethods: reader.readNameToOptionalIdMap(),
      allDeclaredFields: ManifestItemIdList.readOptional(reader),
      allDeclaredGetters: ManifestItemIdList.readOptional(reader),
      allDeclaredSetters: ManifestItemIdList.readOptional(reader),
      allDeclaredMethods: ManifestItemIdList.readOptional(reader),
    );
  }

  void write(BufferedSink sink) {
    sink.writeNameToIdMap(requestedDeclaredFields);
    sink.writeNameToIdMap(requestedDeclaredGetters);
    sink.writeNameToIdMap(requestedDeclaredSetters);
    sink.writeNameToIdMap(requestedDeclaredMethods);
    allDeclaredFields.writeOptional(sink);
    allDeclaredGetters.writeOptional(sink);
    allDeclaredSetters.writeOptional(sink);
    allDeclaredMethods.writeOptional(sink);
  }
}

/// Requirements for [InterfaceElementImpl], in addition to those that
/// we already record as [InstanceItemRequirements].
///
/// Includes all requirements from class-like items: classes, enums,
/// extension types, mixins.
class InterfaceItemRequirements {
  /// If the element was asked for its full interface.
  ManifestItemId? interfaceId;

  /// The value of `hasNonFinalField`, if it was requested.
  bool? hasNonFinalField;

  /// Set if [InterfaceElementImpl.constructors] is invoked.
  ManifestItemIdList? allConstructors;

  /// Requested with [InterfaceElementImpl.getNamedConstructor].
  final Map<LookupName, ManifestItemId?> requestedConstructors;

  /// These are "methods" in wide meaning: methods, getters, setters.
  final Map<LookupName, ManifestItemId?> methods;
  final Map<LookupName, ManifestItemId?> implementedMethods;
  final Map<int, Map<LookupName, ManifestItemId?>> superMethods;

  InterfaceItemRequirements({
    required this.interfaceId,
    required this.hasNonFinalField,
    required this.allConstructors,
    required this.requestedConstructors,
    required this.methods,
    required this.implementedMethods,
    required this.superMethods,
  });

  factory InterfaceItemRequirements.empty() {
    return InterfaceItemRequirements(
      interfaceId: null,
      hasNonFinalField: null,
      allConstructors: null,
      requestedConstructors: {},
      methods: {},
      implementedMethods: {},
      superMethods: {},
    );
  }

  factory InterfaceItemRequirements.read(SummaryDataReader reader) {
    return InterfaceItemRequirements(
      interfaceId: ManifestItemId.readOptional(reader),
      hasNonFinalField: reader.readOptionalBool(),
      allConstructors: ManifestItemIdList.readOptional(reader),
      requestedConstructors: reader.readNameToOptionalIdMap(),
      methods: reader.readNameToOptionalIdMap(),
      implementedMethods: reader.readNameToOptionalIdMap(),
      superMethods: reader.readMap(
        readKey: () => reader.readInt64(),
        readValue: () => reader.readNameToOptionalIdMap(),
      ),
    );
  }

  void write(BufferedSink sink) {
    interfaceId.writeOptional(sink);
    sink.writeOptionalBool(hasNonFinalField);
    allConstructors.writeOptional(sink);
    sink.writeNameToIdMap(requestedConstructors);
    sink.writeNameToIdMap(methods);
    sink.writeNameToIdMap(implementedMethods);
    sink.writeMap(
      superMethods,
      writeKey: (index) => sink.writeInt64(index),
      writeValue: (map) => sink.writeNameToIdMap(map),
    );
  }
}

class LibraryElementRequirementState {
  RequirementsManifest? _owner;
  LibraryRequirements? _result;

  void _dispose() {
    _owner = null;
    _result = null;
  }

  void _ensureFor(RequirementsManifest owner) {
    if (!identical(_owner, owner)) {
      owner._libraryElementStates.add(this);
      _owner = owner;
      _result = null;
    }
  }
}

/// Requirements for all `export`s of a library.
@visibleForTesting
class LibraryExportRequirements {
  final Uri libraryUri;
  final Set<LookupName> declaredTopNames;
  final List<ExportRequirement> exports;

  LibraryExportRequirements({
    required this.libraryUri,
    required this.declaredTopNames,
    required this.exports,
  });

  factory LibraryExportRequirements.read(SummaryDataReader reader) {
    return LibraryExportRequirements(
      libraryUri: reader.readUri(),
      declaredTopNames: reader.readLookupNameSet(),
      exports: reader.readTypedList(() => ExportRequirement.read(reader)),
    );
  }

  ExportFailure? isSatisfied({required LinkedElementFactory elementFactory}) {
    for (var export in exports) {
      var failure = export.isSatisfied(
        elementFactory: elementFactory,
        declaredTopNames: declaredTopNames,
      );
      if (failure != null) {
        return failure;
      }
    }
    return null;
  }

  void write(BufferedSink sink) {
    sink.writeUri(libraryUri);
    declaredTopNames.write(sink);
    sink.writeList(exports, (export) => export.write(sink));
  }

  static LibraryExportRequirements? build(LibraryElementImpl libraryElement) {
    var declaredTopNames = libraryElement.children
        .map((element) => element.lookupName)
        .nonNulls
        .map((nameStr) => nameStr.asLookupName)
        .toSet();

    var fragments = <ExportRequirement>[];

    for (var fragment in libraryElement.fragments) {
      for (var export in fragment.libraryExports) {
        var exportedLibrary = export.exportedLibrary;

        // If no library, then there is nothing to re-export.
        if (exportedLibrary == null) {
          continue;
        }

        var combinators = export.combinators.map((combinator) {
          switch (combinator) {
            case HideElementCombinator():
              return ExportRequirementHideCombinator(
                hiddenBaseNames: combinator.hiddenNames.toBaseNameSet(),
              );
            case ShowElementCombinator():
              return ExportRequirementShowCombinator(
                shownBaseNames: combinator.shownNames.toBaseNameSet(),
              );
          }
        }).toList();

        // SAFETY: every library has the manifest.
        var manifest = exportedLibrary.manifest!;

        var exportMap = globalResultRequirements.untracked(
          reason: 'Recoding requirements',
          operation: () {
            return NamespaceBuilder()
                .createExportNamespaceForDirective2(export)
                .definedNames2;
          },
        );

        var exportedIds = <LookupName, ManifestItemId>{};
        for (var entry in exportMap.entries) {
          var lookupName = entry.key.asLookupName;
          if (declaredTopNames.contains(lookupName)) {
            continue;
          }
          // TODO(scheglov): must always be not null.
          var id = manifest.getExportedId(lookupName);
          if (id != null) {
            exportedIds[lookupName] = id;
          }
        }

        fragments.add(
          ExportRequirement(
            fragmentUri: fragment.source.uri,
            exportedUri: exportedLibrary.uri,
            combinators: combinators,
            exportedIds: exportedIds,
          ),
        );
      }
    }

    if (fragments.isNotEmpty) {
      return LibraryExportRequirements(
        libraryUri: libraryElement.uri,
        declaredTopNames: declaredTopNames,
        exports: fragments,
      );
    } else {
      return null;
    }
  }
}

class LibraryRequirements {
  String? name;
  bool? isSynthetic;
  Uint8List? featureSet;
  ManifestLibraryLanguageVersion? languageVersion;
  ManifestItemId? libraryMetadataId;

  List<Uri>? exportedLibraryUris;

  /// TopName => ID
  final Map<LookupName, ManifestItemId?> exportedTopLevels;

  /// Names that must be in [LibraryManifest.reExportDeprecatedOnly].
  final Map<LookupName, bool> reExportDeprecatedOnly;

  /// TopName => InstanceItemRequirements
  final Map<LookupName, InstanceItemRequirements> instances;

  /// TopName => InterfaceItemRequirements
  final Map<LookupName, InterfaceItemRequirements> interfaces;

  /// All extensions exported from the library (including re-exports).
  ManifestItemIdList? exportedExtensions;

  final Map<LookupName, ManifestItemId?> requestedDeclaredClasses;
  final Map<LookupName, ManifestItemId?> requestedDeclaredEnums;
  final Map<LookupName, ManifestItemId?> requestedDeclaredExtensions;
  final Map<LookupName, ManifestItemId?> requestedDeclaredExtensionTypes;
  final Map<LookupName, ManifestItemId?> requestedDeclaredMixins;
  final Map<LookupName, ManifestItemId?> requestedDeclaredTypeAliases;
  final Map<LookupName, ManifestItemId?> requestedDeclaredFunctions;
  final Map<LookupName, ManifestItemId?> requestedDeclaredVariables;
  final Map<LookupName, ManifestItemId?> requestedDeclaredGetters;
  final Map<LookupName, ManifestItemId?> requestedDeclaredSetters;

  ManifestItemIdList? allDeclaredClasses;
  ManifestItemIdList? allDeclaredEnums;
  ManifestItemIdList? allDeclaredExtensions;
  ManifestItemIdList? allDeclaredExtensionTypes;
  ManifestItemIdList? allDeclaredMixins;
  ManifestItemIdList? allDeclaredTypeAliases;
  ManifestItemIdList? allDeclaredFunctions;
  ManifestItemIdList? allDeclaredVariables;
  ManifestItemIdList? allDeclaredGetters;
  ManifestItemIdList? allDeclaredSetters;

  LibraryRequirements({
    required this.name,
    required this.isSynthetic,
    required this.featureSet,
    required this.languageVersion,
    required this.libraryMetadataId,
    required this.exportedLibraryUris,
    required this.exportedTopLevels,
    required this.instances,
    required this.interfaces,
    required this.exportedExtensions,
    required this.requestedDeclaredClasses,
    required this.requestedDeclaredEnums,
    required this.requestedDeclaredExtensions,
    required this.requestedDeclaredExtensionTypes,
    required this.requestedDeclaredMixins,
    required this.requestedDeclaredTypeAliases,
    required this.requestedDeclaredFunctions,
    required this.requestedDeclaredVariables,
    required this.requestedDeclaredGetters,
    required this.requestedDeclaredSetters,
    required this.reExportDeprecatedOnly,
    required this.allDeclaredClasses,
    required this.allDeclaredEnums,
    required this.allDeclaredExtensions,
    required this.allDeclaredExtensionTypes,
    required this.allDeclaredMixins,
    required this.allDeclaredTypeAliases,
    required this.allDeclaredFunctions,
    required this.allDeclaredVariables,
    required this.allDeclaredGetters,
    required this.allDeclaredSetters,
  });

  factory LibraryRequirements.empty() {
    return LibraryRequirements(
      name: null,
      isSynthetic: null,
      featureSet: null,
      languageVersion: null,
      libraryMetadataId: null,
      exportedLibraryUris: null,
      exportedTopLevels: {},
      instances: {},
      interfaces: {},
      exportedExtensions: null,
      requestedDeclaredClasses: {},
      requestedDeclaredEnums: {},
      requestedDeclaredExtensions: {},
      requestedDeclaredExtensionTypes: {},
      requestedDeclaredMixins: {},
      requestedDeclaredTypeAliases: {},
      requestedDeclaredFunctions: {},
      requestedDeclaredVariables: {},
      requestedDeclaredGetters: {},
      requestedDeclaredSetters: {},
      reExportDeprecatedOnly: {},
      allDeclaredClasses: null,
      allDeclaredEnums: null,
      allDeclaredExtensions: null,
      allDeclaredExtensionTypes: null,
      allDeclaredMixins: null,
      allDeclaredTypeAliases: null,
      allDeclaredFunctions: null,
      allDeclaredVariables: null,
      allDeclaredGetters: null,
      allDeclaredSetters: null,
    );
  }

  factory LibraryRequirements.read(SummaryDataReader reader) {
    return LibraryRequirements(
      name: reader.readOptionalStringUtf8(),
      isSynthetic: reader.readOptionalBool(),
      featureSet: reader.readOptionalUint8List(),
      languageVersion: ManifestLibraryLanguageVersion.readOptional(reader),
      libraryMetadataId: ManifestItemId.readOptional(reader),
      exportedLibraryUris: reader.readOptionalUriList(),
      exportedTopLevels: reader.readNameToOptionalIdMap(),
      instances: reader.readMap(
        readKey: () => LookupName.read(reader),
        readValue: () => InstanceItemRequirements.read(reader),
      ),
      interfaces: reader.readMap(
        readKey: () => LookupName.read(reader),
        readValue: () => InterfaceItemRequirements.read(reader),
      ),
      exportedExtensions: ManifestItemIdList.readOptional(reader),
      requestedDeclaredClasses: reader.readNameToOptionalIdMap(),
      requestedDeclaredEnums: reader.readNameToOptionalIdMap(),
      requestedDeclaredExtensions: reader.readNameToOptionalIdMap(),
      requestedDeclaredExtensionTypes: reader.readNameToOptionalIdMap(),
      requestedDeclaredMixins: reader.readNameToOptionalIdMap(),
      requestedDeclaredTypeAliases: reader.readNameToOptionalIdMap(),
      requestedDeclaredFunctions: reader.readNameToOptionalIdMap(),
      requestedDeclaredVariables: reader.readNameToOptionalIdMap(),
      requestedDeclaredGetters: reader.readNameToOptionalIdMap(),
      requestedDeclaredSetters: reader.readNameToOptionalIdMap(),
      reExportDeprecatedOnly: reader.readMap(
        readKey: () => LookupName.read(reader),
        readValue: () => reader.readBool(),
      ),
      allDeclaredClasses: ManifestItemIdList.readOptional(reader),
      allDeclaredEnums: ManifestItemIdList.readOptional(reader),
      allDeclaredExtensions: ManifestItemIdList.readOptional(reader),
      allDeclaredExtensionTypes: ManifestItemIdList.readOptional(reader),
      allDeclaredMixins: ManifestItemIdList.readOptional(reader),
      allDeclaredTypeAliases: ManifestItemIdList.readOptional(reader),
      allDeclaredFunctions: ManifestItemIdList.readOptional(reader),
      allDeclaredVariables: ManifestItemIdList.readOptional(reader),
      allDeclaredGetters: ManifestItemIdList.readOptional(reader),
      allDeclaredSetters: ManifestItemIdList.readOptional(reader),
    );
  }

  void write(BufferedSink sink) {
    sink.writeOptionalStringUtf8(name);
    sink.writeOptionalBool(isSynthetic);
    sink.writeOptionalUint8List(featureSet);
    sink.writeOptionalObject(languageVersion, (it) => it.write(sink));
    libraryMetadataId.writeOptional(sink);
    sink.writeOptionalUriList(exportedLibraryUris);
    sink.writeNameToIdMap(exportedTopLevels);

    sink.writeMap(
      instances,
      writeKey: (name) => name.write(sink),
      writeValue: (instance) => instance.write(sink),
    );

    sink.writeMap(
      interfaces,
      writeKey: (name) => name.write(sink),
      writeValue: (interface) => interface.write(sink),
    );

    exportedExtensions.writeOptional(sink);

    sink.writeNameToIdMap(requestedDeclaredClasses);
    sink.writeNameToIdMap(requestedDeclaredEnums);
    sink.writeNameToIdMap(requestedDeclaredExtensions);
    sink.writeNameToIdMap(requestedDeclaredExtensionTypes);
    sink.writeNameToIdMap(requestedDeclaredMixins);
    sink.writeNameToIdMap(requestedDeclaredTypeAliases);
    sink.writeNameToIdMap(requestedDeclaredFunctions);
    sink.writeNameToIdMap(requestedDeclaredVariables);
    sink.writeNameToIdMap(requestedDeclaredGetters);
    sink.writeNameToIdMap(requestedDeclaredSetters);

    sink.writeMap(
      reExportDeprecatedOnly,
      writeKey: (name) => name.write(sink),
      writeValue: (value) => sink.writeBool(value),
    );

    allDeclaredClasses.writeOptional(sink);
    allDeclaredEnums.writeOptional(sink);
    allDeclaredExtensions.writeOptional(sink);
    allDeclaredExtensionTypes.writeOptional(sink);
    allDeclaredMixins.writeOptional(sink);
    allDeclaredTypeAliases.writeOptional(sink);
    allDeclaredFunctions.writeOptional(sink);
    allDeclaredVariables.writeOptional(sink);
    allDeclaredGetters.writeOptional(sink);
    allDeclaredSetters.writeOptional(sink);
  }
}

/// Information about an API usage that is not supported by fine-grained
/// dependencies. If such API is used, we have to decide that the requirements
/// are not satisfied, because we don't know for sure.
class OpaqueApiUse {
  final String targetRuntimeType;
  final String methodName;
  final Uri? targetElementLibraryUri;
  final String? targetElementName;

  OpaqueApiUse({
    required this.targetRuntimeType,
    required this.methodName,
    this.targetElementLibraryUri,
    this.targetElementName,
  });

  factory OpaqueApiUse.read(SummaryDataReader reader) {
    return OpaqueApiUse(
      targetRuntimeType: reader.readStringUtf8(),
      methodName: reader.readStringUtf8(),
      targetElementLibraryUri: reader.readOptionalObject(
        () => reader.readUri(),
      ),
      targetElementName: reader.readOptionalStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(targetRuntimeType);
    sink.writeStringUtf8(methodName);
    sink.writeOptionalObject(
      targetElementLibraryUri,
      (uri) => sink.writeUri(uri),
    );
    sink.writeOptionalStringUtf8(targetElementName);
  }
}

/// Mutable state [RequirementsManifest] uses whenever a prefix-scope lookup
/// happens. It binds to the current [RequirementsManifest] and suppresses
/// duplicate recordings for the same identifier during that run.
class PrefixScopeRequirementState {
  RequirementsManifest? _owner;

  /// The set of names for which we already recorded requirements.
  HashSet<String> _idSet = HashSet();

  void _dispose() {
    _owner = null;
    _idSet = HashSet();
  }

  void _ensureFor(RequirementsManifest owner) {
    if (!identical(_owner, owner)) {
      owner._prefixScopeStates.add(this);
      _owner = owner;
      _idSet = HashSet();
    }
  }
}

class RequirementsManifest {
  /// LibraryUri => LibraryRequirements
  final Map<Uri, LibraryRequirements> libraries = {};

  final List<LibraryExportRequirements> exportRequirements = [];

  /// If this list is not empty, [isSatisfied] returns `false`.
  final List<OpaqueApiUse> opaqueApiUses = [];

  final Set<Uri> _excludedLibraries = {};

  int _recordingLockLevel = 0;

  final List<InstanceElementRequirementState> _instanceElementStates = [];
  final List<LibraryElementRequirementState> _libraryElementStates = [];
  final List<PrefixScopeRequirementState> _prefixScopeStates = [];

  RequirementsManifest();

  factory RequirementsManifest.read(SummaryDataReader reader) {
    var result = RequirementsManifest();

    result.libraries.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () => LibraryRequirements.read(reader),
      ),
    );

    result.exportRequirements.addAll(
      reader.readTypedList(() => LibraryExportRequirements.read(reader)),
    );

    result.opaqueApiUses.addAll(
      reader.readTypedList(() => OpaqueApiUse.read(reader)),
    );

    return result;
  }

  void addExcludedLibraries(Iterable<Uri> libraries) {
    _excludedLibraries.addAll(libraries);
  }

  /// Adds requirements to exports from libraries.
  ///
  /// We have already computed manifests for each library.
  void addExports({
    required LinkedElementFactory elementFactory,
    required Set<Uri> libraryUriSet,
  }) {
    for (var libraryUri in libraryUriSet) {
      var element = elementFactory.libraryOfUri2(libraryUri);
      var exports = LibraryExportRequirements.build(element);
      if (exports != null) {
        exportRequirements.add(exports);
      }
    }
  }

  /// Checks that this manifest can be written and read back without any
  /// changes, and that the binary form is exactly the same each time.
  ///
  /// Used in `assert()` during debug runs to catch serialization issues.
  ///
  /// Returns `true` if everything matches. Throws [StateError] if not.
  bool assertSerialization() {
    Uint8List manifestAsBytes(RequirementsManifest manifest) {
      var sink = BufferedSink();
      manifest.write(sink);
      return sink.takeBytes();
    }

    var bytes = manifestAsBytes(this);

    var readManifest = RequirementsManifest.read(SummaryDataReader(bytes));
    var bytes2 = manifestAsBytes(readManifest);

    if (!const ListEquality<int>().equals(bytes, bytes2)) {
      throw StateError('Requirement manifest bytes are different.');
    }

    return true;
  }

  /// Returns the first unsatisfied requirement, or `null` if all requirements
  /// are satisfied.
  RequirementFailure? isSatisfied({
    required LinkedElementFactory elementFactory,
    required Map<Uri, LibraryManifest> libraryManifests,
  }) {
    if (opaqueApiUses.isNotEmpty) {
      return OpaqueApiUseFailure(uses: opaqueApiUses);
    }

    for (var libraryEntry in libraries.entries) {
      var libraryUri = libraryEntry.key;
      var libraryRequirements = libraryEntry.value;

      var libraryElement = elementFactory.libraryOfUri(libraryUri);
      var libraryManifest = libraryElement?.manifest;
      if (libraryManifest == null) {
        return LibraryMissing(uri: libraryUri);
      }

      if (libraryRequirements.name case var expected?) {
        var actual = libraryManifest.name;
        if (expected != actual) {
          return LibraryNameMismatch(
            libraryUri: libraryUri,
            expected: expected,
            actual: actual,
          );
        }
      }

      if (libraryRequirements.isSynthetic case var expected?) {
        var actual = libraryManifest.isSynthetic;
        if (expected != actual) {
          return LibraryIsSyntheticMismatch(
            libraryUri: libraryUri,
            expected: expected,
            actual: actual,
          );
        }
      }

      if (libraryRequirements.featureSet case var expected?) {
        var actual = libraryManifest.featureSet;
        if (!const ListEquality<int>().equals(expected, actual)) {
          return LibraryFeatureSetMismatch(
            libraryUri: libraryUri,
            expected: expected,
            actual: actual,
          );
        }
      }

      if (libraryRequirements.languageVersion case var expected?) {
        var actual = libraryManifest.languageVersion;
        if (expected != actual) {
          return LibraryLanguageVersionMismatch(
            libraryUri: libraryUri,
            expected: expected,
            actual: actual,
          );
        }
      }

      if (libraryRequirements.libraryMetadataId case var expectedId?) {
        var actualId = libraryManifest.libraryMetadata.id;
        if (actualId != expectedId) {
          return LibraryMetadataMismatch(libraryUri: libraryUri);
        }
      }

      for (var topLevelEntry in libraryRequirements.exportedTopLevels.entries) {
        var name = topLevelEntry.key;
        var actualId = libraryManifest.getExportedId(name);
        if (topLevelEntry.value != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: topLevelEntry.value,
            actualId: actualId,
          );
        }
      }

      for (var entry in libraryRequirements.reExportDeprecatedOnly.entries) {
        var name = entry.key;
        var expected = entry.value;
        var actual = libraryManifest.reExportDeprecatedOnly.contains(name);
        if (expected != actual) {
          return ReExportDeprecatedOnlyMismatch(
            libraryUri: libraryUri,
            name: name,
            expected: expected,
            actual: actual,
          );
        }
      }

      for (var entry in libraryRequirements.requestedDeclaredClasses.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredClasses[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      for (var entry in libraryRequirements.requestedDeclaredEnums.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredEnums[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      for (var entry
          in libraryRequirements.requestedDeclaredExtensions.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredExtensions[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      for (var entry
          in libraryRequirements.requestedDeclaredExtensionTypes.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredExtensionTypes[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      for (var entry in libraryRequirements.requestedDeclaredMixins.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredMixins[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      for (var entry
          in libraryRequirements.requestedDeclaredTypeAliases.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredTypeAliases[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      for (var entry
          in libraryRequirements.requestedDeclaredFunctions.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredFunctions[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      for (var entry
          in libraryRequirements.requestedDeclaredVariables.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredVariables[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      for (var entry in libraryRequirements.requestedDeclaredGetters.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredGetters[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      for (var entry in libraryRequirements.requestedDeclaredSetters.entries) {
        var name = entry.key;
        var expectedId = entry.value;
        var actualId = libraryManifest.declaredSetters[name]?.id;
        if (expectedId != actualId) {
          return TopLevelIdMismatch(
            libraryUri: libraryUri,
            name: name,
            expectedId: expectedId,
            actualId: actualId,
          );
        }
      }

      if (libraryRequirements.allDeclaredClasses case var required?) {
        var actualItems = libraryManifest.declaredClasses.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'classes',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      if (libraryRequirements.allDeclaredEnums case var required?) {
        var actualItems = libraryManifest.declaredEnums.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'enums',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      if (libraryRequirements.allDeclaredExtensions case var required?) {
        var actualItems = libraryManifest.declaredExtensions.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'extensions',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      if (libraryRequirements.allDeclaredExtensionTypes case var required?) {
        var actualItems = libraryManifest.declaredExtensionTypes.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'extensionTypes',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      if (libraryRequirements.allDeclaredMixins case var required?) {
        var actualItems = libraryManifest.declaredMixins.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'mixins',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      if (libraryRequirements.allDeclaredTypeAliases case var required?) {
        var actualItems = libraryManifest.declaredTypeAliases.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'typeAliases',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      if (libraryRequirements.allDeclaredFunctions case var required?) {
        var actualItems = libraryManifest.declaredFunctions.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'topLevelFunctions',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      if (libraryRequirements.allDeclaredVariables case var required?) {
        var actualItems = libraryManifest.declaredVariables.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'topLevelVariables',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      if (libraryRequirements.allDeclaredGetters case var required?) {
        var actualItems = libraryManifest.declaredGetters.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'getters',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      if (libraryRequirements.allDeclaredSetters case var required?) {
        var actualItems = libraryManifest.declaredSetters.values;
        var actualIds = actualItems.map((item) => item.id);
        if (!required.equalToIterable(actualIds)) {
          return LibraryChildrenIdsMismatch(
            libraryUri: libraryUri,
            childrenPropertyName: 'setters',
            expectedIds: required,
            actualIds: ManifestItemIdList(actualIds.toList()),
          );
        }
      }

      for (var instanceEntry in libraryRequirements.instances.entries) {
        var instanceName = instanceEntry.key;
        var instanceRequirements = instanceEntry.value;

        var instanceItem =
            libraryManifest.declaredClasses[instanceName] ??
            libraryManifest.declaredEnums[instanceName] ??
            libraryManifest.declaredExtensions[instanceName] ??
            libraryManifest.declaredExtensionTypes[instanceName] ??
            libraryManifest.declaredMixins[instanceName];
        if (instanceItem is! InstanceItem) {
          return TopLevelNotInstance(
            libraryUri: libraryUri,
            name: instanceName,
            actualItem: instanceItem,
          );
        }

        for (var fieldEntry
            in instanceRequirements.requestedDeclaredFields.entries) {
          var name = fieldEntry.key;
          var expectedId = fieldEntry.value;
          var currentId = instanceItem.getDeclaredFieldId(name);
          if (expectedId != currentId) {
            return InstanceFieldIdMismatch(
              libraryUri: libraryUri,
              interfaceName: instanceName,
              fieldName: name,
              expectedId: expectedId,
              actualId: currentId,
            );
          }
        }

        for (var getterEntry
            in instanceRequirements.requestedDeclaredGetters.entries) {
          var name = getterEntry.key;
          var expectedId = getterEntry.value;
          var currentId = instanceItem.getDeclaredGetterId(name);
          if (expectedId != currentId) {
            return InstanceMethodIdMismatch(
              libraryUri: libraryUri,
              interfaceName: instanceName,
              methodName: name,
              expectedId: expectedId,
              actualId: currentId,
            );
          }
        }

        for (var setterEntry
            in instanceRequirements.requestedDeclaredSetters.entries) {
          var name = setterEntry.key;
          var expectedId = setterEntry.value;
          var currentId = instanceItem.getDeclaredSetterId(name);
          if (expectedId != currentId) {
            return InstanceMethodIdMismatch(
              libraryUri: libraryUri,
              interfaceName: instanceName,
              methodName: name,
              expectedId: expectedId,
              actualId: currentId,
            );
          }
        }

        for (var methodEntry
            in instanceRequirements.requestedDeclaredMethods.entries) {
          var name = methodEntry.key;
          var expectedId = methodEntry.value;
          var currentId = instanceItem.getDeclaredMethodId(name);
          if (expectedId != currentId) {
            return InstanceMethodIdMismatch(
              libraryUri: libraryUri,
              interfaceName: instanceName,
              methodName: name,
              expectedId: expectedId,
              actualId: currentId,
            );
          }
        }

        if (instanceRequirements.allDeclaredFields case var required?) {
          var actualItems = instanceItem.declaredFields.values;
          var actualIds = actualItems.map((item) => item.id);
          if (!required.equalToIterable(actualIds)) {
            return InstanceChildrenIdsMismatch(
              libraryUri: libraryUri,
              instanceName: instanceName,
              childrenPropertyName: 'fields',
              expectedIds: required,
              actualIds: ManifestItemIdList(actualIds.toList()),
            );
          }
        }

        if (instanceRequirements.allDeclaredGetters case var required?) {
          var actualItems = instanceItem.declaredGetters.values;
          var actualIds = actualItems.map((item) => item.id);
          if (!required.equalToIterable(actualIds)) {
            return InstanceChildrenIdsMismatch(
              libraryUri: libraryUri,
              instanceName: instanceName,
              childrenPropertyName: 'getters',
              expectedIds: required,
              actualIds: ManifestItemIdList(actualIds.toList()),
            );
          }
        }

        if (instanceRequirements.allDeclaredSetters case var required?) {
          var actualItems = instanceItem.declaredSetters.values;
          var actualIds = actualItems.map((item) => item.id);
          if (!required.equalToIterable(actualIds)) {
            return InstanceChildrenIdsMismatch(
              libraryUri: libraryUri,
              instanceName: instanceName,
              childrenPropertyName: 'setters',
              expectedIds: required,
              actualIds: ManifestItemIdList(actualIds.toList()),
            );
          }
        }

        if (instanceRequirements.allDeclaredMethods case var required?) {
          var actualItems = instanceItem.declaredMethods.values;
          var actualIds = actualItems.map((item) => item.id);
          if (!required.equalToIterable(actualIds)) {
            return InstanceChildrenIdsMismatch(
              libraryUri: libraryUri,
              instanceName: instanceName,
              childrenPropertyName: 'methods',
              expectedIds: required,
              actualIds: ManifestItemIdList(actualIds.toList()),
            );
          }
        }
      }

      for (var interfaceEntry in libraryRequirements.interfaces.entries) {
        var interfaceName = interfaceEntry.key;
        var interfaceItem =
            libraryManifest.declaredClasses[interfaceName] ??
            libraryManifest.declaredEnums[interfaceName] ??
            libraryManifest.declaredExtensionTypes[interfaceName] ??
            libraryManifest.declaredMixins[interfaceName];
        if (interfaceItem is! InterfaceItem) {
          return TopLevelNotInterface(
            libraryUri: libraryUri,
            name: interfaceName,
          );
        }

        var interfaceRequirements = interfaceEntry.value;
        if (interfaceRequirements.interfaceId case var expectedId?) {
          var actualId = interfaceItem.interface.id;
          if (expectedId != actualId) {
            return InterfaceIdMismatch(
              libraryUri: libraryUri,
              interfaceName: interfaceName,
              expectedId: expectedId,
              actualId: actualId,
            );
          }
        }

        if (interfaceRequirements.hasNonFinalField case var expected?) {
          var actual = interfaceItem.hasNonFinalField;
          if (expected != actual) {
            return InterfaceHasNonFinalFieldMismatch(
              libraryUri: libraryUri,
              interfaceName: interfaceName,
              expected: expected,
              actual: actual,
            );
          }
        }

        if (interfaceRequirements.allConstructors case var required?) {
          var actualItems = interfaceItem.declaredConstructors.values;
          var actualIds = actualItems.map((item) => item.id);
          if (!required.equalToIterable(actualIds)) {
            return InterfaceChildrenIdsMismatch(
              libraryUri: libraryUri,
              interfaceName: interfaceName,
              childrenPropertyName: 'constructors',
              expectedIds: required,
              actualIds: ManifestItemIdList(actualIds.toList()),
            );
          }
        }

        var constructors = interfaceRequirements.requestedConstructors;
        for (var constructorEntry in constructors.entries) {
          var constructorName = constructorEntry.key;
          var constructorId = interfaceItem.getConstructorId(constructorName);
          var expectedId = constructorEntry.value;
          if (expectedId != constructorId) {
            return InterfaceConstructorIdMismatch(
              libraryUri: libraryUri,
              interfaceName: interfaceName,
              constructorName: constructorName,
              expectedId: expectedId,
              actualId: constructorId,
            );
          }
        }

        var methods = interfaceRequirements.methods;
        for (var methodEntry in methods.entries) {
          var methodName = methodEntry.key;
          var methodId = interfaceItem.getInterfaceMethodId(methodName);
          var expectedId = methodEntry.value;
          if (expectedId != methodId) {
            return InstanceMethodIdMismatch(
              libraryUri: libraryUri,
              interfaceName: interfaceName,
              methodName: methodName,
              expectedId: expectedId,
              actualId: methodId,
            );
          }
        }

        var implementedMethods = interfaceRequirements.implementedMethods;
        for (var methodEntry in implementedMethods.entries) {
          var methodName = methodEntry.key;
          var methodId = interfaceItem.getImplementedMethodId(methodName);
          var expectedId = methodEntry.value;
          if (expectedId != methodId) {
            return ImplementedMethodIdMismatch(
              libraryUri: libraryUri,
              interfaceName: interfaceName,
              methodName: methodName,
              expectedId: expectedId,
              actualId: methodId,
            );
          }
        }

        var superMethods = interfaceRequirements.superMethods;
        for (var superEntry in superMethods.entries) {
          var superIndex = superEntry.key;
          var nameToId = superEntry.value;
          for (var methodEntry in nameToId.entries) {
            var methodName = methodEntry.key;
            var methodId = interfaceItem.getSuperImplementedMethodId(
              superIndex,
              methodName,
            );
            var expectedId = methodEntry.value;
            if (expectedId != methodId) {
              return SuperImplementedMethodIdMismatch(
                libraryUri: libraryUri,
                interfaceName: interfaceName,
                superIndex: superIndex,
                methodName: methodName,
                expectedId: expectedId,
                actualId: methodId,
              );
            }
          }
        }
      }

      if (libraryRequirements.exportedExtensions case var expectedIds?) {
        var actualIds = libraryManifest.exportedExtensions;
        if (actualIds != expectedIds) {
          return ExportedExtensionsMismatch(
            libraryUri: libraryUri,
            expectedIds: expectedIds,
            actualIds: actualIds,
          );
        }
      }

      if (libraryRequirements.exportedLibraryUris case var expected?) {
        var actual = libraryManifest.exportedLibraryUris;
        if (!const ListEquality<Uri>().equals(expected, actual)) {
          return LibraryExportedUrisMismatch(
            libraryUri: libraryUri,
            expected: expected,
            actual: actual,
          );
        }
      }
    }

    for (var exportRequirement in exportRequirements) {
      var failure = exportRequirement.isSatisfied(
        elementFactory: elementFactory,
      );
      if (failure != null) {
        return failure;
      }
    }

    return null;
  }

  void record_classElement_allSubtypes({required ClassElementImpl element}) {
    // TODO(scheglov): implement.
  }

  void record_fieldElement_getter({
    required FieldElementImpl element,
    String? name,
  }) {
    if (name != null) {
      record_instanceElement_getGetter(
        element: element.enclosingElement,
        name: name,
      );
    }
  }

  void record_fieldElement_setter({
    required FieldElementImpl element,
    String? name,
  }) {
    if (name != null) {
      record_instanceElement_getSetter(
        element: element.enclosingElement,
        name: name,
      );
    }
  }

  /// Record that [id] was looked up in the import prefix scope that
  /// imports [importedLibraries].
  void record_importPrefixScope_lookup({
    required PrefixScopeRequirementState state,
    required List<LibraryElementImpl> importedLibraries,
    required String id,
  }) {
    assert(!id.endsWith('='));

    if (_recordingLockLevel != 0) {
      return;
    }

    state._ensureFor(this);
    if (!state._idSet.add(id)) {
      return;
    }

    var getterLookupName = id.asLookupName;
    var setterLookupName = '$id='.asLookupName;

    for (var importedLibrary in importedLibraries) {
      if (importedLibrary.manifest case var manifest?) {
        var libraryRequirements = _getLibraryRequirements(importedLibrary);

        var getterId = manifest.getExportedId(getterLookupName);
        libraryRequirements.exportedTopLevels[getterLookupName] = getterId;
        if (getterId != null) {
          libraryRequirements.reExportDeprecatedOnly[getterLookupName] =
              manifest.reExportDeprecatedOnly.contains(getterLookupName);
        }

        var setterId = manifest.getExportedId(setterLookupName);
        libraryRequirements.exportedTopLevels[setterLookupName] = setterId;
        if (setterId != null) {
          libraryRequirements.reExportDeprecatedOnly[setterLookupName] =
              manifest.reExportDeprecatedOnly.contains(setterLookupName);
        }
      }
    }
  }

  void record_instanceElement_constructors({
    required InterfaceElementImpl element,
  }) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var itemRequirements = _getInterfaceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    requirements.allConstructors ??= ManifestItemIdList(
      item.declaredConstructors.values.map((item) => item.id).toList(),
    );
  }

  void record_instanceElement_fields({required InstanceElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    requirements.allDeclaredFields ??= ManifestItemIdList(
      item.declaredFields.values.map((item) => item.id).toList(),
    );
  }

  void record_instanceElement_getField({
    required InstanceElementImpl element,
    required String name,
  }) {
    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var fieldName = name.asLookupName;
    var fieldId = item.getDeclaredFieldId(fieldName);
    requirements.requestedDeclaredFields[fieldName] = fieldId;
  }

  void record_instanceElement_getGetter({
    required InstanceElementImpl element,
    required String name,
  }) {
    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var methodName = name.asLookupName;
    var methodId = item.getDeclaredGetterId(methodName);
    requirements.requestedDeclaredGetters[methodName] = methodId;
  }

  void record_instanceElement_getMethod({
    required InstanceElementImpl element,
    required String name,
  }) {
    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var methodName = name.asLookupName;
    var methodId = item.getDeclaredMethodId(methodName);
    requirements.requestedDeclaredMethods[methodName] = methodId;
  }

  void record_instanceElement_getSetter({
    required InstanceElementImpl element,
    required String name,
  }) {
    assert(!name.endsWith('='));
    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var methodName = '$name='.asLookupName;
    var methodId = item.getDeclaredSetterId(methodName);
    requirements.requestedDeclaredSetters[methodName] = methodId;
  }

  void record_instanceElement_getters({required InstanceElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    requirements.allDeclaredGetters ??= ManifestItemIdList(
      item.declaredGetters.values.map((item) => item.id).toList(),
    );
  }

  void record_instanceElement_methods({required InstanceElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    requirements.allDeclaredMethods ??= ManifestItemIdList(
      item.declaredMethods.values.map((item) => item.id).toList(),
    );
  }

  void record_instanceElement_setters({required InstanceElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var itemRequirements = _getInstanceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    requirements.allDeclaredSetters ??= ManifestItemIdList(
      item.declaredSetters.values.map((item) => item.id).toList(),
    );
  }

  void record_interface_all({required InterfaceElementImpl element}) {
    var itemRequirements = _getInterfaceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var interface = itemRequirements.item.interface;
    itemRequirements.requirements.interfaceId = interface.id;
  }

  /// Record that a member with [nameObj] was requested from the interface
  /// of [element]. The [methodElement] is used for consistency checking.
  void record_interface_getMember({
    required InterfaceElementImpl element,
    required Name nameObj,
    required ExecutableElement? methodElement,
    required bool concrete,
    required bool forSuper,
    required int forMixinIndex,
  }) {
    // Skip private names, cannot be used outside this library.
    if (!nameObj.isPublic) {
      return;
    }

    var itemRequirements = _getInterfaceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;
    var methodName = nameObj.name.asLookupName;

    ManifestItemId? methodId;
    if (forSuper) {
      var superIndex = forMixinIndex >= 0
          ? forMixinIndex
          : item.interface.superImplemented.length - 1;
      var superMethods = requirements.superMethods[superIndex] ??= {};
      methodId = item.getSuperImplementedMethodId(superIndex, methodName);
      superMethods[methodName] = methodId;
    } else if (concrete) {
      methodId = item.getImplementedMethodId(methodName);
      requirements.implementedMethods[methodName] = methodId;
    } else {
      methodId = item.getInterfaceMethodId(methodName);
      requirements.methods[methodName] = methodId;
    }

    // Check for consistency between the actual interface and manifest.
    if (methodElement != null) {
      if (methodId == null) {
        var qName = _qualifiedMethodName(element, methodName);
        throw StateError('Expected ID for $qName');
      }
    } else {
      if (methodId != null) {
        var qName = _qualifiedMethodName(element, methodName);
        throw StateError('Expected no ID for $qName');
      }
    }
  }

  void record_interfaceElement_getNamedConstructor({
    required InterfaceElementImpl element,
    required String name,
  }) {
    var itemRequirements = _getInterfaceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    var constructorName = name.asLookupName;
    var constructorId = item.getConstructorId(constructorName);
    requirements.requestedConstructors[constructorName] = constructorId;
  }

  void record_interfaceElement_hasNonFinalField({
    required InterfaceElementImpl element,
  }) {
    var itemRequirements = _getInterfaceItem(element);
    if (itemRequirements == null) {
      return;
    }

    var item = itemRequirements.item;
    var requirements = itemRequirements.requirements;

    requirements.hasNonFinalField = item.hasNonFinalField;
  }

  void record_library_allClasses({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredClasses ??= ManifestItemIdList(
      manifest.declaredClasses.values.map((item) => item.id).toList(),
    );
  }

  void record_library_allEnums({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredEnums ??= ManifestItemIdList(
      manifest.declaredEnums.values.map((item) => item.id).toList(),
    );
  }

  void record_library_allExportedTopLevels({
    required LibraryElementImpl element,
  }) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.exportedTopLevels.addAll(manifest.exportedIds);
  }

  void record_library_allExtensions({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredExtensions ??= ManifestItemIdList(
      manifest.declaredExtensions.values.map((item) => item.id).toList(),
    );
  }

  void record_library_allExtensionTypes({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredExtensionTypes ??= ManifestItemIdList(
      manifest.declaredExtensionTypes.values.map((item) => item.id).toList(),
    );
  }

  void record_library_allGetters({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredGetters ??= ManifestItemIdList(
      manifest.declaredGetters.values.map((item) => item.id).toList(),
    );
  }

  void record_library_allMixins({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredMixins ??= ManifestItemIdList(
      manifest.declaredMixins.values.map((item) => item.id).toList(),
    );
  }

  void record_library_allSetters({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredSetters ??= ManifestItemIdList(
      manifest.declaredSetters.values.map((item) => item.id).toList(),
    );
  }

  void record_library_allTopLevelFunctions({
    required LibraryElementImpl element,
  }) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredFunctions ??= ManifestItemIdList(
      manifest.declaredFunctions.values.map((item) => item.id).toList(),
    );
  }

  void record_library_allTopLevelVariables({
    required LibraryElementImpl element,
  }) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredVariables ??= ManifestItemIdList(
      manifest.declaredVariables.values.map((item) => item.id).toList(),
    );
  }

  void record_library_allTypeAliases({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.allDeclaredTypeAliases ??= ManifestItemIdList(
      manifest.declaredTypeAliases.values.map((item) => item.id).toList(),
    );
  }

  void record_library_entryPoint({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var mainName = TopLevelFunctionElement.MAIN_FUNCTION_NAME.asLookupName;
    var id = manifest.getExportedId(mainName);
    requirements.exportedTopLevels[mainName] = id;
  }

  void record_library_exportedLibraries({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.exportedLibraryUris = manifest.exportedLibraryUris;
  }

  void record_library_exportScope_get({
    required LibraryElementImpl element,
    required String name,
  }) {
    record_importPrefixScope_lookup(
      state: PrefixScopeRequirementState(),
      importedLibraries: [element],
      id: name.removeSuffix('=') ?? name,
    );
  }

  void record_library_featureSet({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.featureSet = manifest.featureSet;
  }

  void record_library_getClass({
    required LibraryElementImpl element,
    required String name,
  }) {
    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = name.asLookupName;
    var id = manifest.declaredClasses[lookupName]?.id;
    requirements.requestedDeclaredClasses[lookupName] = id;
  }

  void record_library_getEnum({
    required LibraryElementImpl element,
    required String name,
  }) {
    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = name.asLookupName;
    var id = manifest.declaredEnums[lookupName]?.id;
    requirements.requestedDeclaredEnums[lookupName] = id;
  }

  void record_library_getExtension({
    required LibraryElementImpl element,
    required String name,
  }) {
    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = name.asLookupName;
    var id = manifest.declaredExtensions[lookupName]?.id;
    requirements.requestedDeclaredExtensions[lookupName] = id;
  }

  void record_library_getExtensionType({
    required LibraryElementImpl element,
    required String name,
  }) {
    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = name.asLookupName;
    var id = manifest.declaredExtensionTypes[lookupName]?.id;
    requirements.requestedDeclaredExtensionTypes[lookupName] = id;
  }

  void record_library_getGetter({
    required LibraryElementImpl element,
    required String name,
  }) {
    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = name.asLookupName;
    var id = manifest.declaredGetters[lookupName]?.id;
    requirements.requestedDeclaredGetters[lookupName] = id;
  }

  void record_library_getMixin({
    required LibraryElementImpl element,
    required String name,
  }) {
    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = name.asLookupName;
    var id = manifest.declaredMixins[lookupName]?.id;
    requirements.requestedDeclaredMixins[lookupName] = id;
  }

  void record_library_getName({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.name = manifest.name;
  }

  void record_library_getSetter({
    required LibraryElementImpl element,
    required String name,
  }) {
    assert(!name.endsWith('='));

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = '$name='.asLookupName;
    var id = manifest.declaredSetters[lookupName]?.id;
    requirements.requestedDeclaredSetters[lookupName] = id;
  }

  void record_library_getTopLevelFunction({
    required LibraryElementImpl element,
    required String name,
  }) {
    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = name.asLookupName;
    var id = manifest.declaredFunctions[lookupName]?.id;
    requirements.requestedDeclaredFunctions[lookupName] = id;
  }

  void record_library_getTopLevelVariable({
    required LibraryElementImpl element,
    required String name,
  }) {
    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = name.asLookupName;
    var id = manifest.declaredVariables[lookupName]?.id;
    requirements.requestedDeclaredVariables[lookupName] = id;
  }

  void record_library_getTypeAlias({
    required LibraryElementImpl element,
    required String name,
  }) {
    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    var lookupName = name.asLookupName;
    var id = manifest.declaredTypeAliases[lookupName]?.id;
    requirements.requestedDeclaredTypeAliases[lookupName] = id;
  }

  void record_library_isSynthetic({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.isSynthetic = manifest.isSynthetic;
  }

  void record_library_languageVersion({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.languageVersion = manifest.languageVersion;
  }

  void record_library_metadata({required LibraryElementImpl element}) {
    if (_recordingLockLevel != 0) {
      return;
    }

    var manifest = element.manifest;
    if (manifest == null) {
      return;
    }

    var requirements = _getLibraryRequirements(element);
    requirements.libraryMetadataId ??= manifest.libraryMetadata.id;
  }

  /// Record that all accessible extensions inside a [LibraryFragmentImpl]
  /// are requested, which means dependency on all extensions exported
  /// from [importedLibraries].
  void record_libraryFragmentScope_accessibleExtensions({
    required List<LibraryElementImpl> importedLibraries,
  }) {
    if (_recordingLockLevel != 0) {
      return;
    }

    for (var importedLibrary in importedLibraries) {
      if (importedLibrary.manifest case var manifest?) {
        var libraryRequirements = _getLibraryRequirements(importedLibrary);
        libraryRequirements.exportedExtensions ??= manifest.exportedExtensions;
      }
    }
  }

  void record_propertyAccessorElement_variable({
    required PropertyAccessorElementImpl element,
    required String? name,
  }) {
    if (name == null) {
      return;
    }

    switch (element.enclosingElement) {
      case InstanceElementImpl instanceElement:
        record_instanceElement_getField(element: instanceElement, name: name);
      default:
      // TODO(scheglov): support for top-level variables
    }
  }

  void recordOpaqueApiUse(Object target, String method) {
    if (_recordingLockLevel != 0) {
      return;
    }

    Uri? targetElementLibraryUri;
    String? targetElementName;
    if (target case ElementImpl targetElement) {
      targetElementLibraryUri = targetElement.library?.uri;
      targetElementName = targetElement.name;
      if (_excludedLibraries.contains(targetElementLibraryUri)) {
        return;
      }
    }

    untracked(
      reason: 'We are recording failure',
      operation: () {
        // TODO(scheglov): remove after adding all tracking
        // print('[${target.runtimeType}.$method]');
        // print(StackTrace.current);

        opaqueApiUses.add(
          OpaqueApiUse(
            targetRuntimeType: target.runtimeType.toString(),
            methodName: method,
            targetElementName: targetElementName,
            targetElementLibraryUri: targetElementLibraryUri,
          ),
        );
      },
    );
  }

  /// This method is invoked after linking of a library cycle, to exclude
  /// requirements to the libraries of this same library cycle. We already
  /// link these libraries together, so only requirements to the previous
  /// libraries are interesting.
  void removeReqForLibs(Set<Uri> bundleLibraryUriSet) {
    for (var exportRequirement in exportRequirements) {
      exportRequirement.exports.removeWhere((export) {
        return bundleLibraryUriSet.contains(export.exportedUri);
      });
    }

    exportRequirements.removeWhere(
      (exportRequirement) => exportRequirement.exports.isEmpty,
    );

    for (var libUri in bundleLibraryUriSet) {
      libraries.remove(libUri);
    }
  }

  void stopRecording() {
    for (var state in _instanceElementStates) {
      state._dispose();
    }
    _instanceElementStates.clear();

    for (var state in _libraryElementStates) {
      state._dispose();
    }
    _libraryElementStates.clear();

    for (var state in _prefixScopeStates) {
      state._dispose();
    }
    _prefixScopeStates.clear();
  }

  void write(BufferedSink sink) {
    sink.writeMap(
      libraries,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (library) => library.write(sink),
    );

    sink.writeList(
      exportRequirements,
      (requirement) => requirement.write(sink),
    );

    sink.writeList(opaqueApiUses, (usage) => usage.write(sink));
  }

  _InstanceItemWithRequirements? _getInstanceItem(InstanceElementImpl element) {
    var state = element.requirementState.._ensureFor(this);
    if (state._instanceResult case var result?) {
      return result;
    }

    var libraryElement = element.library;
    var manifest = libraryElement.manifest;

    // If we are linking the library, its manifest is not set yet.
    // But then we also don't care about this dependency.
    if (manifest == null) {
      return null;
    }

    var instanceName = element.lookupName?.asLookupName;
    if (instanceName == null) {
      return null;
    }

    var libraryRequirements = _getLibraryRequirements(libraryElement);
    var instancesMap = libraryRequirements.instances;
    var instanceItem =
        manifest.declaredClasses[instanceName] ??
        manifest.declaredEnums[instanceName] ??
        manifest.declaredExtensions[instanceName] ??
        manifest.declaredExtensionTypes[instanceName] ??
        manifest.declaredMixins[instanceName];

    // SAFETY: every instance element must be in the manifest.
    instanceItem as InstanceItem;

    var requirements = instancesMap[instanceName] ??=
        InstanceItemRequirements.empty();
    var result = _InstanceItemWithRequirements(
      item: instanceItem,
      requirements: requirements,
    );
    return state._instanceResult = result;
  }

  _InterfaceItemWithRequirements? _getInterfaceItem(
    InterfaceElementImpl element,
  ) {
    var state = element.requirementState.._ensureFor(this);
    if (state._interfaceResult case var result?) {
      return result;
    }

    var libraryElement = element.library;
    var manifest = libraryElement.manifest;

    // If we are linking the library, its manifest is not set yet.
    // But then we also don't care about this dependency.
    if (manifest == null) {
      return null;
    }

    var interfaceName = element.lookupName?.asLookupName;
    if (interfaceName == null) {
      return null;
    }

    var libraryRequirements = _getLibraryRequirements(libraryElement);
    var interfacesMap = libraryRequirements.interfaces;
    var interfaceItem =
        manifest.declaredClasses[interfaceName] ??
        manifest.declaredEnums[interfaceName] ??
        manifest.declaredExtensionTypes[interfaceName] ??
        manifest.declaredMixins[interfaceName];

    // SAFETY: every interface element must be in the manifest.
    interfaceItem as InterfaceItem;

    var requirements = interfacesMap[interfaceName] ??=
        InterfaceItemRequirements.empty();
    var result = _InterfaceItemWithRequirements(
      item: interfaceItem,
      requirements: requirements,
    );
    return state._interfaceResult = result;
  }

  LibraryRequirements _getLibraryRequirements(LibraryElementImpl element) {
    var state = element.requirementState.._ensureFor(this);
    if (state._result case var result?) {
      return result;
    }

    var result = libraries[element.uri] ??= LibraryRequirements.empty();
    return state._result = result;
  }

  String _qualifiedMethodName(
    InterfaceElementImpl element,
    LookupName methodName,
  ) {
    return '${element.library.uri} '
        '${element.displayName}.'
        '${methodName.asString}';
  }
}

enum _ExportRequirementCombinatorKind { hide, show }

class _InstanceItemWithRequirements {
  final InstanceItem item;
  final InstanceItemRequirements requirements;

  _InstanceItemWithRequirements({
    required this.item,
    required this.requirements,
  });
}

class _InterfaceItemWithRequirements {
  final InterfaceItem item;
  final InterfaceItemRequirements requirements;

  _InterfaceItemWithRequirements({
    required this.item,
    required this.requirements,
  });
}

extension RequirementsManifestExtension on RequirementsManifest? {
  /// Executes the given [operation] without recording dependencies, because
  /// the dependency has already been recorded at a higher level of
  /// granularity.
  T alreadyRecorded<T>(T Function() operation) {
    return untracked(
      reason: 'The dependency has already been recorded',
      operation: operation,
    );
  }

  /// Executes the given [operation] without recording dependencies.
  ///
  /// This is used for getters on elements that are considered part of the
  /// element's identity. Since a change to such a getter implies a change to
  /// the element's identity, separate dependency tracking is not necessary.
  T includedInId<T>(T Function() operation) {
    return untracked(reason: 'Included in ID', operation: operation);
  }

  T untracked<T>({required String reason, required T Function() operation}) {
    var self = this;
    if (self == null) {
      return operation();
    } else {
      self._recordingLockLevel++;
      try {
        return operation();
      } finally {
        self._recordingLockLevel--;
      }
    }
  }
}

extension _BufferedSinkExtension on BufferedSink {
  void writeNameToIdMap(Map<LookupName, ManifestItemId?> map) {
    writeMap(
      map,
      writeKey: (name) => name.write(this),
      writeValue: (id) => id.writeOptional(this),
    );
  }

  void writeOptionalBool(bool? value) {
    if (value == null) {
      writeBool(false);
    } else {
      writeBool(true);
      writeBool(value);
    }
  }
}

extension _SummaryDataReaderExtension on SummaryDataReader {
  Map<LookupName, ManifestItemId?> readNameToOptionalIdMap() {
    return readMap(
      readKey: () => LookupName.read(this),
      readValue: () => ManifestItemId.readOptional(this),
    );
  }

  bool? readOptionalBool() {
    if (readBool()) {
      return readBool();
    } else {
      return null;
    }
  }
}
