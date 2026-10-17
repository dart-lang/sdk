// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Runtime for the Wasm dev compiler.

import 'dart:_wasm';

final class _StaticMetadata {
  final String label;

  /// The static's function, or `null` if it hasn't been declared.
  _Function? function;

  // TODO: Store the parameter shape.
  _StaticMetadata(this.label);
}

/// Wraps a [WasmFuncRef], which dart2wasm can't null-check.
final class _Function {
  final WasmFuncRef ref;

  _Function(this.ref);
}

/// Maps a static's ID to its metadata.
final List<_StaticMetadata> _statics = [];

/// Maps a static's label to its ID.
final Map<String, int> _staticIds = {};

/// Returns the ID of the static with [label] or assigns it one.
///
/// Static labels have a format like: `package:foo/foo.dart::bar`, or
/// `package:foo/foo.dart::Foo.bar` for a static member of class `Foo`.
int staticId(String label) {
  final existing = _staticIds[label];
  if (existing != null) return existing;
  final id = _statics.length;
  _statics.add(_StaticMetadata(label));
  _staticIds[label] = id;
  return id;
}

/// Declares [function] as static [id]'s function.
///
/// Statics are declared once.
void declareStatic(int id, WasmFuncRef function) {
  final metadata = _statics[id];
  if (metadata.function != null) {
    throw StateError('Static ${metadata.label} is already declared');
  }
  metadata.function = _Function(function);
}

/// Returns static [id]'s function.
// TODO: Check the caller's arguments against the parameter shape.
WasmFuncRef lookupStatic(int id) {
  final metadata = _statics[id];
  final function = metadata.function;
  if (function == null) {
    throw StateError('Static ${metadata.label} is not declared');
  }
  return function.ref;
}
