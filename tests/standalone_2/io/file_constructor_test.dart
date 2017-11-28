// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:io';

void main() {
  new File('blåbærgrød');
  new File('foo.txt');
  try {
    new File(null);
    Expect.fail('ArgumentError expected.');
  } on ArgumentError catch (e) {
    // Expected.
  }
  try {
    dynamic one = 1;
    new File(one);
    Expect.fail('Error expected.');
  } on TypeError catch (e) {}
}
