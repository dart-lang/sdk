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

  test_drop_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(2))
      ..drop()
      ..onValidate((v) => check(v.valueStackDepth).equals(1))
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

  test_end_function_pushesOneValue() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..onValidate((v) => check(v.valueStackDepth).equals(1))
      ..ordinaryFunction(parameterCount: 1)
      ..end()
      ..onValidate((v) => check(v.valueStackDepth).equals(2))
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

  test_end_unmatched() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..end()
      ..label('bad')
      ..end());
    _checkInvalidMessageAt('bad').equals('Unmatched end');
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
      ..onValidate((v) => check(v.valueStackDepth).equals(3))
      ..drop()
      ..drop()
      ..end());
    _validate();
  }

  test_function_parameterCount_notInstanceFunction() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 2)
      ..onValidate((v) => check(v.valueStackDepth).equals(2))
      ..drop()
      ..end());
    _validate();
  }

  test_literal_ok() {
    _analyze((ir) => ir
      ..ordinaryFunction()
      ..onValidate((v) => check(v.valueStackDepth).equals(0))
      ..literal(ir.encodeLiteral(null)) // Push `null`
      ..onValidate((v) => check(v.valueStackDepth).equals(1))
      ..end());
    _validate();
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
    validate(ir,
        eventListener: _ValidationEventListener(_addressToOnValidateCallbacks));
    check(
            because: 'make sure all callbacks got invoked',
            _addressToOnValidateCallbacks)
        .isEmpty();
  }
}

/// Validation event listener that executes callbacks installed by
/// [_ValidationTestIRWriter].
base class _ValidationEventListener extends ValidationEventListener {
  final Map<int, List<void Function(ValidationEventListener)>>
      _addressToOnValidateCallbacks;

  _ValidationEventListener(this._addressToOnValidateCallbacks);

  @override
  void onAddress(int address) {
    if (_addressToOnValidateCallbacks.remove(address) case var callbacks?) {
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
