// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/wolf/ir/ast_to_ir.dart';
import 'package:analyzer/src/wolf/ir/coded_ir.dart';
import 'package:analyzer/src/wolf/ir/ir.dart';
import 'package:checks/checks.dart';
import 'package:checks/context.dart';
import 'package:meta/meta.dart' as meta;

void dumpInstructions(BaseIRContainer ir) {
  for (var i = 0; i < ir.endAddress; i++) {
    print('$i: ${ir.instructionToString(i)}');
  }
}

/// Event listener for [astToIR] that records the range of IR instructions
/// associated with each AST node.
///
/// These ranges can be queried using the `[]` operator after [astToIR]
/// completes.
base class AstNodes extends AstToIREventListener {
  /// Outstanding [AstNodes] which have been entered but not exited.
  final _nodeStack = <AstNode>[];

  /// For each entry in [_nodeStack], the value returned by
  /// [nextInstructionAddress] at the time [onEnterNode] was called.
  ///
  /// In other words, the address of the first instruction that was output (or
  /// that will be output) while visiting the corresponding to the AST node.
  final _nodeStartStack = <int>[];

  final _nodeMap = <AstNode, ({int start, int end})>{};

  /// The full IR.
  ///
  /// Only available after [onFinished] has been called.
  late final CodedIRContainer ir;

  /// Gets the [InstructionRange] for [node].
  ///
  /// Only available after [onFinished] has been called.
  InstructionRange? operator [](AstNode node) => switch (_nodeMap[node]) {
        null => null,
        (:var start, :var end) =>
          InstructionRange(ir: ir, start: start, end: end)
      };

  @override
  void onEnterNode(AstNode node) {
    _nodeStack.add(node);
    _nodeStartStack.add(nextInstructionAddress);
    super.onEnterNode(node);
  }

  @override
  void onExitNode() {
    _nodeMap[_nodeStack.removeLast()] =
        (start: _nodeStartStack.removeLast(), end: nextInstructionAddress);
    super.onExitNode();
  }

  @override
  void onFinished(CodedIRContainer ir) {
    check(_nodeStack).isEmpty();
    check(_nodeStartStack).isEmpty();
    this.ir = ir;
    super.onFinished(ir);
  }

  @override
  String toString() {
    if (_nodeMap.isEmpty) return 'AstNodes(<empty>)';
    return [
      'AstNodes(',
      for (var MapEntry(:key, :value) in _nodeMap.entries)
        '  ${key.runtimeType} $key => $value',
      ')'
    ].join('\n');
  }
}

/// Reference to a single instruction in a [CodedIRContainer].
class Instruction {
  final CodedIRContainer ir;
  final int address;

  Instruction(this.ir, this.address);

  Opcode get opcode => ir.opcodeAt(address);

  @override
  String toString() => '$address: ${ir.instructionToString(address)}';
}

/// Reference to a range of instructions in a [CodedIRContainer].
class InstructionRange {
  final CodedIRContainer ir;

  /// Start address of the range (i.e., the address of the first instruction in
  /// the range).
  final int start;

  /// "Past the end" address of the range (i.e., one more than the address of
  /// the last instruction in the range).
  ///
  /// If [start] is equal to [end], the range is empty.
  final int end;

  InstructionRange({required this.ir, required this.start, required this.end});

  bool containsAddress(int address) => start <= address && address < end;

  @override
  String toString() => '[$start, $end)';
}

/// Minimal representation of a function type in unit tests that use
/// [TestIRContainer].
class TestFunctionType {
  final int parameterCount;

  TestFunctionType(this.parameterCount);
}

/// Container for a sequence of IR instructions that aren't connected to an
/// analyzer AST data structure.
///
/// Suitable for use in unit tests that test the IR instructions directly rather
/// than generate them from a Dart AST.
///
/// To construct a sequence of IR instructions, see [TestIRWriter].
class TestIRContainer extends BaseIRContainer {
  final Map<int, String> _addressToLabel;
  final List<String?> _allocNames;
  final List<TestFunctionType> _functionTypes;
  final Map<String, int> _labelToAddress;

  TestIRContainer(TestIRWriter super.writer)
      : _addressToLabel = writer._addressToLabel,
        _allocNames = writer._allocNames,
        _functionTypes = writer._functionTypes,
        _labelToAddress = writer._labelToAddress;

  String? addressToLabel(int address) => _addressToLabel[address];

  String? allocIndexToName(int index) => _allocNames[index];

  @override
  int countParameters(TypeRef type) =>
      _functionTypes[type.index].parameterCount;

  int? labelToAddress(String label) => _labelToAddress[label];
}

