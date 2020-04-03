// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable
// @dart = 2.2
import 'package:expect/expect.dart';

class late {
  int get g => 1;
}

class required {
  int get g => 2;
}

class C {
  late l = late();
  required r = required();
}

main() {
  Expect.equals(C().l.g, 1);
  Expect.equals(C().r.g, 2);
}
