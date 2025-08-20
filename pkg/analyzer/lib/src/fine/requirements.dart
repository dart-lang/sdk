// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

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

  /// Set if [InstanceElementImpl.constructors] is invoked.
  ManifestItemIdList? allConstructors;

  /// Requested with [InstanceElementImpl.getNamedConstructor].
  final Map<LookupName, ManifestItemId?> requestedConstructors;

  /// These are "methods" in wide meaning: methods, getters, setters.
  final Map<LookupName, ManifestItemId?> methods;

  InterfaceItemRequirements({
    required this.interfaceId,
    required this.allConstructors,
    required this.requestedConstructors,
    required this.methods,
  });

  factory InterfaceItemRequirements.empty() {
    return InterfaceItemRequirements(
      interfaceId: null,
      allConstructors: null,
      requestedConstructors: {},
      methods: {},
    );
  }

  factory InterfaceItemRequirements.read(SummaryDataReader reader) {
    return InterfaceItemRequirements(
      interfaceId: ManifestItemId.readOptional(reader),
      allConstructors: ManifestItemIdList.readOptional(reader),
      requestedConstructors: reader.readNameToOptionalIdMap(),
      methods: reader.readNameToOptionalIdMap(),
    );
  }

  void write(BufferedSink sink) {
    interfaceId.writeOptional(sink);
    allConstructors.writeOptional(sink);
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

class LibraryRequirements {
  /// TopName => ID
  final Map<LookupName, ManifestItemId?> exportedTopLevels;

  /// TopName => InstanceItemRequirements
  final Map<LookupName, InstanceItemRequirements> instances;

  /// TopName => InterfaceItemRequirements
  final Map<LookupName, InterfaceItemRequirements> interfaces;

  /// All extensions exported from the library (including re-exports).
  ManifestItemIdList? exportedExtensions;

  LibraryRequirements({
    required this.exportedTopLevels,
    required this.instances,
    required this.interfaces,
    required this.exportedExtensions,
  });

  factory LibraryRequirements.empty() {
    return LibraryRequirements(
      exportedTopLevels: {},
      instances: {},
      interfaces: {},
      exportedExtensions: null,
    );
  }

  factory LibraryRequirements.read(SummaryDataReader reader) {
    return LibraryRequirements(
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
    );
  }

  void write(BufferedSink sink) {
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

class RequirementsManifest {
  /// LibraryUri => LibraryRequirements
  final Map<Uri, LibraryRequirements> libraries = {};

  final List<LibraryExportRequirements> exportRequirements = [];

  /// If this list is not empty, [isSatisfied] returns `false`.
  final List<OpaqueApiUse> opaqueApiUses = [];

  final Set<Uri> _excludedLibraries = {};

  int _recordingLockLevel = 0;

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
      var libraryElement = elementFactory.libraryOfUri2(libraryUri);
      _addExports(libraryElement);
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
    required List<LibraryElementImpl> importedLibraries,
    required String id,
  }) {
    var lookupName = id.asLookupName;
    for (var importedLibrary in importedLibraries) {
      if (importedLibrary.manifest case var manifest?) {
        var libraryRequirements = _getLibraryRequirements(importedLibrary);
        var nameToId = libraryRequirements.exportedTopLevels;
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
  void removeReqForLibs(Set<Uri> bundleLibraryUriList) {
    var uriSet = bundleLibraryUriList.toSet();

    for (var exportRequirement in exportRequirements) {
      exportRequirement.exports.removeWhere((export) {
        return uriSet.contains(export.exportedUri);
      });
    }

    for (var libUri in bundleLibraryUriList) {
      libraries.remove(libUri);
    }
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

    var libraryRequirements = _getLibraryRequirements(libraryElement);
    var interfacesMap = libraryRequirements.interfaces;
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

  LibraryRequirements _getLibraryRequirements(LibraryElementImpl element) {
    return libraries[element.uri] ??= LibraryRequirements.empty();
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
}

extension _SummaryDataReaderExtension on SummaryDataReader {
  Map<LookupName, ManifestItemId?> readNameToOptionalIdMap() {
    return readMap(
      readKey: () => LookupName.read(this),
      readValue: () => ManifestItemId.readOptional(this),
    );
  }
}
