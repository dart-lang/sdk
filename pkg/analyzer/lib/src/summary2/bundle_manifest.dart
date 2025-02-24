// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

typedef BaseName = String;

class BundleManifest {
  final LinkedElementFactory elementFactory;
  final List<LibraryFileKind> inputLibraries;
  final Map<Uri, LibraryManifest> inputLibraryManifests;
  final BundleRequirementsManifest requirementsManifest;

  BundleManifest({
    required this.elementFactory,
    required this.inputLibraries,
    required this.inputLibraryManifests,
    required this.requirementsManifest,
  });

  Map<Uri, LibraryManifest> computeManifests({
    required OperationPerformanceImpl performance,
  }) {
    performance.getDataInt('libraryCount').add(inputLibraries.length);

    var libraryElements = inputLibraries.map((kind) {
      return elementFactory.libraryOfUri2(kind.file.uri);
    }).toList(growable: false);

    // Compare structures of the elements against the existing manifests.
    // At the end `affectedElements` is filled with mismatched by structure.
    // And for matched by structure we have reference maps.

    var itemMap = Map<Element2, ManifestItem>.identity();
    var refElementsMap = Map<Element2, List<Element2>>.identity();

    var refExternalIds = Map<Element2, ManifestItemId>.identity();
    var affectedElements = Set<Element2>.identity();
    for (var libraryElement in libraryElements) {
      var libraryUri = libraryElement.uri;
      var manifest = _getInputManifest(libraryUri);
      manifest.compareStructures(
        itemMap: itemMap,
        refElementsMap: refElementsMap,
        refExternalIds: refExternalIds,
        structureMismatched: affectedElements,
        library: libraryElement,
      );
    }

    performance
      ..getDataInt('structureMatchedCount').add(itemMap.length)
      ..getDataInt('structureMismatchedCount').add(affectedElements.length);

    // See if there are external elements that affect current.
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
            itemMap.remove(element);
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
              itemMap.remove(element);
              refElementsMap.remove(element);
              break;
            }
          }
        }
      }
    }

    performance
      ..getDataInt('transitiveMatchedCount').add(itemMap.length)
      ..getDataInt('transitiveAffectedCount').add(affectedElements.length);

    // Fill `result` with new library manifests.
    // We reuse existing items when they fully match.
    // We build new items for mismatched elements.
    var result = <Uri, LibraryManifest>{};
    var encodingContext = _EncodeContext(
      elementFactory: elementFactory,
    );
    for (var libraryElement in libraryElements) {
      var libraryUri = libraryElement.uri;
      var newItems = <LookupName, TopLevelItem>{};
      for (var element in libraryElement.children2) {
        var lookupName = element.lookupName?.asLookupName;
        if (lookupName == null) {
          continue;
        }
        switch (element) {
          case ClassElementImpl2():
            var item = itemMap[element];
            if (item is! ClassItem) {
              item = ClassItem.fromElement(
                name: lookupName,
                id: ManifestItemId.generate(),
                context: encodingContext,
                element: element,
              );
              newItems[lookupName] = item;
            } else {
              newItems[lookupName] = item;
            }

            var item0 = item;
            encodingContext.withTypeParameters(
              element.typeParameters2,
              (typeParameters) {
                item0.members.clear();
                var map2 =
                    element.inheritanceManager.getInterface2(element).map2;
                for (var entry in map2.entries) {
                  var nameObj = entry.key;
                  var name = nameObj.name.asLookupName;
                  var executable = entry.value;

                  // Skip private names, cannot be used outside this library.
                  if (!nameObj.isPublic) {
                    continue;
                  }

                  var item2 = itemMap[executable];

                  switch (executable) {
                    case GetterElement2OrMember():
                      if (item2 is! InstanceGetterItem) {
                        item2 = InstanceGetterItem.fromElement(
                          name: name,
                          id: ManifestItemId.generate(),
                          context: encodingContext,
                          element: executable,
                        );
                        itemMap[executable] = item2;
                      }
                      item0.members[name] = item2;
                    case MethodElement2OrMember():
                      if (item2 is! InstanceMethodItem) {
                        item2 = InstanceMethodItem.fromElement(
                          name: name,
                          id: ManifestItemId.generate(),
                          context: encodingContext,
                          element: executable,
                        );
                        itemMap[executable] = item2;
                      }
                      item0.members[name] = item2;
                  }
                }
              },
            );

          case GetterElementImpl():
            var item = itemMap[element];
            if (item is! TopLevelGetterItem) {
              newItems[lookupName] = TopLevelGetterItem.fromElement(
                name: lookupName,
                id: ManifestItemId.generate(),
                context: encodingContext,
                element: element,
              );
            } else {
              newItems[lookupName] = item;
            }
          // TODO(scheglov): add remaining elements
        }
        // TODO(scheglov): add remaining elements
      }

      var newManifest = LibraryManifest(
        uri: libraryUri,
        items: newItems,
      );
      libraryElement.manifest = newManifest;
      result[libraryUri] = newManifest;
    }

    // Add re-exported elements, and corresponding requirements.
    for (var libraryElement in libraryElements) {
      var libraryUri = libraryElement.uri;
      var manifest = result[libraryUri]!;

      for (var entry in libraryElement.exportNamespace.definedNames2.entries) {
        var name = entry.key.asLookupName;
        var element = entry.value;
        if (element is DynamicElementImpl2 || element is NeverElementImpl2) {
          continue;
        }

        // Skip if the element is declared in this library.
        if (element.library2 == libraryElement) {
          continue;
        }

        var id = elementFactory.getElementId(element) ??
            result[element.library2!.uri]?.items[name]?.id;
        if (id == null) {
          // TODO(scheglov): complete
          continue;
        }
        manifest.items[name] = ExportItem(
          libraryUri: libraryUri,
          name: name,
          id: id,
        );
      }

      // TODO(scheglov): not quite correct.
      // We depend not only on what is exported, but what would pass
      // the combinators.
      for (var fragment in libraryElement.fragments) {
        for (var export in fragment.libraryExports) {
          var exportedLibrary = export.exportedLibrary;
          // TODO(scheglov): record this
          if (exportedLibrary == null) {
            continue;
          }

          var combinators = export.combinators.map((combinator) {
            switch (combinator) {
              case HideElementCombinator():
                return ExportRequirementHideCombinator(
                  hiddenBaseNames: combinator.hiddenNames.toSet(),
                );
              case ShowElementCombinator():
                return ExportRequirementShowCombinator(
                  shownBaseNames: combinator.shownNames.toSet(),
                );
            }
          }).toList();

          if (exportedLibrary.manifest case var manifest?) {
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

            requirementsManifest.exportRequirements.add(
              _ExportRequirement(
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

    return result;
  }

  /// Returns the manifest from [inputLibraryManifests], empty if absent.
  LibraryManifest _getInputManifest(Uri uri) {
    return inputLibraryManifests[uri] ?? LibraryManifest(uri: uri, items: {});
  }
}

class BundleRequirementsManifest {
  /// LibraryUri => TopName => ID
  final Map<Uri, Map<LookupName, ManifestItemId?>> topLevels = {};

  /// LibraryUri => TopName => MemberName => ID
  final Map<Uri, Map<LookupName, Map<LookupName, ManifestItemId?>>>
      interfaceMembers = {};

  final List<_ExportRequirement> exportRequirements = [];

  BundleRequirementsManifest();

  factory BundleRequirementsManifest.read(SummaryDataReader reader) {
    var result = BundleRequirementsManifest();

    result.topLevels.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () {
          return reader.readMap(
            readKey: () => LookupName.read(reader),
            readValue: () => reader.readOptionalObject(
              (reader) => ManifestItemId.read(reader),
            ),
          );
        },
      ),
    );

    result.interfaceMembers.addAll(
      reader.readMap(
        readKey: () => reader.readUri(),
        readValue: () {
          return reader.readMap(
            readKey: () => LookupName.read(reader),
            readValue: () {
              return reader.readMap(
                readKey: () => LookupName.read(reader),
                readValue: () => reader.readOptionalObject(
                  (reader) => ManifestItemId.read(reader),
                ),
              );
            },
          );
        },
      ),
    );

    result.exportRequirements.addAll(
      reader.readTypedList(() => _ExportRequirement.read(reader)),
    );

    return result;
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
        var item = libraryManifest.items[name];
        if (topLevelEntry.value == null) {
          if (item != null) {
            return TopLevelPresent(
              libraryUri: libraryUri,
              name: name,
            );
          }
        } else {
          if (item == null) {
            return TopLevelMissing(
              libraryUri: libraryUri,
              name: name,
            );
          }
          if (item.id != topLevelEntry.value) {
            return TopLevelIdMismatch(
              libraryUri: libraryUri,
              name: name,
              expectedId: topLevelEntry.value,
              actualId: item.id,
            );
          }
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
        if (interfaceItem is! ClassItem) {
          return TopLevelNotClass(
            libraryUri: libraryUri,
          );
        }

        for (var memberEntry in interfaceEntry.value.entries) {
          var memberName = memberEntry.key;
          var memberItem = interfaceItem.members[memberName];
          var expectedId = memberEntry.value;
          if (expectedId == null) {
            if (memberItem != null) {
              return InstanceMemberPresent();
            }
          } else {
            if (memberItem == null) {
              return InstanceMemberMissing();
            }
            var actualId = memberItem.id;
            if (actualId != expectedId) {
              return InstanceMemberIdMismatch(
                libraryUri: libraryUri,
                interfaceName: interfaceName,
                memberName: memberName,
                expectedId: expectedId,
                actualId: actualId,
              );
            }
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

  /// This method is invoked by [InheritanceManager3] to notify the collector
  /// that a member with [nameObj] was requested from the [element].
  void notifyInterfaceRequest({
    required InterfaceElement2 element,
    required Name nameObj,
  }) {
    // Skip private names, cannot be used outside this library.
    if (!nameObj.isPublic) {
      return;
    }

    var libraryElement = element.library2 as LibraryElementImpl;
    var manifest = libraryElement.manifest;

    // TODO(scheglov): can this happen?
    if (manifest == null) {
      return;
    }

    // TODO(scheglov): support other elements
    if (element is! ClassElement2) {
      return;
    }

    var interfacesMap = interfaceMembers[libraryElement.uri] ??= {};

    var interfaceName = element.lookupName!.asLookupName;
    var interfaceMap = interfacesMap[interfaceName] ??= {};

    var classItem = manifest.items[interfaceName] as ClassItem?;
    // TODO(scheglov): can this happen?
    if (classItem == null) {
      return;
    }

    var name = nameObj.name.asLookupName;
    var member = classItem.members[name];
    interfaceMap[name] = member?.id;
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
      nameToId[name] = manifest.items[name]?.id;
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
    sink.writeMap(
      topLevels,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (nameToIdMap) {
        sink.writeMap(
          nameToIdMap,
          writeKey: (name) => name.write(sink),
          writeValue: (id) {
            sink.writeOptionalObject(id, (id) {
              id.write(sink);
            });
          },
        );
      },
    );

    sink.writeMap(
      interfaceMembers,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (nameToIdMap) {
        sink.writeMap(
          nameToIdMap,
          writeKey: (name) => name.write(sink),
          writeValue: (interface) {
            sink.writeMap(
              interface,
              writeKey: (name) => name.write(sink),
              writeValue: (id) {
                sink.writeOptionalObject(id, (id) {
                  id.write(sink);
                });
              },
            );
          },
        );
      },
    );

    sink.writeList(
      exportRequirements,
      (requirement) => requirement.write(sink),
    );
  }
}

class ClassItem extends TopLevelItem {
  final List<ManifestTypeParameter> typeParameters;
  final ManifestType? supertype;
  final List<ManifestType> interfaces;
  final List<ManifestType> mixins;
  final Map<LookupName, InstanceMemberItem> members;

  ClassItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required this.typeParameters,
    required this.supertype,
    required this.interfaces,
    required this.mixins,
    required this.members,
  });

  factory ClassItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required _EncodeContext context,
    required ClassElementImpl2 element,
  }) {
    return context.withTypeParameters(
      element.typeParameters2,
      (typeParameters) {
        return ClassItem(
          libraryUri: element.library2.uri,
          name: name,
          id: id,
          typeParameters: typeParameters,
          supertype: element.supertype?.encode(context),
          interfaces: element.interfaces.encode(context),
          mixins: element.mixins.encode(context),
          members: {},
        );
      },
    );
  }

  factory ClassItem.read(SummaryDataReader reader) {
    return ClassItem(
      libraryUri: reader.readUri(),
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      typeParameters: reader.readTypedList(
        () => ManifestTypeParameter.read(reader),
      ),
      supertype: reader.readOptionalObject((_) => ManifestType.read(reader)),
      interfaces: reader.readTypedList(() => ManifestType.read(reader)),
      mixins: reader.readTypedList(() => ManifestType.read(reader)),
      members: reader.readMap(
        readKey: () => LookupName.read(reader),
        readValue: () => InstanceMemberItem.read(reader),
      ),
    );
  }

  _MatchContext? match(ClassElementImpl2 element) {
    var context = _MatchContext(parent: null);
    context.addTypeParameters(element.typeParameters2);
    if (supertype.match(context, element.supertype) &&
        interfaces.match(context, element.interfaces) &&
        mixins.match(context, element.mixins)) {
      return context;
    }
    return null;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.class_);
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
    sink.writeList(typeParameters, (e) => e.write(sink));
    sink.writeOptionalObject(supertype, (x) => x.write(sink));
    sink.writeList(interfaces, (x) => x.write(sink));
    sink.writeList(mixins, (x) => x.write(sink));
    sink.writeMap(
      members,
      writeKey: (name) => name.write(sink),
      writeValue: (member) => member.write(sink),
    );
  }
}

final class ExportCountMismatch extends ExportFailure {
  final Uri fragmentUri;
  final Uri exportedUri;
  final int actualCount;
  final int requiredCount;

  ExportCountMismatch({
    required this.fragmentUri,
    required this.exportedUri,
    required this.actualCount,
    required this.requiredCount,
  });
}

// TODO(scheglov): break down
sealed class ExportFailure extends RequirementFailure {}

final class ExportIdMismatch extends ExportFailure {
  final Uri fragmentUri;
  final Uri exportedUri;
  final LookupName name;
  final ManifestItemId actualId;
  final ManifestItemId? expectedId;

  ExportIdMismatch({
    required this.fragmentUri,
    required this.exportedUri,
    required this.name,
    required this.actualId,
    required this.expectedId,
  });
}

class ExportItem extends TopLevelItem {
  ExportItem({
    required super.libraryUri,
    required super.name,
    required super.id,
  });

  factory ExportItem.read(SummaryDataReader reader) {
    return ExportItem(
      libraryUri: reader.readUri(),
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.export_);
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
  }
}

final class ExportLibraryMissing extends ExportFailure {
  final Uri uri;

  ExportLibraryMissing({
    required this.uri,
  });
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
      hiddenBaseNames: reader.readStringUtf8Set(),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ExportRequirementCombinatorKind.hide);
    sink.writeStringUtf8Iterable(hiddenBaseNames);
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
      shownBaseNames: reader.readStringUtf8Set(),
    );
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ExportRequirementCombinatorKind.show);
    sink.writeStringUtf8Iterable(shownBaseNames);
  }
}

