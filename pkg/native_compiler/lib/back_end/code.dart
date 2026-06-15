// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:cfg/ir/functions.dart';
import 'package:native_compiler/back_end/code_metadata.dart';
import 'package:native_compiler/back_end/object_pool.dart';

/// Generated code for a function or a stub.
class Code(
  final String name,
  final CFunction? function,
  final Uint8List instructions,
  final ObjectPool objectPool, [
  final ExceptionHandlers? exceptionHandlers,
  final PcDescriptors? pcDescriptors,
  final CatchEntryMoves? catchEntryMoves,
  final CodeSourceMap? codeSourceMap,
]) {
  /// Offset of instructions in the resulting image.
  int? instructionsImageOffset;
}

/// Comsumer of the generated code.
typedef CodeConsumer = void Function(Code);
