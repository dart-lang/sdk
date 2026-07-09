// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class();
  Class.named(int /*normal|limited.int*/ /*verbose.dart.core::int*/ i);

  /*member: Class.initUnnamed:
this()*/
  Class.initUnnamed() : this();
  /*member: Class.initNamed:
this.named(0)*/
  Class.initNamed() : this.named(0);
}
