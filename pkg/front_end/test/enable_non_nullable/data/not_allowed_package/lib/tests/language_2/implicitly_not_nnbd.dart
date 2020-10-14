// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Partial copy of tests/language_2/syntax/pre_nnbd_modifiers_test.dart.

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
