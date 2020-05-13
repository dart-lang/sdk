// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  @override
  noSuchMethod(Object o, {String foo = ''}) => 42;

  @override
  toString({String foo = ''}) => 'foo';
}

main() {}

test() {
  dynamic c = new Class();
  var v1 = c.toString();
  var v2 = c.toString(foo: 42);
  var v3 = c.toString;
  var v4 = c.hashCode;
  var v5 = c.hashCode();
  // TODO(johnniwinther): Avoid compile-time error here.
  var v6 = c.noSuchMethod("foo");
  var v7 = c.noSuchMethod("foo", foo: 42);
  var v8 = c.noSuchMethod;
}
