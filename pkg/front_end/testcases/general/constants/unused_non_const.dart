// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final int nonConstTopLevel = 0;

class Class {
  static final int nonConstField = 1;
  void test(int nonConstParameter) {
    final int nonConstLocal = 2;

    const _ = {if (false) nonConstTopLevel};
    const _ = {if (false) nonConstField};
    const _ = {if (false) nonConstParameter};
    const _ = {if (false) nonConstLocal};
  }
}
