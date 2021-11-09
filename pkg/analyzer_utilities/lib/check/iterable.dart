// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:meta/meta.dart';

extension IterableExtension<T> on CheckTarget<Iterable<T>> {
  void get isEmpty {
    if (value.isNotEmpty) {
      fail('is not empty');
    }
  }

  void get isNotEmpty {
    if (value.isEmpty) {
      fail('is empty');
    }
  }

  @UseResult.unless(parameterDefined: 'expected')
  CheckTarget<int> hasLength([int? expected]) {
    var actual = value.length;

    if (expected != null && actual != expected) {
      fail('does not have length ${valueStr(expected)}');
    }

    return nest(actual, (length) => 'has length $length');
  }
}
