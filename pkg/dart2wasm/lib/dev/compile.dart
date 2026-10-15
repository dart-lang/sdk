// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'runtime.dart';

/// Compiles a Dart file into a Wasm dev module.
///
/// Currently only emits this hard-coded program:
/// ```dart
/// void main() {
///   print('Hello, world!');
/// }
/// ```
Uint8List compile() {
  final module = w.ModuleBuilder('dev', null);
  final runtime = DevRuntime(module);

  final main = module.functions.define(
    module.types.defineFunction(const [], const []),
    'main',
  );
  final b = main.body;
  _pushString(b, 'Hello, world!');
  b.call(runtime.print);
  b.end();
  module.exports.export('main', main.build());

  final serializer = w.Serializer();
  module.build().serialize(serializer);
  return serializer.data;
}

/// Pushes [value] as a JS string.
// TODO: Canonicalize strings.
void _pushString(w.InstructionsBuilder b, String value) => b.global_get(
  b.moduleBuilder.globals.import(
    '',
    value,
    w.GlobalType(w.RefType.extern(nullable: false), mutable: false),
  ),
);
