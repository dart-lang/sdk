// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib1;

import 'package:shared.dart';
import 'package:lib2/lib2.dart';

void lib1() {
  output += '|lib1';
  lib2();
}
