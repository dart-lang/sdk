// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsKnownTest);
  });
}

@reflectiveTest
class IsKnownTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _checkKnown(parseType('dynamic'));
  }

  test_function() {
    _checkKnown(parseType('void Function()'));

    _checkUnknown(parseType('UnknownInferredType Function()'));

    _checkUnknown(parseType('void Function(UnknownInferredType)'));
  }

  test_interface() {
    _checkKnown(parseType('int'));
    _checkKnown(parseType('List<int>'));
    _checkUnknown(parseType('List<UnknownInferredType>'));
  }

  test_never() {
    _checkKnown(parseType('Never'));
  }

  test_null() {
    _checkKnown(parseType('Null'));
  }

  test_record() {
    _checkKnown(parseRecordType('(int,)'));

    _checkUnknown(parseType('(UnknownInferredType,)'));

    _checkKnown(parseRecordType('({int x})'));

    _checkUnknown(parseType('({UnknownInferredType x})'));
  }

  test_unknownInferredType() {
    _checkUnknown(parseType('UnknownInferredType'));
  }

  test_void() {
    _checkKnown(parseType('void'));
  }

  void _checkKnown(DartType type) {
    expect(UnknownInferredType.isKnown(type), isTrue);
    expect(UnknownInferredType.isUnknown(type), isFalse);
  }

  void _checkUnknown(DartType type) {
    expect(UnknownInferredType.isKnown(type), isFalse);
    expect(UnknownInferredType.isUnknown(type), isTrue);
  }
}
