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
  late TestIRContainer ir;

  test_drop() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..drop() // Pop parameter
      ..drop() // UNDERFLOW
      ..end());
    check(_validate).throws<ValidationError>()
      ..address.equals(2)
      ..message.equals('Value stack underflow');
  }

  test_firstInstruction_function() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..literal(ir.encodeLiteral(null))
      ..end());
    check(_validate).returnsNormally();
  }

  test_firstInstruction_instanceFunction() {
    _analyze((ir) => ir
      ..function(ir.encodeFunctionType(parameterCount: 0),
          FunctionFlags(instance: true))
      ..end());
    check(_validate).returnsNormally();
  }

  test_firstInstruction_notFunction() {
    _analyze((ir) => ir..literal(ir.encodeLiteral(null)));
    check(_validate).throws<ValidationError>()
      ..address.equals(0)
      ..message.equals('First instruction must be function');
  }

  test_function_nested_instanceFunction() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..function(ir.encodeFunctionType(parameterCount: 0),
          FunctionFlags(instance: true))
      ..end()
      ..end());
    check(_validate).throws<ValidationError>()
      ..address.equals(1)
      ..message.equals(
          'Instance function may only be used at instruction address 0');
  }

  test_function_nested_notInstanceFunction() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..ordinaryFunction()
      ..literal(ir.encodeLiteral(null))
      ..end()
      ..end());
    check(_validate).returnsNormally();
  }

  test_function_parameterCount_instanceFunction() {
    _analyze((ir) => ir
      ..function(ir.encodeFunctionType(parameterCount: 2),
          FunctionFlags(instance: true))
      ..drop() // Pop second parameter
      ..drop() // Pop first parameter
      ..drop() // Pop `this`
      ..drop() // UNDERFLOW
      ..end());
    check(_validate).throws<ValidationError>()
      ..address.equals(4)
      ..message.equals('Value stack underflow');
  }

  test_function_parameterCount_notInstanceFunction() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..drop() // Pop second parameter
      ..drop() // Pop first parameter
      ..drop() // UNDERFLOW
      ..end());
    check(_validate).throws<ValidationError>()
      ..address.equals(3)
      ..message.equals('Value stack underflow');
  }

  test_literal() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..literal(ir.encodeLiteral(null)) // Push `null`
      ..drop() // Pop `null`
      ..drop() // UNDERFLOW
      ..end());
    check(_validate).throws<ValidationError>()
      ..address.equals(3)
      ..message.equals('Value stack underflow');
  }

  test_missingEnd() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..literal(ir.encodeLiteral(null)));
    check(_validate).throws<ValidationError>()
      ..address.equals(2)
      ..message.equals('Missing end');
  }

  test_noInstructions() {
    _analyze((ir) => ir);
    check(_validate).throws<ValidationError>()
      ..address.equals(0)
      ..message.equals('No instructions');
  }

  void _analyze(void Function(TestIRWriter) writeIR) {
    var writer = TestIRWriter();
    writeIR(writer);
    ir = TestIRContainer(writer);
  }

  void _validate() => validate(ir);
}

extension on Subject<ValidationError> {
  Subject<int> get address => has((e) => e.address, 'address');
  Subject<String> get message => has((e) => e.message, 'message');
}
