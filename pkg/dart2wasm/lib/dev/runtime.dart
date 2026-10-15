// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:wasm_builder/wasm_builder.dart' as w;

const w.ValueType _jsString = w.RefType.extern(nullable: false);

/// The Wasm dev runtime (`pkg/wasm_dev_rt`) API for [module].
class DevRuntime {
  final w.ModuleBuilder module;

  late final w.BaseFunction print = _import('print', [_jsString]);

  DevRuntime(this.module);

  /// Imports the function [name] exported by the runtime.
  w.BaseFunction _import(
    String name,
    List<w.ValueType> inputs, [
    List<w.ValueType> outputs = const [],
  ]) => module.functions.import(
    'wasm_dev_rt',
    name,
    module.types.defineFunction(inputs, outputs),
    'wasm_dev_rt.$name',
  );
}
