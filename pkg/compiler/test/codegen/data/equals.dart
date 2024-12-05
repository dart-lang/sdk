// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Primitive '==' tests compile to '===', or '==' when both sides can be null.

/*member: test1a:function(value) {
  return value == null;
}*/
test1a(int? value) {
  return value == null;
}

/*member: test1b:function(value) {
  return value == null;
}*/
test1b(int? value) {
  return null == value;
}

/*member: test2a:function(value) {
  return value === 1;
}*/
test2a(int? value) {
  return value == 1;
}

/*member: test2b:function(value) {
  return 1 === value;
}*/
test2b(int? value) {
  return 1 == value;
}

/*member: test3a:function(value) {
  return value === "foo";
}*/
test3a(String? value) {
  return value == 'foo';
}

/*member: test3b:function(value) {
  return "foo" === value;
}*/
test3b(String? value) {
  return 'foo' == value;
}

/*member: test4a:function(value) {
  return value === 1;
}*/
test4a(int value) {
  return value == 1;
}

/*member: test4b:function(value) {
  return 1 === value;
}*/
test4b(int value) {
  return 1 == value;
}

/*member: test5:function(x, y) {
  return x === y;
}*/
test5(int x, int y) {
  return x == y;
}

/*member: test6:function(x, y) {
  return x == y;
}*/
test6(int? x, int? y) {
  return x == y;
}

/*member: test7a:function(value) {
  return value === "foo";
}*/
test7a(String value) {
  return value == 'foo';
}

/*member: test7b:function(value) {
  return "foo" === value;
}*/
test7b(String value) {
  return 'foo' == value;
}

/*member: test8:function(a, b) {
  return a === b;
}*/
test8(String a, String b) {
  return a == b;
}

/*member: test9:function(a, b) {
  return a == b;
}*/
test9(String? a, String? b) {
  return a == b;
}

/*member: main:ignore*/
@pragma('dart2js:disable-inlining')
main() {
  test1a(-1);
  test1a(1);
  test1a(null);
  test1b(-1);
  test1b(1);
  test1b(null);

  test2a(-1);
  test2a(1);
  test2a(null);
  test2b(-1);
  test2b(1);
  test2b(null);

  test3a('x');
  test3a('y');
  test3a(null);
  test3b('x');
  test3b('y');
  test3b(null);

  test4a(-1);
  test4a(1);
  test4b(-1);
  test4b(1);

  test5(1, -1);
  test5(1, 1);
  test5(-1, 1);
  test5(-1, -1);

  test6(null, -1);
  test6(1, -1);
  test6(1, 1);
  test6(-1, 1);
  test6(-1, null);

  test7a('foo');
  test7a('bar');
  test7b('foo');
  test7b('bar');

  test8('foo', 'bar');
  test8('foo', 'foo');
  test8('bar', 'foo');
  test8('bar', 'bar');

  test9(null, 'foo');
  test9(null, null);
  test9('foo', 'foo');
  test9('foo', 'bar');
  test9('bar', null);
}
