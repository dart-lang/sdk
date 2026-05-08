// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'field_dependency_helper1.dart';

class Deferred {
  final String a = 'a';
  final String b = 'b';
}

void useEager() {
  print(Eager().b);
}
