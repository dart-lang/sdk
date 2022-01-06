// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:test';
import 'dart:extra';
import 'dart:sub';
import 'dart:sub2';
import 'dart:super1';
import 'dart:super2';
import 'dart:common';

main() {
  new Class();
  new Extra();
  new Sub();
  new Sub2();
  new Super1();
  new Super2();
  new Common();
}
