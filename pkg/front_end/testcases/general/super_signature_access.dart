// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void method(num a) {}
  num operator [](num a) => 0;
  void operator []=(num a, num b) {}
  void set setter(num a) {}
}

class Super1 {
  num? operator [](num a) => null;
  void operator []=(num a, num b) {}
}

class Class extends Super {
  void method(covariant int a);
  num operator [](covariant int a);
  void operator []=(covariant int a, covariant int b);
  void set setter(covariant int a);
}

class Class1 extends Super1 {
  num? operator [](covariant int a);

  void operator []=(covariant int a, covariant int b);
}

class Subclass extends Class {
  void method(int a) {
    num b = a;
    void Function(num) f = super.method; // Ok: type `void Function(num)`.
    void Function(num) g = Class().method; // Error: type `void Function(int)`.
    super.method(b); // Ok.
    Class().method(b); // Error.
  }

  num operator [](covariant int a) {
    num b = a;
    super[b]; // Ok.
    Class()[b]; // Error.
    return 0;
  }

  void operator []=(covariant int a, covariant int b) {
    num c = a;
    super[a] = c; // Ok.
    Class()[a] = c; // Error.
    super[c] = b; // Ok.
    Class()[c] = b; // Error.
    super[a] += c; // Ok.
    Class()[a] += c; // Error.
  }

  void set setter(int a) {
    num b = a;
    super.setter = b; // Ok.
    Class().setter = b; // Error.
  }
}

class Subclass1 extends Class1 {
  num? operator [](covariant int a) {
    return null;
  }

  void operator []=(covariant int a, covariant int b) {
    num c = a;
    super[a] ??= c; // Ok.
    Class1()[b] ??= c; // Error.
  }
}

mixin Mixin on Class {
  void method(int a) {
    num b = a;
    void Function(num) f = super.method; // Error: type `void Function(int)`.
    void Function(num) g = Class().method; // Error: type `void Function(int)`.
    super.method(b); // Error.
    Class().method(b); // Error.
  }

  num operator [](covariant int a) {
    num b = a;
    super[b]; // Error.
    Class()[b]; // Error.
    return 0;
  }

  void operator []=(covariant int a, covariant int b) {
    num c = a;
    super[a] = c; // Error.
    Class()[a] = c; // Error.
    super[c] = b; // Error.
    Class()[c] = b; // Error.
    super[a] += c; // Error.
    Class()[a] += c; // Error.
  }

  void set setter(int a) {
    num b = a;
    super.setter = b; // Error.
    Class().setter = b; // Error.
  }
}

mixin Mixin1 on Class1 {
  void operator []=(covariant int a, covariant int b) {
    num c = a;
    super[a] ??= c; // Error.
    Class1()[b] ??= c; // Error.
  }
}
