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

import '../cfg/passes/lower_irreducible_control_flow.dart';
import '../target.dart';
import '../util.dart';
import 'cfg/to_wasm.dart';
import 'names.dart';
import 'runtime.dart';

const w.ValueType _jsString = w.RefType.extern(nullable: false);

/// Maps a boxed Wasm type to its boxed class's label.
// TODO(dart2wasm): Remove once dart:core is compiled.
final Map<w.ValueType, String> _boxLabels = {
  w.NumType.i64: 'dart:_boxed_int::BoxedInt',
  w.NumType.f64: 'dart:_boxed_double::BoxedDouble',
  w.NumType.i32: 'dart:_boxed_bool::BoxedBool',
  _jsString: 'dart:_string::JSStringImpl',
};

/// Compiles a Dart file and its imported libraries into Wasm dev modules.
///
/// The first returned module is the main module (exporting `main`), followed by
/// modules for the other imported libraries.
///
/// It assumes that either
/// * [platformPath] is provided and is the path to the
///   `dart2wasm_dev_platform.dill` file or
/// * [librariesSpecPath] is provided and points to a valid `libraries.json`
///   file allowing the compiler to compile the `dart:*` libraries from source
Future<List<Uint8List>> compile(
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
      int nextModuleId = 0;
      Uint8List compileLibrary(
        ast.Library library, {
        ast.Procedure? mainMethod,
      }) {
        final moduleName = moduleNameFromId(nextModuleId++);
        final module = w.ModuleBuilder(moduleName, null);
        final runtime = DevRuntime(module);
        final compiler = ModuleCompiler(module, runtime);
        compiler.compileLibrary(library, mainMethod: mainMethod);

        final serializer = w.Serializer();
        module.build().serialize(serializer);
        return serializer.data;
      }

      final mainLibrary = mainMethod.enclosingLibrary;
      return [
        compileLibrary(mainLibrary, mainMethod: mainMethod),
        for (final library in component.libraries)
          if (!library.importUri.isScheme('dart') && library != mainLibrary)
            compileLibrary(library),
      ];
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

  /// The Wasm type of parameters and return types.
  late final w.RefType topType = w.RefType.def(objectStruct, nullable: true);

  /// The Wasm type of `this` in instance members and constructors.
  late final w.RefType receiverType = w.RefType.def(
    objectStruct,
    nullable: false,
  );

  static const int sentinelClassId = -1;

  /// A placeholder for omitted optional parameters.
  ///
  /// Replaced on startup with the runtime's shared defaultValueSentinel.
  // TODO(dart2wasm): Replace with a shared object once dart:core is compiled.
  late final w.Global defaultValueSentinel = () {
    final type = w.RefType.def(objectStruct, nullable: false);
    final globalBuilder = module.globals.define(
      w.GlobalType(type, mutable: true),
      'defaultValueSentinel',
    );
    globalBuilder.initializer
      ..i32_const(sentinelClassId)
      ..struct_new(objectStruct)
      ..end();
    final global = globalBuilder.build();
    _start
      ..global_get(global)
      ..call(runtime.defaultValueSentinel)
      ..ref_cast(type)
      ..global_set(global);
    return global;
  }();

  /// Maps a boxed Wasm type to its box struct.
  final Map<w.ValueType, w.StructType> _boxStructs = {};

  /// Maps a static's label to the global holding its ID.
  final Map<String, w.Global> _staticIds = {};

  /// Maps a class's label to the global holding its ID.
  final Map<String, w.Global> _classIds = {};

  /// Maps an instance member name to the global holding its ID.
  final Map<String, w.Global> _instanceMemberIds = {};

  /// Maps a shape's label to the global holding its ID.
  final Map<String, w.Global> _shapeIds = {};

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
      if (isMain) _exportMain(function);
      defineStatic(memberLabel(procedure), function);
    }
  }

  // TODO(dart2wasm): Remove once dart:core is compiled.
  void _exportMain(w.BaseFunction main) {
    if (main.type.inputs.isNotEmpty) {
      throw UnimplementedError('Unsupported parameters in main');
    }
    module.exports.export('main', main);
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
    Pipeline([SSAComputation(), LowerIrreducibleControlFlow()]).run(graph);
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
    TopType() || ObjectType() || StaticType(dartType: ast.InterfaceType()) =>
      w.RefType.def(objectStruct, nullable: type.isNullable),
    _ => throw UnimplementedError('Unsupported type: $type'),
  };

  /// Returns [cFunction]'s Wasm type.
  w.FunctionType functionTypeFor(CFunction cFunction) {
    final functionNode = cFunction.functionNode!;
    // TODO(dart2wasm): Support type parameters.
    if (functionNode.typeParameters.isNotEmpty) {
      throw UnimplementedError(
        'Unsupported type parameters in ${cFunction.member}',
      );
    }
    final parameterCount =
        functionNode.positionalParameters.length +
        functionNode.namedParameters.length;
    return module.types.defineFunction(
      [
        if (cFunction.hasReceiverParameter) receiverType,
        for (var i = 0; i < parameterCount; i++) topType,
      ],
      [topType],
    );
  }

  /// Returns the Wasm parameter index of [cFunction]'s [index]th parameter.
  ///
  /// Wasm functions take named parameters sorted by name, but CFG IR indexes
  /// them in declaration order.
  int wasmParameterIndex(CFunction cFunction, int index) {
    final functionNode = cFunction.functionNode!;
    final namedStart =
        (cFunction.hasReceiverParameter ? 1 : 0) +
        functionNode.positionalParameters.length;
    if (index < namedStart) return index;
    final parameter = functionNode.namedParameters[index - namedStart];
    return namedStart + sortedNamedParameters(functionNode).indexOf(parameter);
  }

  /// Returns [function]'s named parameters sorted by name.
  List<ast.NamedParameter> sortedNamedParameters(ast.FunctionNode function) =>
      function.namedParameters.toList()
        ..sort((a, b) => a.parameterName.compareTo(b.parameterName));

  /// Converts the value on the stack from [from] to [to].
  ///
  /// ints, doubles, bools, and strings are boxed/unboxed if needed.
  void convertType(w.InstructionsBuilder b, w.ValueType from, w.ValueType to) {
    if (from.isSubtypeOf(to)) return;
    final nonNullFrom = from.withNullability(false);
    final nonNullTo = to.withNullability(false);
    final fromIsUnboxed = _boxLabels.containsKey(nonNullFrom);
    final toIsUnboxed = _boxLabels.containsKey(nonNullTo);
    final onlyNullabilityDiffers = !to.nullable && nonNullFrom.isSubtypeOf(to);
    switch ((fromIsUnboxed, toIsUnboxed)) {
      case (true, true):
        if (!onlyNullabilityDiffers) {
          throw UnimplementedError(
            'Unsupported type conversion from $from to $to',
          );
        }
        b.ref_as_non_null();
      case (true, false):
        if (from.nullable) b.ref_as_non_null();
        _box(b, nonNullFrom);
      case (false, true):
        _unbox(b, nonNullTo);
      case (false, false):
        if (onlyNullabilityDiffers) {
          b.ref_as_non_null();
        } else {
          b.ref_cast(to as w.RefType);
        }
    }
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
    b.call_indirect(type, runtime.staticFunctionsTable);
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
    final shapeId = _shapeId(shapeLabel(member.function!));
    _start.global_get(classId);
    _start.global_get(instanceMemberId);
    _start.global_get(shapeId);
    _start.ref_func(function);
    _start.call(runtime.defineInstanceMember);
  }

  /// Pushes a new instance of [cls].
  void allocateObject(w.InstructionsBuilder b, ast.Class cls) {
    b.global_get(_classId(classLabel(cls)));
    b.struct_new(objectStruct);
  }

  /// Emits a call to [receiver.name] with [shape] and [type].
  ///
  /// Expects the arguments on the stack (including [receiver]).
  void callInstance(
    w.InstructionsBuilder b,
    w.Local receiver,
    String name,
    String shape,
    w.FunctionType type,
  ) {
    b.local_get(receiver);
    b.struct_get(objectStruct, 0);
    b.global_get(_instanceMemberId(name));
    b.global_get(_shapeId(shape));
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

  /// Boxes the [type] value on the stack.
  void _box(w.InstructionsBuilder b, w.ValueType type) {
    final value = b.addLocal(type);
    b.local_set(value);
    b.global_get(_classId(_boxLabels[type]!));
    b.local_get(value);
    b.struct_new(_boxStructFor(type));
  }

  /// Unboxes the [type] value from the box on the stack.
  void _unbox(w.InstructionsBuilder b, w.ValueType type) {
    final struct = _boxStructFor(type);
    b.ref_cast(w.RefType.def(struct, nullable: false));
    b.struct_get(struct, 1);
  }

  /// Returns [type]'s box struct.
  w.StructType _boxStructFor(w.ValueType type) =>
      _boxStructs[type] ??= module.types.defineStruct(
        _boxLabels[type]!.split('::').last,
        fields: [objectStruct.fields.single, w.FieldType(type, mutable: false)],
        superType: objectStruct,
        brand: false,
      );

  /// Returns the global holding static [label]'s ID.
  w.Global _staticId(String label) => _id(_staticIds, label, runtime.staticId);

  /// Returns the global holding class [label]'s ID.
  w.Global _classId(String label) => _id(_classIds, label, runtime.classId);

  /// Returns the global holding instance member [name]'s ID.
  w.Global _instanceMemberId(String name) =>
      _id(_instanceMemberIds, name, runtime.instanceMemberId);

  /// Returns the global holding shape [label]'s ID.
  w.Global _shapeId(String label) => _id(_shapeIds, label, runtime.shapeId);

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
