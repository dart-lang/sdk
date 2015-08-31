// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.program_builder;

/// Maps [LibraryElement]s to their [Element]s.
///
/// Fundamentally, this class nicely encapsulates a
/// `Map<LibraryElement, List<Element>>`.
///
/// There exists exactly one instance per [OutputUnit].
class LibrariesMap {
  final Map<LibraryElement, List<Element>> _mapping =
      <LibraryElement, List<Element>>{};

  // It is very common to access the same library multiple times in a row, so
  // we cache the last access.
  LibraryElement _lastLibrary;
  List<Element> _lastElements;

  /// A unique name representing this instance.
  final String name;
  final OutputUnit outputUnit;

  LibrariesMap.main(this.outputUnit) : name = "";

  LibrariesMap.deferred(this.outputUnit, this.name) {
    assert(name != "");
  }

  void add(LibraryElement library, Element element) {
    if (_lastLibrary != library) {
      _lastLibrary = library;
      _lastElements = _mapping.putIfAbsent(library, () => <Element>[]);
    }
    _lastElements.add(element);
  }

  int get length => _mapping.length;

  void forEach(void f(LibraryElement library, List<Element> elements)) {
    _mapping.forEach(f);
  }
}

/// Keeps track of all elements and holders.
///
/// This class assigns each registered element to its [LibrariesMap] (which are
/// in bijection with [OutputUnit]s).
///
/// Registered holders are assigned a name.
class Registry {
  final Compiler _compiler;
  final Map<String, Holder> _holdersMap = <String, Holder>{};
  final Map<OutputUnit, LibrariesMap> _deferredLibrariesMap =
      <OutputUnit, LibrariesMap>{};

  /// Cache for the last seen output unit.
  OutputUnit _lastOutputUnit;
  LibrariesMap _lastLibrariesMap;

  DeferredLoadTask get _deferredLoadTask => _compiler.deferredLoadTask;
  Iterable<Holder> get holders => _holdersMap.values;
  Iterable<LibrariesMap> get deferredLibrariesMap =>
      _deferredLibrariesMap.values;

  // Add one for the main libraries map.
  int get librariesMapCount => _deferredLibrariesMap.length + 1;

  LibrariesMap mainLibrariesMap;

  Registry(this._compiler);

  OutputUnit get _mainOutputUnit => _deferredLoadTask.mainOutputUnit;

  LibrariesMap _mapUnitToLibrariesMap(OutputUnit targetUnit) {
    if (targetUnit == _lastOutputUnit) return _lastLibrariesMap;

    LibrariesMap result = (targetUnit == _mainOutputUnit)
        ? mainLibrariesMap
        : _deferredLibrariesMap[targetUnit];

    assert(result != null);
    _lastOutputUnit = targetUnit;
    _lastLibrariesMap = result;
    return result;
  }

  void registerOutputUnit(OutputUnit outputUnit) {
    if (outputUnit == _mainOutputUnit) {
      assert(mainLibrariesMap == null);
      mainLibrariesMap =
          new LibrariesMap.main(_deferredLoadTask.mainOutputUnit);
    } else {
      assert(!_deferredLibrariesMap.containsKey(outputUnit));
      String name = outputUnit.name;
      _deferredLibrariesMap[outputUnit] =
          new LibrariesMap.deferred(outputUnit, name);
    }
  }

  /// Adds all elements to their respective libraries in the correct
  /// libraries map.
  void registerElements(OutputUnit outputUnit, Iterable<Element> elements) {
    LibrariesMap targetLibrariesMap = _mapUnitToLibrariesMap(outputUnit);
    for (Element element in Elements.sortedByPosition(elements)) {
      targetLibrariesMap.add(element.library, element);
    }
  }

  void registerConstant(OutputUnit outputUnit, ConstantValue constantValue) {
    // Ignore for now.
  }

  Holder registerHolder(
      String name,
      {bool isStaticStateHolder: false, bool isConstantsHolder: false}) {
    assert(_holdersMap[name] == null ||
        (_holdersMap[name].isStaticStateHolder == isStaticStateHolder &&
         _holdersMap[name].isConstantsHolder == isConstantsHolder));

    return _holdersMap.putIfAbsent(name, () {
      return new Holder(name, _holdersMap.length,
          isStaticStateHolder: isStaticStateHolder,
          isConstantsHolder: isConstantsHolder);
    });
  }
}
