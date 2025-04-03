// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:collection/collection.dart';

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

  void write(BufferedSink sink) {
    sink.writeUri(uri);
    sink.writeMap(
      items,
      writeKey: (lookupName) => lookupName.write(sink),
      writeValue: (item) => item.write(sink),
    );
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

  /// Key: an element from [inputLibraries].
  /// Value: the item from [inputManifests].
  ///
  /// We attempt to reuse the same item, mostly importantly its ID.
  ///
  /// It is filled initially during matching element structures.
  /// Then we remove those that affected by changed elements.
  final Map<Element2, ManifestItem> itemMap = Map.identity();

  /// The new manifests for libraries.
  final Map<Uri, LibraryManifest> newManifests = {};

  LibraryManifestBuilder({
    required this.elementFactory,
    required this.inputLibraries,
    required this.inputManifests,
  }) {
    libraryElements = inputLibraries.map((kind) {
      return elementFactory.libraryOfUri2(kind.file.uri);
    }).toList(growable: false);
  }

  Map<Uri, LibraryManifest> computeManifests({
    required OperationPerformanceImpl performance,
  }) {
    performance.getDataInt('libraryCount').add(inputLibraries.length);

    _fillItemMapFromInputManifests(
      performance: performance,
    );

    _buildManifests();
    _addReExports();
    assert(_assertSerialization());

    return newManifests;
  }

  void _addClass({
    required EncodeContext encodingContext,
    required Map<LookupName, TopLevelItem> newItems,
    required ClassElementImpl2 element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return ClassItem.fromElement(
        name: lookupName,
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    newItems[lookupName] = item;

    var classItem = item;
    encodingContext.withTypeParameters(
      element.typeParameters2,
      (typeParameters) {
        classItem.members.clear();
        _addStaticExecutables(
          encodingContext: encodingContext,
          instanceElement: element,
          interfaceItem: classItem,
        );
        _addInstanceExecutables(
          encodingContext: encodingContext,
          element: element,
          classItem: classItem,
        );
      },
    );
  }

  void _addInstanceExecutable({
    required EncodeContext encodingContext,
    required ClassItem instanceItem,
    required Name nameObj,
    required ExecutableElement2OrMember element,
  }) {
    var lookupName = nameObj.name.asLookupName;

    switch (element) {
      case GetterElement2OrMember():
        _addInstanceGetter(
          encodingContext: encodingContext,
          instanceItem: instanceItem,
          element: element,
          lookupName: lookupName,
        );
      case MethodElement2OrMember():
        _addInstanceMethod(
          encodingContext: encodingContext,
          instanceItem: instanceItem,
          element: element,
          lookupName: lookupName,
        );
      // TODO(scheglov): add setters support
    }
  }

  void _addInstanceExecutables({
    required EncodeContext encodingContext,
    required ClassElementImpl2 element,
    required ClassItem classItem,
  }) {
    var map = element.inheritanceManager.getInterface2(element).map2;
    for (var entry in map.entries) {
      _addInstanceExecutable(
        encodingContext: encodingContext,
        instanceItem: classItem,
        nameObj: entry.key,
        element: entry.value,
      );
    }
  }

  void _addInstanceGetter({
    required EncodeContext encodingContext,
    required ClassItem instanceItem,
    required GetterElement2OrMember element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return InstanceGetterItem.fromElement(
        name: lookupName,
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    instanceItem.members[lookupName] = item;
  }

  void _addInstanceMethod({
    required EncodeContext encodingContext,
    required ClassItem instanceItem,
    required MethodElement2OrMember element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return InstanceMethodItem.fromElement(
        name: lookupName,
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    instanceItem.members[lookupName] = item;
  }

  void _addInterfaceConstructor({
    required EncodeContext encodingContext,
    required ClassItem interfaceItem,
    required ConstructorElementImpl2 element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return InterfaceConstructorItem.fromElement(
        name: lookupName,
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    interfaceItem.members[lookupName] = item;
  }

  void _addReExports() {
    for (var libraryElement in libraryElements) {
      var libraryUri = libraryElement.uri;
      var manifest = newManifests[libraryUri]!;

      for (var entry in libraryElement.exportNamespace.definedNames2.entries) {
        var name = entry.key.asLookupName;
        var element = entry.value;

        // Skip elements that exist in nowhere.
        var elementLibraryUri = element.library2?.uri;
        if (elementLibraryUri == null) {
          continue;
        }

        // Skip if the element is declared in this library.
        if (element.library2 == libraryElement) {
          continue;
        }

        var id = elementFactory.getElementId(element) ??
            newManifests[elementLibraryUri]?.items[name]?.id;
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
    }
  }

  void _addStaticExecutables({
    required EncodeContext encodingContext,
    required InstanceElementImpl2 instanceElement,
    required ClassItem interfaceItem,
  }) {
    if (instanceElement is InterfaceElementImpl2) {
      for (var constructor in instanceElement.constructors2) {
        var lookupName = constructor.name3?.asLookupName;
        if (lookupName != null) {
          _addInterfaceConstructor(
            encodingContext: encodingContext,
            interfaceItem: interfaceItem,
            element: constructor,
            lookupName: lookupName,
          );
        }
      }
    }

    for (var getter in instanceElement.getters2) {
      if (getter.isStatic) {
        var lookupName = getter.name3?.asLookupName;
        if (lookupName != null) {
          _addInstanceGetter(
            encodingContext: encodingContext,
            instanceItem: interfaceItem,
            element: getter,
            lookupName: lookupName,
          );
        }
      }
    }

    for (var method in instanceElement.methods2) {
      if (method.isStatic) {
        var lookupName = method.name3?.asLookupName;
        if (lookupName != null) {
          _addInstanceMethod(
            encodingContext: encodingContext,
            instanceItem: interfaceItem,
            element: method,
            lookupName: lookupName,
          );
        }
      }
    }
  }

  void _addTopLevelFunction({
    required EncodeContext encodingContext,
    required Map<LookupName, TopLevelItem> newItems,
    required TopLevelFunctionElementImpl element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return TopLevelFunctionItem.fromElement(
        name: lookupName,
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    newItems[lookupName] = item;
  }

  void _addTopLevelGetter({
    required EncodeContext encodingContext,
    required Map<LookupName, TopLevelItem> newItems,
    required GetterElementImpl element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return TopLevelGetterItem.fromElement(
        name: lookupName,
        id: ManifestItemId.generate(),
        context: encodingContext,
        element: element,
      );
    });
    newItems[lookupName] = item;
  }

  void _addTopLevelSetter({
    required EncodeContext encodingContext,
    required Map<LookupName, TopLevelItem> newItems,
    required SetterElementImpl element,
    required LookupName lookupName,
  }) {
    var item = _getOrBuildElementItem(element, () {
      return TopLevelSetterItem.fromElement(
        name: lookupName,
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
    Uint8List manifestAsBytes(LibraryManifest manifest) {
      var byteSink = BufferedSink();
      manifest.write(byteSink);
      return byteSink.takeBytes();
    }

    newManifests.forEach((uri, manifest) {
      var bytes = manifestAsBytes(manifest);

      var readManifest = LibraryManifest.read(
        SummaryDataReader(bytes),
      );
      var readBytes = manifestAsBytes(readManifest);

      if (!const ListEquality<int>().equals(bytes, readBytes)) {
        throw StateError('Library manifest bytes are different: $uri');
      }
    });

    return true;
  }

  /// Fill `result` with new library manifests.
  /// We reuse existing items when they fully match.
  /// We build new items for mismatched elements.
  Map<Uri, LibraryManifest> _buildManifests() {
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
            _addClass(
              encodingContext: encodingContext,
              newItems: newItems,
              element: element,
              lookupName: lookupName,
            );
          case GetterElementImpl():
            _addTopLevelGetter(
              encodingContext: encodingContext,
              newItems: newItems,
              element: element,
              lookupName: lookupName,
            );
          case SetterElementImpl():
            _addTopLevelSetter(
              encodingContext: encodingContext,
              newItems: newItems,
              element: element,
              lookupName: lookupName,
            );
          case TopLevelFunctionElementImpl():
            _addTopLevelFunction(
              encodingContext: encodingContext,
              newItems: newItems,
              element: element,
              lookupName: lookupName,
            );
          // TODO(scheglov): add remaining elements
        }
      }

      var newManifest = LibraryManifest(
        uri: libraryUri,
        items: newItems,
      );
      libraryElement.manifest = newManifest;
      newManifests[libraryUri] = newManifest;
    }

    return newManifests;
  }

  void _fillItemMapFromInputManifests({
    required OperationPerformanceImpl performance,
  }) {
    // Compare structures of the elements against the existing manifests.
    // At the end `affectedElements` is filled with mismatched by structure.
    // And for matched by structure we have reference maps.
    var refElementsMap = Map<Element2, List<Element2>>.identity();
    var refExternalIds = Map<Element2, ManifestItemId>.identity();
    var affectedElements = Set<Element2>.identity();
    for (var libraryElement in libraryElements) {
      var libraryUri = libraryElement.uri;
      var manifest = _getInputManifest(libraryUri);
      _LibraryMatch(
        manifest: manifest,
        library: libraryElement,
        itemMap: itemMap,
        structureMismatched: affectedElements,
        refElementsMap: refElementsMap,
        refExternalIds: refExternalIds,
      ).compareStructures();
    }

    performance
      ..getDataInt('structureMatchedCount').add(itemMap.length)
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
  }

  /// Returns the manifest from [inputManifests], empty if absent.
  LibraryManifest _getInputManifest(Uri uri) {
    return inputManifests[uri] ?? LibraryManifest(uri: uri, items: {});
  }

  /// Returns either the existing item from [itemMap], or builds a new one.
  Item _getOrBuildElementItem<Element extends Element2,
      Item extends ManifestItem>(
    Element element,
    Item Function() build,
  ) {
    // We assume that when matching elements against the structure of
    // the item, we put into [itemMap] only the type of the item that
    // corresponds the type of the element.
    var item = itemMap[element] as Item?;
    if (item == null) {
      item = build();
      // To reuse items for inherited members.
      itemMap[element] = item;
    }
    return item;
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
  final Map<Element2, ManifestItem> itemMap;

  /// Elements with mismatched structure.
  /// These elements will get new identifiers.
  final Set<Element2> structureMismatched;

  /// Key: an element of [library].
  /// Value: the elements that the key references.
  ///
  /// This includes references to elements of this bundle, and of external
  /// bundles. This information allows propagating invalidation from affected
  /// elements to their dependents.
  // TODO(scheglov): hm... maybe store it? And reverse it.
  final Map<Element2, List<Element2>> refElementsMap;

  /// Key: an element from an external bundle.
  /// Value: the identifier at the time when [manifest] was built.
  ///
  /// If [LibraryManifestBuilder] later finds that some of these elements now
  /// have different identifiers, it propagates invalidation using
  /// [refElementsMap].
  final Map<Element2, ManifestItemId> refExternalIds;

  _LibraryMatch({
    required this.manifest,
    required this.library,
    required this.itemMap,
    required this.refElementsMap,
    required this.refExternalIds,
    required this.structureMismatched,
  });

  void compareStructures() {
    for (var element in library.children2) {
      var name = element.lookupName?.asLookupName;
      switch (element) {
        case ClassElementImpl2():
          if (!_matchClass(name: name, element: element)) {
            structureMismatched.add(element);
          }
        case GetterElementImpl():
          if (!_matchTopGetter(name: name, element: element)) {
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
      }
    }
  }

  bool _matchClass({
    required LookupName? name,
    required ClassElementImpl2 element,
  }) {
    var item = manifest.items[name];
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

    _matchInterfaceConstructors(
      matchContext: matchContext,
      interfaceElement: element,
      item: item,
    );
    _matchStaticExecutables(
      matchContext: matchContext,
      element: element,
      item: item,
    );

    _matchInstanceExecutables(
      matchContext: matchContext,
      element: element,
      item: item,
    );

    return true;
  }

  bool _matchInstanceExecutable({
    required MatchContext interfaceMatchContext,
    required Map<LookupName, InstanceMemberItem> members,
    required LookupName lookupName,
    required ExecutableElement2 executable,
  }) {
    var item = members[lookupName];

    switch (executable) {
      case GetterElement2OrMember():
        if (item is! InstanceGetterItem) {
          return false;
        }

        var matchContext = item.match(interfaceMatchContext, executable);
        if (matchContext == null) {
          return false;
        }

        itemMap[executable] = item;
        refElementsMap[executable] = matchContext.elementList;
        refExternalIds.addAll(matchContext.externalIds);
        return true;
      case MethodElement2OrMember():
        if (item is! InstanceMethodItem) {
          return false;
        }

        var matchContext = item.match(interfaceMatchContext, executable);
        if (matchContext == null) {
          return false;
        }

        itemMap[executable] = item;
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

  void _matchInstanceExecutables({
    required MatchContext matchContext,
    required ClassElementImpl2 element,
    required ClassItem item,
  }) {
    var map = element.inheritanceManager.getInterface2(element).map2;
    for (var entry in map.entries) {
      var nameObj = entry.key;
      var executable = entry.value;
      if (!_matchInstanceExecutable(
        interfaceMatchContext: matchContext,
        members: item.members,
        lookupName: nameObj.name.asLookupName,
        executable: executable,
      )) {
        structureMismatched.add(executable);
      }
    }
  }

  bool _matchInterfaceConstructor({
    required MatchContext interfaceMatchContext,
    required Map<LookupName, InstanceMemberItem> members,
    required ConstructorElementImpl2 element,
  }) {
    var lookupName = element.name3?.asLookupName;
    if (lookupName == null) {
      return false;
    }

    var item = members[lookupName];
    if (item is! InterfaceConstructorItem) {
      return false;
    }

    var matchContext = item.match(interfaceMatchContext, element);
    if (matchContext == null) {
      return false;
    }

    itemMap[element] = item;
    refElementsMap[element] = matchContext.elementList;
    refExternalIds.addAll(matchContext.externalIds);
    return true;
  }

  void _matchInterfaceConstructors({
    required MatchContext matchContext,
    required ClassElementImpl2 interfaceElement,
    required ClassItem item,
  }) {
    for (var constructor in interfaceElement.constructors2) {
      if (!_matchInterfaceConstructor(
        interfaceMatchContext: matchContext,
        members: item.members,
        element: constructor,
      )) {
        structureMismatched.add(constructor);
      }
    }
  }

  void _matchStaticExecutables({
    required MatchContext matchContext,
    required ClassElementImpl2 element,
    required ClassItem item,
  }) {
    // TODO(scheglov): it looks that we repeat iterations
    // We do it for structural matching, and then for adding.
    for (var getters in element.getters2) {
      if (getters.isStatic) {
        var lookupName = getters.name3?.asLookupName;
        if (lookupName != null) {
          if (!_matchInstanceExecutable(
            interfaceMatchContext: matchContext,
            members: item.members,
            lookupName: lookupName,
            executable: getters,
          )) {
            structureMismatched.add(getters);
          }
        }
      }
    }

    for (var method in element.methods2) {
      if (method.isStatic) {
        var lookupName = method.name3?.asLookupName;
        if (lookupName != null) {
          if (!_matchInstanceExecutable(
            interfaceMatchContext: matchContext,
            members: item.members,
            lookupName: lookupName,
            executable: method,
          )) {
            structureMismatched.add(method);
          }
        }
      }
    }
  }

  bool _matchTopFunction({
    required LookupName? name,
    required TopLevelFunctionElementImpl element,
  }) {
    var item = manifest.items[name];
    if (item is! TopLevelFunctionItem) {
      return false;
    }

    var matchContext = item.match(element);
    if (matchContext == null) {
      return false;
    }

    // TODO(scheglov): it looks that this code is repeating
    itemMap[element] = item;
    refElementsMap[element] = matchContext.elementList;
    refExternalIds.addAll(matchContext.externalIds);
    return true;
  }

  bool _matchTopGetter({
    required LookupName? name,
    required GetterElementImpl element,
  }) {
    var item = manifest.items[name];
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

  bool _matchTopSetter({
    required LookupName? name,
    required SetterElementImpl element,
  }) {
    var item = manifest.items[name];
    if (item is! TopLevelSetterItem) {
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
}
