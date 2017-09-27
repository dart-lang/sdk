// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Second dart test program.

// VMOptions=--optimization-counter-threshold=5

import "dart:mirrors";
import "package:expect/expect.dart";

class BadInherit
  extends Null //    //# 01: compile-time error
  implements Null // //# 02: compile-time error
  extends Object with Null // //# 03: compile-time error
{}

class EqualsNotCalled {
  int get hashCode => throw "And don't warn!";
  bool operator ==(Object other) {
    throw "SHOULD NOT GET HERE";
  }
}

class Generic<T> {
  bool test(o) => o is T;
  T cast(o) => o as T;
  Type get type => T;
}

class Generic2<T, S> {
  bool test(o) => new Generic<T>().test(o);
  T cast(o) => new Generic<T>().cast(o);
  Type get type => new Generic<T>().type;
}

// Magic incantation to avoid the compiler recognizing the constant values
// at compile time. If the result is computed at compile time, the dynamic code
// will not be tested.
confuse(x) {
  try {
    if (new DateTime.now().millisecondsSinceEpoch == 42) x = 42;
    throw [x];
  } on dynamic catch (e) {
    return e[0];
  }
  return 42;
}

void main() {
  for (int i = 0; i < 10; i++) {
    test();
  }
}

void test() {
  new BadInherit(); // Make sure class is referenced.

  int foo(var obj) {
    Expect.equals(null, obj);
  }

  bool compareToNull(var value) {
    return null == value;
  }

  bool compareWithNull(var value) {
    return value == null;
  }

  var val = 1;
  var obj = confuse(null); // Null value that isn't known at compile-time.
  Expect.isTrue(identical(obj, null), "identical");

  Expect.isTrue(null == null);
  Expect.isTrue(null == obj);
  Expect.isTrue(obj == null);
  Expect.isTrue(obj == obj);

  // Using  == null  or  null ==  will not call any equality method.
  Expect.isFalse(new EqualsNotCalled() == null);
  Expect.isFalse(null == new EqualsNotCalled());
  Expect.isFalse(new EqualsNotCalled() == obj);
  Expect.isFalse(obj == new EqualsNotCalled());

  Expect.isFalse(null == false);
  Expect.isFalse(null == 0);
  Expect.isFalse(null == "");
  Expect.isFalse(null == []);
  Expect.isFalse(null == 0.0);
  Expect.isFalse(null == -0.0);
  Expect.isFalse(null == double.NAN);

  Expect.isFalse(obj == false);
  Expect.isFalse(obj == 0);
  Expect.isFalse(obj == "");
  Expect.isFalse(obj == []);
  Expect.isFalse(obj == 0.0);
  Expect.isFalse(obj == -0.0);
  Expect.isFalse(obj == double.NAN);

  // Explicit constant expressions.
  const t1 = null == null;
  const t2 = null == 0;
  const t3 = false == null;
  Expect.isTrue(t1);
  Expect.isFalse(t2);
  Expect.isFalse(t3);

  foo(obj);
  foo(null);
  if (obj != null) {
    foo(null);
  } else {
    foo(obj);
  }

  // Test "is" operator.
  Expect.isTrue(null is Null);
  Expect.isTrue(obj is Null);
  Expect.isTrue(null is Object);
  Expect.isTrue(obj is Object);
  Expect.isTrue(null is dynamic);
  Expect.isTrue(obj is dynamic);
  Expect.isFalse(null is String);
  Expect.isFalse(obj is String);
  Expect.isFalse(0 is Null); // It's only assignable.
  Expect.isFalse(null is! Null);
  Expect.isFalse(obj is! Null);
  Expect.isFalse(null is! Object);
  Expect.isFalse(obj is! Object);
  Expect.isFalse(null is! dynamic);
  Expect.isFalse(obj is! dynamic);
  Expect.isTrue(null is! String);
  Expect.isTrue(obj is! String);
  Expect.isTrue(0 is! Null); // It's only assignable.

  // Test "is" operator with generic type variable.
  Expect.isTrue(new Generic<Null>().test(null));
  Expect.isFalse(new Generic<Null>().test(42));
  Expect.isTrue(new Generic2<Null, int>().test(null));
  Expect.isFalse(new Generic2<Null, int>().test(42));

  // Test cast, "as", operator.
  Expect.equals(null, null as Null);
  Expect.equals(null, null as Object);
  Expect.equals(null, null as int);
  Expect.throws(() => 42 as Null, (e) => e is CastError);
  Expect.equals(null, new Generic<Null>().cast(null));
  Expect.equals(null, new Generic<Object>().cast(null));
  Expect.equals(null, new Generic<int>().cast(null));

  Expect.equals(null, obj as Null);
  Expect.equals(null, obj as Object);
  Expect.equals(null, obj as int);
  Expect.equals(null, new Generic<Null>().cast(obj));
  Expect.equals(null, new Generic<Object>().cast(obj));
  Expect.equals(null, new Generic<int>().cast(obj));

  Expect.equals("null", null.toString());
  Expect.equals("null", "${null}");
  Expect.equals("null", obj.toString());
  Expect.equals("null", "${obj}");

  Expect.equals(Null, null.runtimeType);
  Expect.equals(Null, obj.runtimeType);
  Expect.equals(Null, new Generic<Null>().type);
  Expect.equals(Null, new Generic2<Null, int>().type);

  Expect.isFalse(compareToNull(val));
  Expect.isTrue(compareToNull(obj));
  Expect.isFalse(compareWithNull(val));
  Expect.isTrue(compareWithNull(obj));

  ClassMirror cm = reflectClass(Null);

  InstanceMirror im1 = reflect(null);
  Expect.equals(cm, im1.type);
  Expect.isTrue(im1.invoke(const Symbol("=="), [null]).reflectee);//# mirrors: ok
  Expect.isFalse(im1.invoke(const Symbol("=="), [42]).reflectee); //# mirrors: ok

  InstanceMirror im2 = reflect(obj);
  Expect.equals(cm, im2.type);
  Expect.isTrue(im2.invoke(const Symbol("=="), [null]).reflectee);//# mirrors: ok
  Expect.isFalse(im2.invoke(const Symbol("=="), [42]).reflectee); //# mirrors: ok

  // Method/value extraction. The runtimeType was checked above, and operator==
  // cannot be extracted.
  // Currently fails in VM.
  Expect.equals(null.toString, obj.toString);
  Expect.equals(null.noSuchMethod, obj.noSuchMethod);
  Expect.equals(null.hashCode, obj.hashCode);

  var toString = null.toString;
  Expect.equals("null", toString());
  Expect.equals("null", Function.apply(toString, []));

  Expect.throws(() => obj.notDeclared());
  var noSuchMethod = null.noSuchMethod;
  // Assign to "dynamic" to prevent compile-time error.
  dynamic capture = new CaptureInvocationMirror();
  var mirror = capture.notDeclared();
  Expect.throws(() => noSuchMethod(mirror));
  Expect.throws(() => Function.apply(noSuchMethod, [mirror]));
}

class CaptureInvocationMirror {
  noSuchMethod(mirror) => mirror;
}
