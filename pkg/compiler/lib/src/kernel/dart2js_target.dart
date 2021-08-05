// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.12

// TODO(johnniwinther): Add a test that ensure that this library doesn't depend
// on the dart2js internals.
library compiler.src.kernel.dart2js_target;

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Message, LocatedMessage;
import 'package:_js_interop_checks/js_interop_checks.dart';
import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart';

import '../options.dart';
import 'invocation_mirror_constants.dart';
import 'transformations/lowering.dart' as lowering show transformLibraries;

const Iterable<String> _allowedDartSchemePaths = const <String>[
  'async',
  'html',
  'html_common',
  'indexed_db',
  'js',
  'js_util',
  'svg',
  '_native_typed_data',
  'web_audio',
  'web_gl',
  'web_sql'
];

List<Pattern> _allowedNativeTestPatterns = [
  RegExp(r'(?<!generated_)tests/web/native'),
  RegExp(r'(?<!generated_)tests/web/internal'),
  'generated_tests/web/native/native_test',
  RegExp(r'(?<!generated_)tests/web_2/native'),
  RegExp(r'(?<!generated_)tests/web_2/internal'),
  'generated_tests/web_2/native/native_test',
];

bool allowedNativeTest(Uri uri) {
  String path = uri.path;
  return _allowedNativeTestPatterns.any((pattern) => path.contains(pattern));
}

bool maybeEnableNative(Uri uri) {
  bool allowedDartLibrary() {
    if (uri.scheme != 'dart') return false;
    return _allowedDartSchemePaths.contains(uri.path);
  }

  return allowedNativeTest(uri) || allowedDartLibrary();
}

int _foldLateLowerings(List<int> lowerings) =>
    lowerings.fold(LateLowering.none, (a, b) => a | b);

/// Late lowerings which the frontend performs for dart2js.
const List<int> _allEnabledLateLowerings = [
  LateLowering.uninitializedNonFinalInstanceField,
  LateLowering.uninitializedFinalInstanceField,
  LateLowering.initializedNonFinalInstanceField,
  LateLowering.initializedFinalInstanceField,
];

final int _enabledLateLowerings = _foldLateLowerings(_allEnabledLateLowerings);

/// A kernel [Target] to configure the Dart Front End for dart2js.
class Dart2jsTarget extends Target {
  @override
  final TargetFlags flags;
  @override
  final String name;

  final CompilerOptions? options;

  Dart2jsTarget(this.name, this.flags, {this.options});

  @override
  bool get enableNoSuchMethodForwarders => true;

  @override
  int get enabledLateLowerings =>
      (options != null && options!.experimentLateInstanceVariables)
          ? LateLowering.none
          : _enabledLateLowerings;

  @override
  bool get supportsLateLoweringSentinel => true;

  @override
  bool get useStaticFieldLowering => false;

  // TODO(johnniwinther,sigmund): Remove this when js-interop handles getter
  //  calls encoded with an explicit property get or disallows getter calls.
  @override
  bool get supportsExplicitGetterCalls => false;

  @override
  int get enabledConstructorTearOffLowerings => ConstructorTearOffLowering.none;

  @override
  List<String> get extraRequiredLibraries => _requiredLibraries[name]!;

  @override
  List<String> get extraIndexedLibraries => const [
        'dart:_foreign_helper',
        'dart:_interceptors',
        'dart:_js_helper',
        'dart:_late_helper',
        'dart:js',
        'dart:js_util'
      ];

  @override
  bool mayDefineRestrictedType(Uri uri) =>
      uri.isScheme('dart') &&
      (uri.path == 'core' ||
          uri.path == 'typed_data' ||
          uri.path == '_interceptors' ||
          uri.path == '_native_typed_data');

  @override
  bool allowPlatformPrivateLibraryAccess(Uri importer, Uri imported) =>
      super.allowPlatformPrivateLibraryAccess(importer, imported) ||
      maybeEnableNative(importer) ||
      (importer.scheme == 'package' &&
          importer.path.startsWith('dart2js_runtime_metrics/'));

  @override
  bool enableNative(Uri uri) => maybeEnableNative(uri);

  @override
  bool get nativeExtensionExpectsString => false;

  @override
  bool get errorOnUnexactWebIntLiterals => true;

