// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';
import '../../async_helper.dart';

class C {
  var _field;
  C() : this._field = 'default';
  C._named(this._field);

  get _getter => 'get $_field';
  set _setter(v) => _field = 'set $v';
  _method(x, y, z) => '$x+$y+$z';

  static var _staticField = 'initial';
  static get _staticGetter => 'sget $_staticField';
  static set _staticSetter(v) => _staticField = 'sset $v';
  static _staticFunction(x, y) => "($x,$y)";
}

var _libraryField = 'a priori';
get _libraryGetter => 'lget $_libraryField';
set _librarySetter(v) => _libraryField = 'lset $v';
_libraryFunction(x,y) => '$x$y';

main() {
  var result;

  // InstanceMirror.
  C c = new C();
  InstanceMirror im = reflect(c);
  result = im.invoke(const Symbol('_method'), [2,4,8]);
  Expect.equals('2+4+8', result.reflectee);

  result = im.getField(const Symbol('_getter'));
  Expect.equals('get default', result.reflectee);
  result = im.getField(const Symbol('_field'));
  Expect.equals('default', result.reflectee);

  im.setField(const Symbol('_setter'), 'foo');
  Expect.equals('set foo', c._field);
  im.setField(const Symbol('_field'), 'bar');
  Expect.equals('bar', c._field);


  // ClassMirror.
  ClassMirror cm = reflectClass(C);
  result = cm.invoke(const Symbol('_staticFunction'),[3,4]);
  Expect.equals('(3,4)', result.reflectee);

  result = cm.getField(const Symbol('_staticGetter'));
  Expect.equals('sget initial', result.reflectee);
  result = cm.getField(const Symbol('_staticField'));
  Expect.equals('initial', result.reflectee);

  cm.setField(const Symbol('_staticSetter'), 'sfoo');
  Expect.equals('sset sfoo', C._staticField);
  cm.setField(const Symbol('_staticField'), 'sbar');
  Expect.equals('sbar', C._staticField);

  result = cm.newInstance(const Symbol('_named'), ['my value']);
  Expect.isTrue(result.reflectee is C);
  Expect.equals('my value', result.reflectee._field);


  // LibraryMirror.
  LibraryMirror lm = cm.owner;
  result = lm.invoke(const Symbol('_libraryFunction'),[':',')']);
  Expect.equals(':)', result.reflectee);

  result = lm.getField(const Symbol('_libraryGetter'));
  Expect.equals('lget a priori', result.reflectee);
  result = lm.getField(const Symbol('_libraryField'));
  Expect.equals('a priori', result.reflectee);

  lm.setField(const Symbol('_librarySetter'), 'lfoo');
  Expect.equals('lset lfoo', _libraryField);
  lm.setField(const Symbol('_libraryField'), 'lbar');
  Expect.equals('lbar', _libraryField);
}
