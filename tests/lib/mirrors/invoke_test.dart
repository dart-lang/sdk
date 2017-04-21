// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_test;

@MirrorsUsed(targets: "test.invoke_test")
import 'dart:mirrors';

import 'dart:async' show Future;

import 'package:expect/expect.dart';

class C {
  var field;
  C() : this.field = 'default';
  C.named(this.field);

  get getter => 'get $field';
  set setter(v) => field = 'set $v';
  method(x, y, z) => '$x+$y+$z';
  toString() => 'a C';

  noSuchMethod(invocation) => 'DNU';

  static var staticField = 'initial';
  static get staticGetter => 'sget $staticField';
  static set staticSetter(v) => staticField = 'sset $v';
  static staticFunction(x, y) => "($x,$y)";
}

var libraryField = 'a priori';
get libraryGetter => 'lget $libraryField';
set librarySetter(v) => libraryField = 'lset $v';
libraryFunction(x, y) => '$x$y';

bool isNoSuchMethodError(e) {
  return e is NoSuchMethodError;
}

testSync() {
  var result;

  // InstanceMirror invoke
  C c = new C();
  InstanceMirror im = reflect(c);
  result = im.invoke(const Symbol('method'), [2, 4, 8]);
  Expect.equals('2+4+8', result.reflectee);
  result = im.invoke(const Symbol('doesntExist'), [2, 4, 8]);
  Expect.equals('DNU', result.reflectee);
  result = im.invoke(const Symbol('method'), [2, 4]); // Wrong arity.
  Expect.equals('DNU', result.reflectee);

  // InstanceMirror invokeGetter
  result = im.getField(const Symbol('getter'));
  Expect.equals('get default', result.reflectee);
  result = im.getField(const Symbol('field'));
  Expect.equals('default', result.reflectee);
  result = im.getField(const Symbol('doesntExist'));
  Expect.equals('DNU', result.reflectee);

  // InstanceMirror invokeSetter
  result = im.setField(const Symbol('setter'), 'foo');
  Expect.equals('foo', result.reflectee);
  Expect.equals('set foo', c.field);
  Expect.equals('set foo', im.getField(const Symbol('field')).reflectee);
  result = im.setField(const Symbol('field'), 'bar');
  Expect.equals('bar', result.reflectee);
  Expect.equals('bar', c.field);
  Expect.equals('bar', im.getField(const Symbol('field')).reflectee);
  result = im.setField(const Symbol('doesntExist'), 'bar');
  Expect.equals('bar', result.reflectee);

  // ClassMirror invoke
  ClassMirror cm = reflectClass(C);
  result = cm.invoke(const Symbol('staticFunction'), [3, 4]);
  Expect.equals('(3,4)', result.reflectee);
  Expect.throws(() => cm.invoke(const Symbol('doesntExist'), [3, 4]),
      isNoSuchMethodError, 'Not defined');
  Expect.throws(() => cm.invoke(const Symbol('staticFunction'), [3]),
      isNoSuchMethodError, 'Wrong arity');

  // ClassMirror invokeGetter
  result = cm.getField(const Symbol('staticGetter'));
  Expect.equals('sget initial', result.reflectee);
  result = cm.getField(const Symbol('staticField'));
  Expect.equals('initial', result.reflectee);
  Expect.throws(() => cm.getField(const Symbol('doesntExist')),
      isNoSuchMethodError, 'Not defined');

  // ClassMirror invokeSetter
  result = cm.setField(const Symbol('staticSetter'), 'sfoo');
  Expect.equals('sfoo', result.reflectee);
  Expect.equals('sset sfoo', C.staticField);
  Expect.equals(
      'sset sfoo', cm.getField(const Symbol('staticField')).reflectee);
  result = cm.setField(const Symbol('staticField'), 'sbar');
  Expect.equals('sbar', result.reflectee);
  Expect.equals('sbar', C.staticField);
  Expect.equals('sbar', cm.getField(const Symbol('staticField')).reflectee);
  Expect.throws(() => cm.setField(const Symbol('doesntExist'), 'sbar'),
      isNoSuchMethodError, 'Not defined');

  // ClassMirror invokeConstructor
  result = cm.newInstance(const Symbol(''), []);
  Expect.isTrue(result.reflectee is C);
  Expect.equals('default', result.reflectee.field);
  result = cm.newInstance(const Symbol('named'), ['my value']);
  Expect.isTrue(result.reflectee is C);
  Expect.equals('my value', result.reflectee.field);
  Expect.throws(() => cm.newInstance(const Symbol('doesntExist'), ['my value']),
      isNoSuchMethodError, 'Not defined');
  Expect.throws(() => cm.newInstance(const Symbol('named'), []),
      isNoSuchMethodError, 'Wrong arity');

  // LibraryMirror invoke
  LibraryMirror lm = cm.owner;
  result = lm.invoke(const Symbol('libraryFunction'), [':', ')']);
  Expect.equals(':)', result.reflectee);
  Expect.throws(() => lm.invoke(const Symbol('doesntExist'), [':', ')']),
      isNoSuchMethodError, 'Not defined');
  Expect.throws(() => lm.invoke(const Symbol('libraryFunction'), [':']),
      isNoSuchMethodError, 'Wrong arity');

  // LibraryMirror invokeGetter
  result = lm.getField(const Symbol('libraryGetter'));
  Expect.equals('lget a priori', result.reflectee);
  result = lm.getField(const Symbol('libraryField'));
  Expect.equals('a priori', result.reflectee);
  Expect.throws(() => lm.getField(const Symbol('doesntExist')),
      isNoSuchMethodError, 'Not defined');

  // LibraryMirror invokeSetter
  result = lm.setField(const Symbol('librarySetter'), 'lfoo');
  Expect.equals('lfoo', result.reflectee);
  Expect.equals('lset lfoo', libraryField);
  Expect.equals(
      'lset lfoo', lm.getField(const Symbol('libraryField')).reflectee);
  result = lm.setField(const Symbol('libraryField'), 'lbar');
  Expect.equals('lbar', result.reflectee);
  Expect.equals('lbar', libraryField);
  Expect.equals('lbar', lm.getField(const Symbol('libraryField')).reflectee);
  Expect.throws(() => lm.setField(const Symbol('doesntExist'), 'lbar'),
      isNoSuchMethodError, 'Not defined');
}

main() {
  testSync();
}
