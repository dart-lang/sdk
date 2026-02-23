// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/front_end/ast_to_ir.dart';
import 'package:cfg/front_end/recognized_methods.dart';
import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/functions.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/stub_code_generator.dart';
import 'package:native_compiler/configuration.dart';
import 'package:native_compiler/runtime/type_utils.dart';
import 'package:native_compiler/snapshot/image_writer.dart';
import 'package:native_compiler/snapshot/snapshot.dart';

/// Accumulates contents of the whole compilation set.
class CompilationSet {
  final List<ast.Library> libraries;
  final Configuration config;
  final FunctionRegistry functionRegistry = FunctionRegistry();
  final RecognizedMethods recognizedMethods = CommonRecognizedMethods();
  final List<CFunction> _pendingFunctions = [];
  final ImageWriter _imageWriter;
  late final SnapshotSerializer _snapshot;
  late final StubFactory _stubFactory;

  CompilationSet(this.libraries, this.config)
    : _imageWriter = config.createImageWriter() {
    _snapshot = SnapshotSerializer(
      config.targetCPU,
      functionRegistry,
      config.objectLayout,
    );
    _stubFactory = config.createStubFactory(_consumeGeneratedCode);
  }

  /// Add [function] to be compiled.
  ///
  /// Can be used to queue nested local functions discovered
  /// during compilation.
  void addFunction(CFunction function) {
    _pendingFunctions.add(function);
  }

  /// Compile all functions from [libraries].
  void compileAllFunctions() {
    for (final lib in libraries) {
      for (final cls in lib.classes) {
        for (final field in cls.fields) {
          if (field.isAbstract) {
            continue;
          }
          _compileFieldFunctions(field);
          _compilePendingFunctions();
        }
        for (final constr in cls.constructors) {
          compileFunction(functionRegistry.getFunction(constr));
          _compilePendingFunctions();
        }
        for (final proc in cls.procedures) {
          if (proc.isAbstract) {
            continue;
          }
          compileFunction(
            functionRegistry.getFunction(
              proc,
              isGetter: proc.isGetter,
              isSetter: proc.isSetter,
            ),
          );
          _compilePendingFunctions();
        }
      }
      for (final field in lib.fields) {
        _compileFieldFunctions(field);
        _compilePendingFunctions();
      }
      for (final proc in lib.procedures) {
        compileFunction(
          functionRegistry.getFunction(
            proc,
            isGetter: proc.isGetter,
            isSetter: proc.isSetter,
          ),
        );
        _compilePendingFunctions();
      }
    }
  }

  void _compileFieldFunctions(ast.Field field) {
    if (field.hasGetter && !field.isStatic) {
      compileFunction(functionRegistry.getFunction(field, isGetter: true));
    }
    if (field.hasSetter && !field.isStatic) {
      compileFunction(functionRegistry.getFunction(field, isSetter: true));
    }
    if ((field.isStatic || field.isLate) && hasNonTrivialInitializer(field)) {
      compileFunction(functionRegistry.getFunction(field, isInitializer: true));
    }
  }

  void _compilePendingFunctions() {
    // [_pendingFunctions] can grow over time as local functions are
    // discovered during compilation.
    for (var i = 0; i < _pendingFunctions.length; ++i) {
      compileFunction(_pendingFunctions[i]);
    }
    _pendingFunctions.clear();
  }

  /// Compile [function] to native code.
  void compileFunction(CFunction function) {
    FlowGraph graph;
    try {
      graph = AstToIr(
        function,
        functionRegistry,
        recognizedMethods,
        enableAsserts: config.enableAsserts,
      ).buildFlowGraph();
    } catch (_) {
      print('Compiler crashed while compiling $function');
      rethrow;
    }

    config
        .createPipeline(
          function,
          functionRegistry,
          _stubFactory,
          _consumeGeneratedCode,
        )
        .run(graph);
  }

  void _consumeGeneratedCode(Code code) {
    code.instructionsImageOffset = _imageWriter.addInstructions(
      code.name,
      code.instructions,
    );
    _snapshot.addRoot(code);
  }

  void writeSnapshot(Sink<List<int>> sink) {
    _snapshot.writeModuleSnapshot();
    _imageWriter.addReadOnlyData(
      _snapshot.out.getContents(),
      _snapshot.out.position,
    );
    _imageWriter.writeTo(sink);
  }
}
