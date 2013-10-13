// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MirrorsUsed(metaTargets: 'X')
import 'dart:mirrors';

const x = const X();
class X {
  const X();
}

@x
class Y {
  foo() => 42;
}

class Z {
  foo() => 99;

  @X()
  bar() => 87;
}

main() {
  var y = new Y();
  var z = new Z();

  if (reflect(y).invoke(#foo, []).reflectee != 42) throw 'Wrong Y.foo';
  if (reflect(z).invoke(#bar, []).reflectee != 87) throw 'Wrong Z.bar';

  bool caught = false;
  try {
    reflect(z).invoke(#foo, []);
  } on UnsupportedError catch (e) {
    caught = true;
  }
  if (!caught) throw 'Wrong Z.foo';
}
