// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/target/targets.dart';

import 'intrinsics.dart';
import 'kernel_nodes.dart';
import 'util.dart' as util;
import 'wasm_annotations.dart';

/// Validates (a subset of) `dart:_wasm` usages.
///
/// So far, we validate usages of:
///   * `Memory` and `MemoryAccessExtension`.
///   * `WasmTable` and `WasmTableAccessExtension`.
///   * `Global`, `MutableGlobal`, `GlobalGet`, and `GlobalSet`.
///   * `wasm:import`, `wasm:export`, and `wasm:weak-export` pragmas.
void checkDartWasmApiUse(
  Iterable<Library> libraries,
  CoreTypes coreTypes,
  DiagnosticReporter diagnosticReporter, {
  required bool isStandalone,
  required bool enableExperimentalWasmInterop,
}) {
  final checks = _DartWasmLibraryChecks(
    coreTypes,
    isStandalone,
    diagnosticReporter,
  );
  for (final library in libraries) {
    if (enableExperimentalWasmInterop || library.importUri.isScheme('dart')) {
      library.accept(checks);
    }
  }
}

class _DartWasmLibraryChecks extends _BaseVerifier
    with _ExternVerifierMixin, _ImportExportVerifierMixin, _SimdVerifierMixin {
  _DartWasmLibraryChecks(
    super.coreTypes,
    super.isStandalone,
    super._diagnosticReporter,
  );
}

abstract class _BaseVerifier extends RecursiveVisitor with KernelNodes {
  final DiagnosticReporter _diagnosticReporter;
  final Set<Constant> _visitedConstants = {};
  Member? _currentMember;
  ConstantExpression? _currentConstantExpression;

  @override
  final CoreTypes coreTypes;

  @override
  final bool isStandalone;

  @override
  LibraryIndex get index => coreTypes.index;

  _BaseVerifier(this.coreTypes, this.isStandalone, this._diagnosticReporter);

  @override
  void visitLibrary(Library library) {
    if (library == wasmLibrary) {
      // The CFE generates getters to tear off extension methods, which look
      // like illegal dynamic invocations to this visitor. We verify that
      // tearoffs aren't used, but don't visit the source library to avoid
      // false-positives here.
      return;
    }

    super.visitLibrary(library);
  }

  @override
  void defaultMember(Member node) {
    final oldMember = _currentMember;
    _currentMember = node;
    super.defaultMember(node);
    _currentMember = oldMember;
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    final oldConstantExpression = _currentConstantExpression;
    _currentConstantExpression = node;
    super.visitConstantExpression(node);
    _currentConstantExpression = oldConstantExpression;
  }

  @override
  void defaultConstantReference(Constant node) {
    if (_visitedConstants.add(node)) {
      node.accept(this);
    }
  }

  /// Checks whether the getter defines an external WebAssembly member that can
  /// only be used through intrinsics.
  ExternType? _categorizeWasmExtern(Member getter) =>
      ExternType.of(this, getter);

  bool _isValidExternalFunctionType(DartType type) {
    return type is FunctionType &&
        !type.isPotentiallyNullable &&
        type.typeParameters.isEmpty &&
        type.namedParameters.isEmpty &&
        type.requiredParameterCount == type.positionalParameters.length &&
        type.positionalParameters.every(_isValidExternalValueType) &&
        _isValidExternalReturnType(type.returnType);
  }

  bool _isValidExternalReturnType(DartType type) {
    return (type is InterfaceType &&
            type.classNode == wasmVoidClass &&
            !type.isPotentiallyNullable) ||
        _isValidExternalValueType(type);
  }

  bool _isValidExternalValueType(DartType type) {
    if (type is! InterfaceType) return false;
    final cls = type.classNode;
    if (cls == wasmI8Class || cls == wasmI16Class) return false;
    return _isValidExternalStorageType(type);
  }

