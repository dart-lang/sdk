// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart' as test_package;

class CheckTarget<T> {
  final T value;
  final int _depth;

  /// The function that return the description of the value, and of the
  /// chain how we arrived to this value.
  final String Function() _describe;

  CheckTarget(this.value, this._depth, this._describe);

  String get _indent => '  ' * (_depth + 1);

  Never fail(String message) {
    test_package.fail(_describe() + '\n' + _indent + message);
  }

  /// Chains to the given [value]; if a subsequent check fails, [describe]
  /// will be invoked to describe the [value].
  CheckTarget<U> nest<U>(
    U value,
    String Function(U value) describe,
  ) {
    return CheckTarget(value, _depth + 1, () {
      return _describe() + '\n' + _indent + describe(value);
    });
  }

  String valueStr(value) {
    if (value is String) {
      return "'$value'";
    }
    return '$value';
  }

  /// Use this if multiple checks are required on the value.
  void which(void Function(CheckTarget<T> e) checker) {
    checker(this);
  }
}
