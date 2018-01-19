// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart';

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
class NativeTypeSet {
  final CoreTypes coreTypes;
  final LibraryIndex sdk;

  // Abstract types that may be implemented by both native and non-native
  // classes.
  final _extensibleTypes = new HashSet<Class>.identity();

  // Concrete native types.
  final _nativeTypes = new HashSet<Class>.identity();
  final _pendingLibraries = new HashSet<Library>.identity();

  NativeTypeSet(Program program)
      : sdk = new LibraryIndex.coreLibraries(program),
        coreTypes = new CoreTypes(program) {
    // First, core types:
    // TODO(vsm): If we're analyzing against the main SDK, those
    // types are not explicitly annotated.
    _extensibleTypes.add(coreTypes.objectClass);
    _addExtensionType(coreTypes.intClass, true);
    _addExtensionType(coreTypes.doubleClass, true);
    _addExtensionType(coreTypes.boolClass, true);
    _addExtensionType(coreTypes.stringClass, true);
    _addExtensionTypes(sdk.getLibrary('dart:_interceptors'));
    _addExtensionTypes(sdk.getLibrary('dart:_native_typed_data'));

    // These are used natively by dart:html but also not annotated.
    _addExtensionTypesForLibrary('dart:core', ['Comparable', 'Map']);
    _addExtensionTypesForLibrary('dart:collection', ['ListMixin']);
    _addExtensionTypesForLibrary('dart:math', ['Rectangle']);

    // Second, html types - these are only searched if we use dart:html, etc.:
    _addPendingExtensionTypes(sdk.getLibrary('dart:html'));
    _addPendingExtensionTypes(sdk.getLibrary('dart:indexed_db'));
    _addPendingExtensionTypes(sdk.getLibrary('dart:svg'));
    _addPendingExtensionTypes(sdk.getLibrary('dart:web_audio'));
    _addPendingExtensionTypes(sdk.getLibrary('dart:web_gl'));
    _addPendingExtensionTypes(sdk.getLibrary('dart:web_sql'));
  }

  bool _isNative(Class c) {
    for (var annotation in c.annotations) {
      if (annotation is ConstructorInvocation) {
        var c = annotation.target.enclosingClass;
        if (c.name == 'Native' || c.name == 'JsPeerInterface') {
          if (c.enclosingLibrary.importUri.scheme == 'dart') return true;
        }
      }
    }
    return false;
  }

  void _addExtensionType(Class c, [bool mustBeNative = false]) {
    if (c == coreTypes.objectClass) return;
    if (_extensibleTypes.contains(c) || _nativeTypes.contains(c)) {
      return;
    }
    bool isNative = mustBeNative || _isNative(c);
    if (isNative) {
      _nativeTypes.add(c);
    } else {
      _extensibleTypes.add(c);
    }
    for (var s in c.supers) {
      _addExtensionType(s.classNode);
    }
  }

  void _addExtensionTypesForLibrary(String library, List<String> classNames) {
    for (var className in classNames) {
      _addExtensionType(sdk.getClass(library, className), true);
    }
  }

  void _addExtensionTypes(Library library) {
    for (var c in library.classes) {
      if (_isNative(c)) {
        _addExtensionType(c, true);
      }
    }
  }

  void _addPendingExtensionTypes(Library library) {
    _pendingLibraries.add(library);
  }

  bool _processPending(Class c) {
    var pending = _pendingLibraries;
    if (pending.isNotEmpty && pending.contains(c.enclosingLibrary)) {
      pending.forEach(_addExtensionTypes);
      pending.clear();
      return true;
    }
    return false;
  }

  bool isNativeClass(Class c) =>
      _nativeTypes.contains(c) ||
      _processPending(c) && _nativeTypes.contains(c);

  bool isNativeInterface(Class c) =>
      _extensibleTypes.contains(c) ||
      _processPending(c) && _extensibleTypes.contains(c);

  bool hasNativeSubtype(Class c) => isNativeInterface(c) || isNativeClass(c);
}
