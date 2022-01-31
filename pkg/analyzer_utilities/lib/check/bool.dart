// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';

extension BoolExtension on CheckTarget<bool> {
  void get isFalse {
    if (value) {
      fail('is not false');
    }
  }

  void get isTrue {
    if (!value) {
      fail('is not true');
    }
  }
}
