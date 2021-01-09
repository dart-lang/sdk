// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';

/// Returns true iff the node has an `@JS(...)` annotation from `package:js` or
/// from the internal `dart:_js_annotations`.
bool hasJSInteropAnnotation(Annotatable a) =>
    a.annotations.any(_isPublicJSAnnotation);

/// Returns true if [m] belongs to an anonymous class.
bool isAnonymousClassMember(Member m) {
  var enclosingClass = m.enclosingClass;
  if (enclosingClass == null) return false;
  return enclosingClass.annotations.any(_isAnonymousAnnotation);
}

final _packageJs = Uri.parse('package:js/js.dart');
final _internalJs = Uri.parse('dart:_js_annotations');

/// Returns true if [value] is the `JS` annotation from `package:js` or from
/// `dart:_js_annotations`.
bool _isPublicJSAnnotation(Expression value) {
  var c = _annotationClass(value);
  return c != null &&
      c.name == 'JS' &&
      (c.enclosingLibrary.importUri == _packageJs ||
          c.enclosingLibrary.importUri == _internalJs);
}

/// Returns true if [value] is the `anyonymous` annotation from `package:js` or
/// from `dart:_js_annotations`.
bool _isAnonymousAnnotation(Expression value) {
  var c = _annotationClass(value);
  return c != null &&
      c.name == '_Anonymous' &&
      (c.enclosingLibrary.importUri == _packageJs ||
          c.enclosingLibrary.importUri == _internalJs);
}

/// Returns the class of the instance referred to by metadata annotation [node].
///
/// For example:
///
/// - `@JS()` would return the "JS" class in "package:js".
/// - `@anonymous` would return the "_Anonymous" class in "package:js".
///
/// This function works regardless of whether the CFE is evaluating constants,
/// or whether the constant is a field reference (such as "anonymous" above).
Class _annotationClass(Expression node) {
  if (node is ConstantExpression) {
    var constant = node.constant;
    if (constant is InstanceConstant) return constant.classNode;
  } else if (node is ConstructorInvocation) {
    return node.target.enclosingClass;
  } else if (node is StaticGet) {
    var type = node.target.getterType;
    if (type is InterfaceType) return type.classNode;
  }
  return null;
}
