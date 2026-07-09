// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

Object? field;

Object? get accessor => field;

set accessor(Object? value) {
  field = value;
  return;
}

void main() {
  LibraryMirror library =
      (reflect(main) as ClosureMirror).function.owner as LibraryMirror;

  field = 42;
  Expect.equals(42, library.getField(#accessor).reflectee);
  Expect.equals(87, library.setField(#accessor, 87).reflectee);
  Expect.equals(87, field);
  Expect.equals(87, library.getField(#accessor).reflectee);
}