/// Writer of an IR instruction stream that's not connected to an analyzer AST
/// data structure.
///
/// Suitable for use in unit tests that test the IR instructions directly rather
/// than generate them from a Dart AST.
class TestIRWriter extends RawIRWriter {
  final _addressToLabel = <int, String>{};
  final _allocNames = <String?>[];
  final _callDescriptorTable = <String>[];
  final _callDescriptorToRef = <String, CallDescriptorRef>{};
  final _functionTypes = <TestFunctionType>[];
  final _labelToAddress = <String, int>{};
  final _literalTable = <Object?>[];
  final _literalToRef = <Object?, LiteralRef>{};
  final _parameterCountToFunctionTypeMap = <int, TypeRef>{};

  @override
  void alloc(int count) {
    var instructionLabel = _addressToLabel[nextInstructionAddress];
    if (count == 1) {
      _allocNames.add(instructionLabel);
    } else {
      for (var i = 0; i < count; i++) {
        _allocNames
            .add(instructionLabel == null ? null : '$instructionLabel$i');
      }
    }
    super.alloc(count);
  }

  CallDescriptorRef encodeCallDescriptor(String name) =>
      _callDescriptorToRef.putIfAbsent(name, () {
        var encoding = CallDescriptorRef(_callDescriptorTable.length);
        _callDescriptorTable.add(name);
        return encoding;
      });

  TypeRef encodeFunctionType({required int parameterCount}) =>
      _parameterCountToFunctionTypeMap.putIfAbsent(parameterCount, () {
        var encoding = TypeRef(_functionTypes.length);
        _functionTypes.add(TestFunctionType(parameterCount));
        return encoding;
      });

  LiteralRef encodeLiteral(Object? value) =>
      _literalToRef.putIfAbsent(value, () {
        var encoding = LiteralRef(_literalTable.length);
        _literalTable.add(value);
        return encoding;
      });

  void label(String name) {
    assert(!_labelToAddress.containsKey(name), 'Duplicate label $name');
    _labelToAddress[name] = nextInstructionAddress;
    _addressToLabel[nextInstructionAddress] = name;
  }

  /// Convenience method for creating an ordinary function (not a method, not
  /// async, not a generator).
  void ordinaryFunction({int parameterCount = 0}) => function(
      encodeFunctionType(parameterCount: parameterCount), FunctionFlags());
}

/// Testing methods for [AstNodes].
extension SubjectAstNodes on Subject<AstNodes> {
  /// Verifies that an entry exists for [node], and returns a [Subject] that
  /// allows its properties to be tested.
  @meta.useResult
  Subject<InstructionRange> operator [](AstNode node) {
    return context
        .nest(() => prefixFirst('contains ${node.runtimeType} ', literal(node)),
            (astNodes) {
      if (astNodes[node] case var range?) return Extracted.value(range);
      return Extracted.rejection(
          which: prefixFirst(
              'does not contain ${node.runtimeType} ', literal(node)));
    });
  }

  /// Verifies that an entry exists for [node].
  void containsNode(AstNode node) {
    context.expect(
        () => prefixFirst('contains ${node.runtimeType} ', literal(node)),
        (astNodes) {
      if (astNodes[node] != null) return null;
      return Rejection(
          which: prefixFirst(
              'does not contain ${node.runtimeType} ', literal(node)));
    });
  }
}

/// Testing methods for [Instruction].
extension SubjectInstruction on Subject<Instruction> {
  @meta.useResult
  Subject<Opcode> get opcode =>
      has((instruction) => instruction.opcode, 'opcode');
}

/// Testing methods for `Iterable<Instruction>`.
extension SubjectInstructionIterable on Subject<Iterable<Instruction>> {
  void hasLength(int expectedLength) => context.expect(
      () => ['has length $expectedLength'],
      (instructions) => instructions.length == expectedLength
          ? null
          : Rejection(which: ['does not have length $expectedLength']));

  @meta.useResult
  Subject<Iterable<Instruction>> withOpcode(Opcode opcode) => context.nest(
      () => ['contains instructions matching ${opcode.describe()}'],
      (instructions) =>
          Extracted.value(instructions.where((i) => i.opcode == opcode)));
}

/// Testing methods for [InstructionRange].
extension SubjectInstructionRange on Subject<InstructionRange> {
  @meta.useResult
  Subject<int> get end => has((range) => range.end, 'end');

  @meta.useResult
  Subject<List<Instruction>> get instructions => has(
      (range) => [
            for (var address = range.start; address < range.end; address++)
              Instruction(range.ir, address)
          ],
      'instructions');

  @meta.useResult
  Subject<int> get start => has((range) => range.start, 'start');

  /// Verifies that [subrange] is contained within the subject range.
  ///
  /// The check passes if [subrange] is the same as the subject range.
  void containsSubrange(InstructionRange subrange) {
    context.expect(() => prefixFirst('contains subrange ', literal(subrange)),
        (range) {
      if (range.start <= subrange.start && subrange.end <= range.end) {
        return null;
      }
      return Rejection(
          which: prefixFirst('does not contain subrange ', literal(subrange)));
    });
  }
}
