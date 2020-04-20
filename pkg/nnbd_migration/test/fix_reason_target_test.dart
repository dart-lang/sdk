// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixReasonTargetTest);
  });
}

@reflectiveTest
class FixReasonTargetTest {
  void test_suffix_complex() {
    var root = FixReasonTarget.root;
    expect(root.returnType.typeArgument(0).suffix,
        ' for type argument 0 of return type');
    expect(root.yieldedType.namedParameter('foo').suffix,
        ' for parameter foo of yielded type');
    expect(root.namedParameter('foo').positionalParameter(0).suffix,
        ' for parameter 0 of parameter foo');
    expect(root.positionalParameter(0).returnType.suffix,
        ' for return type of parameter 0');
    expect(root.typeArgument(0).yieldedType.suffix,
        ' for yielded type from type argument 0');
  }

  void test_suffix_simple() {
    var root = FixReasonTarget.root;
    expect(root.suffix, '');
    expect(root.returnType.suffix, ' for return type');
    expect(root.yieldedType.suffix, ' for yielded type');
    expect(root.namedParameter('foo').suffix, ' for parameter foo');
    expect(root.positionalParameter(0).suffix, ' for parameter 0');
    expect(root.typeArgument(0).suffix, ' for type argument 0');
  }
}
