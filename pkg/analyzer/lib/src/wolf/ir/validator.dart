// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/wolf/ir/ir.dart';

/// Checks that [ir] is well-formed.
///
/// Throws [ValidationError] if it's not.
void validate(BaseIRContainer ir) {
  _Validator(ir).run();
}

class ValidationError extends Error {
  final int address;
  final String instructionString;
  final String message;

  ValidationError(
      {required this.address,
      required this.instructionString,
      required this.message});

  @override
  String toString() =>
      'Validation error at $address ($instructionString): $message';
}

/// Used by [_Validator] to track a control flow instruction (`block`, `loop`,
/// `tryCatch`, `tryFinally`, or `function` instruction) whose `matching `end`
/// instruction has not yet been encountered.
class _ControlFlowElement {
  /// The state of [_Validator._functionFlags] before the control flow
  /// instruction was encountered.
  final FunctionFlags functionFlagsBefore;

  /// The number of entries that will be in the value stack after the matching
  /// `end` instruction.
  final int valueStackDepthAfter;

  /// The number of values that will be consumed from the value stack when the
  /// control flow construct is ended (or branched out of).
  final int branchValueCount;

  /// Whether the control flow instruction was a `function` instruction.
  final bool isFunction;

  _ControlFlowElement(
      {required this.functionFlagsBefore,
      required this.valueStackDepthAfter,
      required this.branchValueCount,
      this.isFunction = false});
}

class _Validator {
  final BaseIRContainer ir;
  final _controlFlowStack = <_ControlFlowElement>[];
  var _address = 0;

  /// Flags from the most recent `function` instruction whose corresponding
  /// `end` instruction has not yet been encountered.
  var _functionFlags = FunctionFlags();

  var _valueStackDepth = 0;

  _Validator(this.ir);

  void run() {
    _check(ir.endAddress > 0, 'No instructions');
    for (_address = 0; _address < ir.endAddress; _address++) {
      var opcode = ir.opcodeAt(_address);
      _check(_address != 0 || opcode == Opcode.function,
          'First instruction must be function');
      switch (opcode) {
        case Opcode.drop:
          _popValues(1);
        case Opcode.end:
          _check(_controlFlowStack.isNotEmpty, 'unmatched end');
          var controlFlowElement = _controlFlowStack.removeLast();
          _popValues(controlFlowElement.branchValueCount);
          _check(_valueStackDepth == 0,
              '$_valueStackDepth superfluous value(s) remaining');
          _pushValues(controlFlowElement.valueStackDepthAfter);
          _functionFlags = controlFlowElement.functionFlagsBefore;
        case Opcode.function:
          var type = Opcode.function.decodeType(ir, _address);
          var kind = Opcode.function.decodeFlags(ir, _address);
          _check(!kind.isInstance || _address == 0,
              'Instance function may only be used at instruction address 0');
          _controlFlowStack.add(_ControlFlowElement(
              functionFlagsBefore: _functionFlags,
              valueStackDepthAfter: _valueStackDepth + 1,
              branchValueCount: 1,
              isFunction: true));
          _functionFlags = kind;
          _valueStackDepth = 0;
          _pushValues(ir.countParameters(type) + (kind.isInstance ? 1 : 0));
        case Opcode.literal:
          _pushValues(1);
        default:
          _fail('Unexpected opcode $opcode');
      }
    }
    _check(_controlFlowStack.isEmpty, 'Missing end');
  }

  /// Reports a validation error if [condition] is `false`.
  void _check(bool condition, String message) {
    if (!condition) {
      _fail(message);
    }
  }

  /// Unconditionally reports a validation error.
  Never _fail(String message) {
    throw ValidationError(
        address: _address,
        instructionString: _address < ir.endAddress
            ? ir.instructionToString(_address)
            : 'after last instruction',
        message: message);
  }

  void _popValues(int count) {
    assert(count >= 0);
    _check(_valueStackDepth >= count, 'Value stack underflow');
    _valueStackDepth -= count;
  }

  void _pushValues(int count) {
    assert(count >= 0);
    _valueStackDepth += count;
  }
}
