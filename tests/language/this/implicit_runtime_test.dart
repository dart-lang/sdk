// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class Interface {
  final x;
  Interface(this.x);
}

abstract class Abstract implements Interface {
  String toString() => x.toString();
}

// This class does not implement "x" either, but it is not marked
// abstract.


// This class does not implement "x", but is itself abstract, so that's OK.
abstract class SubAbstract2 extends Abstract {
  get x; // Abstract.
}

// This class does not implement "x" either, but it is not marked
// abstract.


class Concrete extends Abstract {
  get x => 7;
}

class SubConcrete extends Concrete {
  final x;
  SubConcrete(this.x);
}

void main() {

  Expect.equals('7', new Concrete().toString());
  Expect.equals('42', new SubConcrete(42).toString());
  Expect.equals('7', new SubConcrete(new Concrete()).toString());
}