class InstanceGetterItem extends InstanceMemberItem {
  final ManifestType returnType;

  InstanceGetterItem({
    required super.name,
    required super.id,
    required this.returnType,
  });

  factory InstanceGetterItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required _EncodeContext context,
    required GetterElement2OrMember element,
  }) {
    return InstanceGetterItem(
      name: name,
      id: id,
      returnType: element.returnType.encode(context),
    );
  }

  factory InstanceGetterItem.read(SummaryDataReader reader) {
    return InstanceGetterItem(
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      returnType: ManifestType.read(reader),
    );
  }

  _MatchContext? match(
    _MatchContext instanceContext,
    GetterElement2OrMember element,
  ) {
    var context = _MatchContext(parent: instanceContext);
    if (returnType.match(context, element.returnType)) {
      return context;
    }
    return null;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.instanceGetter);
    name.write(sink);
    id.write(sink);
    returnType.write(sink);
  }
}

sealed class InstanceMemberFailure extends RequirementFailure {}

class InstanceMemberIdMismatch extends InstanceMemberFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final LookupName memberName;
  final ManifestItemId? expectedId;
  final ManifestItemId actualId;

  InstanceMemberIdMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.memberName,
    required this.expectedId,
    required this.actualId,
  });
}

abstract class InstanceMemberItem extends ManifestItem {
  final LookupName name;
  final ManifestItemId id;

