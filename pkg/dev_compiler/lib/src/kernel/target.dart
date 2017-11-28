// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/target/targets.dart';

/// A kernel [Target] to configure the Dart Front End for dartdevc.
class DevCompilerTarget extends Target {
  bool get strongMode => true; // the only correct answer

  String get name => 'dartdevc';

  List<String> get extraRequiredLibraries => const [
        'dart:_runtime',
        'dart:_debugger',
        'dart:_foreign_helper',
        'dart:_interceptors',
        'dart:_internal',
        'dart:_isolate_helper',
        'dart:_js_embedded_names',
        'dart:_js_helper',
        'dart:_js_mirrors',
        'dart:_js_primitives',
        'dart:_metadata',
        'dart:_native_typed_data',
        'dart:async',
        'dart:collection',
        'dart:convert',
        'dart:developer',
        'dart:io',
        'dart:isolate',
        'dart:js',
        'dart:js_util',
        'dart:math',
        'dart:mirrors',
        'dart:typed_data',
        'dart:indexed_db',
        'dart:html',
        'dart:html_common',
        'dart:svg',
        'dart:web_audio',
        'dart:web_gl',
        'dart:web_sql'
      ];

  @override
  bool mayDefineRestrictedType(Uri uri) =>
      uri.scheme == 'dart' &&
      (uri.path == 'core' || uri.path == '_interceptors');

  @override
  bool enableNative(Uri uri) => uri.scheme == 'dart';

  @override
  bool get nativeExtensionExpectsString => false;

  @override
  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)}) {}

  @override
  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)}) {}

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    // TODO(sigmund): implement;
    return new InvalidExpression();
  }

  @override
  Expression instantiateNoSuchMethodError(CoreTypes coreTypes,
      Expression receiver, String name, Arguments arguments, int offset,
      {bool isMethod: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isField: false,
      bool isLocalVariable: false,
      bool isDynamic: false,
      bool isSuper: false,
      bool isStatic: false,
      bool isConstructor: false,
      bool isTopLevel: false}) {
    // TODO(sigmund): implement;
    return new InvalidExpression();
  }
}
