// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.src.kernel.dart2js_target;

import 'package:kernel/kernel.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/target/targets.dart';

import 'package:compiler/src/native/native.dart' show maybeEnableNative;

/// A kernel [Target] to configure the Dart Front End for dart2js.
class Dart2jsTarget extends Target {
  final TargetFlags flags;

  Dart2jsTarget(this.flags);

  bool get strongMode => flags.strongMode;

  String get name => 'dart2js';

  List<String> get extraRequiredLibraries => const <String>[
        'dart:_chrome',
        'dart:_foreign_helper',
        'dart:_interceptors',
        'dart:_internal',
        'dart:_isolate_helper',
        'dart:_js_embedded_names',
        'dart:_js_helper',
        'dart:_js_mirrors',
        'dart:_js_names',
        'dart:_native_typed_data',
        'dart:async',
        'dart:collection',
        'dart:html',
        'dart:html_common',
        'dart:indexed_db',
        'dart:js',
        'dart:js_util',
        'dart:mirrors',
        'dart:svg',
        'dart:web_audio',
        'dart:web_gl',
        'dart:web_sql',
      ];

  @override
  bool mayDefineRestrictedType(Uri uri) =>
      uri.scheme == 'dart' &&
      (uri.path == 'core' || uri.path == '_interceptors');

  @override
  bool enableNative(Uri uri) => maybeEnableNative(uri);

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
