// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const int REMOVED = 0;
const int ABOVE_ZERO = 1;
const int BELOW_LENGTH = 2;
const int KEPT = 3;
const int ONE_CHECK = 4;
const int ONE_ZERO_CHECK = 5;
const int BELOW_ZERO_CHECK = 6;

final List TESTS = [
"""
main() {
  var a = new List();
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
  }
  return sum;
}
""",
REMOVED,

"""
main(value) {
  var a = new List();
  var sum = 0;
  for (int i = 0; i < value; i++) {
    sum += a[i];
  }
  return sum;
}
""",
ABOVE_ZERO,

"""
main(check) {
  // Make sure value is an int.
  var value = check ? 42 : 54;
  var a = new List(value);
  var sum = 0;
  for (int i = 0; i < value; i++) {
    sum += a[i];
  }
  return sum;
}
""",
REMOVED,

"""
main() {
  var a = new List();
  return a[0];
}
""",
KEPT,

"""
main() {
  var a = new List();
  return a.removeLast();
}
""",
KEPT,

"""
main() {
  var a = new List(4);
  return a[0];
}
""",
REMOVED,

"""
main() {
  var a = new List(4);
  return a.removeLast();
}
""",
REMOVED,

"""
main(value) {
  var a = new List(value);
  return a[value];
}
""",
KEPT,

"""
main(value) {
  var a = new List(1024);
  return a[1023 & value];
}
""",
REMOVED,

"""
main(value) {
  var a = new List(1024);
  return a[1024 & value];
}
""",
ABOVE_ZERO,

"""
main(value) {
  var a = new List();
  return a[1];
}
""",
ABOVE_ZERO,

"""
main(value, call) {
  var a = new List();
  return a[value] + call() + a[value];
}
""",
ONE_ZERO_CHECK,

"""
main(value) {
  var a = new List();
  return a[1] + a[0];
}
""",
ONE_CHECK,

"""
main() {
  var a = new List();
  var sum = 0;
  for (int i = 0; i <= a.length - 1; i++) {
    sum += a[i];
  }
  return sum;
}
""",
REMOVED,

"""
main() {
  var a = new List();
  var sum = 0;
  for (int i = a.length - 1; i >=0; i--) {
    sum += a[i];
  }
  return sum;
}
""",
REMOVED,

"""
main(value) {
  value = value is int ? value as int : 42;
  int sum = ~value;
  for (int i = 0; i < 42; i++) sum += (value & 4);
  var a = new List();
  if (value > a.length - 1) return;
  if (value < 0) return;
  return a[value];
}
""",
REMOVED,

"""
main(value) {
  value = value is int ? value as int : 42;
  int sum = ~value;
  for (int i = 0; i < 42; i++) sum += (value & 4);
  var a = new List();
  if (value <= a.length - 1) {
    if (value >= 0) {
      return a[value];
    }
  }
}
""",
REMOVED,
"""
main(value) {
  value = value is int ? value as int : 42;
  int sum = ~value;
  for (int i = 0; i < 42; i++) sum += (value & 4);
  var a = new List();
  if (value >= a.length) return;
  if (value <= -1) return;
  return a[value];
}
""",
REMOVED,
"""
main(value) {
  var a = new List(4);
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
    if (sum == 0) i++;
  }
  return sum;
}
""",
REMOVED,
"""
main(value) {
  var a = new List(5);
  var sum = 0;
  for (int i = a.length - 1; i >= 0; i--) {
    sum += a[i];
    if (sum == 0) i--;
  }
  return sum;
}
""",
REMOVED,
"""
main(value) {
  var a = new List(6);
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
    if (sum == 0) i--;
  }
  return sum;
}
""",
BELOW_ZERO_CHECK,
"""
main(value) {
  var a = new List(7);
  var sum = 0;
  for (int i = 0; i < a.length;) {
    sum += a[i];
    sum == 0 ? i-- : i++;
  }
  return sum;
}
""",
BELOW_ZERO_CHECK,
"""
main(value) {
  var a = new List(7);
  var sum = 0;
  for (int i = -2; i < a.length; i = 0) {
    sum += a[i];
  }
  return sum;
}
""",
BELOW_ZERO_CHECK,
];

