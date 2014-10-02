// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.program_builder;

/// A Fragment maps [LibraryElement]s to their [Element]s.
///
/// Fundamentally, this class nicely encapsulates a
/// `Map<LibraryElement, List<Element>>`.
class Fragment {
  final Map<LibraryElement, List<Element>> _mapping =
      <LibraryElement, List<Element>>{};

  // It is very common to access the same library multiple times in a row, so
  // we cache the last access.
  LibraryElement _lastLibrary;
  List<Element> _lastElements;

  /// A unique name representing this fragment.
  final String name;
  final OutputUnit outputUnit;

  Fragment.main(this.outputUnit) : name = "";
  Fragment.deferred(this.outputUnit, this.name);

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
/// This class assigns each registered element to its [Fragment] (which are in
/// bijection with [OutputUnit]s).
///
/// Registered holders are assigned a name.
class Registry {
  final Compiler _compiler;
  final Map<String, Holder> _holdersMap = <String, Holder>{};
  final Map<OutputUnit, Fragment> _deferredFragmentsMap =
      <OutputUnit, Fragment>{};

  DeferredLoadTask get _deferredLoadTask => _compiler.deferredLoadTask;
  Iterable<Holder> get holders => _holdersMap.values;
  Iterable<Fragment> get deferredFragments => _deferredFragmentsMap.values;
  // Add one for the main fragment.
  int get fragmentCount => _deferredFragmentsMap.length + 1;

  Fragment mainFragment;

  Registry(this._compiler);

  bool get _isProgramSplit => _deferredLoadTask.isProgramSplit;
  OutputUnit get _mainOutputUnit => _deferredLoadTask.mainOutputUnit;

  Fragment _computeTargetFragment(Element element) {
    if (mainFragment == null) {
      mainFragment = new Fragment.main(_deferredLoadTask.mainOutputUnit);
    }
    if (!_isProgramSplit) return mainFragment;
    OutputUnit targetUnit = _deferredLoadTask.outputUnitForElement(element);
    if (targetUnit == _mainOutputUnit) return mainFragment;
    String name = targetUnit.name;
    return _deferredFragmentsMap.putIfAbsent(
        targetUnit, () => new Fragment.deferred(targetUnit, name));
  }

  /// Adds the element to the list of elements of the library in the right
  /// fragment.
  void registerElement(Element element) {
    _computeTargetFragment(element).add(element.library, element);
  }

  Holder registerHolder(String name) {
    return _holdersMap.putIfAbsent(
        name,
        () => new Holder(name, _holdersMap.length));
  }
}