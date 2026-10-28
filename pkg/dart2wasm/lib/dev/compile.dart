// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:cfg/front_end/ast_to_ir.dart';
import 'package:cfg/front_end/computed_scopes.dart';
import 'package:cfg/front_end/recognized_methods.dart';
import 'package:cfg/ir/flow_graph.dart';
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

  // TODO(dart2wasm): Add support for class fields.
  late final w.StructType objectStruct = module.types.defineStruct(
    'Object',
    fields: [w.FieldType(w.NumType.i32, mutable: false)],
    brand: false,
  );

  /// Maps a static's label to the global holding its ID.
  final Map<String, w.Global> _staticIds = {};

  /// Maps a class's label to the global holding its ID.
  final Map<String, w.Global> _classIds = {};

  /// Maps an instance member name to the global holding its ID.
  final Map<String, w.Global> _instanceMemberIds = {};

  ModuleCompiler(this.module, this.runtime);

  w.InstructionsBuilder get _start => module.startFunction.body;

  void compileLibrary(ast.Library library, {ast.Procedure? mainMethod}) {
    for (final procedure in library.procedures) {
      _compileProcedure(procedure, isMain: procedure == mainMethod);
    }
    for (final cls in library.classes) {
      defineClassSupers(cls);
      for (final constructor in cls.constructors) {
        _compileConstructor(constructor);
      }
      startInstanceMemberDefinitions(cls);
      for (final procedure in cls.procedures) {
        if (procedure.isAbstract) continue; // Not needed at runtime.
        _compileProcedure(procedure, isMain: false);
      }
      endInstanceMemberDefinitions(cls);
    }
  }

  void _compileProcedure(ast.Procedure procedure, {required bool isMain}) {
    final cFunction = functionRegistry.getFunction(procedure);
    final graph = _buildCfg(cFunction);
    final function = _buildWasmFunction(
      memberLabel(procedure),
      functionTypeFor(cFunction),
      (b) => DevCfgToWasm(this, graph, b).generate(),
    );
    if (procedure.isInstanceMember) {
      defineInstanceMember(procedure, function);
    } else {
      if (isMain) module.exports.export('main', function);
      defineStatic(memberLabel(procedure), function);
    }
  }

  /// Compiles [constructor] as a static that takes the new object.
  void _compileConstructor(ast.Constructor constructor) {
    final cFunction = functionRegistry.getFunction(constructor);
    final graph = _buildCfg(cFunction);
    final function = _buildWasmFunction(
      memberLabel(constructor),
      functionTypeFor(cFunction),
      (b) => DevCfgToWasm(this, graph, b).generate(),
    );
    defineStatic(memberLabel(constructor), function);
  }

  /// Builds [cFunction]'s CFG representation.
  FlowGraph _buildCfg(CFunction cFunction) {
    final graph = AstToIr(
      cFunction,
      functionRegistry,
      recognizedMethods,
      onLocalFunction: (_) {},
      enableAsserts: false,
      typeParametersStyle: .separateFunctionAndClassTypeParameters,
      scopes: ComputedScopes(cFunction.member, enableAsserts: false),
    ).buildFlowGraph();
    Pipeline([SSAComputation()]).run(graph);
    return graph;
  }

  /// Returns the Wasm type of values of [type].
  w.ValueType translateType(CType type) => switch (type) {
    IntType() => w.NumType.i64,
    DoubleType() => w.NumType.f64,
    BoolType() => w.NumType.i32,
    // TODO(dart2wasm): Lower String to a Dart object (Wasm struct).
    StringType() => _jsString,
    NullType() || NeverType() => const w.RefType.none(nullable: true),
    StaticType(dartType: ast.InterfaceType()) => w.RefType.def(
      objectStruct,
      nullable: type.isNullable,
    ),
    _ => throw UnimplementedError('Unsupported type: $type'),
  };

  w.FunctionType functionTypeFor(CFunction cFunction) {
    final functionNode = cFunction.functionNode!;
    // TODO(dart2wasm): Support optional, named, and type parameters.
    if (functionNode.requiredParameterCount !=
            functionNode.positionalParameters.length ||
        functionNode.namedParameters.isNotEmpty ||
        functionNode.typeParameters.isNotEmpty) {
      throw UnimplementedError('Unsupported parameters in ${cFunction.member}');
    }
    final inputs = <w.ValueType>[
      if (cFunction.hasReceiverParameter)
        w.RefType.def(objectStruct, nullable: false),
      for (final param in functionNode.positionalParameters)
        translateType(CType.fromStaticType(param.type)),
    ];
    final returnType = cFunction.returnType;
    final outputs =
        (returnType.dartType is ast.VoidType || returnType is NeverType)
        ? const <w.ValueType>[]
        : <w.ValueType>[translateType(returnType)];
    return module.types.defineFunction(inputs, outputs);
  }

  /// Defines static [label] as [function] in the runtime.
  void defineStatic(String label, w.BaseFunction function) {
    _start.global_get(_staticId(label));
    _start.ref_func(function);
    _start.call(runtime.defineStatic);
  }

  /// Emits a call to static [label] with [type].
  ///
  /// Expects the arguments on the stack.
  void callStatic(w.InstructionsBuilder b, String label, w.FunctionType type) {
    b.global_get(_staticId(label));
    b.call(runtime.lookupStatic);
    b.ref_cast(w.RefType.def(type, nullable: false));
    b.call_ref(type);
  }

  /// Defines [cls]'s superclass.
  void defineClassSupers(ast.Class cls) {
    final classId = _classId(classLabel(cls));
    final superclassId = _classId(classLabel(cls.superclass!));
    _start.global_get(classId);
    _start.global_get(superclassId);
    _start.call(runtime.defineClassSupers);
  }

  /// Starts defining [cls]'s instance members.
  void startInstanceMemberDefinitions(ast.Class cls) {
    _start.global_get(_classId(classLabel(cls)));
    _start.call(runtime.startInstanceMemberDefinitions);
  }

  /// Ends defining [cls]'s instance members.
  void endInstanceMemberDefinitions(ast.Class cls) {
    _start.global_get(_classId(classLabel(cls)));
    _start.call(runtime.endInstanceMemberDefinitions);
  }

  /// Defines instance [member] as [function] in the runtime.
  void defineInstanceMember(ast.Member member, w.BaseFunction function) {
    final classId = _classId(classLabel(member.enclosingClass!));
    final instanceMemberId = _instanceMemberId(instanceMemberName(member));
    _start.global_get(classId);
    _start.global_get(instanceMemberId);
    _start.ref_func(function);
    _start.call(runtime.defineInstanceMember);
  }

  /// Pushes a new instance of [cls].
  void allocateObject(w.InstructionsBuilder b, ast.Class cls) {
    b.global_get(_classId(classLabel(cls)));
    b.struct_new(objectStruct);
  }

  /// Emits a call to [receiver.name] with [type].
  ///
  /// Expects the arguments on the stack (including [receiver]).
  void callInstance(
    w.InstructionsBuilder b,
    w.Local receiver,
    String name,
    w.FunctionType type,
  ) {
    b.local_get(receiver);
    b.struct_get(objectStruct, 0);
    b.global_get(_instanceMemberId(name));
    b.call(runtime.findTarget);
    b.ref_cast(w.RefType.def(type, nullable: false));
    b.call_ref(type);
  }

  /// Builds Wasm function [name] with [type] and body [emitBody].
  w.BaseFunction _buildWasmFunction(
    String name,
    w.FunctionType type,
    void Function(w.InstructionsBuilder b) emitBody,
  ) {
    final functionBuilder = module.functions.define(type, name);
    emitBody(functionBuilder.body);
    final function = functionBuilder.build();
    // Declare [function] so `ref.func` can reference it.
    module.elements.declarativeSegmentBuilder.declare(function);
    return function;
  }

  /// Returns the global holding static [label]'s ID.
  w.Global _staticId(String label) => _id(_staticIds, label, runtime.staticId);

  /// Returns the global holding class [label]'s ID.
  w.Global _classId(String label) => _id(_classIds, label, runtime.classId);

  /// Returns the global holding instance member [name]'s ID.
  w.Global _instanceMemberId(String name) =>
      _id(_instanceMemberIds, name, runtime.instanceMemberId);

  /// Returns the global in [ids[label]].
  ///
  /// Initializes the ID with [idFunction] on first access.
  w.Global _id(
    Map<String, w.Global> ids,
    String label,
    w.BaseFunction idFunction,
  ) => ids.putIfAbsent(label, () {
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
    _start.call(idFunction);
    _start.global_set(globalBuilder.global);
    return globalBuilder.build();
  });
}

/// Returns [member]'s label.
///
/// Example: `package:foo/foo.dart::Foo.bar`
String memberLabel(ast.Member member) {
  final libraryUri = member.enclosingLibrary.importUri;
  final className = member.enclosingClass?.name;
  final isUnnamedConstructor =
      member is ast.Constructor && member.name.text.isEmpty;
  final name = isUnnamedConstructor ? 'new' : member.name.text;
  if (className != null) {
    return '$libraryUri::$className.$name';
  }
  return '$libraryUri::$name';
}

/// Returns [cls]'s label.
///
/// Example: `package:foo/foo.dart::Foo`
String classLabel(ast.Class cls) =>
    '${cls.enclosingLibrary.importUri}::${cls.name}';

/// Returns instance [member]'s name.
///
/// Example: `mem` or `_mem@package:foo/foo.dart` if private.
String instanceMemberName(ast.Member member) {
  final name = member.name;
  return name.isPrivate ? '${name.text}@${name.library!.importUri}' : name.text;
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
