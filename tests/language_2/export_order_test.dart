// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'export_order_helper1.dart' as bar;
import 'export_order_helper2.dart';

final y = 38;
final info = new Info();

void main() {
  Expect.equals(38, info.x);
  Expect.equals(38, bar.y);
  Expect.equals(38, bar.z);
}
