// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.program_builder;

class LibraryContents {
  final List<ClassEntity> classes = <ClassEntity>[];
  final List<MemberEntity> members = <MemberEntity>[];
}

/// Maps [LibraryEntity]s to their [ClassEntity]s and [MemberEntity]s.
///
/// Fundamentally, this class nicely encapsulates a
/// `Map<LibraryElement, Pair<List<ClassElement>, List<MemberElement>>>`.
///
/// There exists exactly one instance per [OutputUnit].
class LibrariesMap {
  final Map<LibraryEntity, LibraryContents> _mapping =
      <LibraryEntity, LibraryContents>{};

  // It is very common to access the same library multiple times in a row, so
  // we cache the last access.
  LibraryEntity _lastLibrary;
  LibraryContents _lastMapping;

  /// A unique name representing this instance.
  final String name;
  final OutputUnit outputUnit;

  LibrariesMap.main(this.outputUnit) : name = "";

  LibrariesMap.deferred(this.outputUnit, this.name) {
    assert(name != "");
  }

  LibraryContents _getMapping(LibraryEntity library) {
    if (_lastLibrary != library) {
      _lastLibrary = library;
      _lastMapping = _mapping.putIfAbsent(library, () => new LibraryContents());
    }
    return _lastMapping;
  }

  void addClass(LibraryEntity library, ClassEntity element) {
    _getMapping(library).classes.add(element);
  }

  void addMember(LibraryEntity library, MemberEntity element) {
    _getMapping(library).members.add(element);
  }

  int get length => _mapping.length;

  void forEach(
      void f(LibraryEntity library, List<ClassEntity> classes,
          List<MemberEntity> members)) {
    _mapping.forEach((LibraryEntity library, LibraryContents mapping) {
      f(library, mapping.classes, mapping.members);
    });
  }
}

/// Keeps track of all elements and holders.
///
/// This class assigns each registered element to its [LibrariesMap] (which are
/// in bijection with [OutputUnit]s).
///
/// Registered holders are assigned a name.
class Registry {
  final DeferredLoadTask _deferredLoadTask;
  final Sorter _sorter;
  final Map<String, Holder> _holdersMap = <String, Holder>{};
  final Map<OutputUnit, LibrariesMap> _deferredLibrariesMap =
      <OutputUnit, LibrariesMap>{};

  /// Cache for the last seen output unit.
  OutputUnit _lastOutputUnit;
  LibrariesMap _lastLibrariesMap;

  Iterable<Holder> get holders => _holdersMap.values;
  Iterable<LibrariesMap> get deferredLibrariesMap =>
      _deferredLibrariesMap.values;

  // Add one for the main libraries map.
  int get librariesMapCount => _deferredLibrariesMap.length + 1;

  LibrariesMap mainLibrariesMap;

  Registry(this._deferredLoadTask, this._sorter);

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
  void registerClasses(OutputUnit outputUnit, Iterable<ClassEntity> elements) {
    LibrariesMap targetLibrariesMap = _mapUnitToLibrariesMap(outputUnit);
    for (ClassEntity element in _sorter.sortClasses(elements)) {
      targetLibrariesMap.addClass(element.library, element);
    }
  }

  /// Adds all elements to their respective libraries in the correct
  /// libraries map.
  void registerMembers(OutputUnit outputUnit, Iterable<MemberEntity> elements) {
    LibrariesMap targetLibrariesMap = _mapUnitToLibrariesMap(outputUnit);
    for (MemberEntity element in _sorter.sortMembers(elements)) {
      targetLibrariesMap.addMember(element.library, element);
    }
  }

  void registerConstant(OutputUnit outputUnit, ConstantValue constantValue) {
    // Ignore for now.
  }

  Holder registerHolder(String name,
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
