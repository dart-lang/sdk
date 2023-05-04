// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int? field1;
  int? field2;
  int? field3;
}

test(o) {
  switch (o) {
    case Class(field1: var s1) || Class(field1: var s2):
      break;
    case Class(field1: var s1) || Class(field1: _):
      break;
    case Class(field1: var field1, field2: var f)
        || Class(:var field1, :var field2):
      break;
    default:
  }
}