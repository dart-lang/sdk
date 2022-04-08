// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Used from 'evaluation_order_test.dart'.

import 'evaluation_order_test.dart';

get arg => argumentEffect();

void Function(void) get m {
  getterEffect();
  return (_) {};
}
