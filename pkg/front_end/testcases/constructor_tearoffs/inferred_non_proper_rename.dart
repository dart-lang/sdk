// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool inSoundMode = <int?>[] is! List<int>;

class A<T> {}

typedef F<X extends num> = A<X>;
typedef G<Y> = A<int>;
typedef H<X, Y> = A<X>;

const f1a = A<int>.new;
const f1b = F<int>.new;
const A<int> Function() f1c = F.new;

const g1a = A<int>.new;
const g1b = G<String>.new;
const A<int> Function() g1c = G.new;

const h1a = A<int>.new;
const h1b = H<int, String>.new;
const A<int> Function() h1c = H.new;

main() {
  test<int>();

  identical(f1a, f1b);
  identical(f1a, f1c);

  identical(g1a, g1b);
  identical(g1a, g1c);

  identical(h1a, h1b);
  identical(h1a, h1c);
}

test<T extends num>() {
  var f2a = A<T>.new;
  var f2b = F<T>.new;
  A<T> Function() f2c = F.new;

  var g2a = A<int>.new;
  var g2b = G<T>.new;
  A<int> Function() g2c = G.new;

  var h2a = A<T>.new;
  var h2b = H<T, String>.new;
  A<T> Function() h2c = H.new;

  // TODO(johnniwinther): Enable these if structural equality is supported at
  // runtime.
  /*expect(f1a, f2a);
  expect(f2a, f2b);
  expect(f2a, f2c);*/

  expect(g1a, g2a);
  expect(g2a, g2b);
  if (inSoundMode) {
    // In weak mode type arguments of constants are weakened.
    expect(g2a, g2c);
  }

  // TODO(johnniwinther): Enable these if structural equality is supported at
  // runtime.
  /*expect(h1a, h2a);
  expect(h2a, h2b);
  expect(h2a, h2c);*/
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
