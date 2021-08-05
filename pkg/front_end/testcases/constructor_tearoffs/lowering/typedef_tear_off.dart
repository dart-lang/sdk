// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool inSoundMode = <int?>[] is! List<int>;

class A {}

class B<X> {
  int field1;
  String field2;

  B._(this.field1, this.field2);
  B() : this._(0, '');
  B.foo(this.field1) : field2 = '';
  factory B.bar(int i, String j) => new B<X>._(i, j);
}

typedef DA1 = A;

typedef DA2<X extends num> = A;

typedef DB1 = B<String>;

typedef DB2<X extends num> = B<X>;

typedef DB3<X extends num, Y extends String> = B<X>;

main() {
  var f1a = DA1.new;
  var c1a = f1a();
  expect(true, c1a is A);
  () {
    f1a(0); // error
  };

  dynamic f1b = DA1.new;
  var c1b = f1b();
  expect(true, c1b is A);
  throws(() => f1b(0));

  var f2a = DA2.new;
  var c2a = f2a();
  expect(true, c2a is A);
  () {
    f2a(0); // error
    f2a<String>(); // error
  };

  dynamic f2b = DA2.new;
  var c2b = f2b();
  expect(true, c2b is A);
  var c2c = f2b<int>();
  expect(true, c2c is A);
  throws(() => f2b(0));
  throws(() => f2b<String>());

  var f3a = DB1.new;
  var c3a = f3a();
  expect(true, c3a is B<String>);
  expect(false, c3a is B<int>);
  expect(0, c3a.field1);
  expect('', c3a.field2);
  () {
    f3a(0); // error
    f3a<String>(); // error
  };

  dynamic f3b = DB1.new;
  var c3b = f3b();
  expect(true, c3b is B<String>);
  expect(false, c3b is B<int>);
  expect(0, c3a.field1);
  expect('', c3a.field2);
  throws(() => f3b(0));
  throws(() => f3b<String>());

  var f3c = DB1.foo;
  var c3c = f3c(42);
  expect(true, c3c is B<String>);
  expect(false, c3c is B<int>);
  expect(42, c3c.field1);
  expect('', c3c.field2);
  () {
    f3c(); // error
    f3c(0, 0); // error
    f3c<String>(0); // error
  };

  dynamic f3d = DB1.foo;
  var c3d = f3d(42);
  expect(true, c3d is B<String>);
  expect(false, c3d is B<int>);
  expect(42, c3d.field1);
  expect('', c3d.field2);
  throws(() => f3d());
  throws(() => f3d(0, 0));
  throws(() => f3d<String>(0));

  var f3e = DB1.bar;
  var c3e = f3e(42, 'foo');
  expect(true, c3e is B<String>);
  expect(false, c3e is B<int>);
  expect(42, c3e.field1);
  expect('foo', c3e.field2);
  () {
    f3e(); // error
    f3e(0); // error
    f3e<String>(0, ''); // error
  };

  dynamic f3f = DB1.bar;
  var c3f = f3f(42, 'foo');
  expect(true, c3f is B<String>);
  expect(false, c3f is B<int>);
  expect(42, c3f.field1);
  expect('foo', c3f.field2);
  throws(() => c3f());
  throws(() => c3f(0));
  throws(() => c3f<String>(0));

  var f4a = DB2.new;
  var c4a = f4a();
  expect(true, c4a is B<num>);
  expect(false, c4a is B<int>);
  var c4b = f4a<int>();
  expect(true, c4b is B<int>);
  expect(false, c4b is B<double>);
  () {
    f4a(0); // error
    f4a<String>(); // error
  };

  dynamic f4b = DB2.new;
  var c4c = f4b();
  expect(true, c4c is B<num>);
  expect(false, c4c is B<int>);
  var c4d = f4b<int>();
  expect(true, c4d is B<int>);
  expect(false, c4d is B<double>);
  throws(() => f4b(0));
  throws(() => f4b<String>());

  var f5a = DB3.new;
  var c5a = f5a();
  expect(true, c5a is B<num>);
  expect(false, c5a is B<int>);
  var c5b = f5a<int, String>();
  expect(true, c5b is B<int>);
  expect(false, c5b is B<double>);
  () {
    f5a(0); // error
    f5a<String>(); // error
    f5a<String, String>(); // error
    f5a<num, num>(); // error
  };

  dynamic f5b = DB3.new;
  var c5c = f5b();
  expect(true, c5c is B<num>);
  expect(false, c5c is B<int>);
  var c5d = f5b<int, String>();
  expect(true, c5d is B<int>);
  expect(false, c5d is B<double>);
  throws(() => f5b(0));
  throws(() => f5b<String>());
  throws(() => f5b<String, String>());
  throws(() => f5b<num, num>());
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(Function() f, {bool inSoundModeOnly: false}) {
  try {
    f();
  } catch (e) {
    print('Thrown: $e');
    return;
  }
  if (!inSoundMode && inSoundModeOnly) {
    return;
  }
  throw 'Expected exception';
}
