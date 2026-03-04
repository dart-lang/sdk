// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Message, LocatedMessage;
import 'package:_js_interop_checks/js_interop_checks.dart';
import 'package:_js_interop_checks/src/js_interop.dart' as jsInteropHelper;
import 'package:_js_interop_checks/src/transformations/shared_interop_transformer.dart';
import 'package:front_end/src/api_prototype/const_conditional_simplifier.dart'
    show ConstConditionalSimplifier;
import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    as constantEvaluator show ConstantEvaluator;

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/verifier.dart';
import 'package:vm/modular/transformations/ffi/common.dart' as ffiHelper
    show calculateTransitiveImportsOfDartFfiIfUsed;
import 'package:vm/modular/transformations/ffi/definitions.dart'
    as transformFfiDefinitions show transformLibraries;
import 'package:vm/modular/transformations/ffi/use_sites.dart'
    as transformFfiUseSites show transformLibraries;
import 'package:vm/modular/transformations/mixin_full_resolution.dart'
    as transformMixins show transformLibraries;

import 'await_transformer.dart' as awaitTrans;
import 'ffi_native_address_transformer.dart' as wasmFfiNativeAddressTrans;
import 'ffi_native_transformer.dart' as wasmFfiNativeTrans;
import 'records.dart' show RecordShape;
import 'transformers.dart' as wasmTrans;
import 'util.dart' as util;
import 'wasm_library_checks.dart' as wasmChecks;

enum Mode {
  regular,
  jsCompatibility,
}

class Dart2WasmConstantsBackend extends ConstantsBackend {
  const Dart2WasmConstantsBackend() : super(keepLocals: false);

  @override
  bool get supportsUnevaluatedConstants => true;
}

class ConstantResolver extends Transformer {
  ConstantResolver(this.evaluator);

  final constantEvaluator.ConstantEvaluator evaluator;

  StaticTypeContext? _context;

  @override
  TreeNode visitLibrary(Library library) {
    final oldContext = _context;
    _context =
        StaticTypeContext.forAnnotations(library, evaluator.typeEnvironment);
    final result = super.visitLibrary(library);
    _context = oldContext;
    return result;
  }

  @override
  TreeNode defaultMember(Member member) {
    final oldContext = _context;
    _context = StaticTypeContext(member, evaluator.typeEnvironment);
    final result = super.defaultMember(member);
    _context = oldContext;
    return result;
  }

  @override
  TreeNode visitConstantExpression(ConstantExpression node) {
    final constant = node.constant;
    if (constant is UnevaluatedConstant) {
      final expression = constant.expression;
      final newConstant = evaluator.evaluate(_context!, expression);
      ConstantExpression result =
          ConstantExpression(newConstant, node.getStaticType(_context!))
            ..fileOffset = node.fileOffset;

      return result;
    }
    return node;
  }
}

class WasmTarget extends Target {
  WasmTarget(
      {this.enableExperimentalFfi = true,
      this.enableExperimentalWasmInterop = true,
      this.removeAsserts = false,
      this.mode = Mode.regular});

  final bool removeAsserts;
  final Mode mode;
  final bool enableExperimentalFfi;
  final bool enableExperimentalWasmInterop;
  Class? _growableList;
  Class? _immutableList;
  Class? _wasmDefaultMap;
  Class? _wasmDefaultSet;
  Class? _wasmImmutableMap;
  Class? _wasmImmutableSet;
  Class? _jsString;
  Class? _closure;
  Class? _boxedInt;
  Class? _boxedDouble;
  Map<String, Class>? _nativeClasses;

  @override
  bool get enableNoSuchMethodForwarders => true;

  @override
  ConstantsBackend get constantsBackend => const Dart2WasmConstantsBackend();

  @override
  Verification get verification => const WasmVerification();

  @override
  String get name {
    return switch (mode) {
      Mode.regular => 'wasm',
      Mode.jsCompatibility => 'wasm_js_compatibility'
    };
  }

  String get platformFile {
    return switch (mode) {
      Mode.regular => 'dart2wasm_platform.dill',
      Mode.jsCompatibility => 'dart2wasm_js_compatibility_platform.dill'
    };
  }

