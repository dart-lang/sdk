// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Message, LocatedMessage, messageWasmImportOrExportInUserCode;
import 'package:_js_interop_checks/js_interop_checks.dart';
import 'package:_js_interop_checks/src/js_interop.dart' as jsInteropHelper;
import 'package:_js_interop_checks/src/transformations/shared_interop_transformer.dart';
import 'package:front_end/src/api_prototype/const_conditional_simplifier.dart'
    show ConstConditionalSimplifier;
import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    as constantEvaluator show ConstantEvaluator, EvaluationMode;
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

enum Mode {
  regular,
  jsCompatibility,
}

class Dart2WasmConstantsBackend extends ConstantsBackend {
  const Dart2WasmConstantsBackend();

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
  Class? _oneByteString;
  Class? _twoByteString;
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
        'dart:js_util',
        'dart:nativewrappers',
        'dart:typed_data',
      ];

  @override
  List<String> get extraIndexedLibraries => [
        'dart:_boxed_bool',
        'dart:_boxed_double',
        'dart:_boxed_int',
        'dart:_compact_hash',
        'dart:_js_helper',
        'dart:_js_types',
        'dart:_list',
        'dart:_string',
        'dart:_wasm',
        'dart:collection',
        'dart:js_interop',
        'dart:js_interop_unsafe',
        'dart:js_util',
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

    // package:js can import dart:js_util & dart:_js_*
    if (importerString.startsWith('package:js/')) return true;

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
        isDart2Wasm: true, enableExperimentalFfi: enableExperimentalFfi);
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
    if (!enableExperimentalWasmInterop) {
      // Check `wasm:import` and `wasm:export` pragmas before FFI transforms as
      // FFI transforms convert JS interop annotations to these pragmas.
      _checkWasmImportExportPragmas(libraries, coreTypes,
          diagnosticReporter as DiagnosticReporter<Message, LocatedMessage>);
    }

    Set<Library> transitiveImportingJSInterop = {
      ...jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component, Uri.parse("package:js/js.dart")),
      ...jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component, Uri.parse("dart:_js_annotations")),
      ...jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component, Uri.parse("dart:js_interop")),
      ...jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component, Uri.parse("dart:convert")),
      ...jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component, Uri.parse("dart:_string")),
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
        evaluationMode: constantEvaluator.EvaluationMode.strong,
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
    if (transitiveImportingDartFfi == null) {
      logger?.call("Skipped ffi transformation");
    } else {
      wasmFfiNativeAddressTrans.transformLibraries(
          component,
          coreTypes,
          hierarchy,
          transitiveImportingDartFfi,
          diagnosticReporter,
          referenceFromIndex);
      wasmFfiNativeTrans.transformLibraries(component, coreTypes, hierarchy,
          transitiveImportingDartFfi, diagnosticReporter, referenceFromIndex);
      transformFfiDefinitions.transformLibraries(
          component,
          coreTypes,
          hierarchy,
          transitiveImportingDartFfi,
          diagnosticReporter,
          referenceFromIndex,
          changedStructureNotifier);
      transformFfiUseSites.transformLibraries(component, coreTypes, hierarchy,
          transitiveImportingDartFfi, diagnosticReporter, referenceFromIndex);
      logger?.call("Transformed ffi annotations");
    }

    wasmTrans.transformLibraries(libraries, coreTypes, hierarchy);

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
  Expression instantiateNoSuchMethodError(CoreTypes coreTypes,
      Expression receiver, String name, Arguments arguments, int offset,
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
    return StaticInvocation(
        coreTypes.noSuchMethodErrorDefaultConstructor,
        Arguments(
            [receiver, _instantiateInvocation(coreTypes, name, arguments)]));
  }

  @override
  bool get supportsSetLiterals => true;

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
    // In JSCM all strings are JS strings.
    if (mode == Mode.jsCompatibility) {
      return _jsString ??=
          coreTypes.index.getClass("dart:_string", "JSStringImpl");
    }
    const int maxLatin1 = 0xff;
    for (int i = 0; i < value.length; ++i) {
      if (value.codeUnitAt(i) > maxLatin1) {
        return _twoByteString ??=
            coreTypes.index.getClass('dart:_string', 'TwoByteString');
      }
    }
    return _oneByteString ??=
        coreTypes.index.getClass('dart:_string', 'OneByteString');
  }

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

final _dartCoreUri = Uri.parse('dart:core');

/// Check that `wasm:import` and `wasm:export` pragmas are only used in `dart:`
/// libraries and in tests, with the exception of
/// `reject_import_export_pragmas` test.
void _checkWasmImportExportPragmas(List<Library> libraries, CoreTypes coreTypes,
    DiagnosticReporter<Message, LocatedMessage> diagnosticReporter) {
  for (Library library in libraries) {
    final importUri = library.importUri;
    if (importUri.isScheme('dart') ||
        (importUri.isScheme('package') &&
            JsInteropChecks.allowedInteropLibrariesInDart2WasmPackages
                .any((pkg) => importUri.pathSegments.first == pkg))) {
      continue;
    }

    for (Member member in library.members) {
      for (Expression annotation in member.annotations) {
        if (annotation is! ConstantExpression) {
          continue;
        }
        final annotationConstant = annotation.constant;
        if (annotationConstant is! InstanceConstant) {
          continue;
        }
        final cls = annotationConstant.classNode;
        if (cls.name == 'pragma' &&
            cls.enclosingLibrary.importUri == _dartCoreUri) {
          final pragmaName = annotationConstant
              .fieldValues[coreTypes.pragmaName.fieldReference];
          if (pragmaName is StringConstant) {
            if (pragmaName.value == 'wasm:import' ||
                pragmaName.value == 'wasm:export') {
              diagnosticReporter.report(
                messageWasmImportOrExportInUserCode,
                annotation.fileOffset,
                0,
                library.fileUri,
              );
            }
          }
        }
      }
    }
  }
}
