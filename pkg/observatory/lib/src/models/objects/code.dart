// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

enum CodeKind { dart, native, stub, tag, collected }

bool isSyntheticCode(CodeKind? kind) {
  if (kind == null) {
    return false;
  }
  switch (kind) {
    case CodeKind.collected:
    case CodeKind.native:
    case CodeKind.tag:
      return true;
    default:
      return false;
  }
}

bool isDartCode(CodeKind? kind) {
  if (kind == null) {
    return false;
  }
  return !isSyntheticCode(kind);
}

abstract class CodeRef extends ObjectRef {
  /// The name of this class.
  String? get name;

  // What kind of code object is this?
  CodeKind? get kind;

  bool? get isOptimized;
}

abstract class Code extends Object implements CodeRef {
  FunctionRef? get function;
  ObjectPoolRef? get objectPool;
  Iterable<FunctionRef>? get inlinedFunctions;
}
