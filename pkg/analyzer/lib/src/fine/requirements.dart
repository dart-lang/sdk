// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/requirement_failure.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
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

/// Requirements for [InstanceElementImpl].
///
/// If [InterfaceElementImpl], there are additional requirements in form
/// of [InterfaceItemRequirements].
class InstanceItemRequirements {
  final Map<LookupName, ManifestItemId?> requestedFields;
  final Map<LookupName, ManifestItemId?> requestedGetters;
  final Map<LookupName, ManifestItemId?> requestedSetters;
  final Map<LookupName, ManifestItemId?> requestedMethods;

  ManifestItemIdList? allDeclaredFields;
  ManifestItemIdList? allDeclaredGetters;
  ManifestItemIdList? allDeclaredSetters;
  ManifestItemIdList? allDeclaredMethods;

  InstanceItemRequirements({
    required this.requestedFields,
    required this.requestedGetters,
    required this.requestedSetters,
    required this.requestedMethods,
    required this.allDeclaredFields,
    required this.allDeclaredGetters,
    required this.allDeclaredSetters,
    required this.allDeclaredMethods,
  });

  factory InstanceItemRequirements.empty() {
    return InstanceItemRequirements(
      requestedFields: {},
      requestedGetters: {},
      requestedSetters: {},
      requestedMethods: {},
      allDeclaredFields: null,
      allDeclaredGetters: null,
      allDeclaredSetters: null,
      allDeclaredMethods: null,
    );
  }

  factory InstanceItemRequirements.read(SummaryDataReader reader) {
    return InstanceItemRequirements(
      requestedFields: reader.readNameToIdMap(),
      requestedGetters: reader.readNameToIdMap(),
      requestedSetters: reader.readNameToIdMap(),
      requestedMethods: reader.readNameToIdMap(),
      allDeclaredFields: ManifestItemIdList.readOptional(reader),
      allDeclaredGetters: ManifestItemIdList.readOptional(reader),
      allDeclaredSetters: ManifestItemIdList.readOptional(reader),
      allDeclaredMethods: ManifestItemIdList.readOptional(reader),
    );
  }

