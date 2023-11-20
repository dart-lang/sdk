// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/wolf/ir/call_descriptor.dart';
import 'package:analyzer/src/wolf/ir/coded_ir.dart';
import 'package:analyzer/src/wolf/ir/ir.dart';
import 'package:meta/meta.dart';

/// Evaluates [ir], passing in [args], and returns the result.
///
/// The interpreter represents [int]s, [double]s, [String]s, and [Null]s
/// directly with the corresponding Dart value. All other values are represented
/// via objects of type [Instance].
///
/// The behavior of the `call` instruction is governed by the [callDispatcher]
/// parameter, which specifies the behavior of each possible [CallDescriptor].
///
/// This interpreter is neither efficient nor full-featured, so it shouldn't be
/// used in production code. It is solely intended to allow unit tests to verify
/// that an instruction sequence behaves as it's expected to.
@visibleForTesting
Object? interpret(CodedIRContainer ir, List<Object?> args,
    {required CallHandler Function(CallDescriptor) callDispatcher}) {
  return _IRInterpreter(ir, callDispatcher: callDispatcher).run(args);
}

/// Function type invoked by [interpret] to execute a `call` instruction.
typedef CallHandler = Object? Function(
    List<Object?> positionalArguments, Map<String, Object?> namedArguments);

/// Interpreter representation of a heap object.
///
/// This class should not be used for the types [int], [double], [String], or
/// [Null], since the interpreter represents those types directly with the
/// corresponding Dart value.
class Instance {
  final InterfaceType type;

  Instance(this.type)
      : assert(!type.isDartCoreInt &&
            !type.isDartCoreDouble &&
            !type.isDartCoreString &&
            !type.isDartCoreNull);
}

/// Error thrown if the interpreter encounters a situation that should be
/// impossible assuming the soundness of flow analysis and the Dart type system.
class SoundnessError extends Error {
  final int address;
  final String instructionString;
  final String message;

  SoundnessError(
      {required this.address,
      required this.instructionString,
      required this.message});

  @override
  String toString() =>
      'Soundness error at $address ($instructionString): $message';
}

class _IRInterpreter {
  final CodedIRContainer ir;
  final List<CallHandler> callHandlers;
  final stack = <Object?>[];
  final locals = <_LocalSlot>[];
  var address = 1;

  _IRInterpreter(this.ir,
      {required CallHandler Function(CallDescriptor) callDispatcher})
      : callHandlers = ir.mapCallDescriptors(callDispatcher);

  /// Performs the necessary logic for a `br`, `brIf`, or `brIndex` instruction.
  ///
  /// [nesting] indicates which enclosing control flow construct is targeted by
  /// the branch (where 0 means the innermost).
  ///
  /// The returned value is the value that should be returned to the caller.
  Object? branch(int nesting) {
    if (nesting != 0) {
      throw UnimplementedError('TODO(paulberry): nonzero branch nesting');
    }
    // Branch targets the function, so return from the code being interpreted.
    return stack.last;
  }

  Object? run(List<Object?> args) {
    var functionType = Opcode.function.decodeType(ir, 0);
    var parameterCount = ir.countParameters(functionType);
    if (Opcode.function.decodeFlags(ir, 0).isInstance) {
      parameterCount++;
    }
    if (args.length != parameterCount) {
      throw StateError('Parameter count mismatch');
    }
    stack.addAll(args);
    while (true) {
      switch (ir.opcodeAt(address)) {
        case Opcode.alloc:
          var count = Opcode.alloc.decodeCount(ir, address);
          for (var i = 0; i < count; i++) {
            locals.add(_LocalSlot());
          }
        case Opcode.br:
          var nesting = Opcode.br.decodeNesting(ir, address);
          return branch(nesting);
        case Opcode.call:
          var argumentNames = ir.decodeArgumentNames(
              Opcode.call.decodeArgumentNames(ir, address));
          var callDescriptorRef = Opcode.call.decodeCallDescriptor(ir, address);
          var newStackLength = stack.length - argumentNames.length;
          var positionalArguments = <Object?>[];
          var namedArguments = <String, Object?>{};
          for (var i = 0; i < argumentNames.length; i++) {
            var argument = stack[newStackLength + i];
            if (argumentNames[i] case var name?) {
              namedArguments[name] = argument;
            } else {
              positionalArguments.add(argument);
            }
          }
          stack.length = newStackLength;
          stack.add(callHandlers[callDescriptorRef.index](
              positionalArguments, namedArguments));
        case Opcode.drop:
          stack.removeLast();
        case Opcode.dup:
          stack.add(stack.last);
        case Opcode.end:
          assert(stack.length == 1);
          return stack.last;
        case Opcode.literal:
          var value = Opcode.literal.decodeValue(ir, address);
          stack.add(ir.decodeLiteral(value));
        case Opcode.readLocal:
          var localIndex = Opcode.readLocal.decodeLocalIndex(ir, address);
          var value = locals[localIndex].contents;
          if (value is _NoValue) {
            throwSoundnessError('Read of unset local');
          }
          stack.add(value);
        case Opcode.release:
          var count = Opcode.release.decodeCount(ir, address);
          locals.length -= count;
        case Opcode.shuffle:
          var popCount = Opcode.shuffle.decodePopCount(ir, address);
          var stackIndices = ir.decodeStackIndices(
              Opcode.shuffle.decodeStackIndices(ir, address));
          var newStackLength = stack.length - popCount;
          var poppedValues = stack.sublist(newStackLength);
          stack.length = newStackLength;
          for (var index in stackIndices) {
            stack.add(poppedValues[index]);
          }
        case Opcode.writeLocal:
          var localIndex = Opcode.writeLocal.decodeLocalIndex(ir, address);
          locals[localIndex].contents = stack.removeLast();
        case var opcode:
          throw UnimplementedError(
              'TODO(paulberry): implement ${opcode.describe()} in '
              '_IRInterpreter');
      }
      address++;
    }
  }

  Never throwSoundnessError(String message) => throw SoundnessError(
      address: address,
      instructionString: ir.instructionToString(address),
      message: message);
}

/// Storage for a single local variable.
class _LocalSlot {
  /// The contents of the local variable, or [_NoValue] if the slot is empty.
  Object? contents = const _NoValue();
}

/// Sentinel value used by [_IRInterpreter] to indicate that a [_LocalSlot] is
/// empty.
class _NoValue {
  const _NoValue();
}
