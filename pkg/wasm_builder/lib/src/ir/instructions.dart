// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import 'ir.dart';

part 'instruction.dart';

class Instructions implements Serializable {
  /// The locals used by this group of instructions.
  final List<Local> locals;

  /// A sequence of Wasm instructions.
  final List<Instruction> instructions;

  final Map<Instruction, StackTrace>? _stackTraces;

  final List<String> _traceLines;

  /// A string trace.
  late final trace = _traceLines.join();

  /// Create a new instruction sequence.
  Instructions(
      this.locals, this.instructions, this._stackTraces, this._traceLines);

  @override
  void serialize(Serializer s) {
    for (final i in instructions) {
      if (_stackTraces != null) s.debugTrace(_stackTraces![i]!);
      i.serialize(s);
    }
  }
}
