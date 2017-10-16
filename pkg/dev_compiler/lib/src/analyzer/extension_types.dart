// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, CompilationUnitElement, Element;
import 'package:analyzer/dart/element/type.dart' show DartType, InterfaceType;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;

/// Contains information about native JS types (those types provided by the
/// implementation) that are also provided by the Dart SDK.
///
/// For types provided by JavaScript, it is important that we don't add methods
/// directly to those types. Instead, we must call through a special set of
/// JS Symbol names, that are used for the "Dart extensions". For example:
///
///     // Dart
///     Iterable iter = myList;
///     print(iter.first);
///
///     // JS
///     let iter =  myLib.myList;
///     core.print(iter[dartx.first]);
///
/// This will provide the [Iterable.first] property, without needing to add
/// `first` to the `Array.prototype`.
class ExtensionTypeSet {
  final AnalysisContext _context;

  // Abstract types that may be implemented by both native and non-native
  // classes.
  final _extensibleTypes = new HashSet<ClassElement>();

  // Concrete native types.
  final _nativeTypes = new HashSet<ClassElement>();
  final _pendingLibraries = new HashSet<String>();

  ExtensionTypeSet(this._context) {
    // TODO(vsm): Eventually, we want to make this extensible - i.e., find
    // annotations in user code as well.  It would need to be summarized in
    // the element model - not searched this way on every compile.  To make this
    // a little more efficient now, we do this in two phases.

    // First, core types:
    // TODO(vsm): If we're analyzing against the main SDK, those
    // types are not explicitly annotated.
    var types = _context.typeProvider;
    _extensibleTypes.add(types.objectType.element);
    _addExtensionType(types.intType, true);
    _addExtensionType(types.doubleType, true);
    _addExtensionType(types.boolType, true);
    _addExtensionType(types.stringType, true);
    _addExtensionTypes('dart:_interceptors');
    _addExtensionTypes('dart:_native_typed_data');

    // These are used natively by dart:html but also not annotated.
    _addExtensionTypesForLibrary('dart:core', ['Comparable', 'Map']);
    _addExtensionTypesForLibrary('dart:collection', ['ListMixin']);
    _addExtensionTypesForLibrary('dart:math', ['Rectangle']);

    // Second, html types - these are only searched if we use dart:html, etc.:
    _addPendingExtensionTypes('dart:html');
    _addPendingExtensionTypes('dart:indexed_db');
    _addPendingExtensionTypes('dart:svg');
    _addPendingExtensionTypes('dart:web_audio');
    _addPendingExtensionTypes('dart:web_gl');
    _addPendingExtensionTypes('dart:web_sql');
  }

  void _visitCompilationUnit(CompilationUnitElement unit) {
    unit.types.forEach(_visitClass);
  }

  void _visitClass(ClassElement element) {
    if (_isNative(element)) {
      _addExtensionType(element.type, true);
    }
  }

  bool _isNative(ClassElement element) {
    for (var metadata in element.metadata) {
      var e = metadata.element?.enclosingElement;
      if (e.name == 'Native' || e.name == 'JsPeerInterface') {
        if (e.source.isInSystemLibrary) return true;
      }
    }
    return false;
  }

  void _addExtensionType(InterfaceType t, [bool mustBeNative = false]) {
    if (t.isObject) return;
    var element = t.element;
    if (_extensibleTypes.contains(element) || _nativeTypes.contains(element)) {
      return;
    }
    bool isNative = mustBeNative || _isNative(element);
    if (isNative) {
      _nativeTypes.add(element);
    } else {
      _extensibleTypes.add(element);
    }
    element.interfaces.forEach(_addExtensionType);
    element.mixins.forEach(_addExtensionType);
    _addExtensionType(element.supertype);
  }

  void _addExtensionTypesForLibrary(String libraryUri, List<String> typeNames) {
    var sourceFactory = _context.sourceFactory.forUri(libraryUri);
    var library = _context.computeLibraryElement(sourceFactory);
    for (var typeName in typeNames) {
      _addExtensionType(library.getType(typeName).type);
    }
  }

  void _addExtensionTypes(String libraryUri) {
    var sourceFactory = _context.sourceFactory.forUri(libraryUri);
    var library = _context.computeLibraryElement(sourceFactory);
    _visitCompilationUnit(library.definingCompilationUnit);
    library.parts.forEach(_visitCompilationUnit);
  }

  void _addPendingExtensionTypes(String libraryUri) {
    _pendingLibraries.add(libraryUri);
  }

  bool _processPending(Element element) {
    if (_pendingLibraries.isEmpty) return false;
    if (element is ClassElement) {
      var uri = element.library.source.uri.toString();
      if (_pendingLibraries.contains(uri)) {
        // Load all pending libraries
        _pendingLibraries.forEach(_addExtensionTypes);
        _pendingLibraries.clear();
        return true;
      }
    }
    return false;
  }

  bool _setContains(HashSet<ClassElement> set, Element element) {
    return set.contains(element) ||
        _processPending(element) && set.contains(element);
  }

  bool isNativeClass(Element element) => _setContains(_nativeTypes, element);

  bool isNativeInterface(Element element) =>
      _setContains(_extensibleTypes, element);

  bool hasNativeSubtype(DartType type) =>
      isNativeInterface(type.element) || isNativeClass(type.element);
}
