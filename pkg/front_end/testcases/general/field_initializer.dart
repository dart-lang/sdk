// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  var field1;
  var field2 = 42 as int?;

  C.c1(this.field1, this.field2);

  C.c2() : field1 = 0, field2 = 1;

  C.c3();
}