  InstanceMemberItem({
    required this.name,
    required this.id,
  });

  factory InstanceMemberItem.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestItemKind2.values);
    switch (kind) {
      case _ManifestItemKind2.instanceGetter:
        return InstanceGetterItem.read(reader);
      case _ManifestItemKind2.instanceMethod:
        return InstanceMethodItem.read(reader);
    }
  }
}

class InstanceMemberMissing extends InstanceMemberFailure {}

class InstanceMemberPresent extends InstanceMemberFailure {}

class InstanceMethodItem extends InstanceMemberItem {
  final List<ManifestTypeParameter> typeParameters;
  final ManifestType returnType;
  final List<ManifestType> formalParameterTypes;

  InstanceMethodItem({
    required super.name,
    required super.id,
    required this.typeParameters,
    required this.returnType,
    required this.formalParameterTypes,
  });

  factory InstanceMethodItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required _EncodeContext context,
    required MethodElement2OrMember element,
  }) {
    return context.withTypeParameters(
      element.typeParameters2,
      (typeParameters) {
        return InstanceMethodItem(
          name: name,
          id: id,
          typeParameters: typeParameters,
          returnType: element.returnType.encode(context),
          // TODO(scheglov): not only types
          formalParameterTypes: element.formalParameters
              .map((formalParameter) => formalParameter.type)
              .encode(context)
              .toFixedList(),
        );
      },
    );
  }

  factory InstanceMethodItem.read(SummaryDataReader reader) {
    return InstanceMethodItem(
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      typeParameters: reader.readTypedList(
        () => ManifestTypeParameter.read(reader),
      ),
      returnType: ManifestType.read(reader),
      formalParameterTypes: reader.readTypedList(
        () => ManifestType.read(reader),
      ),
    );
  }

  _MatchContext? match(
    _MatchContext instanceContext,
    MethodElement2OrMember element,
  ) {
    var context = _MatchContext(parent: instanceContext);
    context.addTypeParameters(element.typeParameters2);

    if (!ManifestTypeParameter.matchList(
        context, typeParameters, element.typeParameters2)) {
      return null;
    }

    if (returnType.match(context, element.returnType) &&
        formalParameterTypes.match(
            context, element.formalParameters.map((e) => e.type).toList())) {
      return context;
    }
    return null;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind2.instanceMethod);
    name.write(sink);
    id.write(sink);
    sink.writeList(typeParameters, (e) => e.write(sink));
    returnType.write(sink);
    sink.writeList(formalParameterTypes, (type) {
      type.write(sink);
    });
  }
}

