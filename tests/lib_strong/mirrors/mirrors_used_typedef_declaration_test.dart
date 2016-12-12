// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'package:expect/expect.dart';

@MirrorsUsed(targets: "Foo")
import 'dart:mirrors';

typedef int Foo(String x);
typedef int Bar();

main() {
  LibraryMirror thisLibrary = currentMirrorSystem().findLibrary(#test);

  Mirror fooMirror = thisLibrary.declarations[#Foo];

  Expect.isTrue(fooMirror != null, 'Foo not found.');
  Expect.isTrue(thisLibrary.declarations[#Foo] is TypedefMirror,
                'TypedefMirror expected, found $fooMirror');

  // The following code does not currenty work on the VM, because it does not
  // support MirrorsUsed (see dartbug.com/16048).
  Mirror barMirror = thisLibrary.declarations[#Bar];              /// 01: ok
  Expect.isTrue(barMirror == null,                                /// 01: continued
                'Bar should not be emitted due to MirrorsUsed.'); /// 01: continued
}
