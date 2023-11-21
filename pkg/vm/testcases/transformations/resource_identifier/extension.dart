// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show ResourceIdentifier;

void main() {
  SomeClass().callWithArgs('42');
}

class SomeClass {}

extension on SomeClass {
  @ResourceIdentifier('id')
  void callWithArgs(String s) {
    s += "suffix";
  }
}
