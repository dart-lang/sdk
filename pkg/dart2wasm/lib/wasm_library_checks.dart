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
import 'wasm_annotations.dart';

/// Validates (a subset of) `dart:_wasm` usages.
///
/// So far, we validate usages of:
///   * `Memory` and `MemoryAccessExtension`.
void checkDartWasmApiUseIfImported(
  Iterable<Library> libraries,
  CoreTypes coreTypes,
  DiagnosticReporter diagnosticReporter,
) {
  final checks = _DartWasmLibraryChecks(coreTypes, diagnosticReporter);
  for (final library in libraries) {
    // Skip the check if the library doesn't import dart:_wasm.
    // TODO: This misses libraries importing dart:_wasm through an export.
    for (final dependency in library.dependencies) {
      if (!dependency.isImport) continue;
      if (dependency.targetLibrary == checks.wasmLibrary) {
        library.accept(checks);
        continue;
      }
    }
  }
}

class _DartWasmLibraryChecks extends RecursiveVisitor with KernelNodes {
  Member? _currentMember;

  final DiagnosticReporter _diagnosticReporter;

  @override
  final CoreTypes coreTypes;

  @override
  LibraryIndex get index => coreTypes.index;

  _DartWasmLibraryChecks(this.coreTypes, this._diagnosticReporter);

  @override
  void visitLibrary(Library library) {
    if (library == wasmLibrary) {
      // The CFE generates getters to tear off extension methods, which look
      // like illegal dynamic invocations to this visitor. We verify that
      // tearoffs aren't used, but don't visit the source library to avoid
      // false-positives here.
      return;
    }

    library.visitChildren(this);
  }

  @override
  void defaultMember(Member node) {
    _currentMember = node;
    node.visitChildren(this);
  }

  @override
  void visitProcedure(Procedure node) {
    _currentMember = node;

    if (_categorizeWasmExtern(node) == ExternType.memory) {
      final parsed = MemoryLimits.readAnnotation(this, node);
      if (parsed == null) {
        _diagnosticReporter.report(diag.wasmExternMemoryMissingAnnotation,
            node.fileOffset, 1, node.fileUri);
      }
    }

    node.visitChildren(this);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    final target = node.target;
    if (target.enclosingLibrary == wasmLibrary &&
        target.name.text.startsWith('MemoryAccessExtension|')) {
      final args = node.arguments;
      final memory = args.positional[0];
      final isTearOff = target.function.returnType is FunctionType;

      if (isTearOff) {
        // Reference to a getter generated to implement tear offs, e.g. in
        // memory.fill (as opposed to a direct memory.fill(a, b, c) call).
        _diagnosticReporter.report(diag.wasmIntrinsicTearOff, node.fileOffset,
            1, _currentMember!.fileUri);
      }

      if (_isWasmMemoryRef(memory)) {
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
                  diag.constEvalNonConstantVariableGet
                      .withArguments(name: named.name),
                  named.value.fileOffset,
                  1,
                  _currentMember!.fileUri);
            }
          }
        }

        return;
      } else {
        _diagnosticReporter.report(diag.wasmExternInvalidTarget,
            node.fileOffset, 0, _currentMember!.fileUri);
      }
    }

    super.visitStaticInvocation(node);
  }

  @override
  void visitStaticGet(StaticGet node) {
    if (_isWasmMemoryRef(node)) {
      // The only valid use of a wasm element is to call an intrinsic extension
      // method on it, in which case an outer visit method would have skipped
      // this node. This get is invalid.
      _diagnosticReporter.report(diag.wasmExternInvalidLoad, node.fileOffset, 1,
          _currentMember!.fileUri);
    }

    super.visitStaticGet(node);
  }

  /// Checks whether the getter defines an external WebAssembly member that can
  /// only be used through intrinsics.
  ExternType? _categorizeWasmExtern(Member getter) {
    if (getter is Procedure && getter.isExternal) {
      final type = getter.function.returnType;

      if (type is InterfaceType) {
        if (type.classNode == wasmMemoryClass) {
          return ExternType.memory;
        }
      }
    }

    return null;
  }

  bool _isWasmMemoryRef(Expression expr) {
    return expr is StaticGet &&
        _categorizeWasmExtern(expr.target) == ExternType.memory;
  }
}
