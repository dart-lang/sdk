// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/wolf/ir/ir.dart';

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
  final List<TestFunctionType> _functionTypes;

  TestIRContainer(TestIRWriter super.writer)
      : _functionTypes = writer._functionTypes;

  @override
  int countParameters(TypeRef type) =>
      _functionTypes[type.index].parameterCount;
}

/// Writer of an IR instruction stream that's not connected to an analyzer AST
/// data structure.
///
/// Suitable for use in unit tests that test the IR instructions directly rather
/// than generate them from a Dart AST.
class TestIRWriter extends RawIRWriter {
  final _functionTypes = <TestFunctionType>[];
  final _literalTable = <Object?>[];
  final _literalToRef = <Object?, LiteralRef>{};
  final _parameterCountToFunctionTypeMap = <int, TypeRef>{};

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

  /// Convenience method for creating an ordinary function (not a method, not
  /// async, not a generator).
  void ordinaryFunction({int parameterCount = 0}) => function(
      encodeFunctionType(parameterCount: parameterCount), FunctionFlags());
}
