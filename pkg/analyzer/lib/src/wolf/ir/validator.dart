// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/wolf/ir/ir.dart';

/// Checks that [ir] is well-formed.
///
/// Throws [ValidationError] if it's not.
///
/// During validation, progress information will be reported to [eventListener]
/// (if provided).
void validate(BaseIRContainer ir, {ValidationEventListener? eventListener}) {
  eventListener ??= ValidationEventListener();
  var validator = _Validator(ir, eventListener: eventListener);
  eventListener._validator = validator;
  validator.run();
  eventListener._validator = null;
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

/// Event listener used by [validate] to report progress information.
///
/// By itself this class does nothing; the caller of [validate] should make a
/// derived class that overrides one or more of the `on...` methods.
base class ValidationEventListener {
  late _Validator? _validator;

  int get valueStackDepth => _validator!.valueStackDepth;

  /// Called for every iteration in the validation loop, just before visiting an
  /// instruction.
  ///
  /// Also called at the end of the validation loop (with [address] equal to the
  /// instruction count).
  void onAddress(int address) {}
}

/// Used by [_Validator] to track a control flow instruction (`block`, `loop`,
/// `tryCatch`, `tryFinally`, or `function` instruction) whose `matching `end`
/// instruction has not yet been encountered.
class _ControlFlowElement {
  /// The state of [_Validator.functionFlags] before the control flow
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
  final ValidationEventListener eventListener;
  final controlFlowStack = <_ControlFlowElement>[];
  var address = 0;

  /// Flags from the most recent `function` instruction whose corresponding
  /// `end` instruction has not yet been encountered.
  var functionFlags = FunctionFlags();

  var valueStackDepth = 0;

  _Validator(this.ir, {required this.eventListener});

  /// Reports a validation error if [condition] is `false`.
  void check(bool condition, String message) {
    if (!condition) {
      fail(message);
    }
  }

  /// Unconditionally reports a validation error.
  Never fail(String message) {
    throw ValidationError(
        address: address,
        instructionString: address < ir.endAddress
            ? ir.instructionToString(address)
            : 'after last instruction',
        message: message);
  }

  void popValues(int count) {
    assert(count >= 0);
    check(valueStackDepth >= count, 'Value stack underflow');
    valueStackDepth -= count;
  }

  void pushValues(int count) {
    assert(count >= 0);
    valueStackDepth += count;
  }

  void run() {
    check(ir.endAddress > 0, 'No instructions');
    for (address = 0; address < ir.endAddress; address++) {
      eventListener.onAddress(address);
      var opcode = ir.opcodeAt(address);
      check(address != 0 || opcode == Opcode.function,
          'First instruction must be function');
      switch (opcode) {
        case Opcode.drop:
          popValues(1);
        case Opcode.end:
          check(controlFlowStack.isNotEmpty, 'Unmatched end');
          var controlFlowElement = controlFlowStack.removeLast();
          popValues(controlFlowElement.branchValueCount);
          check(valueStackDepth == 0,
              '$valueStackDepth superfluous value(s) remaining');
          valueStackDepth = controlFlowElement.valueStackDepthAfter;
          functionFlags = controlFlowElement.functionFlagsBefore;
        case Opcode.function:
          var type = Opcode.function.decodeType(ir, address);
          var kind = Opcode.function.decodeFlags(ir, address);
          check(!kind.isInstance || address == 0,
              'Instance function may only be used at instruction address 0');
          controlFlowStack.add(_ControlFlowElement(
              functionFlagsBefore: functionFlags,
              valueStackDepthAfter: valueStackDepth + 1,
              branchValueCount: 1,
              isFunction: true));
          functionFlags = kind;
          valueStackDepth =
              ir.countParameters(type) + (kind.isInstance ? 1 : 0);
        case Opcode.literal:
          pushValues(1);
        default:
          fail('Unexpected opcode ${opcode.describe()}');
      }
    }
    eventListener.onAddress(address);
    check(controlFlowStack.isEmpty, 'Missing end');
  }
}
