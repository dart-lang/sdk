// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';

extension IntExtension on CheckTarget<int> {
  void get isZero {
    if (value != 0) {
      fail('is not zero');
    }
  }

  void isGreaterThan(int other) {
    if (!(value > other)) {
      fail('is not greater than $other');
    }
  }
}
