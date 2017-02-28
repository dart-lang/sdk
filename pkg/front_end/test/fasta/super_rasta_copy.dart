// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// TODO(ahe): This is a copy of [rasta/super.dart] without the `n`
// property. Remove this once fasta can handle all of the original file.

class A {
  var a;
  var b;
  var c;
  var d;
  get e => null;
  final f;
  set g(_) {}
  get h => null;
  set h(_) {}
  get i => null;

  operator [](_) => null;
  operator []=(a, b) {}
  operator ~() => 117;
  operator -() => 117;

  operator ==(other) => true;

  void m() {}
}

class B extends A {
  get b => null;
  set c(x) {}
  final d;
  set i(x) {}
}

class C extends B {
  test() {
    ~super;
    use(~super);
    -super;
    use(-super);
    super == 87;
    use(super == 87);
    super != 87;
    use(super != 87);

    super.a;
    use(super.a);
    super.b;
    use(super.b);
    super.c;
    use(super.c);
    super.d;
    use(super.d);
    super.e;
    use(super.e);
    super.f;
    use(super.f);
    super.g;
    use(super.g);
    super.h;
    use(super.h);
    super.i;
    use(super.i);
    super[87];
    use(super[87]);
    super.m;
    use(super.m);

    super.a++;
    use(super.a++);
    super.b++;
    use(super.b++);
    super.c++;
    use(super.c++);
    super.d++;
    use(super.d++);
    super.e++;
    use(super.e++);
    super.f++;
    use(super.f++);
    super.g++;
    use(super.g++);
    super.h++;
    use(super.h++);
    super.i++;
    use(super.i++);
    super[87]++;
    use(super[87]++);
    super.m++;
    use(super.m++);

    ++super.a;
    use(++super.a);
    ++super.b;
    use(++super.b);
    ++super.c;
    use(++super.c);
    ++super.d;
    use(++super.d);
    ++super.e;
    use(++super.e);
    ++super.f;
    use(++super.f);
    ++super.g;
    use(++super.g);
    ++super.h;
    use(++super.h);
    ++super.i;
    use(++super.i);
    ++super[87];
    use(++super[87]);
    ++super.m;
    use(++super.m);

    super.a();
    use(super.a());
    super.b();
    use(super.b());
    super.c();
    use(super.c());
    super.d();
    use(super.d());
    super.e();
    use(super.e());
    super.f();
    use(super.f());
    super.g();
    use(super.g());
    super.h();
    use(super.h());
    super.i();
    use(super.i());
    super[87]();
    use(super[87]());
    super.m();
    use(super.m());
    super.m(87);
    use(super.m(87));

    super.a = 42;
    use(super.a = 42);
    super.b = 42;
    use(super.b = 42);
    super.c = 42;
    use(super.c = 42);
    super.d = 42;
    use(super.d = 42);
    super.e = 42;
    use(super.e = 42);
    super.f = 42;
    use(super.f = 42);
    super.g = 42;
    use(super.g = 42);
    super.h = 42;
    use(super.h = 42);
    super.i = 42;
    use(super.i = 42);
    super[87] = 42;
    use(super[87] = 42);
    super.m = 42;
    use(super.m = 42);

    super.a ??= 42;
    use(super.a ??= 42);
    super.b ??= 42;
    use(super.b ??= 42);
    super.c ??= 42;
    use(super.c ??= 42);
    super.d ??= 42;
    use(super.d ??= 42);
    super.e ??= 42;
    use(super.e ??= 42);
    super.f ??= 42;
    use(super.f ??= 42);
    super.g ??= 42;
    use(super.g ??= 42);
    super.h ??= 42;
    use(super.h ??= 42);
    super.i ??= 42;
    use(super.i ??= 42);
    super[87] ??= 42;
    use(super[87] ??= 42);
    super.m ??= 42;
    use(super.m ??= 42);

    super.a += 42;
    use(super.a += 42);
    super.b += 42;
    use(super.b += 42);
    super.c += 42;
    use(super.c += 42);
    super.d += 42;
    use(super.d += 42);
    super.e += 42;
    use(super.e += 42);
    super.f += 42;
    use(super.f += 42);
    super.g += 42;
    use(super.g += 42);
    super.h += 42;
    use(super.h += 42);
    super.i += 42;
    use(super.i += 42);
    super[87] += 42;
    use(super[87] += 42);
    super.m += 42;
    use(super.m += 42);

    super.a -= 42;
    use(super.a -= 42);
    super.b -= 42;
    use(super.b -= 42);
    super.c -= 42;
    use(super.c -= 42);
    super.d -= 42;
    use(super.d -= 42);
    super.e -= 42;
    use(super.e -= 42);
    super.f -= 42;
    use(super.f -= 42);
    super.g -= 42;
    use(super.g -= 42);
    super.h -= 42;
    use(super.h -= 42);
    super.i -= 42;
    use(super.i -= 42);
    super[87] -= 42;
    use(super[87] -= 42);
    super.m -= 42;
    use(super.m -= 42);
  }
}

use(x) {
  if (x == new DateTime.now().millisecondsSinceEpoch) throw "Shouldn't happen";
}

main() {
  try {
    new C().test();
  } on NoSuchMethodError {
    return; // Test passed.
  }
  throw "Test failed";
}
