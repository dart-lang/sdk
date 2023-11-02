// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Add a test that ensure that this library doesn't depend
// on the dart2js internals.
library compiler.src.kernel.dart2js_target;

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Message, LocatedMessage;
import 'package:_js_interop_checks/js_interop_checks.dart';
import 'package:_js_interop_checks/src/transformations/export_creator.dart';
import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';

import '../options.dart';
import 'invocation_mirror_constants.dart';
import 'transformations/modular/lowering.dart' as modularTransforms;

const Iterable<String> _allowedDartSchemePaths = [
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
];

List<Pattern> _allowedNativeTestPatterns = [
  RegExp(r'(?<!generated_)tests/web/native'),
  RegExp(r'(?<!generated_)tests/web/internal'),
  'generated_tests/web/native/native_test',
  'generated_tests/web/internal/deferred_url_test',
  RegExp(r'(?<!generated_)tests/web_2/native'),
  RegExp(r'(?<!generated_)tests/web_2/internal'),
  'generated_tests/web_2/native/native_test',
  'generated_tests/web_2/internal/deferred_url_test',
  'pkg/front_end/testcases/dart2js/native',
];

bool allowedNativeTest(Uri uri) {
  String path = uri.path;
  return _allowedNativeTestPatterns.any((pattern) => path.contains(pattern));
}

bool maybeEnableNative(Uri uri) {
  bool allowedDartLibrary() {
    if (!uri.isScheme('dart')) return false;
    return _allowedDartSchemePaths.contains(uri.path);
  }

  return allowedNativeTest(uri) || allowedDartLibrary();
}

/// A kernel [Target] to configure the Dart Front End for dart2js.
class Dart2jsTarget extends Target {
  @override
  final TargetFlags flags;
  @override
  final String name;

  final CompilerOptions? options;
  final bool supportsUnevaluatedConstants;
  Map<String, ir.Class>? _nativeClasses;

  Dart2jsTarget(this.name, this.flags,
      {this.options, this.supportsUnevaluatedConstants = true});

  @override
  bool get enableNoSuchMethodForwarders => true;

  @override
  int get enabledLateLowerings => LateLowering.none;

  @override
  bool get supportsLateLoweringSentinel => true;

  @override
  bool get useStaticFieldLowering => false;

  // TODO(johnniwinther,sigmund): Remove this when js-interop handles getter
  //  calls encoded with an explicit property get or disallows getter calls.
  @override
  bool get supportsExplicitGetterCalls => false;

  @override
  int get enabledConstructorTearOffLowerings => ConstructorTearOffLowering.all;

  @override
  List<String> get extraRequiredLibraries => requiredLibraries[name]!;

  @override
  List<String> get extraIndexedLibraries => const [
        'dart:_foreign_helper',
        'dart:_interceptors',
        'dart:_js_helper',
        'dart:_js_types',
        'dart:_late_helper',
        'dart:js',
        'dart:js_interop',
        'dart:js_interop_unsafe',
        'dart:js_util',
        'dart:typed_data',
      ];

  @override
  bool mayDefineRestrictedType(Uri uri) =>
      uri.isScheme('dart') &&
      (uri.path == 'core' ||
          uri.path == 'typed_data' ||
          uri.path == '_interceptors' ||
          uri.path == '_native_typed_data' ||
          uri.path == '_js_helper');

  @override
  bool allowPlatformPrivateLibraryAccess(Uri importer, Uri imported) =>
      super.allowPlatformPrivateLibraryAccess(importer, imported) ||
      maybeEnableNative(importer) ||
      (importer.isScheme('package') &&
          (importer.path.startsWith('dart2js_runtime_metrics/') ||
              importer.path == 'js/js.dart'));

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
    _nativeClasses = JsInteropChecks.getNativeClasses(component);
    final jsInteropReporter = JsInteropDiagnosticReporter(
        diagnosticReporter as DiagnosticReporter<Message, LocatedMessage>);
    var jsInteropChecks = JsInteropChecks(
        coreTypes, hierarchy, jsInteropReporter, _nativeClasses!);
    // Process and validate first before doing anything with exports.
    for (var library in libraries) {
      jsInteropChecks.visitLibrary(library);
    }
    var exportCreator = ExportCreator(TypeEnvironment(coreTypes, hierarchy),
        jsInteropReporter, jsInteropChecks.exportChecker);
    var jsUtilOptimizer = JsUtilOptimizer(coreTypes, hierarchy);
    for (var library in libraries) {
      // Export creator has static checks, so we still visit even if there are
      // errors.
      exportCreator.visitLibrary(library);
      // TODO (rileyporter): Merge js_util optimizations with other lowerings
      // in the single pass in `transformations/lowering.dart`.
      if (!jsInteropReporter.hasJsInteropErrors) {
        // We can't guarantee calls are well-formed, so don't transform.
        jsUtilOptimizer.visitLibrary(library);
      }
    }
    modularTransforms.transformLibraries(
        libraries, coreTypes, hierarchy, options);
    logger?.call("Modular transformations performed");
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
    return ir.StaticInvocation(
        coreTypes.index
            .getTopLevelProcedure('dart:core', '_createInvocationMirror'),
        ir.Arguments(<ir.Expression>[
          ir.StringLiteral(name)..fileOffset = offset,
          ir.ListLiteral(arguments.types
              .map<ir.Expression>((t) => ir.TypeLiteral(t))
              .toList()),
          ir.ListLiteral(arguments.positional)..fileOffset = offset,
          ir.MapLiteral(List<ir.MapLiteralEntry>.from(
              arguments.named.map((ir.NamedExpression arg) {
            return ir.MapLiteralEntry(
                ir.StringLiteral(arg.name)..fileOffset = arg.fileOffset,
                arg.value)
              ..fileOffset = arg.fileOffset;
          })), keyType: coreTypes.stringNonNullableRawType)
            ..isConst = (arguments.named.length == 0)
            ..fileOffset = arguments.fileOffset,
          ir.IntLiteral(kind)..fileOffset = offset,
        ]))
      ..fileOffset = offset;
  }

  @override
  ir.Expression instantiateNoSuchMethodError(CoreTypes coreTypes,
      ir.Expression receiver, String name, ir.Arguments arguments, int offset,
      {bool isMethod = false,
      bool isGetter = false,
      bool isSetter = false,
      bool isField = false,
      bool isLocalVariable = false,
      bool isDynamic = false,
      bool isSuper = false,
      bool isStatic = false,
      bool isConstructor = false,
      bool isTopLevel = false}) {
    // TODO(sigmund): implement;
    return ir.InvalidExpression(null);
  }

  @override
  ConstantsBackend get constantsBackend => Dart2jsConstantsBackend(
      supportsUnevaluatedConstants: supportsUnevaluatedConstants);

  @override
  DartLibrarySupport get dartLibrarySupport =>
      const Dart2jsDartLibrarySupport();
}

