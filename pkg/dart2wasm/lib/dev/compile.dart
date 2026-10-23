// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:cfg/front_end/ast_to_ir.dart';
import 'package:cfg/front_end/computed_scopes.dart';
import 'package:cfg/front_end/recognized_methods.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/ssa_computation.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/passes/pass.dart';
import 'package:front_end/src/api_unstable/vm.dart'
    show CompilerOptions, kernelForProgram;
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/library_index.dart';
import 'package:kernel/type_environment.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import '../target.dart';
import 'cfg/to_wasm.dart';
import 'runtime.dart';

const w.ValueType _jsString = w.RefType.extern(nullable: false);

/// Compiles a Dart file into a Wasm dev module.
///
/// It assumes that either
/// * [platformPath] is provided and is the path to the
///   `dart2wasm_dev_platform.dill` file or
/// * [librariesSpecPath] is provided and points to a valid `libraries.json`
///   file allowing the compiler to compile the `dart:*` libraries from source
Future<Uint8List> compile(
  Uri mainUri, {
  Uri? platformPath,
  Uri? librariesSpecPath,
}) async {
  final compilerOptions = CompilerOptions()
    ..target = WasmDevTarget()
    ..sdkRoot = Uri.file('.')
    ..librariesSpecificationUri = librariesSpecPath
    ..sdkSummary = platformPath
    ..compileSdk = platformPath == null
    ..environmentDefines = const {};
  final compilerResult = (await kernelForProgram(mainUri, compilerOptions))!;
  final component = compilerResult.component!;
  final mainMethod = component.mainMethod!;

  return GlobalContext.withContext(
    GlobalContext(
      typeEnvironment: TypeEnvironment(
        compilerResult.coreTypes!,
        compilerResult.classHierarchy!,
      ),
      coreLibraries: LibraryIndex.all(component),
    ),
    () {
      final module = w.ModuleBuilder('dev', null);
      final runtime = DevRuntime(module);
      final compiler = ModuleCompiler(module, runtime);
      compiler.compileLibrary(
        mainMethod.enclosingLibrary,
        mainMethod: mainMethod,
      );

      final serializer = w.Serializer();
      module.build().serialize(serializer);
      return serializer.data;
    },
  );
}

/// Emits a Wasm dev module's code into [module].
class ModuleCompiler {
  final w.ModuleBuilder module;
  final DevRuntime runtime;
  final FunctionRegistry functionRegistry = FunctionRegistry();
  final RecognizedMethods recognizedMethods = CommonRecognizedMethods(
    requireMethods: false,
  );

  /// Maps a static's label to the global holding its ID.
  final Map<String, w.Global> _staticIds = {};

  ModuleCompiler(this.module, this.runtime);

  w.InstructionsBuilder get _start => module.startFunction.body;

  void compileLibrary(ast.Library library, {ast.Procedure? mainMethod}) {
    for (final procedure in library.procedures) {
      _compileProcedure(procedure, isMain: procedure == mainMethod);
    }
    for (final cls in library.classes) {
      for (final procedure in cls.procedures) {
        _compileProcedure(procedure, isMain: false);
      }
    }
  }

  void _compileProcedure(ast.Procedure procedure, {required bool isMain}) {
    final cFunction = functionRegistry.getFunction(procedure);
    final graph = AstToIr(
      cFunction,
      functionRegistry,
      recognizedMethods,
      onLocalFunction: (_) {},
      enableAsserts: false,
      typeParametersStyle: .separateFunctionAndClassTypeParameters,
      scopes: ComputedScopes(procedure, enableAsserts: false),
    ).buildFlowGraph();

    Pipeline([SSAComputation()]).run(graph);

    final label = staticLabel(procedure);
    final type = functionTypeFor(cFunction);
    defineStatic(
      label,
      type,
      (b) => DevCfgToWasm(this, graph, b).generate(),
      exportName: isMain ? 'main' : null,
    );
  }

  w.FunctionType functionTypeFor(CFunction cFunction) {
    final functionNode = cFunction.functionNode!;
    final inputs = <w.ValueType>[
      for (final param in functionNode.positionalParameters)
        DevCfgToWasm.translateCType(CType.fromStaticType(param.type)),
    ];
    final returnType = cFunction.returnType;
    final outputs =
        (returnType.dartType is ast.VoidType || returnType is NeverType)
        ? const <w.ValueType>[]
        : <w.ValueType>[DevCfgToWasm.translateCType(returnType)];
    return module.types.defineFunction(inputs, outputs);
  }

  /// Defines static [label] with [type] and body [emitBody].
  void defineStatic(
    String label,
    w.FunctionType type,
    void Function(w.InstructionsBuilder b) emitBody, {
    String? exportName,
  }) {
    final functionBuilder = module.functions.define(type, label);
    emitBody(functionBuilder.body);
    final function = functionBuilder.build();
    if (exportName != null) {
      module.exports.export(exportName, function);
    }
    // Declare [function] so `ref.func` can reference it.
    module.elements.declarativeSegmentBuilder.declare(function);
    _start.global_get(_staticId(label));
    _start.ref_func(function);
    _start.call(runtime.declareStatic);
  }

  /// Emits a call to static [label] with [type].
  void callStatic(w.InstructionsBuilder b, String label, w.FunctionType type) {
    b.global_get(_staticId(label));
    b.call(runtime.lookupStatic);
    b.ref_cast(w.RefType.def(type, nullable: false));
    b.call_ref(type);
  }

  /// Returns the global holding static [label]'s ID.
  w.Global _staticId(String label) => _staticIds.putIfAbsent(label, () {
    // Emit a global variable to hold [label]'s ID.
    final globalBuilder = module.globals.define(
      w.GlobalType(w.NumType.i32, mutable: true),
      label,
    );
    // We use 0 as a placeholder but override it below.
    globalBuilder.initializer
      ..i32_const(0)
      ..end();
    pushString(_start, label);
    _start.call(runtime.staticId);
    _start.global_set(globalBuilder.global);
    return globalBuilder.build();
  });
}

/// Returns the static label for [member].
String staticLabel(ast.Member member) {
  final libraryUri = member.enclosingLibrary.importUri;
  final className = member.enclosingClass?.name;
  final memberName = member.name.text;
  if (className != null) {
    return '$libraryUri::$className.$memberName';
  }
  return '$libraryUri::$memberName';
}

/// Pushes [value] as a JS string.
// TODO: Canonicalize strings.
w.ValueType pushString(w.InstructionsBuilder b, String value) {
  b.global_get(
    b.moduleBuilder.globals.import(
      '',
      value,
      w.GlobalType(_jsString, mutable: false),
    ),
  );
  return _jsString;
}
