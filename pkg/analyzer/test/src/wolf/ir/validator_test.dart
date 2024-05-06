// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/wolf/ir/ir.dart';
import 'package:analyzer/src/wolf/ir/validator.dart';
import 'package:checks/checks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ValidatorTest);
  });
}

@reflectiveTest
class ValidatorTest {
  final _addressToOnValidateCallbacks =
      <int, List<void Function(ValidationEventListener)>>{};
  late TestIRContainer ir;

  test_alloc_negativeCount() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..alloc(-1)
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative alloc count');
  }

  test_alloc_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..onValidate((v) => check(v.localCount).equals(0))
      ..alloc(1)
      ..onValidate((v) => check(v.localCount).equals(1))
      ..release(1)
      ..end());
    _validate();
  }

  test_await_inSynchronousFunction() {
    _analyze((ir) => ir
      ..function(ir.encodeFunctionType(parameterCount: 1), FunctionFlags())
      ..label('bad')
      ..await_()
      ..end());
    _checkInvalidMessageAt('bad').equals('Await in synchronous function');
  }

  test_await_ok() {
    _analyze((ir) => ir
      ..function(
          ir.encodeFunctionType(parameterCount: 1), FunctionFlags(async: true))
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..await_()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_await_underflow() {
    _analyze((ir) => ir
      ..function(
          ir.encodeFunctionType(parameterCount: 0), FunctionFlags(async: true))
      ..label('bad')
      ..await_()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_block_negativeInputCount() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..block(-1, 0)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative input count');
  }

  test_block_negativeOutputCount() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..block(0, -1)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative output count');
  }

  test_block_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..block(2, 1)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..drop()
      ..end()
      ..end());
    _validate();
  }

  test_block_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..block(2, 1)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_br_controlFlowStackUnderflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..br(1)
      ..end());
    _checkInvalidMessageAt('bad').equals('Control flow stack underflow');
  }

  test_br_fromBlock_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..block(2, 1)
      ..drop()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..br(0)
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..end()
      ..end());
    _validate();
  }

  test_br_fromBlock_stackUnderflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..block(2, 1)
      ..drop()
      ..drop()
      ..label('bad')
      ..br(0)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_br_fromFunction_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..br(0)
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..end());
    _validate();
  }

  test_br_fromFunction_stackUnderflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..br(0)
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_br_fromLoop_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..loop(2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..br(0)
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..end()
      ..end());
    _validate();
  }

  test_br_fromLoop_stackUnderflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..loop(2)
      ..drop()
      ..label('bad')
      ..br(0)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_br_negativeNesting() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..br(-1)
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative branch nesting');
  }

  test_br_outsideOfEnclosingFunction() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..br(1)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad')
        .equals('Cannot branch outside of enclosing function');
  }

  test_brIf_controlFlowStackUnderflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..label('bad')
      ..brIf(1)
      ..end());
    _checkInvalidMessageAt('bad').equals('Control flow stack underflow');
  }

  test_brIf_fromBlock_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..block(2, 1)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..brIf(0)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end()
      ..end());
    _validate();
  }

  test_brIf_fromBlock_stackUnderflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..block(2, 1)
      ..drop()
      ..label('bad')
      ..brIf(0)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_brIf_fromFunction_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..brIf(0)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_brIf_fromFunction_stackUnderflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..brIf(0)
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_brIf_fromLoop_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..loop(2)
      ..dup()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(3)))
      ..brIf(0)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..end()
      ..end());
    _validate();
  }

  test_brIf_fromLoop_stackUnderflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..loop(2)
      ..label('bad')
      ..brIf(0)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_brIf_negativeNesting() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..label('bad')
      ..brIf(-1)
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative branch nesting');
  }

  test_brIf_outsideOfEnclosingFunction() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..ordinaryFunction(parameterCount: 2)
      ..label('bad')
      ..br(1)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad')
        .equals('Cannot branch outside of enclosing function');
  }

  test_call_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..call(ir.encodeCallDescriptor('f'), ir.encodeArgumentNames([null, null]))
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_call_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..call(ir.encodeCallDescriptor('f'), ir.encodeArgumentNames([null, null]))
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_concat_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 3)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(3)))
      ..concat(3)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_concat_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..label('bad')
      ..concat(3)
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_drop_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..drop()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_drop_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..drop()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_dup_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..dup()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..drop()
      ..end());
    _validate();
  }

  test_dup_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..dup()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_end_block_indeterminate() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..block(2, 1)
      ..br(1)
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..end()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_end_block_preservesStackValuesBelowInput() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 3)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(3)))
      ..block(2, 1)
      ..drop()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..drop()
      ..end());
    _validate();
  }

  test_end_block_superfluousValues() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..block(2, 1)
      ..label('bad')
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('1 superfluous value(s) remaining');
  }

  test_end_block_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..block(0, 1)
      ..label('bad')
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_end_function_indeterminate() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..br(0)
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..ordinaryFunction(parameterCount: 1)
      ..end()
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..end());
    _validate();
  }

  test_end_function_pushesOneValue() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..ordinaryFunction(parameterCount: 1)
      ..end()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..drop()
      ..end());
    _validate();
  }

  test_end_function_superfluousValues() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..label('bad')
      ..end());
    _checkInvalidMessageAt('bad').equals('1 superfluous value(s) remaining');
  }

  test_end_function_valueStackUnderflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_end_loop_indeterminate() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..loop(2)
      ..br(1)
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..end()
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..end());
    _validate();
  }

  test_end_loop_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 3)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(3)))
      ..loop(2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..end()
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..end());
    _validate();
  }

  test_end_loop_superfluousValues() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..loop(2)
      ..dup()
      ..label('bad')
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('1 superfluous value(s) remaining');
  }

  test_end_loop_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..loop(2)
      ..drop()
      ..label('bad')
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_end_unmatched() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..end()
      ..label('bad')
      ..end());
    _checkInvalidMessageAt('bad').equals('Unmatched end');
  }

  test_end_unreleasedLocals() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..alloc(1)
      ..label('bad')
      ..end());
    _checkInvalidMessageAt('bad').equals('Unreleased locals');
  }

  test_eq_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..eq()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
  }

  test_eq_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..eq()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_firstInstruction_function_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..literal(ir.encodeLiteral(null))
      ..end());
    _validate();
  }

  test_firstInstruction_instanceFunction_ok() {
    _analyze((ir) => ir
      ..function(ir.encodeFunctionType(parameterCount: 0),
          FunctionFlags(instance: true))
      ..end());
    _validate();
  }

  test_firstInstruction_notFunction() {
    _analyze((ir) => ir
      ..label('bad')
      ..literal(ir.encodeLiteral(null)));
    _checkInvalidMessageAt('bad').equals('First instruction must be function');
  }

  test_function_nested_instanceFunction() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..function(ir.encodeFunctionType(parameterCount: 0),
          FunctionFlags(instance: true))
      ..end()
      ..end());
    _checkInvalidMessageAt('bad')
        .equals('Instance function may only be used at instruction address 0');
  }

  test_function_nested_notInstanceFunction_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..ordinaryFunction()
      ..literal(ir.encodeLiteral(null))
      ..end()
      ..end());
    _validate();
  }

  test_function_parameterCount_instanceFunction() {
    _analyze((ir) => ir
      ..function(ir.encodeFunctionType(parameterCount: 2),
          FunctionFlags(instance: true))
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(3)))
      ..drop()
      ..drop()
      ..end());
    _validate();
  }

  test_function_parameterCount_notInstanceFunction() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..drop()
      ..end());
    _validate();
  }

  test_identical_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..identical()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
  }

  test_identical_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..identical()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_is_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..is_(ir.encodeFunctionType(parameterCount: 0))
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_is_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..is_(ir.encodeFunctionType(parameterCount: 0))
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_literal_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(0)))
      ..literal(ir.encodeLiteral(null)) // Push `null`
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_loop_negativeInputCount() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..loop(-1)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative input count');
  }

  test_loop_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..loop(2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..end()
      ..end());
    _validate();
  }

  test_loop_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..loop(2)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_missingEnd() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..literal(ir.encodeLiteral(null))
      ..label('bad'));
    _checkInvalidMessageAt('bad').equals('Missing end');
  }

  test_noInstructions() {
    _analyze((ir) => ir..label('bad'));
    _checkInvalidMessageAt('bad').equals('No instructions');
  }

  test_not_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..not()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_not_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..not()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_readLocal_negativeLocalIndex() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..readLocal(-1)
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative local index');
  }

  test_readLocal_noSuchLocal() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..readLocal(0)
      ..end());
    _checkInvalidMessageAt('bad').equals('No such local');
  }

  test_readLocal_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..alloc(1)
      ..writeLocal(0)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(0)))
      ..readLocal(0)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..release(1)
      ..end());
    _validate();
  }

  test_release_negativeCount() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..label('bad')
      ..release(-1)
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative release count');
  }

  test_release_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..alloc(1)
      ..onValidate((v) => check(v.localCount).equals(1))
      ..release(1)
      ..onValidate((v) => check(v.localCount).equals(0))
      ..end());
    _validate();
  }

  test_release_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..alloc(1)
      ..ordinaryFunction()
      ..label('bad')
      ..release(1)
      ..end()
      ..end());
    _checkInvalidMessageAt('bad').equals('Local variable stack underflow');
  }

  test_shuffle_negativePopCount() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..shuffle(-1, ir.encodeStackIndices([]))
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative pop count');
  }

  test_shuffle_negativeStackIndex() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..label('bad')
      ..shuffle(2, ir.encodeStackIndices([-1]))
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative stack index');
  }

  test_shuffle_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(2)))
      ..shuffle(2, ir.encodeStackIndices([0, 1, 0, 1]))
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(4)))
      ..drop()
      ..drop()
      ..drop()
      ..end());
    _validate();
  }

  test_shuffle_stackIndexTooLarge() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..label('bad')
      ..shuffle(2, ir.encodeStackIndices([2]))
      ..end());
    _checkInvalidMessageAt('bad').equals('Stack index too large');
  }

  test_shuffle_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..shuffle(2, ir.encodeStackIndices([0, 1, 0, 1]))
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_stack_push() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(0)))
      ..literal(ir.encodeLiteral(null))
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..end());
    _validate();
  }

  test_stack_push_indeterminate() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..br(0)
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..literal(ir.encodeLiteral(null))
      ..onValidate(
          (v) => check(v.valueStackDepth).equals(ValueCount.indeterminate))
      ..end());
    _validate();
  }

  test_writeLocal_negativeLocalIndex() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..writeLocal(-1)
      ..end());
    _checkInvalidMessageAt('bad').equals('Negative local index');
  }

  test_writeLocal_noSuchLocal() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('bad')
      ..writeLocal(0)
      ..end());
    _checkInvalidMessageAt('bad').equals('No such local');
  }

  test_writeLocal_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..alloc(1)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..writeLocal(0)
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(0)))
      ..release(1)
      ..literal(ir.encodeLiteral(null))
      ..end());
    _validate();
  }

  test_writeLocal_underflow() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..alloc(1)
      ..label('bad')
      ..writeLocal(0)
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  test_yield_inNonGeneratorFunction() {
    _analyze((ir) => ir
      ..function(ir.encodeFunctionType(parameterCount: 1), FunctionFlags())
      ..label('bad')
      ..yield_()
      ..end());
    _checkInvalidMessageAt('bad').equals('Yield in non-generator function');
  }

  test_yield_ok() {
    _analyze((ir) => ir
      ..function(ir.encodeFunctionType(parameterCount: 1),
          FunctionFlags(generator: true))
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(1)))
      ..yield_()
      ..onValidate((v) => check(v.valueStackDepth).equals(ValueCount(0)))
      ..literal(ir.encodeLiteral(null))
      ..end());
    _validate();
  }

  test_yield_underflow() {
    _analyze((ir) => ir
      ..function(ir.encodeFunctionType(parameterCount: 0),
          FunctionFlags(generator: true))
      ..label('bad')
      ..yield_()
      ..end());
    _checkInvalidMessageAt('bad').equals('Value stack underflow');
  }

  void _analyze(void Function(_ValidationTestIRWriter) writeIR) {
    var writer = _ValidationTestIRWriter(_addressToOnValidateCallbacks);
    writeIR(writer);
    ir = TestIRContainer(writer);
  }

  Subject<String> _checkInvalidMessageAt(String label) =>
      (check(_validate).throws<ValidationError>()
            ..address.equals(ir.labelToAddress('bad')!))
          .message;

  void _validate() {
    validate(ir, eventListener: _ValidationEventListener(this));
    check(
            because: 'make sure all callbacks got invoked',
            _addressToOnValidateCallbacks)
        .isEmpty();
  }
}

