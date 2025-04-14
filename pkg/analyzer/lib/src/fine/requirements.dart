// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
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

/// When [withFineDependencies], this variable might be set to accumulate
/// requirements for the analysis result being computed.
RequirementsManifest? globalResultRequirements;

/// Whether fine-grained dependencies feature is enabled.
///
/// This cannot be `const` because we change it in tests.
bool withFineDependencies = false;

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
  }) {
    var libraryElement = elementFactory.libraryOfUri(exportedUri);
    var libraryManifest = libraryElement?.manifest;
    if (libraryManifest == null) {
      return ExportLibraryMissing(uri: exportedUri);
    }

    // Every now exported ID must be previously exported.
    var actualCount = 0;
    for (var topEntry in libraryManifest.items.entries) {
      var name = topEntry.key;
      if (name.isPrivate) {
        continue;
      }

      if (!_passCombinators(name)) {
        continue;
      }

      actualCount++;
      var actualId = topEntry.value.id;
      var expectedId = exportedIds[topEntry.key];
      if (actualId != expectedId) {
        return ExportIdMismatch(
          fragmentUri: fragmentUri,
          exportedUri: exportedUri,
          name: name,
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
        actualCount: actualCount,
        requiredCount: exportedIds.length,
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

  ExportRequirementHideCombinator({
    required this.hiddenBaseNames,
  });

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

  ExportRequirementShowCombinator({
    required this.shownBaseNames,
  });

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

class RequirementsManifest {
  /// LibraryUri => TopName => ID
  final Map<Uri, Map<LookupName, ManifestItemId?>> topLevels = {};

  /// LibraryUri => TopName => MemberName => ID
  final Map<Uri, Map<LookupName, Map<LookupName, ManifestItemId?>>>
      interfaceMembers = {};

  final List<ExportRequirement> exportRequirements = [];

  RequirementsManifest();

  factory RequirementsManifest.read(SummaryDataReader reader) {
    var result = RequirementsManifest();

    Map<LookupName, ManifestItemId?> readNameToIdMap() {
      return reader.readMap(
        readKey: () => LookupName.read(reader),
        readValue: () => reader.readOptionalObject(
          () => ManifestItemId.read(reader),
        ),
      );
    }

    result.topLevels.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: readNameToIdMap,
      ),
    );

    result.interfaceMembers.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () {
          return reader.readMap(
            readKey: () => LookupName.read(reader),
            readValue: readNameToIdMap,
          );
        },
      ),
    );

    result.exportRequirements.addAll(
      reader.readTypedList(() => ExportRequirement.read(reader)),
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

    for (var libraryEntry in interfaceMembers.entries) {
      var libraryUri = libraryEntry.key;

      var libraryElement = elementFactory.libraryOfUri(libraryUri);
      var libraryManifest = libraryElement?.manifest;
      if (libraryManifest == null) {
        return LibraryMissing(uri: libraryUri);
      }

      for (var interfaceEntry in libraryEntry.value.entries) {
        var interfaceName = interfaceEntry.key;
        var interfaceItem = libraryManifest.items[interfaceName];
        if (interfaceItem is! InterfaceItem) {
          return TopLevelNotInterface(
            libraryUri: libraryUri,
            name: interfaceName,
          );
        }

        for (var memberEntry in interfaceEntry.value.entries) {
          var memberName = memberEntry.key;
          var memberId = interfaceItem.getMemberId(memberName);
          var expectedId = memberEntry.value;
          if (expectedId != memberId) {
            return InstanceMemberIdMismatch(
              libraryUri: libraryUri,
              interfaceName: interfaceName,
              memberName: memberName,
              expectedId: expectedId,
              actualId: memberId,
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

  void notify_interfaceElement_getNamedConstructor({
    required InterfaceElementImpl2 element,
    required String name,
  }) {
    var libraryElement = element.library2;
    var manifest = libraryElement.manifest;

    // If we are linking the library, its manifest is not set yet.
    // But then we also don't care about this dependency.
    if (manifest == null) {
      return;
    }

    var interfaceName = element.lookupName?.asLookupName;

    // SAFETY: we don't export elements without name.
    interfaceName!;

    var interfacesMap = interfaceMembers[libraryElement.uri] ??= {};
    var interfaceItem = manifest.items[interfaceName];

    // SAFETY: every interface element must be in the manifest.
    interfaceItem as InterfaceItem;

    var memberName = name.asLookupName;
    var memberId = interfaceItem.getMemberId(memberName);
    var interfaceMap = interfacesMap[interfaceName] ??= {};
    interfaceMap[memberName] = memberId;
  }

  /// This method is invoked by [InheritanceManager3] to notify the collector
  /// that a member with [nameObj] was requested from the [element].
  void notifyInterfaceRequest({
    required InterfaceElementImpl2 element,
    required Name nameObj,
  }) {
    // Skip private names, cannot be used outside this library.
    if (!nameObj.isPublic) {
      return;
    }

    var libraryElement = element.library2;
    var manifest = libraryElement.manifest;

    // If we are linking the library, its manifest is not set yet.
    // But then we also don't care about this dependency.
    if (manifest == null) {
      return;
    }

    var interfaceName = element.lookupName?.asLookupName;

    // SAFETY: we don't export elements without name.
    interfaceName!;

    var interfacesMap = interfaceMembers[libraryElement.uri] ??= {};
    var interfaceItem = manifest.items[interfaceName];

    // SAFETY: every interface element must be in the manifest.
    interfaceItem as InterfaceItem;

    var memberName = nameObj.name.asLookupName;
    var memberId = interfaceItem.getMemberId(memberName);
    var interfaceMap = interfacesMap[interfaceName] ??= {};
    interfaceMap[memberName] = memberId;
  }

  /// This method is invoked by an import scope to notify the collector that
  /// the name [nameStr] was requested from [importedLibrary].
  void notifyRequest({
    required LibraryElementImpl importedLibrary,
    required String nameStr,
  }) {
    if (importedLibrary.manifest case var manifest?) {
      var uri = importedLibrary.uri;
      var nameToId = topLevels[uri] ??= {};
      var name = nameStr.asLookupName;
      nameToId[name] = manifest.getExportedId(name);
    }
  }

  /// This method is invoked after linking of a library cycle, to exclude
  /// requirements to the libraries of this same library cycle. We already
  /// link these libraries together, so only requirements to the previous
  /// libraries are interesting.
  void removeReqForLibs(Set<Uri> bundleLibraryUriList) {
    var uriSet = bundleLibraryUriList.toSet();
    exportRequirements.removeWhere((export) {
      return uriSet.contains(export.exportedUri);
    });

    for (var libUri in bundleLibraryUriList) {
      topLevels.remove(libUri);
    }

    for (var libUri in bundleLibraryUriList) {
      interfaceMembers.remove(libUri);
    }
  }

  void write(BufferedSink sink) {
    void writeNameToIdMap(Map<LookupName, ManifestItemId?> map) {
      sink.writeMap(
        map,
        writeKey: (name) => name.write(sink),
        writeValue: (id) {
          sink.writeOptionalObject(id, (id) {
            id.write(sink);
          });
        },
      );
    }

    sink.writeMap(
      topLevels,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: writeNameToIdMap,
    );

    sink.writeMap(
      interfaceMembers,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (nameToInterfaceMap) {
        sink.writeMap(
          nameToInterfaceMap,
          writeKey: (name) => name.write(sink),
          writeValue: writeNameToIdMap,
        );
      },
    );

    sink.writeList(
      exportRequirements,
      (requirement) => requirement.write(sink),
    );
  }

  void _addExports(LibraryElementImpl libraryElement) {
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

        var exportedIds = <LookupName, ManifestItemId>{};
        var exportMap =
            NamespaceBuilder().createExportNamespaceForDirective2(export);
        for (var entry in exportMap.definedNames2.entries) {
          var lookupName = entry.key.asLookupName;
          // TODO(scheglov): must always be not null.
          var item = manifest.items[lookupName];
          if (item != null) {
            exportedIds[lookupName] = item.id;
          }
        }

        exportRequirements.add(
          ExportRequirement(
            fragmentUri: fragment.source.uri,
            exportedUri: exportedLibrary.uri,
            combinators: combinators,
            exportedIds: exportedIds,
          ),
        );
      }
    }
  }
}

enum _ExportRequirementCombinatorKind {
  hide,
  show,
}