// TODO(ahe): It would probably be better if this test used the real
// core library sources, as its purpose is to detect failure to
// optimize fixed-sized arrays.
const String DEFAULT_CORELIB_WITH_LIST_INTERFACE = r'''
  print(var obj) {}
  abstract class num {}
  abstract class int extends num { }
  abstract class double extends num { }
  class bool {}
  class String {}
  class Object {
    Object();
  }
  class Type {}
  class Function {}
  class List {
    List([int length]);
  }
  abstract class Map {}
  class Closure {}
  class Null {}
  class Dynamic_ {}
  class StackTrace {}
  bool identical(Object a, Object b) {}
  const proxy = 0;''';

const String INTERCEPTORSLIB_WITH_MEMBERS = r'''
  class Interceptor {
    toString() {}
    bool operator==(other) => identical(this, other);
    noSuchMethod(im) { throw im; }
  }
  abstract class JSIndexable {
    get length;
  }
  abstract class JSMutableIndexable extends JSIndexable {}
  class JSArray implements JSIndexable {
    JSArray() {}
    JSArray.typed(a) => a;
    var length;
    var removeLast;
    operator[] (_) {}
  }
  class JSMutableArray extends JSArray implements JSMutableIndexable {}
  class JSFixedArray extends JSMutableArray {}
  class JSExtendableArray extends JSMutableArray {}
  class JSString implements JSIndexable {
    var length;
  }
  class JSNumber {
    operator +(other) {}
    operator -(other) {}
    operator ~/(other) {}
    operator /(other) {}
    operator *(other) {}
    operator <<(other) {}
    operator >>(other) {}
    operator |(other) {}
    operator &(other) {}
    operator ^(other) {}
    operator <(other) {}
    operator >(other) {}
    operator <=(other) {}
    operator >=(other) {}
    operator ==(other) {}
  }
  class JSInt extends JSNumber {
    operator~() => this;
  }
  class JSDouble extends JSNumber {
  }
  class JSNull {
    bool operator==(other) => identical(null, other);
    get hashCode => throw "JSNull.hashCode not implemented.";
    String toString() => 'Null';
    Type get runtimeType => Null;
    noSuchMethod(x) => super.noSuchMethod(x);
  }
  class JSBool {
  }
  class JSFunction {
  }
  class ObjectInterceptor {
  }
  class JSPositiveInt extends JSInt {}
  class JSUInt32 extends JSPositiveInt {}
  class JSUInt31 extends JSUInt32 {}
  getInterceptor(x) {}''';

Future expect(String code, int kind) {
  return compile(
      code,
      coreSource: DEFAULT_CORELIB_WITH_LIST_INTERFACE,
      interceptorsSource: INTERCEPTORSLIB_WITH_MEMBERS,
      check: (String generated) {
    switch (kind) {
      case REMOVED:
        Expect.isTrue(!generated.contains('ioore'));
        break;

      case ABOVE_ZERO:
        Expect.isTrue(!generated.contains('< 0'));
        Expect.isTrue(generated.contains('ioore'));
        break;

      case BELOW_ZERO_CHECK:
        Expect.isTrue(generated.contains('< 0'));
        Expect.isTrue(!generated.contains('||'));
        Expect.isTrue(generated.contains('ioore'));
        break;

      case BELOW_LENGTH:
        Expect.isTrue(!generated.contains('||'));
        Expect.isTrue(generated.contains('ioore'));
        break;

      case KEPT:
        Expect.isTrue(generated.contains('ioore'));
        break;

      case ONE_CHECK:
        RegExp regexp = new RegExp('ioore');
        Iterator matches = regexp.allMatches(generated).iterator;
        checkNumberOfMatches(matches, 1);
        break;

      case ONE_ZERO_CHECK:
        RegExp regexp = new RegExp('< 0|>>> 0 !==');
        Iterator matches = regexp.allMatches(generated).iterator;
        checkNumberOfMatches(matches, 1);
        break;
    }
  });
}


main() {
  int i = 0;
  Future testNext() {
    return expect(TESTS[i], TESTS[i + 1]).then((_) {
      i += 2;
      if (i < TESTS.length) return testNext();
    });
  }

  asyncTest(() => testNext());
}
