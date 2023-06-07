// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Message, LocatedMessage;
import 'package:_js_interop_checks/js_interop_checks.dart';
import 'package:_js_interop_checks/src/js_interop.dart' as jsInteropHelper;
import 'package:_js_interop_checks/src/transformations/export_creator.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/verifier.dart';
import 'package:vm/transformations/mixin_full_resolution.dart'
    as transformMixins show transformLibraries;
import 'package:vm/transformations/ffi/common.dart' as ffiHelper
    show calculateTransitiveImportsOfDartFfiIfUsed;
import 'package:vm/transformations/ffi/definitions.dart'
    as transformFfiDefinitions show transformLibraries;
import 'package:vm/transformations/ffi/use_sites.dart' as transformFfiUseSites
    show transformLibraries;
import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    as constantEvaluator show EvaluationMode;
import 'package:front_end/src/api_prototype/const_conditional_simplifier.dart'
    show ConstConditionalSimplifier;

import 'package:dart2wasm/await_transformer.dart' as awaitTrans;
import 'package:dart2wasm/ffi_native_transformer.dart' as wasmFfiNativeTrans;
import 'package:dart2wasm/records.dart' show RecordShape;
import 'package:dart2wasm/transformers.dart' as wasmTrans;

class WasmTarget extends Target {
  WasmTarget({this.removeAsserts = true});

  bool removeAsserts;
  Class? _growableList;
  Class? _immutableList;
  Class? _wasmDefaultMap;
  Class? _wasmDefaultSet;
  Class? _wasmImmutableMap;
  Class? _wasmImmutableSet;
  Class? _oneByteString;
  Class? _twoByteString;
  Map<String, Class>? _nativeClasses;

  @override
  bool get enableNoSuchMethodForwarders => true;

  @override
  ConstantsBackend get constantsBackend => const ConstantsBackend();

  @override
  Verification get verification => const WasmVerification();

  @override
  String get name => 'wasm';

  @override
  TargetFlags get flags => TargetFlags();

  @override
  List<String> get extraRequiredLibraries => const <String>[
        'dart:async',
        'dart:ffi',
        'dart:_internal',
        'dart:_http',
        'dart:_js_helper',
        'dart:typed_data',
        'dart:nativewrappers',
        'dart:io',
        'dart:js_interop',
        'dart:js_interop_unsafe',
        'dart:js',
        'dart:js_util',
        'dart:_wasm',
        'dart:developer',
      ];

  @override
  List<String> get extraIndexedLibraries => const <String>[
        'dart:_js_helper',
        'dart:collection',
        'dart:typed_data',
        'dart:js_interop',
        'dart:js_util',
        'dart:_wasm',
      ];

