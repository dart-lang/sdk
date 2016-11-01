// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashMap;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:func/func.dart';
import '../js_ast/js_ast.dart' as JS;

/// Helper that tracks order of elements visited by the compiler, detecting
/// if the top level item can be loaded eagerly or not.
class ElementLoader {
  final HashMap<Element, AstNode> _declarationNodes;

  /// The stack of currently emitting elements, if generating top-level code
  /// for them. This is not used when inside method bodies, because order does
  /// not matter for those.
  final _topLevelElements = new List<Element>();

  /// The current element being loaded.
  /// We can use this to determine if we're loading top-level code or not:
  ///
  ///     _currentElements.last == _topLevelElements.last
  final _currentElements = new List<Element>();

  bool _checkReferences;

  ElementLoader(this._declarationNodes) {
    assert(!_declarationNodes.containsKey(null));
  }

  Element get currentElement => _currentElements.last;

  bool isLoaded(Element e) => !_declarationNodes.containsKey(e);

  /// True if the element is currently being loaded.
  bool _isLoading(Element e) => _currentElements.contains(e);

  /// Start generating top-level code for the element [e].
  ///
  /// Subsequent [emitDeclaration] calls will cause those elements to be
  /// generated before this one, until [finishTopLevel] is called.
  void startTopLevel(Element e) {
    assert(identical(e, currentElement));
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
    assert(_topLevelElements.isEmpty ||
        !identical(currentElement, _topLevelElements.last));
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

  /// Ensures a top-level declaration is generated, and returns `true` if it
  /// is part of the current module.
  /*=T*/ emitDeclaration/*<T extends JS.Node>*/(
      Element e, Func1<AstNode, JS.Node/*=T*/ > visit) {
    var node = _declarationNodes.remove(e);
    if (node == null) return null; // not from this module or already loaded.

    _currentElements.add(e);

    var result = visit(node);

    var last = _currentElements.removeLast();
    assert(identical(e, last));

    return result;
  }

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
  void declareBeforeUse(Element e, VoidFunc1<Element> emit) {
    if (e == null) return;

    if (_checkReferences != null) {
      _checkReferences = _checkReferences && isLoaded(e) && !_isLoading(e);
      return;
    }

    var topLevel = _topLevelElements;
    if (topLevel.isNotEmpty && identical(currentElement, topLevel.last)) {
      // If the item is from our library, try to emit it now.
      emit(e);
    }
  }
}