  @override
  TargetFlags get flags => TargetFlags();

  @override
  List<String> get extraRequiredLibraries => [
        'dart:_boxed_bool',
        'dart:_boxed_double',
        'dart:_boxed_int',
        'dart:_compact_hash',
        'dart:_http',
        'dart:_internal',
        'dart:_js_helper',
        'dart:_js_types',
        'dart:_list',
        'dart:_string',
        'dart:_wasm',
        'dart:async',
        'dart:developer',
        'dart:ffi',
        'dart:io',
        'dart:js_interop',
        'dart:js_interop_unsafe',
        'dart:nativewrappers',
        'dart:typed_data',
      ];

  @override
  List<String> get extraIndexedLibraries => [
        'dart:_boxed_bool',
        'dart:_boxed_double',
        'dart:_boxed_int',
        'dart:_compact_hash',
        'dart:_error_utils',
        'dart:_js_helper',
        'dart:_js_types',
        'dart:_list',
        'dart:_string',
        'dart:_wasm',
        'dart:collection',
        'dart:js_interop',
        'dart:js_interop_unsafe',
        'dart:typed_data',
      ];

  @override
  bool mayDefineRestrictedType(Uri uri) => uri.isScheme('dart');

  @override
  bool allowPlatformPrivateLibraryAccess(Uri importer, Uri imported) {
    if (super.allowPlatformPrivateLibraryAccess(importer, imported)) {
      return true;
    }

    if (imported.toString() == 'dart:_wasm') {
      return enableExperimentalWasmInterop;
    }

    final importerString = importer.toString();

    // We have some tests that import dart:js*
    if (importerString.contains('tests/web/wasm')) return true;

    // Flutter's dart:ui is also package:ui (in test mode)
    if (importerString.startsWith('package:ui/')) return true;

    return false;
  }

  void _patchHostEndian(CoreTypes coreTypes) {
    // Fix Endian.host to be a const field equal to Endian.little instead of
    // a final field. Wasm is a little-endian platform.
    // Can't use normal patching process for this because CFE does not
    // support patching fields.
    // See http://dartbug.com/32836 for the background.
    final Field host =
        coreTypes.index.getField('dart:typed_data', 'Endian', 'host');
    final Field little =
        coreTypes.index.getField('dart:typed_data', 'Endian', 'little');
    host.isConst = true;
    host.initializer = CloneVisitorNotMembers().clone(little.initializer!)
      ..parent = host;
  }

  void _performJSInteropTransformations(
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      Set<Library> interopDependentLibraries,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex) {
    _nativeClasses ??= JsInteropChecks.getNativeClasses(component);
    final jsInteropReporter = JsInteropDiagnosticReporter(
        diagnosticReporter as DiagnosticReporter<Message, LocatedMessage>);
    final jsInteropChecks = JsInteropChecks(
        coreTypes, hierarchy, jsInteropReporter, _nativeClasses!,
        isDart2Wasm: true);
    // Process and validate first before doing anything with exports.
    for (Library library in interopDependentLibraries) {
      jsInteropChecks.visitLibrary(library);
    }
    final sharedInteropTransformer = SharedInteropTransformer(
        TypeEnvironment(coreTypes, hierarchy),
        jsInteropReporter,
        jsInteropChecks.exportChecker,
        jsInteropChecks.extensionIndex);
    for (Library library in interopDependentLibraries) {
      sharedInteropTransformer.visitLibrary(library);
    }
  }

