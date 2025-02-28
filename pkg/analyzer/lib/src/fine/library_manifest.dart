// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

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
    var encodingContext = EncodeContext(
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

      requirementsManifest.addExportRequirements(libraryElement);
    }

    return result;
  }

  /// Returns the manifest from [inputLibraryManifests], empty if absent.
  LibraryManifest _getInputManifest(Uri uri) {
    return inputLibraryManifests[uri] ?? LibraryManifest(uri: uri, items: {});
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
      MatchContext interfaceMatchContext,
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
