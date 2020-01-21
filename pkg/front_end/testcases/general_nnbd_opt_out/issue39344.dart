// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class A {}

class B extends A {}

List<B> xs;
List<List<B>> xss;

class Class<T extends A> {
  void method1a(T t) {
    if (t is B) {
      // `t` is now promoted to T & B

      // The list literal has type List<T>, not List<T & B>
      var ys = [t];
      xs = ys;
    }
  }

  void method1b(T t) {
    if (t is B) {
      // `t` is now promoted to T & B

      // The list literal has type List<List<T>>, not List<List<T & B>>
      var yss = [
        [t]
      ];
      xss = yss;
    }
  }

  void method2a(T t) {
    dynamic alias;
    if (t is B) {
      // `t` is now promoted to T & B

      // The list literal has type List<T>, not List<T & B>
      var ys = [t];
      alias = ys;
      xs = alias;
    }
  }

  void method2b(T t) {
    dynamic alias;
    if (t is B) {
      // `t` is now promoted to T & B

      // The list literal has type List<List<T>>, not List<List<T & B>>
      var yss = [
        [t]
      ];
      alias = yss;
      xss = alias;
    }
  }
}

void main() {
  throws(() {
    Class<A>().method2a(B());
    print(xs.runtimeType); // 'List<A>'.
  });
  throws(() {
    Class<A>().method2b(B());
    print(xs.runtimeType); // 'List<A>'.
  });
}

void errors() {
  Class<A>().method1a(B());
  Class<A>().method1b(B());
}

void throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Expected throws';
}
