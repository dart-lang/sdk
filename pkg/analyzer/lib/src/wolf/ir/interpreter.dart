// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/wolf/ir/call_descriptor.dart';
import 'package:analyzer/src/wolf/ir/coded_ir.dart';
import 'package:analyzer/src/wolf/ir/ir.dart';
import 'package:analyzer/src/wolf/ir/scope_analyzer.dart';
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
    {required Scopes scopes, required CallDispatcher callDispatcher}) {
  return _IRInterpreter(ir, scopes: scopes, callDispatcher: callDispatcher)
      .run(args);
}

/// Function type invoked by [interpret] to execute a `call` instruction.
typedef CallHandler = Object? Function(
    List<Object?> positionalArguments, Map<String, Object?> namedArguments);

/// Interface used by [interpret] to query the behavior of calls to external
/// code.
abstract interface class CallDispatcher {
  /// Evaluates a call to `operator==`, using virtual dispatch on [firstValue],
  /// and passing [secondValue] as the parameter to `operator==`.
  ///
  /// In accordance with Dart semantics, this method is only called if both
  /// [firstValue] and [secondValue] are non-null.
  bool equals(Object firstValue, Object secondValue);

  /// Looks up the function that can be used to evaluate calls to
  /// [callDescriptor].
  ///
  /// The interpreter may invoke this method for any [CallDescriptor] in the
  /// IR's call descriptor table (whether or not it's invoked), and it may cache
  /// the results. However, it is guaranteed to call the [CallHandler] exactly
  /// once for each `call` instruction that is interpreted.
  CallHandler lookupCallDescriptor(CallDescriptor callDescriptor);
}

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

/// An entry on the control flow stack, representing a control flow construct
/// (such as a `block`) that the interpreter is currently executing.
class _ControlFlowStackEntry {
  /// The index into [_IRInterpreter.stack] before the first input to control
  /// flow construct.
  ///
  /// This is called a "fence" because it represents the dividing line between
  /// stack values that belong to the instructions inside the control flow
  /// construct and stack values that belong to the instructions outside the
  /// control flow construct. If a branch instruction targets the control flow
  /// construct, this helps to determine which stack values should be discarded
  /// (see [outputCount]).
  final int stackFence;

  /// The length of [_IRInterpreter.locals] at the time the control flow
  /// construct was entered.
  ///
  /// This is called a "fence" because it represents the dividing line between
  /// locals that belong to the instructions inside the control flow construct
  /// and locals that belong to the instructions outside the control flow
  /// construct. If a branch instruction targets the control flow construct,
  /// then locals whose index is greater than equal to this value will
  /// automatically be released.
  final int localFence;

  /// The number of outputs of the control flow construct.
  ///
  /// If a branch instruction targets the control flow construct, this is the
  /// number of entries at the top of [_IRInterpreter.stack] that will remain on
  /// the stack after the branch is taken. Any other stack entries belonging to
  /// the instructions inside the control flow construct will be discarded (see
  /// [stackFence]).
  final int outputCount;

  /// The scope index (as defined by [Scopes]) corresponding to the instructions
  /// that delimit the control flow construct.
  final int scope;

  _ControlFlowStackEntry(
      {required this.stackFence,
      required this.localFence,
      required this.outputCount,
      required this.scope});
}

class _IRInterpreter {
  static const keepGoing = _KeepGoing();
  final CodedIRContainer ir;
  final Scopes scopes;
  final CallDispatcher callDispatcher;
  final List<CallHandler> callHandlers;
  final stack = <Object?>[];
  final locals = <_LocalSlot>[];
  final controlFlowStack = <_ControlFlowStackEntry>[];
  var address = 1;

  /// The scope index (as defined by [Scopes]) corresponding to the last begin
  /// instruction preceding [address].
  var mostRecentScope = 0;

  _IRInterpreter(this.ir, {required this.scopes, required this.callDispatcher})
      : callHandlers =
            ir.mapCallDescriptors(callDispatcher.lookupCallDescriptor);

  /// Performs the necessary logic for a `br`, `brIf`, or `brIndex` instruction.
  ///
  /// [nesting] indicates which enclosing control flow construct is targeted by
  /// the branch (where 0 means the innermost).
  ///
  /// The returned value is either:
  /// - [keepGoing], indicating that interpretation should continue from the
  ///   instruction following [address], or
  /// - Some other value, indicating that the code being interpreted has
  ///   finished executing, and this value should be returned to the caller.
  Object? branch(int nesting) {
    while (nesting-- > 0) {
      controlFlowStack.removeLast();
    }
    if (controlFlowStack.isNotEmpty) {
      var stackEntry = controlFlowStack.removeLast();
      var stackFence = stackEntry.stackFence;
      var outputCount = stackEntry.outputCount;
      var newStackLength = stackFence + outputCount;
      stack.setRange(stackFence, newStackLength, stack,
          stack.length - stackEntry.outputCount);
      stack.length = stackFence + outputCount;
      locals.length = stackEntry.localFence;
      var scope = stackEntry.scope;
      address = scopes.endAddress(scope);
      mostRecentScope = scopes.lastDescendant(scope);
      return keepGoing;
    } else {
      // Branch targets the function, so return from the code being interpreted.
      return stack.last;
    }
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
      assert(scopes.mostRecentScope(address - 1) == mostRecentScope);
      switch (ir.opcodeAt(address)) {
        case Opcode.alloc:
          var count = Opcode.alloc.decodeCount(ir, address);
          for (var i = 0; i < count; i++) {
            locals.add(_LocalSlot());
          }
        case Opcode.block:
          var inputCount = Opcode.block.decodeInputCount(ir, address);
          var outputCount = Opcode.block.decodeOutputCount(ir, address);
          var scope = ++mostRecentScope;
          assert(scopes.beginAddress(scope) == address);
          controlFlowStack.add(_ControlFlowStackEntry(
              stackFence: stack.length - inputCount,
              localFence: locals.length,
              outputCount: outputCount,
              scope: scope));
        case Opcode.br:
          var nesting = Opcode.br.decodeNesting(ir, address);
          var result = branch(nesting);
          if (!identical(result, keepGoing)) {
            return result;
          }
        case Opcode.brIf:
          var nesting = Opcode.brIf.decodeNesting(ir, address);
          if (stack.removeLast() as bool) {
            var result = branch(nesting);
            if (!identical(result, keepGoing)) {
              return result;
            }
          }
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
          if (controlFlowStack.isEmpty) {
            assert(stack.length == 1);
            return stack.last;
          } else {
            var stackEntry = controlFlowStack.last;
            assert(
                stack.length == stackEntry.stackFence + stackEntry.outputCount);
            assert(locals.length == stackEntry.localFence);
            // Continue with the code following the block.
            controlFlowStack.removeLast();
          }
        case Opcode.eq:
          var secondValue = stack.removeLast();
          var firstValue = stack.removeLast();
          if (firstValue == null) {
            stack.add(null == secondValue);
          } else if (secondValue == null) {
            stack.add(false);
          } else {
            stack.add(callDispatcher.equals(firstValue, secondValue));
          }
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

/// Sentinel value used by [_IRInterpreter.branch] to indicate that the
/// interpreter should keep executing instructions.
class _KeepGoing {
  const _KeepGoing();
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