  bool allowPlatformPrivateLibraryAccess(Uri importer, Uri imported) =>
      super.allowPlatformPrivateLibraryAccess(importer, imported) ||
      importer.path.contains('tests/web/wasm') ||
      importer.isScheme('package') && importer.path == 'js/js.dart';

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
    host.initializer = new CloneVisitorNotMembers().clone(little.initializer!)
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
        isDart2Wasm: true, enableStrictMode: true);
    // Process and validate first before doing anything with exports.
    for (Library library in interopDependentLibraries) {
      jsInteropChecks.visitLibrary(library);
    }
    final exportCreator = ExportCreator(TypeEnvironment(coreTypes, hierarchy),
        jsInteropReporter, jsInteropChecks.exportChecker);
    for (Library library in interopDependentLibraries) {
      exportCreator.visitLibrary(library);
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
      {void logger(String msg)?,
      ChangedStructureNotifier? changedStructureNotifier}) {
    Set<Library> transitiveImportingJSInterop = {
      ...?jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component, Uri.parse("package:js/js.dart")),
      ...?jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component, Uri.parse("dart:_js_annotations")),
      ...?jsInteropHelper.calculateTransitiveImportsOfJsInteropIfUsed(
          component, Uri.parse("dart:js_interop")),
    };
    if (transitiveImportingJSInterop.isEmpty) {
      logger?.call("Skipped JS interop transformations");
    } else {
      _performJSInteropTransformations(component, coreTypes, hierarchy,
          transitiveImportingJSInterop, diagnosticReporter, referenceFromIndex);
      logger?.call("Transformed JS interop classes");
    }

    final reportError =
        (LocatedMessage message, [List<LocatedMessage>? context]) {
      diagnosticReporter.report(message.messageObject, message.charOffset,
          message.length, message.uri);
      if (context != null) {
        for (final m in context) {
          diagnosticReporter.report(
              m.messageObject, m.charOffset, m.length, m.uri);
        }
      }
    };

    ConstConditionalSimplifier(
      dartLibrarySupport,
      constantsBackend,
      component,
      reportError,
      environmentDefines: environmentDefines ?? {},
      evaluationMode: constantEvaluator.EvaluationMode.strong,
      coreTypes: coreTypes,
      classHierarchy: hierarchy,
      removeAsserts: removeAsserts,
    ).run();

    transformMixins.transformLibraries(
        this, coreTypes, hierarchy, libraries, referenceFromIndex);
    logger?.call("Transformed mixin applications");

    List<Library>? transitiveImportingDartFfi = ffiHelper
        .calculateTransitiveImportsOfDartFfiIfUsed(component, libraries);
    if (transitiveImportingDartFfi == null) {
      logger?.call("Skipped ffi transformation");
    } else {
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

    wasmTrans.transformLibraries(
        libraries, coreTypes, hierarchy, diagnosticReporter);

    awaitTrans.transformLibraries(libraries, hierarchy, coreTypes);
  }

  @override
  void performTransformationsOnProcedure(
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      Procedure procedure,
      Map<String, String>? environmentDefines,
      {void logger(String msg)?}) {
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
              return new MapLiteralEntry(SymbolLiteral(arg.name), arg.value);
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
  bool enableNative(Uri uri) => true;

  @override
  Class concreteListLiteralClass(CoreTypes coreTypes) {
    return _growableList ??=
        coreTypes.index.getClass('dart:core', '_GrowableList');
  }

  @override
  Class concreteConstListLiteralClass(CoreTypes coreTypes) {
    return _immutableList ??=
        coreTypes.index.getClass('dart:core', '_ImmutableList');
  }

  @override
  Class concreteMapLiteralClass(CoreTypes coreTypes) {
    return _wasmDefaultMap ??=
        coreTypes.index.getClass('dart:collection', '_WasmDefaultMap');
  }

  @override
  Class concreteConstMapLiteralClass(CoreTypes coreTypes) {
    return _wasmImmutableMap ??=
        coreTypes.index.getClass('dart:collection', '_WasmImmutableMap');
  }

  @override
  Class concreteSetLiteralClass(CoreTypes coreTypes) {
    return _wasmDefaultSet ??=
        coreTypes.index.getClass('dart:collection', '_WasmDefaultSet');
  }

  @override
  Class concreteConstSetLiteralClass(CoreTypes coreTypes) {
    return _wasmImmutableSet ??=
        coreTypes.index.getClass('dart:collection', '_WasmImmutableSet');
  }

  @override
  Class concreteStringLiteralClass(CoreTypes coreTypes, String value) {
    const int maxLatin1 = 0xff;
    for (int i = 0; i < value.length; ++i) {
      if (value.codeUnitAt(i) > maxLatin1) {
        return _twoByteString ??=
            coreTypes.index.getClass('dart:core', '_TwoByteString');
      }
    }
    return _oneByteString ??=
        coreTypes.index.getClass('dart:core', '_OneByteString');
  }

  @override
  bool isSupportedPragma(String pragmaName) => pragmaName.startsWith("wasm:");

  late final Map<RecordShape, Class> recordClasses;

  @override
  Class getRecordImplementationClass(CoreTypes coreTypes,
          int numPositionalFields, List<String> namedFields) =>
      recordClasses[RecordShape(numPositionalFields, namedFields)]!;
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