  void write(BufferedSink sink) {
    sink.writeNameToIdMap(requestedFields);
    sink.writeNameToIdMap(requestedGetters);
    sink.writeNameToIdMap(requestedSetters);
    sink.writeNameToIdMap(requestedMethods);
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

  /// Set if [InstanceElementImpl.constructors] is invoked.
  ManifestItemIdList? allDeclaredConstructors;

  /// Requested with [InstanceElementImpl.getNamedConstructor].
  final Map<LookupName, ManifestItemId?> requestedConstructors;

  /// These are "methods" in wide meaning: methods, getters, setters.
  final Map<LookupName, ManifestItemId?> methods;

  InterfaceItemRequirements({
    required this.interfaceId,
    required this.allDeclaredConstructors,
    required this.requestedConstructors,
    required this.methods,
  });

  factory InterfaceItemRequirements.empty() {
    return InterfaceItemRequirements(
      interfaceId: null,
      allDeclaredConstructors: null,
      requestedConstructors: {},
      methods: {},
    );
  }

  factory InterfaceItemRequirements.read(SummaryDataReader reader) {
    return InterfaceItemRequirements(
      interfaceId: ManifestItemId.readOptional(reader),
      allDeclaredConstructors: ManifestItemIdList.readOptional(reader),
      requestedConstructors: reader.readNameToIdMap(),
      methods: reader.readNameToIdMap(),
    );
  }

  void write(BufferedSink sink) {
    interfaceId.writeOptional(sink);
    allDeclaredConstructors.writeOptional(sink);
    sink.writeNameToIdMap(requestedConstructors);
    sink.writeNameToIdMap(methods);
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
}

class RequirementsManifest {
  /// LibraryUri => TopName => ID
  final Map<Uri, Map<LookupName, ManifestItemId?>> topLevels = {};

  /// LibraryUri => TopName => InstanceItemRequirements
  final Map<Uri, Map<LookupName, InstanceItemRequirements>> instances = {};

  /// LibraryUri => TopName => InterfaceItemRequirements
  final Map<Uri, Map<LookupName, InterfaceItemRequirements>> interfaces = {};

  final List<LibraryExportRequirements> exportRequirements = [];

  int _recordingLockLevel = 0;

  RequirementsManifest();

  factory RequirementsManifest.read(SummaryDataReader reader) {
    var result = RequirementsManifest();

    result.topLevels.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () => reader.readNameToIdMap(),
      ),
    );

    result.instances.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () {
          return reader.readMap(
            readKey: () => LookupName.read(reader),
            readValue: () => InstanceItemRequirements.read(reader),
          );
        },
      ),
    );

    result.interfaces.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () {
          return reader.readMap(
            readKey: () => LookupName.read(reader),
            readValue: () => InterfaceItemRequirements.read(reader),
          );
        },
      ),
    );

    result.exportRequirements.addAll(
      reader.readTypedList(() => LibraryExportRequirements.read(reader)),
    );

    return result;
  }

  /// Adds requirements to exports from libraries.
  ///
  /// We have already computed manifests for each library.
  void addExports({
    required LinkedElementFactory elementFactory,
    required Set<Uri> libraryUriSet,
  }) {
    for (var libraryUri in libraryUriSet) {
      var libraryElement = elementFactory.libraryOfUri2(libraryUri);
      _addExports(libraryElement);
    }
  }

  /// Returns the first unsatisfied requirement, or `null` if all requirements
  /// are satisfied.
  RequirementFailure? isSatisfied({
    required LinkedElementFactory elementFactory,
    required Map<Uri, LibraryManifest> libraryManifests,
  }) {
    for (var libraryEntry in topLevels.entries) {
      var libraryUri = libraryEntry.key;

      var libraryElement = elementFactory.libraryOfUri(libraryUri);
      var libraryManifest = libraryElement?.manifest;
      if (libraryManifest == null) {
        return LibraryMissing(uri: libraryUri);
      }

      for (var topLevelEntry in libraryEntry.value.entries) {
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
    }

    for (var libraryEntry in instances.entries) {
      var libraryUri = libraryEntry.key;

      var libraryElement = elementFactory.libraryOfUri(libraryUri);
      var libraryManifest = libraryElement?.manifest;
      if (libraryManifest == null) {
        return LibraryMissing(uri: libraryUri);
      }

      for (var instanceEntry in libraryEntry.value.entries) {
        var instanceName = instanceEntry.key;
        var requirements = instanceEntry.value;

        var instanceItem =
            libraryManifest.declaredClasses[instanceName] ??
            libraryManifest.declaredEnums[instanceName] ??
            libraryManifest.declaredExtensions[instanceName] ??
            libraryManifest.declaredExtensionTypes[instanceName] ??
            libraryManifest.declaredMixins[instanceName];
        if (instanceItem is! InstanceItem) {
          return TopLevelNotInterface(
            libraryUri: libraryUri,
            name: instanceName,
          );
        }

        for (var fieldEntry in requirements.requestedFields.entries) {
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

        for (var getterEntry in requirements.requestedGetters.entries) {
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

        for (var setterEntry in requirements.requestedSetters.entries) {
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

        for (var methodEntry in requirements.requestedMethods.entries) {
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

        if (requirements.allDeclaredFields case var required?) {
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

        if (requirements.allDeclaredGetters case var required?) {
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

        if (requirements.allDeclaredSetters case var required?) {
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

        if (requirements.allDeclaredMethods case var required?) {
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
    }

    for (var libraryEntry in interfaces.entries) {
      var libraryUri = libraryEntry.key;

      var libraryElement = elementFactory.libraryOfUri(libraryUri);
      var libraryManifest = libraryElement?.manifest;
      if (libraryManifest == null) {
        return LibraryMissing(uri: libraryUri);
      }

      for (var interfaceEntry in libraryEntry.value.entries) {
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

        var requirements = interfaceEntry.value;
        if (requirements.interfaceId case var expectedId?) {
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

        if (requirements.allDeclaredConstructors case var required?) {
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

        var constructors = requirements.requestedConstructors;
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

        var methods = requirements.methods;
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

  void record_classElement_hasNonFinalField({
    required ClassElementImpl element,
  }) {
    // TODO(scheglov): implement.
  }

  void record_classElement_isEnumLike({required ClassElementImpl element}) {
    // TODO(scheglov): implement.
  }

  void record_disable(Object target, String method) {
    // TODO(scheglov): implement.
  }

  /// Record that [id] was looked up in the import prefix scope that
  /// imports [importedLibraries].
  void record_importPrefixScope_lookup({
    required List<LibraryElementImpl> importedLibraries,
    required String id,
  }) {
    var lookupName = id.asLookupName;
    for (var importedLibrary in importedLibraries) {
      if (importedLibrary.manifest case var manifest?) {
        var uri = importedLibrary.uri;
        var nameToId = topLevels[uri] ??= {};
        nameToId[lookupName] = manifest.getExportedId(lookupName);
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

    requirements.allDeclaredConstructors ??= ManifestItemIdList(
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
    requirements.requestedFields[fieldName] = fieldId;
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
    requirements.requestedGetters[methodName] = methodId;
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
    requirements.requestedMethods[methodName] = methodId;
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
    requirements.requestedSetters[methodName] = methodId;
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
    var methodId = item.getInterfaceMethodId(methodName);
    requirements.methods[methodName] = methodId;

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

  /// This method is invoked after linking of a library cycle, to exclude
  /// requirements to the libraries of this same library cycle. We already
  /// link these libraries together, so only requirements to the previous
  /// libraries are interesting.
  void removeReqForLibs(Set<Uri> bundleLibraryUriList) {
    var uriSet = bundleLibraryUriList.toSet();

    for (var exportRequirement in exportRequirements) {
      exportRequirement.exports.removeWhere((export) {
        return uriSet.contains(export.exportedUri);
      });
    }

    for (var libUri in bundleLibraryUriList) {
      topLevels.remove(libUri);
      instances.remove(libUri);
      interfaces.remove(libUri);
    }
  }

  void write(BufferedSink sink) {
    sink.writeMap(
      topLevels,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (map) => sink.writeNameToIdMap(map),
    );

    sink.writeMap(
      instances,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (nameToInstanceMap) {
        sink.writeMap(
          nameToInstanceMap,
          writeKey: (name) => name.write(sink),
          writeValue: (instance) => instance.write(sink),
        );
      },
    );

    sink.writeMap(
      interfaces,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (nameToInterfaceMap) {
        sink.writeMap(
          nameToInterfaceMap,
          writeKey: (name) => name.write(sink),
          writeValue: (interface) => interface.write(sink),
        );
      },
    );

    sink.writeList(
      exportRequirements,
      (requirement) => requirement.write(sink),
    );
  }

  void _addExports(LibraryElementImpl libraryElement) {
    var declaredTopNames =
        libraryElement.children
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

        var combinators =
            export.combinators.map((combinator) {
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

        var exportedIds = <LookupName, ManifestItemId>{};
        var exportMap = NamespaceBuilder().createExportNamespaceForDirective2(
          export,
        );
        for (var entry in exportMap.definedNames2.entries) {
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
      exportRequirements.add(
        LibraryExportRequirements(
          libraryUri: libraryElement.uri,
          declaredTopNames: declaredTopNames,
          exports: fragments,
        ),
      );
    }
  }

  _InstanceItemWithRequirements? _getInstanceItem(InstanceElementImpl element) {
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

    var instancesMap = instances[libraryElement.uri] ??= {};
    var instanceItem =
        manifest.declaredClasses[instanceName] ??
        manifest.declaredEnums[instanceName] ??
        manifest.declaredExtensions[instanceName] ??
        manifest.declaredExtensionTypes[instanceName] ??
        manifest.declaredMixins[instanceName];

    // SAFETY: every instance element must be in the manifest.
    instanceItem as InstanceItem;

    var requirements =
        instancesMap[instanceName] ??= InstanceItemRequirements.empty();
    return _InstanceItemWithRequirements(
      item: instanceItem,
      requirements: requirements,
    );
  }

  _InterfaceItemWithRequirements? _getInterfaceItem(
    InterfaceElementImpl element,
  ) {
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

    var interfacesMap = interfaces[libraryElement.uri] ??= {};
    var interfaceItem =
        manifest.declaredClasses[interfaceName] ??
        manifest.declaredEnums[interfaceName] ??
        manifest.declaredExtensionTypes[interfaceName] ??
        manifest.declaredMixins[interfaceName];

    // SAFETY: every interface element must be in the manifest.
    interfaceItem as InterfaceItem;

    var requirements =
        interfacesMap[interfaceName] ??= InterfaceItemRequirements.empty();
    return _InterfaceItemWithRequirements(
      item: interfaceItem,
      requirements: requirements,
    );
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
  T withoutRecording<T>({
    required String reason,
    required T Function() operation,
  }) {
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
}

extension _SummaryDataReaderExtension on SummaryDataReader {
  Map<LookupName, ManifestItemId?> readNameToIdMap() {
    return readMap(
      readKey: () => LookupName.read(this),
      readValue: () => ManifestItemId.readOptional(this),
    );
  }
}
