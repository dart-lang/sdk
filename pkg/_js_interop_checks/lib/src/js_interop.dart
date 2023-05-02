// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/util/graph.dart' as kernel_graph;

/// Returns true iff the node has an `@JS(...)` annotation from `package:js`,
/// `dart:_js_annotations`, or `dart:_js_interop`. Note that while `package:js`
/// has no annotations any more, it used to, so we still need to support those
/// versions.
bool hasJSInteropAnnotation(Annotatable a) =>
    a.annotations.any(_isJSInteropAnnotation);

/// Returns true iff the node has an `@JS(...)` annotation from `package:js` or
/// `dart:_js_annotations`.
bool hasPackageJSAnnotation(Annotatable a) =>
    a.annotations.any(_isPackageJSAnnotation);

/// Returns true iff the node has an `@JS(...)` annotation from
/// `dart:js_interop`.
bool hasDartJSInteropAnnotation(Annotatable a) =>
    a.annotations.any(_isDartJSInteropAnnotation);

/// Returns true iff the node has an `@anonymous` annotation from `package:js`
/// or `dart:_js_annotations`.
bool hasAnonymousAnnotation(Annotatable a) =>
    a.annotations.any(_isAnonymousAnnotation);

/// Returns true iff the node has an `@staticInterop` annotation from
/// `package:js` or `dart:_js_annotations`.
bool hasStaticInteropAnnotation(Annotatable a) =>
    a.annotations.any(_isStaticInteropAnnotation);

/// Returns true iff the node has an `@trustTypes` annotation from `package:js`
/// or `dart:_js_annotations`.
bool hasTrustTypesAnnotation(Annotatable a) =>
    a.annotations.any(_isTrustTypesAnnotation);

/// Returns true iff the node has an `@JSExport(...)` annotation from
/// `package:js` or `dart:_js_annotations`.
bool hasJSExportAnnotation(Annotatable a) =>
    a.annotations.any(_isJSExportAnnotation);

/// Returns true iff the node has an `@Native(...)` annotation from the internal
/// `dart:_js_helper`.
bool hasNativeAnnotation(Annotatable a) =>
    a.annotations.any(_isNativeAnnotation);

/// Returns true iff the node has an `@ObjectLiteral(...)` annotation from
/// `dart:js_interop`.
bool hasObjectLiteralAnnotation(Annotatable a) =>
    a.annotations.any(_isObjectLiteralAnnotation);

