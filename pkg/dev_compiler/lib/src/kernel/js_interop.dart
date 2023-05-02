// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';

import 'kernel_helpers.dart';

/// Returns true if [library] is one of the [candidates].
/// The latter should be a list, e.g.,: ['dart:js', 'dart:_js_annotations'].
bool _isLibrary(Library library, List<String> candidates) {
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

/// Returns true if [library] represents any library from `package:js`,
/// `dart:_foreign_helper`, `dart:_js_annotations`, or `dart:_js_helper`, or
/// `dart:js_interop`.
bool _isJSLibrary(Library library) => _isLibrary(library, [
      // While the annotations no longer live in `package:js`, this is needed to
      // support older versions of the package.
      'package:js',
      'dart:_foreign_helper',
      'dart:_js_annotations',
      'dart:_js_helper',
      // This is to allow `dart:js_interop`'s `@JS` to work with
      // `@staticInterop`.
      'dart:js_interop',
    ]);

/// Whether [node] is a direct call to `allowInterop`.
bool isAllowInterop(Expression node) {
  if (node is StaticInvocation) {
    var target = node.target;
    return _isLibrary(target.enclosingLibrary, ['dart:js_util']) &&
        target.name.text == 'allowInterop';
  }
  return false;
}

bool isJsMember(Member member) {
  // TODO(vsm): If we ever use external outside the SDK for non-JS interop,
  // we're need to fix this.
  return !_isLibrary(member.enclosingLibrary, ['dart:*']) &&
      member.isExternal &&
      !isNative(member);
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
// TODO(jacobr): The 'JS' annotation is the new, publicly accessible one.
// The 'JsName' annotation is the old one using internally by dart2js and
// html libraries.  These two concepts will probably merge eventually.
bool isJSAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('JS', value) || isJSName(value);

/// Returns [true] if [value] is the `JS` annotation from
/// `package:js`, `dart:_js_annotations`, or `dart:js_interop`.
bool isJSInteropAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('JS', value);

bool _isJSAnonymousAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('_Anonymous', value);

bool _isStaticInteropAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('_StaticInterop', value);

/// Whether [value] is a `@JSExportName` (internal annotation used in SDK
/// instead of `@JS` from `dart:_js_annotations`).
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

bool isStaticInteropType(Class namedClass) {
  var hasJSInterop = hasJSInteropAnnotation(namedClass);
  var isStaticInterop =
      findAnnotation(namedClass, _isStaticInteropAnnotation) != null;
  return hasJSInterop && isStaticInterop;
}

bool isUndefinedAnnotation(Expression value) =>
    isBuiltinAnnotation(value, '_js_helper', '_Undefined');

bool isObjectLiteralAnnotation(Expression value) {
  final c = getAnnotationClass(value);
  return c != null &&
      c.name == 'ObjectLiteral' &&
      _isLibrary(c.enclosingLibrary, ['dart:js_interop']);
}

/// Returns whether [a] is annotated with the `@ObjectLiteral(...)` annotation
/// from `dart:js_interop`.
bool hasObjectLiteralAnnotation(Annotatable a) =>
    a.annotations.any(isObjectLiteralAnnotation);

/// Returns true iff the class has an `@JS(...)` annotation from
/// `package:js`, `dart:_js_annotations`, or `dart:js_interop`.
///
/// Note: usually [usesJSInterop] should be used instead of this.
//
// TODO(jmesserly): I think almost all uses of this should be replaced with
// [usesJSInterop], which also checks that the library is marked with `@JS`.
//
// Right now we have inconsistencies: sometimes we'll respect `@JS` on the
// class itself, other places we require it on the library. Also members are
// inconsistent: sometimes they need to have `@JS` on them, other times they
// need to be `external` in an `@JS` class.
bool hasJSInteropAnnotation(Class c) =>
    c.annotations.any(isJSInteropAnnotation);

/// Returns true iff [c] is a class from `dart:_js_types` implemented using
/// `@staticInterop`.
bool isDartJSTypesType(Class c) =>
    _isLibrary(c.enclosingLibrary, const ['dart:_js_types']) &&
    isStaticInteropType(c);

/// Returns true iff this element is a JS interop member.
///
/// JS annotations are required explicitly on classes. Other elements, such as
/// class members and top-level functions/accessors, should be marked `external`
/// and should have directly or indirectly a `JS` annotation. It is sufficient
/// if the annotation is in the procedure itself or an enclosing element like
/// the class or library.
bool usesJSInterop(NamedNode n) {
  if (n is Member && n.isExternal) {
    return n.enclosingLibrary.annotations.any(isJSInteropAnnotation) ||
        n.annotations.any(isJSInteropAnnotation) ||
        (n.enclosingClass?.annotations.any(isJSInteropAnnotation) ?? false);
  } else if (n is Class) {
    return n.annotations.any(isJSInteropAnnotation);
  }
  return false;
}
