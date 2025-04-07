// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `is` tests against some parameterized interface types are equivalent to a
// weaker test for just the interface. The weaker test is usually more efficient,
// sometimes being compiled to `instanceof`.

class Base<T extends num> {
  /*member: Base.test1:function(other) {
  if (other instanceof A.D1)
    return other.foo$0();
  return "other";
}*/
  @pragma('dart2js:parameter:trust')
  String test1(Base<T> other) {
    if (other is D1<T>) return other.foo();
    return 'other';
  }

  /*member: Base.test1qn:function(other) {
  if (other instanceof A.D1)
    return other.foo$0();
  return "other";
}*/
  @pragma('dart2js:parameter:trust')
  String test1qn(Base<T>? other) {
    if (other is D1<T>) return other.foo();
    return 'other';
  }

  /*member: Base.test1nq:function(other) {
  if (other instanceof A.D1)
    return other.method$0();
  return "other";
}*/
  @pragma('dart2js:parameter:trust')
  String? test1nq(Base<T> other) {
    if (other is D1<T>?) return other.method(); // No promotion, so can't foo().
    return 'other';
  }

  /*member: Base.test1qq:function(other) {
  var t1;
  if (type$.nullable_D1_dynamic._is(other)) {
    t1 = other.foo$0();
    return t1;
  }
  return "other";
}*/
  @pragma('dart2js:parameter:trust')
  String? test1qq(Base<T>? other) {
    if (other is D1<T>?) return other?.foo();
    return 'other';
  }

  /*member: Base.test2:function(other) {
  if (other instanceof A.D2)
    return other.bar$0();
  return "other";
}*/
  @pragma('dart2js:parameter:trust')
  String test2(Base<T> other) {
    if (other is D2<T>) return other.bar();
    return 'other';
  }

  @pragma('dart2js:never-inline')
  /*member: Base.method:ignore*/
  String method() => 'Base.method';
}

class D1<T extends num> extends Base<T> {
  @pragma('dart2js:never-inline')
  /*member: D1.foo:ignore*/
  String foo() => 'D1<$T>.foo';
}

class D2<T extends num> extends D1<T> {
  @pragma('dart2js:never-inline')
  /*member: D2.bar:ignore*/
  String bar() => 'D2.bar';
}

/*member: main:ignore*/
main() {
  final items = [Base<int>(), D1<int>(), D2<int>()];

  for (final item in items) {
    print(item.test1(items.first));
    print(item.test1(item));

    print(item.test1qn(items.first));
    print(item.test1qn(item));
    print(item.test1nq(items.first));
    print(item.test1nq(item));
    print(item.test1qq(items.first));
    print(item.test1qq(item));

    print(item.test2(items.first));
    print(item.test2(item));
  }
}