/// The manifest of a single library.
class LibraryManifest {
  /// The URI of the library, mostly for debugging.
  final Uri uri;

  /// The manifests of the top-level items.
  final Map<LookupName, TopLevelItem> items;

  LibraryManifest({
    required this.uri,
    required this.items,
  });

  factory LibraryManifest.read(SummaryDataReader reader) {
    return LibraryManifest(
      uri: reader.readUri(),
      items: reader.readMap(
        readKey: () => LookupName.read(reader),
        readValue: () => TopLevelItem.read(reader),
      ),
    );
  }

  /// Compares structures of [library] children against the [items] of this
  /// manifest.
  ///
  /// Records mismatched elements into [structureMismatched].
  ///
  /// Records dependencies into [refElementsMap]. This includes
  /// references to elements of this bundle, and of dependencies.
  ///
  /// Records the required identifiers (stored in this manifest) of elements
  /// that are not from this bundle.
  void compareStructures({
    required Map<Element2, ManifestItem> itemMap,
    required Map<Element2, List<Element2>> refElementsMap,
    required Map<Element2, ManifestItemId> refExternalIds,
    required Set<Element2> structureMismatched,
    required LibraryElementImpl library,
  }) {
    bool handleInterfaceExecutable(
      _MatchContext interfaceMatchContext,
      Map<LookupName, InstanceMemberItem> members,
      Name nameObj,
      ExecutableElement2 executable,
    ) {
      // Skip private names, cannot be used outside this library.
      if (!nameObj.isPublic) {
        return true;
      }

      var item2 = members[nameObj.name.asLookupName];

      switch (executable) {
        case GetterElement2OrMember():
          if (item2 is! InstanceGetterItem) {
            return false;
          }

          var matchContext = item2.match(interfaceMatchContext, executable);
          if (matchContext == null) {
            return false;
          }

          itemMap[executable] = item2;
          refElementsMap[executable] = matchContext.elementList;
          refExternalIds.addAll(matchContext.externalIds);
          return true;
        case MethodElement2OrMember():
          if (item2 is! InstanceMethodItem) {
            return false;
          }

          var matchContext = item2.match(interfaceMatchContext, executable);
          if (matchContext == null) {
            item2.match(interfaceMatchContext, executable);
            return false;
          }

          itemMap[executable] = item2;
          refElementsMap[executable] = matchContext.elementList;
          refExternalIds.addAll(matchContext.externalIds);
          return true;
        case SetterElement2OrMember():
          // TODO(scheglov): implement
          return true;
      }

      // TODO(scheglov): fix it
      throw UnimplementedError('(${executable.runtimeType}) $executable');
    }

    bool handleClassElement(LookupName? name, ClassElementImpl2 element) {
      var item = items[name];
      if (item is! ClassItem) {
        return false;
      }

      var matchContext = item.match(element);
      if (matchContext == null) {
        return false;
      }

      itemMap[element] = item;
      refElementsMap[element] = matchContext.elementList;
      refExternalIds.addAll(matchContext.externalIds);

      var map2 = element.inheritanceManager.getInterface2(element).map2;
      for (var entry in map2.entries) {
        var nameObj = entry.key;
        var executable = entry.value;
        if (!handleInterfaceExecutable(
            matchContext, item.members, nameObj, executable)) {
          structureMismatched.add(executable);
        }
      }

      return true;
    }

    bool handleTopGetterElement(LookupName? name, GetterElementImpl element) {
      var item = items[name];
      if (item is! TopLevelGetterItem) {
        return false;
      }

      var matchContext = item.match(element);
      if (matchContext == null) {
        return false;
      }

      itemMap[element] = item;
      refElementsMap[element] = matchContext.elementList;
      refExternalIds.addAll(matchContext.externalIds);
      return true;
    }

    for (var element in library.children2) {
      var name = element.lookupName?.asLookupName;
      switch (element) {
        case ClassElementImpl2():
          if (!handleClassElement(name, element)) {
            structureMismatched.add(element);
          }
        case GetterElementImpl():
          if (!handleTopGetterElement(name, element)) {
            structureMismatched.add(element);
          }
      }
    }
  }

  void write(BufferedSink sink) {
    sink.writeUri(uri);
    sink.writeMap(
      items,
      writeKey: (lookupName) => lookupName.write(sink),
      writeValue: (item) => item.write(sink),
    );
  }
}

class LibraryMissing extends RequirementFailure {
  final Uri uri;

  LibraryMissing({
    required this.uri,
  });
}

final class ManifestDynamicType extends ManifestType {
  static final instance = ManifestDynamicType._();

  ManifestDynamicType._()
      : super(
          nullabilitySuffix: NullabilitySuffix.none,
        );

  @override
  bool match(_MatchContext context, DartType type) {
    return type is DynamicTypeImpl;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.dynamic);
  }
}

/// The description of an element referenced by a result library.
///
/// For example, if we encode `int get foo`, we want to know that the return
/// type of this getter references `int` from `dart:core`. How exactly we
/// arrived to this type is not important (for the manifest, but not for
/// requirements); it could be `final int foo = 0;` or `final foo = 0;`.
///
/// So, when we link the library next time, and compare the result with the
/// previous manifest, we can check if all the referenced elements are the
/// same.
final class ManifestElement {
  /// The URI of the library that declares the element.
  final Uri libraryUri;

  /// The name of the element.
  final String name;

  /// The id of the element, if not from the same bundle.
  final ManifestItemId? id;

  ManifestElement({
    required this.libraryUri,
    required this.name,
    required this.id,
  });

  factory ManifestElement.read(SummaryDataReader reader) {
    return ManifestElement(
      libraryUri: reader.readUri(),
      name: reader.readStringUtf8(),
      id: reader.readOptionalObject((reader) {
        return ManifestItemId.read(reader);
      }),
    );
  }

  @override
  int get hashCode => Object.hash(libraryUri, name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestElement &&
        other.libraryUri == libraryUri &&
        other.name == name;
  }

  /// If [element] matches this description, records the reference and id.
  /// If not, returns `false`, it is a mismatch anyway.
  bool match(_MatchContext context, InstanceElement2 element) {
    if (element.library2.uri == libraryUri && element.name3 == name) {
      context.elements.add(element);
      if (id case var id?) {
        context.externalIds[element] = id;
      }
      return true;
    }
    return false;
  }

