// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'multiple_libraries_shared_helper.dart';

class SA1 extends B1 with M1<int> {
  SA1() {
    super.foo();
  }
}

class SA3 extends B1 with M1<String> {
  SA3() {
    super.foo();
  }
}