  @override
  void performPreConstantEvaluationTransformations(
      Component component,
      CoreTypes coreTypes,
      List<Library> libraries,
      DiagnosticReporter diagnosticReporter,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier}) {
    _patchHostEndian(coreTypes);
  }

  @override
  void performModularTransformationsOnLibraries(
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      List<Library> libraries,
      Map<String, String>? environmentDefines,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier}) {
    var invalidFfiUsage = false;
    for (final library in libraries) {
      if (!enableExperimentalFfi) {
        invalidFfiUsage |= _checkDisallowedDartFfiUsage(library,
            diagnosticReporter as DiagnosticReporter<Message, LocatedMessage>);
      }
      // Check `wasm:import` and `wasm:export` pragmas before FFI transforms
      // as FFI transforms convert JS interop annotations to these pragmas.
      if (!enableExperimentalWasmInterop) {
        _checkWasmImportExportPragmas(library, coreTypes,
            diagnosticReporter as DiagnosticReporter<Message, LocatedMessage>);
      }
    }

    Set<Library> transitiveImportingJSInterop = {
      ...jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component.libraries, Uri.parse("dart:js_interop")),
      ...jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component.libraries, Uri.parse("dart:convert")),
      ...jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component.libraries, Uri.parse("dart:_string")),
    };
    if (transitiveImportingJSInterop.isEmpty) {
      logger?.call("Skipped JS interop transformations");
    } else {
      _performJSInteropTransformations(component, coreTypes, hierarchy,
          transitiveImportingJSInterop, diagnosticReporter, referenceFromIndex);
      logger?.call("Transformed JS interop classes");
    }

    // If we are compiling with a null environment, skip constant resolution
    // and simplification.
    if (environmentDefines != null) {
      void reportError(LocatedMessage message,
          [List<LocatedMessage>? context]) {
        diagnosticReporter.report(message.messageObject, message.charOffset,
            message.length, message.uri);
        if (context != null) {
          for (final m in context) {
            diagnosticReporter.report(
                m.messageObject, m.charOffset, m.length, m.uri);
          }
        }
      }

      final simplifier = ConstConditionalSimplifier(
        dartLibrarySupport,
        constantsBackend,
        component,
        reportError,
        environmentDefines: environmentDefines,
        coreTypes: coreTypes,
        classHierarchy: hierarchy,
        removeAsserts: removeAsserts,
      );
      final evaluator = simplifier.constantEvaluator;
      ConstantResolver(evaluator).transform(component);
      simplifier.run();
    }

    transformMixins.transformLibraries(
        this, coreTypes, hierarchy, libraries, referenceFromIndex);
    logger?.call("Transformed mixin applications");

    List<Library>? transitiveImportingDartFfi = ffiHelper
        .calculateTransitiveImportsOfDartFfiIfUsed(component, libraries);
    if (transitiveImportingDartFfi == null || invalidFfiUsage) {
      logger?.call("Skipped ffi transformation");
    } else {
      wasmFfiNativeAddressTrans.transformLibraries(
        component,
        coreTypes,
        hierarchy,
        transitiveImportingDartFfi,
        diagnosticReporter,
        referenceFromIndex,
      );
      wasmFfiNativeTrans.transformLibraries(component, coreTypes, hierarchy,
          transitiveImportingDartFfi, diagnosticReporter, referenceFromIndex);
      transformFfiDefinitions.transformLibraries(
        component,
        coreTypes,
        hierarchy,
        transitiveImportingDartFfi,
        diagnosticReporter,
        referenceFromIndex,
        changedStructureNotifier,
      );
      transformFfiUseSites.transformLibraries(
        this,
        component,
        coreTypes,
        hierarchy,
        transitiveImportingDartFfi,
        diagnosticReporter,
        referenceFromIndex,
        environmentDefines,
      );
      logger?.call("Transformed ffi annotations");
    }

    wasmTrans.transformLibraries(libraries, coreTypes, hierarchy);
    wasmChecks.checkDartWasmApiUseIfImported(
        libraries, coreTypes, diagnosticReporter);

    awaitTrans.transformLibraries(libraries, hierarchy, coreTypes);
  }

  @override
  void performTransformationsOnProcedure(
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      Procedure procedure,
      Map<String, String>? environmentDefines,
      {void Function(String msg)? logger}) {
    wasmTrans.transformProcedure(procedure, coreTypes, hierarchy);
  }

  Expression _instantiateInvocation(
      CoreTypes coreTypes, String name, Arguments arguments) {
    if (name.startsWith("set:")) {
      name = name.substring(4);
      Procedure invocationSetter = coreTypes.invocationClass.procedures
          .firstWhere((c) => c.name.text == "setter");
      return StaticInvocation(invocationSetter,
          Arguments([SymbolLiteral(name), arguments.positional.single]));
    } else if (name.startsWith("get:")) {
      name = name.substring(4);
      Procedure invocationGetter = coreTypes.invocationClass.procedures
          .firstWhere((c) => c.name.text == "getter");
      return StaticInvocation(
          invocationGetter, Arguments([SymbolLiteral(name)]));
    } else if (arguments.types.isEmpty) {
      Procedure invocationMethod = coreTypes.invocationClass.procedures
          .firstWhere((c) => c.name.text == "method");
      return StaticInvocation(
          invocationMethod,
          Arguments([
            SymbolLiteral(name),
            ListLiteral(arguments.positional),
            MapLiteral(List<MapLiteralEntry>.from(
                arguments.named.map((NamedExpression arg) {
              return MapLiteralEntry(SymbolLiteral(arg.name), arg.value);
            })), keyType: coreTypes.symbolNonNullableRawType)
              ..isConst = (arguments.named.isEmpty)
          ]));
    } else {
      Procedure invocationGenericMethod = coreTypes.invocationClass.procedures
          .firstWhere((c) => c.name.text == "genericMethod");
      return StaticInvocation(
          invocationGenericMethod,
          Arguments([
            SymbolLiteral(name),
            ListLiteral(arguments.types.map((t) => TypeLiteral(t)).toList()),
            ListLiteral(arguments.positional),
            MapLiteral(List<MapLiteralEntry>.from(
                arguments.named.map((NamedExpression arg) {
              return MapLiteralEntry(SymbolLiteral(arg.name), arg.value);
            })), keyType: coreTypes.symbolNonNullableRawType)
              ..isConst = (arguments.named.isEmpty)
          ]));
    }
  }

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    return _instantiateInvocation(coreTypes, name, arguments);
  }

  @override
  bool get supportsSetLiterals => true;

  @override
  bool get supportsFileUriExpression => true;

  @override
  int get enabledLateLowerings => LateLowering.all;

  @override
  int get enabledConstructorTearOffLowerings => ConstructorTearOffLowering.all;

  @override
  bool get supportsExplicitGetterCalls => true;

  @override
  bool get supportsLateLoweringSentinel => false;

  @override
  bool get useStaticFieldLowering => false;

  @override
  Class concreteListLiteralClass(CoreTypes coreTypes) {
    return _growableList ??=
        coreTypes.index.getClass('dart:_list', 'GrowableList');
  }

  @override
  Class concreteConstListLiteralClass(CoreTypes coreTypes) {
    return _immutableList ??=
        coreTypes.index.getClass('dart:_list', 'ImmutableList');
  }

  @override
  Class concreteMapLiteralClass(CoreTypes coreTypes) {
    return _wasmDefaultMap ??=
        coreTypes.index.getClass('dart:_compact_hash', 'DefaultMap');
  }

  @override
  Class concreteConstMapLiteralClass(CoreTypes coreTypes) {
    return _wasmImmutableMap ??=
        coreTypes.index.getClass('dart:_compact_hash', '_ConstMap');
  }

  @override
  Class concreteSetLiteralClass(CoreTypes coreTypes) {
    return _wasmDefaultSet ??=
        coreTypes.index.getClass('dart:_compact_hash', 'DefaultSet');
  }

  @override
  Class concreteConstSetLiteralClass(CoreTypes coreTypes) {
    return _wasmImmutableSet ??=
        coreTypes.index.getClass('dart:_compact_hash', '_ConstSet');
  }

  @override
  Class concreteStringLiteralClass(CoreTypes coreTypes, String value) {
    return _jsString ??=
        coreTypes.index.getClass("dart:_string", "JSStringImpl");
  }

  // In dart2wasm we can't assume that `x == "hello"` means `x`'s class is
  // `concreteStringLiteralClass("hello")`, it may also be `JSStringImpl` when
  // it's obtained from a JS call, or `TwoByteString` when it's a substring of a
  // `TwoByteString`.
  @override
  bool get canInferStringClassAfterEqualityComparison => false;

  @override
  Class concreteClosureClass(CoreTypes coreTypes) {
    return _closure ??= coreTypes.index.getClass('dart:core', '_Closure');
  }

  @override
  bool isSupportedPragma(String pragmaName) =>
      pragmaName.startsWith("wasm:") || pragmaName.startsWith("dyn-module:");

  late final Map<RecordShape, Class> recordClasses;

  @override
  Class getRecordImplementationClass(CoreTypes coreTypes,
          int numPositionalFields, List<String> namedFields) =>
      recordClasses[RecordShape(numPositionalFields, namedFields)]!;

  @override
  Class concreteIntLiteralClass(CoreTypes coreTypes, int value) =>
      _boxedInt ??= coreTypes.index.getClass("dart:_boxed_int", "BoxedInt");

  @override
  Class concreteDoubleLiteralClass(CoreTypes coreTypes, double value) =>
      _boxedDouble ??=
          coreTypes.index.getClass("dart:_boxed_double", "BoxedDouble");

  @override
  DartLibrarySupport get dartLibrarySupport => CustomizedDartLibrarySupport(
      unsupported: {if (!enableExperimentalFfi) 'ffi'});
}

