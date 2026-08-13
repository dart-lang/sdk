// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'load_dill_twice_lib_2.dart';

// Use annotation to force proper printing.

typedef myTypedefWithNamed(@Foo int a, {@Foo int b});
typedef myTypedefWithOptionalPositional(@Foo int a, [@Foo int b]);

const Foo = 42;

class Bar {}

extension BarX on Bar {
  void hello() {
    print("Hello!");
  }
}