  @override
  void performModularTransformationsOnLibraries(
      ir.Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      List<ir.Library> libraries,
      Map<String, String>? environmentDefines,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier}) {
    var nativeClasses = JsInteropChecks.getNativeClasses(component);
    var jsUtilOptimizer = JsUtilOptimizer(coreTypes, hierarchy);
    for (var library in libraries) {
      // TODO (rileyporter): Merge js_util optimizations with other lowerings
      // in the single pass in `transformations/lowering.dart`.
      jsUtilOptimizer.visitLibrary(library);
      JsInteropChecks(
              coreTypes,
              diagnosticReporter as DiagnosticReporter<Message, LocatedMessage>,
              nativeClasses)
          .visitLibrary(library);
    }
    lowering.transformLibraries(libraries, coreTypes, hierarchy, options);
    logger?.call("Lowering transformations performed");
  }

  @override
  ir.Expression instantiateInvocation(
      CoreTypes coreTypes,
      ir.Expression receiver,
      String name,
      ir.Arguments arguments,
      int offset,
      bool isSuper) {
    int kind;
    if (name.startsWith('get:')) {
      kind = invocationMirrorGetterKind;
      name = name.substring(4);
    } else if (name.startsWith('set:')) {
      kind = invocationMirrorSetterKind;
      name = name.substring(4);
    } else {
      kind = invocationMirrorMethodKind;
    }
    return new ir.StaticInvocation(
        coreTypes.index
            .getTopLevelProcedure('dart:core', '_createInvocationMirror'),
        new ir.Arguments(<ir.Expression>[
          new ir.StringLiteral(name)..fileOffset = offset,
          new ir.ListLiteral(
              arguments.types.map((t) => new ir.TypeLiteral(t)).toList()),
          new ir.ListLiteral(arguments.positional)..fileOffset = offset,
          new ir.MapLiteral(new List<ir.MapLiteralEntry>.from(
              arguments.named.map((ir.NamedExpression arg) {
            return new ir.MapLiteralEntry(
                new ir.StringLiteral(arg.name)..fileOffset = arg.fileOffset,
                arg.value)
              ..fileOffset = arg.fileOffset;
          })), keyType: coreTypes.stringNonNullableRawType)
            ..isConst = (arguments.named.length == 0)
            ..fileOffset = arguments.fileOffset,
          new ir.IntLiteral(kind)..fileOffset = offset,
        ]))
      ..fileOffset = offset;
  }

  @override
  ir.Expression instantiateNoSuchMethodError(CoreTypes coreTypes,
      ir.Expression receiver, String name, ir.Arguments arguments, int offset,
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
    return new ir.InvalidExpression(null);
  }

  @override
  ConstantsBackend constantsBackend(CoreTypes coreTypes) =>
      const Dart2jsConstantsBackend(supportsUnevaluatedConstants: true);
}

// TODO(sigmund): this "extraRequiredLibraries" needs to be removed...
// compile-platform should just specify which libraries to compile instead.
const _requiredLibraries = const <String, List<String>>{
  'dart2js': const <String>[
    'dart:_dart2js_runtime_metrics',
    'dart:_foreign_helper',
    'dart:_interceptors',
    'dart:_internal',
    'dart:_js_annotations',
    'dart:_js_embedded_names',
    'dart:_js_helper',
    'dart:_js_names',
    'dart:_late_helper',
    'dart:_native_typed_data',
    'dart:async',
    'dart:collection',
    'dart:html',
    'dart:html_common',
    'dart:indexed_db',
    'dart:io',
    'dart:js',
    'dart:js_util',
    'dart:svg',
    'dart:web_audio',
    'dart:web_gl',
    'dart:web_sql',
  ],
  'dart2js_server': const <String>[
    'dart:_dart2js_runtime_metrics',
    'dart:_foreign_helper',
    'dart:_interceptors',
    'dart:_internal',
    'dart:_js_annotations',
    'dart:_js_embedded_names',
    'dart:_js_helper',
    'dart:_js_names',
    'dart:_late_helper',
    'dart:_native_typed_data',
    'dart:async',
    'dart:collection',
    'dart:io',
    'dart:js',
    'dart:js_util',
  ]
};

class Dart2jsConstantsBackend extends ConstantsBackend {
  @override
  final bool supportsUnevaluatedConstants;

  const Dart2jsConstantsBackend({required this.supportsUnevaluatedConstants});

  @override
  NumberSemantics get numberSemantics => NumberSemantics.js;
}
