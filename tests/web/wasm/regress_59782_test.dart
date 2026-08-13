// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  String? result;
  dynamic number = 42;
  switch (number) {
    case 'a':
      result = 'a';
    case 'b':
      result = 'b';
    default:
      result = 'default';
  }

  Expect.equals(result, 'default');

  result = null;
  switch (number) {
    case 'a':
      result = 'a';
    case 'b':
      result = 'b';
  }
  Expect.isNull(result);
}
