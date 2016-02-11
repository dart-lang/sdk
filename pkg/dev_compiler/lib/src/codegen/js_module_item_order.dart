// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashMap;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import '../compiler.dart' show corelibOrder;

typedef void ModuleItemEmitter(AstNode item);

/// Helper that tracks order of elements visited by the compiler, detecting
/// if the top level item can be loaded eagerly or not.
class ModuleItemLoadOrder {
  /// The order that elements should be emitted in, with a bit indicating if
  /// the element should be generated lazily. The value will be `false` if
  /// the item could not be loaded, and needs to be made lazy.
  ///
  /// The order will match the original source order, unless something needed to
  /// be moved sooner to satisfy dependencies.
  ///
  /// Sometimes it's impossible to ensure an ordering when confronting library
  /// cycles. In that case, we mark the definition as lazy.
  final _loaded = new Map<Element, bool>();

  final _declarationNodes = new HashMap<Element, AstNode>();

  /// The stack of currently emitting elements, if generating top-level code
  /// for them. This is not used when inside method bodies, because order does
  /// not matter for those.
  final _topLevelElements = new List<Element>();

  /// The current element being loaded.
  /// We can use this to determine if we're loading top-level code or not:
  ///
  ///     _currentElements.last == _topLevelElements.last
  final _currentElements = new List<Element>();

  /// Memoized results of [_inLibraryCycle].
  final _libraryCycleMemo = new HashMap<LibraryElement, bool>();

  bool _checkReferences;

  final ModuleItemEmitter _emitModuleItem;

  LibraryElement _currentLibrary;

  ModuleItemLoadOrder(this._emitModuleItem);

  bool isLoaded(Element e) => (e.library == _currentLibrary)
      ? _loaded[e] == true
      : libraryIsLoaded(e.library);

  /// True if the element is currently being loaded.
  bool _isLoading(Element e) => _currentElements.contains(e);

  /// Collect top-level elements and nodes we need to emit.
  void collectElements(
      LibraryElement library, Iterable<CompilationUnit> partsThenLibrary) {
    assert(_currentLibrary == null);
    _currentLibrary = library;

    for (var unit in partsThenLibrary) {
      for (var decl in unit.declarations) {
        _declarationNodes[decl.element] = decl;

        if (decl is TopLevelVariableDeclaration) {
          _collectElementsForVariable(decl.variables);
        }
      }
    }
  }

  void _collectElementsForVariable(VariableDeclarationList fields) {
    for (var field in fields.variables) {
      _declarationNodes[field.element] = field;
    }
  }

  /// Start generating top-level code for the element [e].
  /// Subsequent [loadElement] calls will cause those elements to be generated
  /// before this one, until [finishElement] is called.
  void startTopLevel(Element e) {
    assert(isCurrentElement(e));
    _topLevelElements.add(e);
  }

  /// Finishes the top-level code for the element [e].
  void finishTopLevel(Element e) {
    var last = _topLevelElements.removeLast();
    assert(identical(e, last));
  }

  /// Starts recording calls to [declareBeforeUse], until
  /// [finishCheckingReferences] is called.
  void startCheckingReferences() {
    // This function should not be reentrant, and we should not current be
    // emitting top-level code.
    assert(_checkReferences == null);
    assert(
        _topLevelElements.isEmpty || !isCurrentElement(_topLevelElements.last));
    // Assume true until proven otherwise
    _checkReferences = true;
  }

  /// Finishes recording references, and returns `true` if all referenced
  /// items were loaded (or if no items were referenced).
  bool finishCheckingReferences() {
    var result = _checkReferences;
    _checkReferences = null;
    return result;
  }

  // Starts generating code for the declaration element [e].
  //
  // Normally this is called implicitly by [loadDeclaration] and/or
  // [loadElement]. However, for synthetic elements (like temporary variables)
  // it must be called explicitly, and paired with a call to [finishElement].
  void startDeclaration(Element e) {
    // Assume load will succeed until proven otherwise.
    _loaded[e] = true;
    _currentElements.add(e);
  }

  /// Returns true if all dependencies were loaded successfully.
  bool finishDeclaration(Element e) {
    var last = _currentElements.removeLast();
    assert(identical(e, last));
    return _loaded[e];
  }

