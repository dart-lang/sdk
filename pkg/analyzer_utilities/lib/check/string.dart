// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:meta/meta.dart';

extension StringExtension on CheckTarget<String> {
  void contains(Pattern other) {
    if (!value.contains(other)) {
      fail('does not contain ${valueStr(other)}');
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

  void startsWith(Pattern other) {
    if (!value.startsWith(other)) {
      fail('does not start with ${valueStr(other)}');
    }
  }
}