/// If [a] has a `@JS('...')` annotation, returns the value inside the
/// parentheses.
///
/// If there is none or the class does not have a `@JS()` annotation, returns
/// an empty String.
String getJSName(Annotatable a) {
  String jsClass = '';
  for (var annotation in a.annotations) {
    if (_isJSInteropAnnotation(annotation)) {
      var jsClasses = stringAnnotationValues(annotation);
      if (jsClasses.isNotEmpty) {
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
      nativeClasses.addAll(stringAnnotationValues(annotation));
    }
  }
  return nativeClasses;
}

/// If [a] has a `@JSExport('...')` annotation, returns the value inside the
/// parentheses.
///
/// If there is no value or the class does not have a `@JSExport()` annotation,
/// returns an empty String.
String getJSExportName(Annotatable a) {
  String jsExportValue = '';
  for (var annotation in a.annotations) {
    if (_isJSExportAnnotation(annotation)) {
      var jsExportValues = stringAnnotationValues(annotation);
      // TODO(srujzs): Theoretically, this should never be empty as there is a
      // default empty value. However, in the modular tests, dart2js modular
      // analysis does not see the default value, and reports this as empty in
      // some cases. We should investigate why and fix it, but for now, we just
      // manually provide the default value.
      if (jsExportValues.isNotEmpty) {
        jsExportValue = jsExportValues[0];
      }
    }
  }
  return jsExportValue;
}

final _packageJs = Uri.parse('package:js/js.dart');
final _jsAnnotations = Uri.parse('dart:_js_annotations');
final _jsHelper = Uri.parse('dart:_js_helper');
final _jsInterop = Uri.parse('dart:js_interop');

/// Returns true if [value] is the interop annotation whose class is
/// [annotationClassName] from [interopLibraries].
///
/// If [interopLibraries] is null, we check `package:js`,
/// `dart:_js_annotations`, and `dart:js_interop`.
bool _isInteropAnnotation(Expression value, String annotationClassName,
    {Set<Uri>? interopLibraries}) {
  interopLibraries ??= {_packageJs, _jsAnnotations, _jsInterop};
  var c = annotationClass(value);
  if (c == null || c.name != annotationClassName) return false;
  var importUri = c.enclosingLibrary.importUri;
  return interopLibraries.contains(importUri);
}

bool _isJSInteropAnnotation(Expression value) =>
    _isInteropAnnotation(value, 'JS');

bool _isPackageJSAnnotation(Expression value) =>
    _isInteropAnnotation(value, 'JS',
        interopLibraries: {_packageJs, _jsAnnotations});

bool _isDartJSInteropAnnotation(Expression value) =>
    _isInteropAnnotation(value, 'JS', interopLibraries: {_jsInterop});

bool _isAnonymousAnnotation(Expression value) =>
    _isInteropAnnotation(value, '_Anonymous');

bool _isStaticInteropAnnotation(Expression value) =>
    _isInteropAnnotation(value, '_StaticInterop');

bool _isTrustTypesAnnotation(Expression value) =>
    _isInteropAnnotation(value, '_TrustTypes');

bool _isJSExportAnnotation(Expression value) =>
    _isInteropAnnotation(value, 'JSExport');

/// Returns true if [value] is the `Native` annotation from `dart:_js_helper`.
bool _isNativeAnnotation(Expression value) {
  var c = annotationClass(value);
  return c != null &&
      c.name == 'Native' &&
      c.enclosingLibrary.importUri == _jsHelper;
}

/// Returns true if [value] is the `ObjectLiteral` annotation from
/// `dart:js_interop`.
bool _isObjectLiteralAnnotation(Expression value) {
  final c = annotationClass(value);
  return c != null &&
      c.name == 'ObjectLiteral' &&
      c.enclosingLibrary.importUri == _jsInterop;
}

/// Returns the class of the instance referred to by metadata annotation [node].
///
/// For example:
///
/// - `@JS()` would return the "JS" class in "dart:_js_annotations".
/// - `@anonymous` would return the "_Anonymous" class in
/// "dart:_js_annotations".
/// - `@staticInterop` would return the "_StaticInterop" class in
/// "dart:_js_annotations".
/// - `@Native` would return the "Native" class in "dart:_js_helper".
///
/// This function works regardless of whether the CFE is evaluating constants,
/// or whether the constant is a field reference (such as "anonymous" above).
Class? annotationClass(Expression node) {
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
List<String> stringAnnotationValues(Expression node) {
  List<String> values = [];
  if (node is ConstantExpression) {
    var constant = node.constant;
    if (constant is InstanceConstant) {
      var argLength = constant.fieldValues.values.length;
      if (argLength == 1) {
        var value = constant.fieldValues.values.elementAt(0);
        if (value is StringConstant) values.addAll(value.value.split(','));
      } else if (argLength > 1) {
        throw ArgumentError('Method expects annotation with at most one '
            'positional argument: $node.');
      }
    }
  } else if (node is ConstructorInvocation) {
    var argLength = node.arguments.positional.length;
    if (argLength > 1 || node.arguments.named.isNotEmpty) {
      throw ArgumentError('Method expects annotation with at most one '
          'positional argument: $node.');
    } else if (argLength == 1) {
      var value = node.arguments.positional[0];
      if (value is StringLiteral) values.addAll(value.value.split(','));
    }
  }
  return values;
}

/// Returns the [Library] within [component] matching the specified
/// [interopUri] or [null].
Library? _findJsInteropLibrary(Component component, Uri interopUri) {
  for (Library lib in component.libraries) {
    for (LibraryDependency dependency in lib.dependencies) {
      Library targetLibrary = dependency.targetLibrary;
      if (targetLibrary.importUri == interopUri) {
        return targetLibrary;
      }
    }
  }
  return null;
}

/// Calculates the libraries in [component] that transitively import a given js
/// interop library.
///
/// Returns null if the given js interop library is not imported.
/// NOTE: This function was based off of
/// `calculateTransitiveImportsOfDartFfiIfUsed` in
/// pkg/vm/lib/transformations/ffi/common.dart.
List<Library>? calculateTransitiveImportsOfJsInteropIfUsed(
    Component component, Uri interopUri) {
  // Check for the presence of [jsInteropLibrary] as a dependency of any of the
  // libraries in [component]. We use this to bypass the expensive
  // [calculateTransitiveDependenciesOf] call for cases where js interop is
  // not used, otherwise we could just use the index of the library instead.
  Library? jsInteropLibrary = _findJsInteropLibrary(component, interopUri);
  if (jsInteropLibrary == null) return null;

  kernel_graph.LibraryGraph graph =
      kernel_graph.LibraryGraph(component.libraries);
  Set<Library> result =
      kernel_graph.calculateTransitiveDependenciesOf(graph, {jsInteropLibrary});
  return result.toList();
}