  /// Loads a top-level declaration. This is similar to [loadElement], but it
  /// ensures we always visit the node if it has not been emitted yet. In other
  /// words, it handles nodes that do not need dependency resolution like
  /// top-level functions.
  bool loadDeclaration(AstNode node, Element e) {
    assert(e.library == _currentLibrary);

    // If we already tried to load it, see if we succeeded or not.
    // Otherwise try and load now.
    var loaded = _loaded[e];
    if (loaded != null) return loaded;

    // Otherwise, try to load it.
    startDeclaration(e);
    _emitModuleItem(node);
    return finishDeclaration(e);
  }

  bool isCurrentElement(Element e) =>
      _currentElements.isNotEmpty && identical(e, _currentElements.last);

  /// To emit top-level module items, we sometimes need to reorder them.
  ///
  /// This function takes care of that, and also detects cases where reordering
  /// failed, and we need to resort to lazy loading, by marking the element as
  /// lazy. All elements need to be aware of this possibility and generate code
  /// accordingly.
  ///
  /// If we are not emitting top-level code, this does nothing, because all
  /// declarations are assumed to be available before we start execution.
  /// See [startTopLevel].
  void declareBeforeUse(Element e) {
    if (e == null) return;

    if (_checkReferences != null) {
      _checkReferences = _checkReferences && isLoaded(e) && !_isLoading(e);
      return;
    }

    if (_topLevelElements.isEmpty ||
        !isCurrentElement(_topLevelElements.last)) {
      return;
    }

    // If the item is from our library, try to emit it now.
    bool loaded;
    if (e.library == _currentLibrary) {
      // Type parameters are not in scope when generating hoisted fields.
      if (e is TypeParameterElement &&
          _currentElements.last is VariableElement) {
        loaded = false;
      } else {
        var node = _declarationNodes[e];
        loaded = node == null || loadDeclaration(node, e);
      }
    } else {
      // We can't force things from other libraries to be emitted in a different
      // order. Instead, we see if the library itself can be loaded before the
      // current library. Generally that is possible, unless we have cyclic
      // imports.
      loaded = libraryIsLoaded(e.library);
    }

    if (loaded) return;

    // If we failed to emit it, then we need to make sure all currently emitting
    // elements are generated in a lazy way.
    for (var current in _topLevelElements) {
      // TODO(jmesserly): if we want to log what triggered laziness, this is
      // the place to do so.
      _loaded[current] = false;
    }
  }

  bool libraryIsLoaded(LibraryElement library) {
    assert(library != _currentLibrary);

    // DynamicElementImpl has no library.
    if (library == null) return true;

    // The SDK is a special case: we optimize the order to prevent laziness.
    if (_isDartUri(library)) {
      // SDK is loaded before non-SDK libraries
      if (!_isDartUri(_currentLibrary)) return true;

      // Compute the order of both SDK libraries. If unknown, assume it's after.
      var order = corelibOrder.indexOf(library.source.uri);
      if (order == -1) order = corelibOrder.length;

      var currentOrder = corelibOrder.indexOf(_currentLibrary.source.uri);
      if (currentOrder == -1) currentOrder = corelibOrder.length;

      // If the dart:* library we are currently compiling is loaded after the
      // class's library, then we know the class is available.
      if (order != currentOrder) return currentOrder > order;

      // If we don't know the order of the class's library or the current
      // library, do the normal cycle check. (Not all SDK libs are cycles.)
    }

    return !_inLibraryCycle(library);
  }

  /// Returns true if [library] depends on the [currentLibrary] via some
  /// transitive import.
  bool _inLibraryCycle(LibraryElement library) {
    // SDK libs don't depend on things outside the SDK.
    // (We can reach this via the recursive call below.)
    if (_isDartUri(library) && !_isDartUri(_currentLibrary)) return false;

    var result = _libraryCycleMemo[library];
    if (result != null) return result;

    result = library == _currentLibrary;
    _libraryCycleMemo[library] = result;
    for (var e in library.imports) {
      if (result) break;
      result = _inLibraryCycle(e.importedLibrary);
    }
    for (var e in library.exports) {
      if (result) break;
      result = _inLibraryCycle(e.exportedLibrary);
    }
    return _libraryCycleMemo[library] = result;
  }

  /// Returns whether this is a library imported with 'dart:' URI.
  ///
  /// This is similar to [LibraryElement.isInSdk], but checking the URI instead
  /// of the library naming convention, because the URI is reliable.
  static bool _isDartUri(LibraryElement e) => e.source.uri.scheme == 'dart';
}