/// Validation event listener that executes callbacks installed by
/// [_ValidationTestIRWriter].
base class _ValidationEventListener extends ValidationEventListener {
  final ValidatorTest test;

  _ValidationEventListener(this.test);

  @override
  void onFinished() => _onAddress(test.ir.endAddress);

  @override
  void onInstruction(int address) => _onAddress(address);

  void _onAddress(int address) {
    if (test._addressToOnValidateCallbacks.remove(address)
        case var callbacks?) {
      for (var callback in callbacks) {
        callback(this);
      }
    }
  }
}

/// IR writer that can record callbacks to be executed during validation.
///
/// These callbacks will have access to the [ValidationEventListener] so they
/// can query some internal validator state.
class _ValidationTestIRWriter extends TestIRWriter {
  final Map<int, List<void Function(ValidationEventListener)>>
      _addressToOnValidateCallbacks;

  _ValidationTestIRWriter(this._addressToOnValidateCallbacks);

  void onValidate(void Function(ValidationEventListener) callback) {
    _addressToOnValidateCallbacks
        .putIfAbsent(nextInstructionAddress, () => [])
        .add(callback);
  }
}

extension on Subject<ValidationError> {
  Subject<int> get address => has((e) => e.address, 'address');
  Subject<String> get message => has((e) => e.message, 'message');
}