  bool _isValidExternalStorageType(DartType type) {
    if (type is! InterfaceType) return false;
    final cls = type.classNode;
    final isNullable = type.isPotentiallyNullable;
    if (cls == wasmI8Class ||
        cls == wasmI16Class ||
        cls == wasmI32Class ||
        cls == wasmI64Class ||
        cls == wasmF32Class ||
        cls == wasmF64Class ||
        cls == wasmV128Class) {
      return !isNullable;
    }
    return _isValidExternalReferenceType(type);
  }

  bool _isValidExternalReferenceType(DartType type) {
    if (type is! InterfaceType) return false;
    final cls = type.classNode;
    if (cls == wasmAnyRefClass ||
        cls == wasmExternRefClass ||
        cls == wasmI31RefClass ||
        cls == wasmFuncRefClass ||
        cls == wasmEqRefClass ||
        cls == wasmStructRefClass ||
        cls == wasmArrayRefClass) {
      return true;
    }
    if (cls == wasmArrayClass || cls == immutableWasmArrayClass) {
      return _isValidExternalStorageType(type.typeArguments.single);
    }
    if (cls == wasmFunctionClass) {
      return _isValidExternalFunctionType(type.typeArguments.single);
    }
    return false;
  }
}

/// Verifies usages of `Memory`, `WasmTable`, and `Global` externs.
mixin _ExternVerifierMixin on _BaseVerifier {
  @override
  void defaultMember(Member node) {
    if (_categorizeWasmExtern(node) == ExternType.memory) {
      final parsed = WasmMemoryType.readAnnotation(this, node);
      if (parsed == null) {
        _diagnosticReporter.report(
          diag.wasmExternMemoryMissingAnnotation,
          node.fileOffset,
          1,
          node.fileUri,
        );
      } else {
        _checkLimits(node, parsed.minSize, parsed.maxSize);
        if (parsed.shared && parsed.maxSize == null) {
          _diagnosticReporter.report(
            diag.wasmSharedMemoryMissingMaximum,
            node.fileOffset,
            1,
            node.fileUri,
          );
        }
      }
    } else if (_categorizeWasmExtern(node) == ExternType.table) {
      final parsed = WasmTableType.readAnnotation(this, node);
      if (parsed == null) {
        _diagnosticReporter.report(
          diag.wasmExternTableMissingAnnotation,
          node.fileOffset,
          1,
          node.fileUri,
        );
      } else {
        _checkLimits(node, parsed.minSize, parsed.maxSize);
      }

      final returnType =
          (node as Procedure).function.returnType as InterfaceType;
      final elementType = returnType.typeArguments.single;
      if (!elementType.isPotentiallyNullable ||
          !_isValidExternalReferenceType(elementType)) {
        _diagnosticReporter.report(
          diag.wasmTableInvalidElementType.withArguments(type: elementType),
          node.fileOffset,
          1,
          node.fileUri,
        );
      }
    }

    super.defaultMember(node);
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    final receiver = _unwrapDeferredLoadCheck(node.receiver);
    if (receiver is StaticInvocation &&
        receiver.target == wasmTableCallIndirect) {
      _validateExternReceiverAndVisitArgs(receiver, .table);

      final args = receiver.arguments;
      final tableElementType = args.types[0];
      final functionType = args.types[1];
      final isValidTableType =
          tableElementType is InterfaceType &&
          (tableElementType.classNode == wasmFuncRefClass ||
              (tableElementType.classNode == wasmFunctionClass &&
                  tableElementType.typeArguments.single == functionType));
      if (!isValidTableType || !_isValidExternalFunctionType(functionType)) {
        _diagnosticReporter.report(
          diag.wasmTableCallIndirectInvalidUsage,
          receiver.fileOffset,
          1,
          _currentMember!.fileUri,
        );
      }

      node.arguments.accept(this);
      return;
    }

    super.visitFunctionInvocation(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    if (_validateMemoryAccessIntrinsic(node)) {
      return;
    }
    if (_validateTableAccessIntrinsic(node)) {
      return;
    }
    if (_validateGlobalAccessIntrinsic(node)) {
      return;
    }

    super.visitStaticInvocation(node);
  }

  bool _validateMemoryAccessIntrinsic(StaticInvocation node) {
    final target = node.target;
    if (target.enclosingLibrary == wasmLibrary &&
        target.name.text.startsWith('MemoryAccessExtension|')) {
      final args = node.arguments;
      final memory = args.positional[0];
      _checkNoTearOff(node, target);

      if (_isWasmExternRef(memory, .memory)) {
        for (final positional in args.positional.skip(1)) {
          positional.accept(this);
        }

        for (final named in args.named) {
          named.accept(this);

          // The parameter to the align and offset method should be a compile-
          // time constant.
          if (named.name case 'align' || 'offset') {
            if (extractIntValue(named.value) == null) {
              _diagnosticReporter.report(
                diag.constEvalNonConstantVariableGet.withArguments(
                  name: named.name,
                ),
                named.value.fileOffset,
                1,
                _currentMember!.fileUri,
              );
            }
          }
        }

        return true;
      }

      _diagnosticReporter.report(
        diag.wasmExternInvalidTarget,
        node.fileOffset,
        0,
        _currentMember!.fileUri,
      );
    }

    return false;
  }

  bool _validateTableAccessIntrinsic(StaticInvocation node) {
    final target = node.target;
    if (target.enclosingLibrary == wasmLibrary &&
        target.name.text.startsWith('WasmTableAccessExtension|')) {
      if (target == wasmTableCallIndirect) {
        _diagnosticReporter.report(
          diag.wasmTableCallIndirectInvalidUsage,
          node.fileOffset,
          1,
          _currentMember!.fileUri,
        );
      } else {
        _checkNoTearOff(node, target);
      }

      _validateExternReceiverAndVisitArgs(node, .table);
      return true;
    }

    return false;
  }

  bool _validateGlobalAccessIntrinsic(StaticInvocation node) {
    final target = node.target;
    if (target.enclosingLibrary == wasmLibrary &&
        (target.name.text.startsWith('GlobalGet|') ||
            target.name.text.startsWith('GlobalSet|'))) {
      _checkNoTearOff(node, target);

      _validateExternReceiverAndVisitArgs(node, .global);
      return true;
    }

    return false;
  }

  void _validateExternReceiverAndVisitArgs(
    StaticInvocation call,
    ExternType expectedType,
  ) {
    final args = call.arguments;
    if (_isWasmExternRef(args.positional[0], expectedType)) {
      for (final positional in args.positional.skip(1)) {
        positional.accept(this);
      }
      final getter =
          (_unwrapDeferredLoadCheck(args.positional[0]) as StaticGet).target
              as Procedure;
      final returnType = getter.function.returnType as InterfaceType;
      if (args.types.first != returnType.typeArguments.single) {
        _diagnosticReporter.report(
          diag.wasmExternInvalidTarget,
          call.fileOffset,
          0,
          _currentMember!.fileUri,
        );
      }
    } else {
      _diagnosticReporter.report(
        diag.wasmExternInvalidTarget,
        call.fileOffset,
        0,
        _currentMember!.fileUri,
      );
      for (final positional in args.positional) {
        positional.accept(this);
      }
    }
  }

  void _checkNoTearOff(StaticInvocation node, Procedure target) {
    final isTearOff = target.function.returnType is FunctionType;

    if (isTearOff) {
      // Reference to a getter generated to implement tear offs, e.g. in
      // memory.fill (as opposed to a direct memory.fill(a, b, c) call).
      _diagnosticReporter.report(
        diag.wasmIntrinsicTearOff,
        node.fileOffset,
        1,
        _currentMember!.fileUri,
      );
    }
  }

  @override
  void visitStaticGet(StaticGet node) {
    if (_categorizeWasmExtern(node.target) != null) {
      // The only valid use of a wasm element is to call an intrinsic extension
      // method on it, in which case an outer visit method would have skipped
      // this node. This get is invalid.
      _diagnosticReporter.report(
        diag.wasmExternInvalidLoad,
        node.fileOffset,
        1,
        _currentMember!.fileUri,
      );
    }

    super.visitStaticGet(node);
  }

  /// Unwraps a deferred library load check if [expr] was produced by accessing
  /// a member through a deferred import prefix (e.g. `M.table[i] = v`,
  /// `(M.memory).size`, or `M.table.callIndirect<...>(i)(...)`).
  Expression _unwrapDeferredLoadCheck(Expression expr) {
    if (expr case Let(value: CheckLibraryIsLoaded(), :final body)) {
      return body;
    }
    return expr;
  }

  bool _isWasmExternRef(Expression expr, ExternType expectedType) {
    expr = _unwrapDeferredLoadCheck(expr);
    return expr is StaticGet &&
        _categorizeWasmExtern(expr.target) == expectedType;
  }

  void _checkLimits(Member node, int minSize, int? maxSize) {
    if (minSize < 0 || (maxSize != null && maxSize < minSize)) {
      _diagnosticReporter.report(
        diag.wasmInvalidLimits,
        node.fileOffset,
        1,
        node.fileUri,
      );
    }
  }
}

mixin _ImportExportVerifierMixin on _BaseVerifier {
  @override
  void defaultMember(Member node) {
    _checkImportExportPragmas(node);
    super.defaultMember(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    final target = node.target;
    if (target == exportWasmFunctionProcedure) {
      final tearOffTarget = _extractStaticTearOffTarget(
        node.arguments.positional.single,
      );
      if (tearOffTarget != null &&
          util.hasWasmWeakExportPragma(coreTypes, tearOffTarget)) {
        return;
      }
    } else if (target == wasmFunctionFromFunction) {
      final tearOffTarget = _extractStaticTearOffTarget(
        node.arguments.positional.single,
      );
      if (tearOffTarget == null ||
          !tearOffTarget.isStatic ||
          tearOffTarget.kind != ProcedureKind.Method ||
          !_hasValidWasmSignature(tearOffTarget.function) ||
          node.arguments.types.single !=
              tearOffTarget.function.computeFunctionType(
                Nullability.nonNullable,
              )) {
        _diagnosticReporter.report(
          diag.wasmFunctionFromFunctionInvalidArgument,
          node.fileOffset,
          1,
          _currentMember!.fileUri,
        );
      }
      return;
    }

    super.visitStaticInvocation(node);
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    if (_hasAnyImportOrExportPragma(node.target)) {
      _diagnosticReporter.report(
        diag.wasmImportOrExportTearOff,
        node.fileOffset,
        1,
        _currentMember?.fileUri ?? node.location?.file,
      );
    }

    super.visitStaticTearOff(node);
  }

  @override
  void visitStaticTearOffConstant(StaticTearOffConstant node) {
    if (_hasAnyImportOrExportPragma(node.target)) {
      final expr = _currentConstantExpression!;
      _diagnosticReporter.report(
        diag.wasmImportOrExportTearOff,
        expr.fileOffset,
        1,
        _currentMember?.fileUri ?? expr.location?.file,
      );
    }
    super.visitStaticTearOffConstant(node);
  }

  void _checkImportExportPragmas(Member node) {
    final hasImport = util.hasWasmImportPragma(coreTypes, node);
    final hasExport = util.hasWasmExportPragma(coreTypes, node);
    final hasWeakExport = util.hasWasmWeakExportPragma(coreTypes, node);
    if (!hasImport && !hasExport && !hasWeakExport) return;

    final externType = _categorizeWasmExtern(node);
    final isMethod = node is Procedure && node.kind == ProcedureKind.Method;

    if (hasImport) {
      final isValidImport =
          node is Procedure &&
          node.isStatic &&
          node.isExternal &&
          (isMethod || externType != null) &&
          !hasExport &&
          !hasWeakExport &&
          util.getWasmImportPragma(coreTypes, node) != null;
      if (!isValidImport) {
        _diagnosticReporter.report(
          diag.wasmImportInvalidPragma,
          node.fileOffset,
          1,
          node.fileUri,
        );
      }
    }

    if (hasExport || hasWeakExport) {
      final isValidExport =
          ((isMethod && node.isStatic && !node.isExternal) ||
              (externType != null && hasExport)) &&
          !hasImport &&
          !(hasExport && hasWeakExport) &&
          (hasExport
              ? util.getWasmExportPragma(coreTypes, node) != null
              : util.getWasmWeakExportPragma(coreTypes, node) != null);
      if (!isValidExport) {
        _diagnosticReporter.report(
          diag.wasmExportInvalidPragma,
          node.fileOffset,
          1,
          node.fileUri,
        );
      }
    }

    if (isMethod) {
      final function = node.function;
      if (!_hasOnlyRequiredPositionalParameters(function)) {
        _diagnosticReporter.report(
          diag.wasmImportOrExportInvalidSignature,
          node.fileOffset,
          1,
          node.fileUri,
        );
      }

      for (final param in function.positionalParameters) {
        if (!_isValidExternalValueType(param.type)) {
          _diagnosticReporter.report(
            diag.wasmImportOrExportInvalidParameterType.withArguments(
              type: param.type,
            ),
            param.fileOffset != TreeNode.noOffset
                ? param.fileOffset
                : node.fileOffset,
            1,
            node.fileUri,
          );
        }
      }

      final returnType = function.returnType;
      if (!_isValidExternalReturnType(returnType)) {
        _diagnosticReporter.report(
          diag.wasmImportOrExportInvalidReturnType.withArguments(
            type: returnType,
          ),
          node.fileOffset,
          1,
          node.fileUri,
        );
      }
    }
  }

  Procedure? _extractStaticTearOffTarget(Expression expr) {
    return switch (expr) {
      StaticTearOff(:final target) => target,
      ConstantExpression(constant: StaticTearOffConstant(:final target)) =>
        target,
      _ => null,
    };
  }

  bool _hasValidWasmSignature(FunctionNode function) {
    return _hasOnlyRequiredPositionalParameters(function) &&
        function.positionalParameters.every(
          (param) => _isValidExternalValueType(param.type),
        ) &&
        _isValidExternalReturnType(function.returnType);
  }

  bool _hasOnlyRequiredPositionalParameters(FunctionNode function) {
    return function.typeParameters.isEmpty &&
        function.namedParameters.isEmpty &&
        function.requiredParameterCount == function.positionalParameters.length;
  }

  bool _hasAnyImportOrExportPragma(Member member) {
    if (member.annotations.isEmpty) return false;
    return util.hasWasmImportPragma(coreTypes, member) ||
        util.hasWasmExportPragma(coreTypes, member) ||
        util.hasWasmWeakExportPragma(coreTypes, member);
  }
}

mixin _SimdVerifierMixin on _BaseVerifier {
  @override
  void visitInstanceConstant(InstanceConstant node) {
    final classNode = node.classNode;
    if (classNode == wasmI8x16ImplClass) {
      _validateLanes(node, classNode, -128, 127, "8-bit");
    } else if (classNode == wasmI16x8ImplClass) {
      _validateLanes(node, classNode, -32768, 32767, "16-bit");
    } else if (classNode == wasmI32x4ImplClass) {
      _validateLanes(node, classNode, -2147483648, 2147483647, "32-bit");
    }
    super.visitInstanceConstant(node);
  }

  void _validateLanes(
    InstanceConstant constant,
    Class cls,
    int min,
    int max,
    String size,
  ) {
    for (final field in cls.fields) {
      final laneConstant = constant.fieldValues[field.fieldReference];
      if (laneConstant is IntConstant) {
        final value = laneConstant.value;
        if (value < min || value > max) {
          _diagnosticReporter.report(
            diag.wasmConstantLaneOutOfRange.withArguments(
              name: field.name.text,
              value: value,
              size: size,
            ),
            _currentConstantExpression!.fileOffset,
            1,
            _currentMember?.fileUri,
          );
        }
      }
    }
  }
}