  void write(BufferedSink sink) {
    sink.writeUri(libraryUri);
    sink.writeStringUtf8(name);
    sink.writeOptionalObject(id, (it) => it.write(sink));
  }

  static ManifestElement encode(
    _EncodeContext context,
    InstanceElement2 element,
  ) {
    return ManifestElement(
      libraryUri: element.library2.uri,
      name: element.name3!,
      id: context.getElementId(element),
    );
  }
}

sealed class ManifestFunctionFormalParameter {
  final bool isRequired;
  final ManifestType type;

  ManifestFunctionFormalParameter({
    required this.isRequired,
    required this.type,
  });

  factory ManifestFunctionFormalParameter.read(SummaryDataReader reader) {
    var kind = reader.readEnum(ManifestFunctionFormalParameterKind.values);
    switch (kind) {
      case ManifestFunctionFormalParameterKind.positional:
        return ManifestFunctionPositionalFormalParameter.read(reader);
      case ManifestFunctionFormalParameterKind.named:
        return ManifestFunctionNamedFormalParameter.read(reader);
    }
  }

  void write(BufferedSink sink);
}

enum ManifestFunctionFormalParameterKind {
  positional,
  named,
}

class ManifestFunctionNamedFormalParameter
    extends ManifestFunctionFormalParameter {
  final String name;

  ManifestFunctionNamedFormalParameter({
    required super.isRequired,
    required super.type,
    required this.name,
  });

  factory ManifestFunctionNamedFormalParameter.read(SummaryDataReader reader) {
    return ManifestFunctionNamedFormalParameter(
      isRequired: reader.readBool(),
      type: ManifestType.read(reader),
      name: reader.readStringUtf8(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestFunctionNamedFormalParameter &&
        other.name == name &&
        other.type == type;
  }

  bool match(_MatchContext context, FormalParameterElementMixin element) {
    return element.isNamed &&
        element.isRequired == isRequired &&
        type.match(context, element.type) &&
        element.name3 == name;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(ManifestFunctionFormalParameterKind.named);
    sink.writeBool(isRequired);
    type.write(sink);
    sink.writeStringUtf8(name);
  }

  static ManifestFunctionNamedFormalParameter encode(
    _EncodeContext context, {
    required bool isRequired,
    required DartType type,
    required String name,
  }) {
    return ManifestFunctionNamedFormalParameter(
      isRequired: isRequired,
      type: type.encode(context),
      name: name,
    );
  }
}

class ManifestFunctionPositionalFormalParameter
    extends ManifestFunctionFormalParameter {
  ManifestFunctionPositionalFormalParameter({
    required super.isRequired,
    required super.type,
  });

  factory ManifestFunctionPositionalFormalParameter.read(
    SummaryDataReader reader,
  ) {
    return ManifestFunctionPositionalFormalParameter(
      isRequired: reader.readBool(),
      type: ManifestType.read(reader),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestFunctionPositionalFormalParameter &&
        other.isRequired == isRequired &&
        other.type == type;
  }

  bool match(_MatchContext context, FormalParameterElementMixin element) {
    return element.isPositional &&
        element.isRequired == isRequired &&
        type.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(ManifestFunctionFormalParameterKind.positional);
    sink.writeBool(isRequired);
    type.write(sink);
  }

  static ManifestFunctionPositionalFormalParameter encode(
    _EncodeContext context, {
    required bool isRequired,
    required DartType type,
  }) {
    return ManifestFunctionPositionalFormalParameter(
      isRequired: isRequired,
      type: type.encode(context),
    );
  }
}

final class ManifestFunctionType extends ManifestType {
  final List<ManifestTypeParameter> typeParameters;
  final ManifestType returnType;
  final List<ManifestFunctionPositionalFormalParameter> positional;
  final List<ManifestFunctionNamedFormalParameter> named;

  ManifestFunctionType({
    required this.typeParameters,
    required this.returnType,
    required this.positional,
    required this.named,
    required super.nullabilitySuffix,
  });

  factory ManifestFunctionType.read(SummaryDataReader reader) {
    return ManifestFunctionType(
      typeParameters: reader.readTypedList(() {
        return ManifestTypeParameter.read(reader);
      }),
      returnType: ManifestType.read(reader),
      positional: reader.readTypedList(() {
        return ManifestFunctionPositionalFormalParameter.read(reader);
      }),
      named: reader.readTypedList(() {
        return ManifestFunctionNamedFormalParameter.read(reader);
      }),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestFunctionType &&
        const ListEquality<ManifestFunctionPositionalFormalParameter>()
            .equals(other.positional, positional) &&
        const ListEquality<ManifestFunctionNamedFormalParameter>()
            .equals(other.named, named) &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(_MatchContext context, DartType type) {
    if (type is! FunctionTypeImpl) {
      return false;
    }

    return context.withTypeParameters(type.typeParameters, () {
      if (!ManifestTypeParameter.matchList(
          context, typeParameters, type.typeParameters)) {
        return false;
      }

      if (!returnType.match(context, type.returnType)) {
        return false;
      }

      var formalParameters = type.formalParameters;
      var index = 0;

      for (var i = 0; i < positional.length; i++) {
        if (i >= formalParameters.length) {
          return false;
        }
        var manifest = positional[i];
        var element = formalParameters[index++];
        if (!manifest.match(context, element)) {
          return false;
        }
      }

      for (var i = 0; i < named.length; i++) {
        if (i >= formalParameters.length) {
          return false;
        }
        var manifest = named[i];
        var element = formalParameters[index++];
        if (!manifest.match(context, element)) {
          return false;
        }
      }

      // Fail if there are more formal parameters than in the manifest.
      if (index != formalParameters.length) {
        return false;
      }

      if (type.nullabilitySuffix != nullabilitySuffix) {
        return false;
      }

      return true;
    });
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.function);
    sink.writeList(typeParameters, (e) => e.write(sink));
    returnType.write(sink);
    sink.writeList(positional, (e) => e.write(sink));
    sink.writeList(named, (e) => e.write(sink));
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestFunctionType encode(
    _EncodeContext context,
    FunctionTypeImpl type,
  ) {
    return context.withTypeParameters(
      type.typeParameters,
      (typeParameters) {
        return ManifestFunctionType(
          typeParameters: typeParameters,
          returnType: type.returnType.encode(context),
          positional: type.positionalParameterTypes.indexed.map((pair) {
            return ManifestFunctionPositionalFormalParameter(
              isRequired: pair.$1 < type.requiredPositionalParameterCount,
              type: pair.$2.encode(context),
            );
          }).toFixedList(),
          named: type.sortedNamedParametersShared.map((element) {
            return ManifestFunctionNamedFormalParameter(
              isRequired: element.isRequired,
              type: element.type.encode(context),
              name: element.name3!,
            );
          }).toFixedList(),
          nullabilitySuffix: type.nullabilitySuffix,
        );
      },
    );
  }
}

final class ManifestInterfaceType extends ManifestType {
  final ManifestElement element;
  final List<ManifestType> arguments;

  ManifestInterfaceType({
    required this.element,
    required this.arguments,
    required super.nullabilitySuffix,
  });

  factory ManifestInterfaceType.read(SummaryDataReader reader) {
    return ManifestInterfaceType(
      element: ManifestElement.read(reader),
      arguments: reader.readTypedList(() {
        return ManifestType.read(reader);
      }),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestInterfaceType &&
        other.element == element &&
        const ListEquality<ManifestType>().equals(other.arguments, arguments) &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(_MatchContext context, DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    if (!element.match(context, type.element3)) {
      return false;
    }

    if (type.typeArguments.length != arguments.length) {
      return false;
    }
    for (var i = 0; i < arguments.length; i++) {
      if (!arguments[i].match(context, type.typeArguments[i])) {
        return false;
      }
    }

    if (type.nullabilitySuffix != nullabilitySuffix) {
      return false;
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.interface);
    element.write(sink);
    sink.writeList(arguments, (argument) {
      argument.write(sink);
    });
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestInterfaceType encode(
    _EncodeContext context,
    InterfaceType type,
  ) {
    return ManifestInterfaceType(
      element: ManifestElement.encode(context, type.element3),
      arguments: type.typeArguments.encode(context),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }
}

final class ManifestInvalidType extends ManifestType {
  static final instance = ManifestInvalidType._();

  ManifestInvalidType._()
      : super(
          nullabilitySuffix: NullabilitySuffix.none,
        );

  @override
  bool match(_MatchContext context, DartType type) {
    return type is InvalidTypeImpl;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.invalid);
  }
}

sealed class ManifestItem {
  void write(BufferedSink sink);
}

/// The globally unique identifier.
///
/// We give a new identifier each time when just anything changes about
/// an element. Even if an element changes as `A` to `B` to `A`, it will get
/// `id1`, `id2`, `id3`. Never `id1` again.
class ManifestItemId {
  static final _randomGenerator = Random();

  final int timestamp;
  final int randomBits;

  factory ManifestItemId.generate() {
    var now = DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF;
    var randomBits = _randomGenerator.nextInt(0xFFFFFFFF);
    return ManifestItemId._(now, randomBits);
  }

  factory ManifestItemId.read(SummaryDataReader reader) {
    return ManifestItemId._(
      reader.readUInt32(),
      reader.readUInt32(),
    );
  }

  ManifestItemId._(this.timestamp, this.randomBits);

  @override
  int get hashCode => Object.hash(timestamp, randomBits);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestItemId &&
        other.timestamp == timestamp &&
        other.randomBits == randomBits;
  }

  @override
  String toString() {
    return '($timestamp, $randomBits)';
  }

  void write(BufferedSink sink) {
    sink.writeUInt32(timestamp);
    sink.writeUInt32(randomBits);
  }
}

final class ManifestNeverType extends ManifestType {
  ManifestNeverType({
    required super.nullabilitySuffix,
  });

  factory ManifestNeverType.read(SummaryDataReader reader) {
    return ManifestNeverType(
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestNeverType &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(_MatchContext context, DartType type) {
    if (type is! NeverTypeImpl) {
      return false;
    }
    if (type.nullabilitySuffix != nullabilitySuffix) {
      return false;
    }
    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.never);
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestNeverType encode(
    _EncodeContext context,
    NeverTypeImpl type,
  ) {
    return ManifestNeverType(
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }
}

final class ManifestRecordType extends ManifestType {
  final List<ManifestType> positionalFields;
  final List<ManifestRecordTypeNamedField> namedFields;

  ManifestRecordType({
    required this.positionalFields,
    required this.namedFields,
    required super.nullabilitySuffix,
  });

  factory ManifestRecordType.read(SummaryDataReader reader) {
    return ManifestRecordType(
      positionalFields: reader.readTypedList(() {
        return ManifestType.read(reader);
      }),
      namedFields: reader.readTypedList(() {
        return ManifestRecordTypeNamedField.read(reader);
      }),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestRecordType &&
        const ListEquality<ManifestType>()
            .equals(other.positionalFields, positionalFields) &&
        const ListEquality<ManifestRecordTypeNamedField>()
            .equals(other.namedFields, namedFields) &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(_MatchContext context, DartType type) {
    if (type is! RecordType) {
      return false;
    }

    if (type.positionalFields.length != positionalFields.length) {
      return false;
    }
    for (var i = 0; i < positionalFields.length; i++) {
      var manifestType = positionalFields[i];
      var typeType = type.positionalFields[i].type;
      if (!manifestType.match(context, typeType)) {
        return false;
      }
    }

    if (type.namedFields.length != namedFields.length) {
      return false;
    }
    for (var i = 0; i < namedFields.length; i++) {
      var manifestField = namedFields[i];
      var typeField = type.namedFields[i];
      if (!manifestField.match(context, typeField)) {
        return false;
      }
    }

    if (type.nullabilitySuffix != nullabilitySuffix) {
      return false;
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.record);
    sink.writeList(positionalFields, (e) => e.write(sink));
    sink.writeList(namedFields, (e) => e.write(sink));
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestRecordType encode(
    _EncodeContext context,
    RecordTypeImpl type,
  ) {
    return ManifestRecordType(
      positionalFields: type.positionalFields.map((field) {
        return field.type;
      }).encode(context),
      namedFields: type.namedFields.map((field) {
        return ManifestRecordTypeNamedField.encode(context, field);
      }).toFixedList(),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }
}

class ManifestRecordTypeNamedField {
  final String name;
  final ManifestType type;

  ManifestRecordTypeNamedField({
    required this.name,
    required this.type,
  });

  factory ManifestRecordTypeNamedField.read(SummaryDataReader reader) {
    return ManifestRecordTypeNamedField(
      name: reader.readStringUtf8(),
      type: ManifestType.read(reader),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestRecordTypeNamedField &&
        other.name == name &&
        other.type == type;
  }

  bool match(_MatchContext context, RecordTypeNamedField field) {
    return field.name == name && type.match(context, field.type);
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
    type.write(sink);
  }

  static ManifestRecordTypeNamedField encode(
    _EncodeContext context,
    RecordTypeNamedField field,
  ) {
    return ManifestRecordTypeNamedField(
      name: field.name,
      type: field.type.encode(context),
    );
  }
}

sealed class ManifestType {
  final NullabilitySuffix nullabilitySuffix;

  ManifestType({
    required this.nullabilitySuffix,
  });

  bool match(_MatchContext context, DartType type);

  void write(BufferedSink sink);

  static ManifestType read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestTypeKind.values);
    switch (kind) {
      case _ManifestTypeKind.dynamic:
        return ManifestDynamicType.instance;
      case _ManifestTypeKind.function:
        return ManifestFunctionType.read(reader);
      case _ManifestTypeKind.interface:
        return ManifestInterfaceType.read(reader);
      case _ManifestTypeKind.invalid:
        return ManifestInvalidType.instance;
      case _ManifestTypeKind.never:
        return ManifestNeverType.read(reader);
      case _ManifestTypeKind.record:
        return ManifestRecordType.read(reader);
      case _ManifestTypeKind.typeParameter:
        return ManifestTypeParameterType.read(reader);
      case _ManifestTypeKind.void_:
        return ManifestVoidType.instance;
    }
  }

  static ManifestType? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(ManifestType.read);
  }
}

class ManifestTypeParameter {
  final ManifestType? bound;

  ManifestTypeParameter({
    required this.bound,
  });

  factory ManifestTypeParameter.read(
    SummaryDataReader reader,
  ) {
    return ManifestTypeParameter(
      bound: ManifestType.readOptional(reader),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestTypeParameter && other.bound == bound;
  }

  bool match(_MatchContext context, TypeParameterElement2 element) {
    return bound.match(context, element.bound);
  }

  void write(BufferedSink sink) {
    sink.writeOptionalObject(bound, (bound) => bound.write(sink));
  }

  static bool matchList(
    _MatchContext context,
    List<ManifestTypeParameter> manifests,
    List<TypeParameterElement2> elements,
  ) {
    if (manifests.length != elements.length) {
      return false;
    }

    for (var i = 0; i < manifests.length; i++) {
      var manifest = manifests[i];
      var element = elements[i];
      if (!manifest.match(context, element)) {
        return false;
      }
    }

    return true;
  }
}

final class ManifestTypeParameterType extends ManifestType {
  final int index;

  ManifestTypeParameterType({
    required this.index,
    required super.nullabilitySuffix,
  });

  factory ManifestTypeParameterType.read(SummaryDataReader reader) {
    return ManifestTypeParameterType(
      index: reader.readUInt30(),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestTypeParameterType &&
        other.index == index &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(_MatchContext context, DartType type) {
    if (type is! TypeParameterTypeImpl) {
      return false;
    }

    var elementIndex = context.indexOfTypeParameter(type.element3);
    if (elementIndex != index) {
      return false;
    }

    if (type.nullabilitySuffix != nullabilitySuffix) {
      return false;
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.typeParameter);
    sink.writeUInt30(index);
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestTypeParameterType encode(
    _EncodeContext context,
    TypeParameterTypeImpl type,
  ) {
    return ManifestTypeParameterType(
      index: context.indexOfTypeParameter(type.element3),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }
}

final class ManifestVoidType extends ManifestType {
  static final instance = ManifestVoidType._();

  ManifestVoidType._()
      : super(
          nullabilitySuffix: NullabilitySuffix.none,
        );

  @override
  bool match(_MatchContext context, DartType type) {
    return type is VoidTypeImpl;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.void_);
  }
}

sealed class RequirementFailure {}

sealed class TopLevelFailure extends RequirementFailure {
  final Uri libraryUri;

  TopLevelFailure({
    required this.libraryUri,
  });
}

class TopLevelGetterItem extends TopLevelItem {
  final ManifestType returnType;

  TopLevelGetterItem({
    required super.libraryUri,
    required super.name,
    required super.id,
    required this.returnType,
  });

  factory TopLevelGetterItem.fromElement({
    required LookupName name,
    required ManifestItemId id,
    required _EncodeContext context,
    required GetterElementImpl element,
  }) {
    return TopLevelGetterItem(
      libraryUri: element.library2.uri,
      name: name,
      id: id,
      returnType: element.returnType.encode(context),
    );
  }

  factory TopLevelGetterItem.read(SummaryDataReader reader) {
    return TopLevelGetterItem(
      libraryUri: reader.readUri(),
      name: LookupName.read(reader),
      id: ManifestItemId.read(reader),
      returnType: ManifestType.read(reader),
    );
  }

  _MatchContext? match(GetterElementImpl element) {
    var context = _MatchContext(parent: null);
    if (returnType.match(context, element.returnType)) {
      return context;
    }
    return null;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestItemKind.topLevelGetter);
    sink.writeUri(libraryUri);
    name.write(sink);
    id.write(sink);
    returnType.write(sink);
  }
}

class TopLevelIdMismatch extends TopLevelFailure {
  final LookupName name;
  final ManifestItemId? expectedId;
  final ManifestItemId actualId;

  TopLevelIdMismatch({
    required super.libraryUri,
    required this.name,
    required this.expectedId,
    required this.actualId,
  });
}

sealed class TopLevelItem extends ManifestItem {
  /// The URI of the declaring library, mostly for debugging.
  final Uri libraryUri;

  /// The name of the item, mostly for debugging.
  final LookupName name;

  /// The unique identifier of this item.
  final ManifestItemId id;

  TopLevelItem({
    required this.libraryUri,
    required this.name,
    required this.id,
  });

  factory TopLevelItem.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestItemKind.values);
    switch (kind) {
      case _ManifestItemKind.class_:
        return ClassItem.read(reader);
      case _ManifestItemKind.export_:
        return ExportItem.read(reader);
      case _ManifestItemKind.topLevelGetter:
        return TopLevelGetterItem.read(reader);
    }
  }
}

class TopLevelMissing extends TopLevelFailure {
  final LookupName name;

  TopLevelMissing({
    required super.libraryUri,
    required this.name,
  });
}

class TopLevelNotClass extends TopLevelFailure {
  TopLevelNotClass({
    required super.libraryUri,
  });
}

class TopLevelPresent extends TopLevelFailure {
  final LookupName name;

  TopLevelPresent({
    required super.libraryUri,
    required this.name,
  });
}

class _EncodeContext {
  final LinkedElementFactory elementFactory;
  final Map<TypeParameterElement2, int> _typeParameters = {};

  _EncodeContext({
    required this.elementFactory,
  });

  /// Returns the id of [element], or `null` if from this bundle.
  ManifestItemId? getElementId(Element2 element) {
    return elementFactory.getElementId(element);
  }

  int indexOfTypeParameter(TypeParameterElement2 element) {
    if (_typeParameters[element] case var bottomIndex?) {
      return _typeParameters.length - 1 - bottomIndex;
    }

    return throw StateError('No type parameter $element');
  }

  T withTypeParameters<T>(
    List<TypeParameterElement2> typeParameters,
    T Function(List<ManifestTypeParameter> typeParameters) operation,
  ) {
    for (var typeParameter in typeParameters) {
      _typeParameters[typeParameter] = _typeParameters.length;
    }

    var encoded = <ManifestTypeParameter>[];
    for (var typeParameter in typeParameters) {
      encoded.add(
        ManifestTypeParameter(
          bound: typeParameter.bound?.encode(this),
        ),
      );
    }

    try {
      return operation(encoded);
    } finally {
      for (var typeParameter in typeParameters) {
        _typeParameters.remove(typeParameter);
      }
    }
  }
}

class _ExportRequirement {
  final Uri fragmentUri;
  final Uri exportedUri;
  final List<ExportRequirementCombinator> combinators;
  final Map<LookupName, ManifestItemId> exportedIds;

  _ExportRequirement({
    required this.fragmentUri,
    required this.exportedUri,
    required this.combinators,
    required this.exportedIds,
  });

  factory _ExportRequirement.read(SummaryDataReader reader) {
    return _ExportRequirement(
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

enum _ExportRequirementCombinatorKind {
  hide,
  show,
}

enum _ManifestItemKind {
  class_,
  export_,
  topLevelGetter,
}

enum _ManifestItemKind2 {
  instanceGetter,
  instanceMethod,
}

enum _ManifestTypeKind {
  dynamic,
  function,
  interface,
  invalid,
  never,
  record,
  typeParameter,
  void_,
}

class _MatchContext {
  final _MatchContext? parent;

  /// Any referenced elements, from this bundle or not.
  final Set<Element2> elements = {};

  /// The required identifiers of referenced elements that are not from this
  /// bundle.
  final Map<Element2, ManifestItemId> externalIds = {};

  final Map<TypeParameterElement2, int> _typeParameters = {};

  _MatchContext({
    required this.parent,
  });

  /// Any referenced elements, from this bundle or not.
  List<Element2> get elementList => elements.toList(growable: false);

  void addTypeParameters(List<TypeParameterElement2> typeParameters) {
    for (var typeParameter in typeParameters) {
      _typeParameters[typeParameter] = _typeParameters.length;
    }
  }

  int indexOfTypeParameter(TypeParameterElement2 element) {
    if (_typeParameters[element] case var result?) {
      return _typeParameters.length - 1 - result;
    }

    if (parent case var parent?) {
      var parentIndex = parent.indexOfTypeParameter(element);
      return _typeParameters.length + parentIndex;
    }

    throw StateError('No type parameter $element');
  }

  T withTypeParameters<T>(
    List<TypeParameterElement2> typeParameters,
    T Function() operation,
  ) {
    addTypeParameters(typeParameters);
    try {
      return operation();
    } finally {
      for (var typeParameter in typeParameters) {
        _typeParameters.remove(typeParameter);
      }
    }
  }
}

extension type LookupName(String _it) {
  factory LookupName.read(SummaryDataReader reader) {
    var str = reader.readStringUtf8();
    return LookupName(str);
  }

  BaseName get asBaseName {
    return _it.removeSuffix('=') ?? _it;
  }

  /// Returns the underlying [String] value, explicitly.
  String get asString => _it;

  bool get isPrivate => _it.startsWith('_');

  void write(BufferedSink sink) {
    sink.writeStringUtf8(_it);
  }

  static int compare(LookupName left, LookupName right) {
    return left._it.compareTo(right._it);
  }
}

extension on LinkedElementFactory {
  /// Returns the id of [element], or `null` if from this bundle.
  ManifestItemId? getElementId(Element2 element) {
    // SAFETY: if we can reference the element, it has a name.
    var name = element.lookupName!.asLookupName;

    // SAFETY: if we can reference the element, it is in a library.
    var libraryUri = element.library2!.uri;

    // Prepare the external library manifest.
    var manifest = libraryManifests[libraryUri];
    if (manifest == null) {
      return null;
    }

    // SAFETY: every element is in the manifest of the declaring library.
    // TODO(scheglov): if we do null assert, it fails, investigate
    return manifest.items[name]?.id;
  }
}

extension on List<ManifestType> {
  bool match(_MatchContext context, List<DartType> types) {
    if (types.length != length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (!this[i].match(context, types[i])) {
        return false;
      }
    }
    return true;
  }
}

extension on ManifestType? {
  bool match(_MatchContext context, DartType? type) {
    var self = this;
    if (self == null || type == null) {
      return self == null && type == null;
    }
    return self.match(context, type);
  }
}

extension on Iterable<DartType> {
  List<ManifestType> encode(_EncodeContext context) {
    return map((type) => type.encode(context)).toFixedList();
  }
}

extension on String {
  LookupName get asLookupName {
    return LookupName(this);
  }
}

extension _DartTypeExtension on DartType {
  ManifestType encode(_EncodeContext context) {
    var type = this;
    switch (type) {
      case DynamicTypeImpl():
        return ManifestDynamicType.instance;
      case FunctionTypeImpl():
        return ManifestFunctionType.encode(context, type);
      case InterfaceTypeImpl():
        return ManifestInterfaceType.encode(context, type);
      case InvalidTypeImpl():
        return ManifestInvalidType.instance;
      case NeverTypeImpl():
        return ManifestNeverType.encode(context, type);
      case RecordTypeImpl():
        return ManifestRecordType.encode(context, type);
      case TypeParameterTypeImpl():
        return ManifestTypeParameterType.encode(context, type);
      case VoidTypeImpl():
        return ManifestVoidType.instance;
      default:
        throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }
}