class WasmVerification extends Verification {
  const WasmVerification();

  @override
  bool allowNoFileOffset(VerificationStage stage, TreeNode node) {
    if (super.allowNoFileOffset(stage, node)) {
      return true;
    }
    if (stage >= VerificationStage.afterModularTransformations) {
      // Allow synthesized classes, procedures, fields and casts.
      // TODO(askesc): Improve the precision of these exceptions.
      return node is Class ||
          node is Constructor ||
          node is Procedure ||
          node is Field ||
          node is AsExpression;
    }
    return false;
  }
}

const _dartFfiAndPragmaAllowlist = [
  // Flutter/benchmarks.
  'flutter',
  'engine',
  'ui',
  // Non-SDK packages that have been migrated for the Wasm experiment but
  // still have references to older interop libraries.
  'package_info_plus',
  'test',
  'url_launcher_web',
];

/// Return whether [importUri] is always allowed to import `dart:ffi` or use
/// the `wasm:` pragmas.
bool allowedToImportDartFfiOrUsePragmas(Uri importUri) =>
    // TODO(srujzs): While we allow these imports for all `dart:*` libraries, we
    // may want to restrict this further, as it may include `dart:ui`.
    importUri.isScheme('dart') ||
    importUri.isScheme('package') &&
        _dartFfiAndPragmaAllowlist.contains(
          importUri.pathSegments.first,
        );

