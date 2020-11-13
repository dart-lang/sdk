// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:kernel/kernel.dart';
import 'kernel_helpers.dart';

/// Returns true if [library] is one of the [candidates].
/// The latter should be a list, e.g.,: ['dart:js', 'package:js'].
bool _isLibrary(Library library, List<String> candidates) {
  if (library == null) return false;
  var uri = library.importUri;
  var scheme = uri.scheme;
  var path = uri.pathSegments[0];
  for (var candidate in candidates) {
    var pair = candidate.split(':');
    if (scheme == pair[0] && (path == pair[1] || pair[1] == '*')) {
      return true;
    }
  }
  return false;
}

/// Returns true if [library] represents any library from `package:js` or is the
/// internal `dart:_js_helper` library.
bool _isJSLibrary(Library library) => _isLibrary(library, [
      'package:js',
      'dart:_js_helper',
      'dart:_foreign_helper',
      'dart:_js_annotations'
    ]);

/// Whether [node] is a direct call to `allowInterop`.
bool isAllowInterop(Expression node) {
  if (node is StaticInvocation) {
    var target = node.target;
    return _isLibrary(target.enclosingLibrary, ['dart:js']) &&
        target.name.text == 'allowInterop';
  }
  return false;
}

bool isJsMember(Member member) {
  // TODO(vsm): If we ever use external outside the SDK for non-JS interop,
  // we're need to fix this.
  return !_isLibrary(member.enclosingLibrary, ['dart:*']) && member.isExternal;
}

bool _annotationIsFromJSLibrary(String expectedName, Expression value) {
  var c = getAnnotationClass(value);
  return c != null &&
      c.name == expectedName &&
      _isJSLibrary(c.enclosingLibrary);
}

/// Whether [value] is a `@rest` annotation (to be used on function parameters
/// to have them compiled as `...` rest params in ES6 outputs).
bool isJsRestAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('_Rest', value);

// TODO(jmesserly): Move JsPeerInterface to package:js (see issue #135).
// TODO(jacobr): The 'JS' annotation is the new, publically accessible one.
// The 'JsName' annotation is the old one using internally by dart2js and
// html libraries.  These two concepts will probably merge eventually.
bool isJSAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('JS', value) || isJSName(value);

/// Returns [true] if [e] is the `JS` annotation from `package:js`.
bool isPublicJSAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('JS', value);

bool _isJSAnonymousAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('_Anonymous', value);

/// Whether [value] is a `@JSExportName` (internal annotation used in SDK
/// instead of `@JS` from `package:js`).
bool isJSExportNameAnnotation(Expression value) =>
    isBuiltinAnnotation(value, '_foreign_helper', 'JSExportName');

/// Whether [i] is a `spread` invocation (to be used on function arguments
/// to have them compiled as `...` spread args in ES6 outputs).
bool isJSSpreadInvocation(Procedure target) =>
    target.name.text == 'spread' && _isJSLibrary(target.enclosingLibrary);

bool isJSName(Expression value) =>
    isBuiltinAnnotation(value, '_js_helper', 'JSName');

bool isJsPeerInterface(Expression value) =>
    isBuiltinAnnotation(value, '_js_helper', 'JsPeerInterface');

bool isNativeAnnotation(Expression value) =>
    isBuiltinAnnotation(value, '_js_helper', 'Native');

bool isJSAnonymousType(Class namedClass) {
  var hasJSInterop = hasJSInteropAnnotation(namedClass);
  var isAnonymous =
      findAnnotation(namedClass, _isJSAnonymousAnnotation) != null;
  return hasJSInterop && isAnonymous;
}

bool isUndefinedAnnotation(Expression value) =>
    isBuiltinAnnotation(value, '_js_helper', '_Undefined');

/// Returns true iff the class has an `@JS(...)` annotation from `package:js`.
///
/// Note: usually [_usesJSInterop] should be used instead of this.
//
// TODO(jmesserly): I think almost all uses of this should be replaced with
// [_usesJSInterop], which also checks that the library is marked with `@JS`.
//
// Right now we have inconsistencies: sometimes we'll respect `@JS` on the
// class itself, other places we require it on the library. Also members are
// inconsistent: sometimes they need to have `@JS` on them, other times they
// need to be `external` in an `@JS` class.
bool hasJSInteropAnnotation(Class c) => c.annotations.any(isPublicJSAnnotation);

/// Returns true iff this element is a JS interop member.
///
/// The element's library must have `@JS(...)` annotation from `package:js`.
/// If the element is a class, it must also be marked with `@JS`. Other
/// elements, such as class members and top-level functions/accessors, should
/// be marked `external`.
bool usesJSInterop(NamedNode n) {
  var library = getLibrary(n);
  return library != null &&
      library.annotations.any(isPublicJSAnnotation) &&
      (n is Procedure && n.isExternal ||
          n is Class && n.annotations.any(isPublicJSAnnotation));
}
