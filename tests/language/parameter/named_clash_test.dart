// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  m({a, b, c}) {
    try {} catch (e) {} // no inline
    return 'Foo $a $b $c';
  }
}

class Bar {
  m(z, {a$b, c}) {
    try {} catch (e) {} // no inline
    var ab = a$b;
    return 'Bar $z $ab $c';
  }
}

inscrutable(xs, i) => i == 0 ? xs[0] : inscrutable(xs.sublist(1), i - 1);

main() {
  var list = [new Foo(), new Bar()];
  var foo = inscrutable(list, 0);
  var bar = inscrutable(list, 1);

  Expect.equals(r'Foo a b c', foo.m(a: 'a', b: 'b', c: 'c'));
  Expect.equals(r'Bar z a$b c', bar.m('z', a$b: r'a$b', c: 'c'));

  Expect.throwsNoSuchMethodError(() => foo.m('z', a$b: r'a$b', c: 'c'));
  Expect.throwsNoSuchMethodError(() => bar.m(a: 'a', b: 'b', c: 'c'));
}
