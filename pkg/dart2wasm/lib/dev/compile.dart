// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'runtime.dart';

const w.ValueType _jsString = w.RefType.extern(nullable: false);

/// Compiles a Dart file into a Wasm dev module.
///
/// Currently only emits this hard-coded program:
/// ```dart
/// class Greeter {
///   static String greeting() => 'Hello, world!';
/// }
///
/// void greet(String message) => print(message);
///
/// void main() => greet(Greeter.greeting());
/// ```
Uint8List compile() {
  const greetingLabel = 'package:hello/hello.dart::Greeter.greeting';
  const greetLabel = 'package:hello/hello.dart::greet';

  final module = w.ModuleBuilder('dev', null);
  final runtime = DevRuntime(module);
  final compiler = _ModuleCompiler(module, runtime);

  final greetingType = module.types.defineFunction(const [], const [_jsString]);
  compiler.defineStatic(greetingLabel, greetingType, (b) {
    _pushString(b, 'Hello, world!');
  });

  final greetType = module.types.defineFunction(const [_jsString], const []);
  compiler.defineStatic(greetLabel, greetType, (b) {
    b.local_get(b.locals[0]);
    b.call(runtime.print);
  });

  final main = module.functions.define(
    module.types.defineFunction(const [], const []),
    'main',
  );
  compiler.callStatic(main.body, greetingLabel, greetingType);
  compiler.callStatic(main.body, greetLabel, greetType);
  main.body.end();
  module.exports.export('main', main.build());

  final serializer = w.Serializer();
  module.build().serialize(serializer);
  return serializer.data;
}

/// Emits a Wasm dev module's code into [module].
class _ModuleCompiler {
  final w.ModuleBuilder module;
  final DevRuntime runtime;

  /// Maps a static's label to the global holding its ID.
  final Map<String, w.Global> _staticIds = {};

  _ModuleCompiler(this.module, this.runtime);

  w.InstructionsBuilder get _start => module.startFunction.body;

  /// Defines static [label] with [type] and body [emitBody].
  // TODO: Temporary. Remove when static functions are lowered.
  void defineStatic(
    String label,
    w.FunctionType type,
    void Function(w.InstructionsBuilder b) emitBody,
  ) {
    final functionBuilder = module.functions.define(type, label);
    emitBody(functionBuilder.body);
    functionBuilder.body.end();
    final function = functionBuilder.build();
    // Declare [function] so `ref.func` can reference it.
    module.elements.declarativeSegmentBuilder.declare(function);
    _start.global_get(_staticId(label));
    _start.ref_func(function);
    _start.call(runtime.declareStatic);
  }

  /// Emits a call to static [label] with [type].
  // TODO: Temporary. Remove when CFG DirectCalls are lowered.
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
    _pushString(_start, label);
    _start.call(runtime.staticId);
    _start.global_set(globalBuilder.global);
    return globalBuilder.build();
  });
}

/// Pushes [value] as a JS string.
// TODO: Canonicalize strings.
void _pushString(w.InstructionsBuilder b, String value) => b.global_get(
  b.moduleBuilder.globals.import(
    '',
    value,
    w.GlobalType(_jsString, mutable: false),
  ),
);
