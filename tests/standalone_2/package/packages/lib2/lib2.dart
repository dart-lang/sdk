// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib2;

import 'package:shared.dart';
import 'package:lib3/sub/lib3.dart';

void lib2() {
  output += '|lib2';
  lib3();
}
