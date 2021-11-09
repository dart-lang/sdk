// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';

/// Returns true iff the node has an `@JS(...)` annotation from `package:js` or
/// from the internal `dart:_js_annotations`.
bool hasJSInteropAnnotation(Annotatable a) =>
    a.annotations.any(_isPublicJSAnnotation);

/// Returns true iff the node has an `@anonymous` annotation from `package:js`
/// or from the internal `dart:_js_annotations`.
bool hasAnonymousAnnotation(Annotatable a) =>
    a.annotations.any(_isAnonymousAnnotation);

/// Returns true iff the node has an `@staticInterop` annotation from
/// `package:js` or from the internal `dart:_js_annotations`.
bool hasStaticInteropAnnotation(Annotatable a) =>
    a.annotations.any(_isStaticInteropAnnotation);

/// If [a] has a `@JS('...')` annotation, returns the value inside the
/// parentheses.
///
/// If there is none or the class does not have a `@JS()` annotation, returns
/// an empty String.
String getJSName(Annotatable a) {
  String jsClass = '';
  for (var annotation in a.annotations) {
    if (_isPublicJSAnnotation(annotation)) {
      var jsClasses = _stringAnnotationValues(annotation);
      if (jsClasses.length > 0) {
        jsClass = jsClasses[0];
      }
    }
  }
  return jsClass;
}

/// If [a] has a `@Native('...')` annotation, returns the values inside the
/// parentheses.
///
/// If there are none or the class does not have a `@Native()` annotation,
/// returns an empty list. Unlike `@JS()`, the string within `@Native()` is
/// allowed to contain several classes separated by a `,`.
List<String> getNativeNames(Annotatable a) {
  List<String> nativeClasses = [];
  for (var annotation in a.annotations) {
    if (_isNativeAnnotation(annotation)) {
      nativeClasses.addAll(_stringAnnotationValues(annotation));
    }
  }
  return nativeClasses;
}

final _packageJs = Uri.parse('package:js/js.dart');
final _internalJs = Uri.parse('dart:_js_annotations');
final _jsHelper = Uri.parse('dart:_js_helper');

/// Returns true if [value] is the interop annotation whose class is
/// [annotationClassName] from `package:js` or from `dart:_js_annotations`.
bool _isInteropAnnotation(Expression value, String annotationClassName) {
  var c = _annotationClass(value);
  return c != null &&
      c.name == annotationClassName &&
      (c.enclosingLibrary.importUri == _packageJs ||
          c.enclosingLibrary.importUri == _internalJs);
}

bool _isPublicJSAnnotation(Expression value) =>
    _isInteropAnnotation(value, 'JS');

bool _isAnonymousAnnotation(Expression value) =>
    _isInteropAnnotation(value, '_Anonymous');

bool _isStaticInteropAnnotation(Expression value) =>
    _isInteropAnnotation(value, '_StaticInterop');

/// Returns true if [value] is the `Native` annotation from `dart:_js_helper`.
bool _isNativeAnnotation(Expression value) {
  var c = _annotationClass(value);
  return c != null &&
      c.name == 'Native' &&
      c.enclosingLibrary.importUri == _jsHelper;
}

/// Returns the class of the instance referred to by metadata annotation [node].
///
/// For example:
///
/// - `@JS()` would return the "JS" class in "package:js".
/// - `@anonymous` would return the "_Anonymous" class in "package:js".
/// - `@staticInterop` would return the "_StaticInterop" class in "package:js".
/// - `@Native` would return the "Native" class in "dart:_js_helper".
///
/// This function works regardless of whether the CFE is evaluating constants,
/// or whether the constant is a field reference (such as "anonymous" above).
Class? _annotationClass(Expression node) {
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

/// Returns the string values inside of a metadata annotation [node].
///
/// For example:
/// - `@JS('Foo')` would return ['Foo'].
/// - `@Native('Foo,Bar')` would return ['Foo', 'Bar'].
///
/// [node] is expected to be an annotation with either StringConstants or
/// StringLiterals that can be made up of multiple values. If there are none,
/// this method returns an empty list. This method throws an assertion if there
/// are multiple arguments or a named arg in the annotation.
List<String> _stringAnnotationValues(Expression node) {
  List<String> values = [];
  if (node is ConstantExpression) {
    var constant = node.constant;
    if (constant is InstanceConstant) {
      var argLength = constant.fieldValues.values.length;
      if (argLength == 1) {
        var value = constant.fieldValues.values.elementAt(0);
        if (value is StringConstant) values.addAll(value.value.split(','));
      } else if (argLength > 1) {
        throw new ArgumentError('Method expects annotation with at most one '
            'positional argument: $node.');
      }
    }
  } else if (node is ConstructorInvocation) {
    var argLength = node.arguments.positional.length;
    if (argLength > 1 || node.arguments.named.length > 0) {
      throw new ArgumentError('Method expects annotation with at most one '
          'positional argument: $node.');
    } else if (argLength == 1) {
      var value = node.arguments.positional[0];
      if (value is StringLiteral) values.addAll(value.value.split(','));
    }
  }
  return values;
}