/// Report an error if [library] incorrectly depends on `dart:ffi` and return
/// whether an error is reported.
bool _checkDisallowedDartFfiUsage(Library library,
    DiagnosticReporter<Message, LocatedMessage> diagnosticReporter) {
  if (allowedToImportDartFfiOrUsePragmas(library.importUri)) return false;

  for (final dependency in library.dependencies) {
    final dependencyUriString = dependency.targetLibrary.importUri.toString();
    if (dependencyUriString == 'dart:ffi') {
      diagnosticReporter.report(
        diag.dartFfiLibraryInDart2Wasm,
        dependency.fileOffset,
        dependencyUriString.length,
        library.fileUri,
      );
      return true;
    }
  }
  return false;
}

/// Check that `wasm:import` and `wasm:export` pragmas are only used in `dart:`
/// libraries and in tests, with the exception of the
/// `reject_import_export_pragmas` test.
void _checkWasmImportExportPragmas(Library library, CoreTypes coreTypes,
    DiagnosticReporter<Message, LocatedMessage> diagnosticReporter) {
  if (allowedToImportDartFfiOrUsePragmas(library.importUri)) return;

  for (Member member in library.members) {
    if (util.hasWasmImportPragma(coreTypes, member) ||
        util.hasWasmExportPragma(coreTypes, member) ||
        util.hasWasmWeakExportPragma(coreTypes, member)) {
      diagnosticReporter.report(
        diag.wasmImportOrExportInUserCode,
        member.fileOffset,
        0,
        library.fileUri,
      );
    }
  }
}
