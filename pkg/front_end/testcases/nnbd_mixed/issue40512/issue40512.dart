// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6
import 'issue40512_lib.dart';

class C extends Object with A, B {}

void main() {
  print(B());
  print(C());
}
