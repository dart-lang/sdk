// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for http://dartbug.com/51321.

import 'dart:ffi';

final class Foo extends Struct {
  @IntPtr()
  external int bar;
}

@Native<Foo Function()>()
external Foo getFoo();

main() {
  print('hello!');
}