const implicitlyUsedLibraries = <String>[
  'dart:_foreign_helper',
  'dart:_interceptors',
  'dart:_js_helper',
  'dart:_late_helper',
  // Needed since dart:js_util methods like createDartExport use this.
  'dart:js_interop_unsafe',
  'dart:js_util'
];

// TODO(sigmund): this "extraRequiredLibraries" needs to be removed...
// compile-platform should just specify which libraries to compile instead.
const requiredLibraries = <String, List<String>>{
  'dart2js': [
    'dart:_async_status_codes',
    'dart:_dart2js_runtime_metrics',
    'dart:_foreign_helper',
    'dart:_http',
    'dart:_interceptors',
    'dart:_internal',
    'dart:_js',
    'dart:_js_annotations',
    'dart:_js_embedded_names',
    'dart:_js_helper',
    'dart:_js_names',
    'dart:_js_primitives',
    'dart:_js_shared_embedded_names',
    'dart:_js_types',
    'dart:_late_helper',
    'dart:_load_library_priority',
    'dart:_metadata',
    'dart:_native_typed_data',
    'dart:_recipe_syntax',
    'dart:_rti',
    'dart:async',
    'dart:collection',
    'dart:convert',
    'dart:developer',
    'dart:html',
    'dart:html_common',
    'dart:indexed_db',
    'dart:io',
    'dart:isolate',
    'dart:js',
    'dart:js_interop',
    'dart:js_interop_unsafe',
    'dart:js_util',
    'dart:math',
    'dart:svg',
    'dart:typed_data',
    'dart:web_audio',
    'dart:web_gl',
  ],
  'dart2js_server': [
    'dart:_async_status_codes',
    'dart:_dart2js_runtime_metrics',
    'dart:_foreign_helper',
    'dart:_http',
    'dart:_interceptors',
    'dart:_internal',
    'dart:_js',
    'dart:_js_annotations',
    'dart:_js_embedded_names',
    'dart:_js_helper',
    'dart:_js_names',
    'dart:_js_primitives',
    'dart:_js_shared_embedded_names',
    'dart:_js_types',
    'dart:_late_helper',
    'dart:_load_library_priority',
    'dart:_native_typed_data',
    'dart:_recipe_syntax',
    'dart:_rti',
    'dart:async',
    'dart:collection',
    'dart:convert',
    'dart:developer',
    'dart:io',
    'dart:isolate',
    'dart:js',
    'dart:js_interop',
    'dart:js_interop_unsafe',
    'dart:js_util',
    'dart:math',
    'dart:typed_data',
  ]
};

/// Extends the Dart2jsTarget to transform outlines to meet the requirements
/// of summaries in bazel and package-build.
class Dart2jsSummaryTarget extends Dart2jsTarget with SummaryMixin {
  @override
  final List<Uri> sources;

  @override
  final bool excludeNonSources;

  Dart2jsSummaryTarget(String name, this.sources, this.excludeNonSources,
      TargetFlags targetFlags)
      : super(name, targetFlags);
}

class Dart2jsConstantsBackend extends ConstantsBackend {
  @override
  final bool supportsUnevaluatedConstants;

  const Dart2jsConstantsBackend({required this.supportsUnevaluatedConstants});

  @override
  NumberSemantics get numberSemantics => NumberSemantics.js;
}

class Dart2jsDartLibrarySupport extends CustomizedDartLibrarySupport {
  const Dart2jsDartLibrarySupport()
      : super(supported: const {'_dart2js_runtime_metrics'});
}
