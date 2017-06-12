// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_private_test;

@MirrorsUsed(targets: "invoke_private_test")
import 'dart:mirrors';

import 'package:expect/expect.dart';

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
_libraryFunction(x, y) => '$x$y';

main() {
  var result;

  // InstanceMirror.
  C c = new C();
  InstanceMirror im = reflect(c);
  result = im.invoke(#_method, [2, 4, 8]);
  Expect.equals('2+4+8', result.reflectee);

  result = im.getField(#_getter);
  Expect.equals('get default', result.reflectee);
  result = im.getField(#_field);
  Expect.equals('default', result.reflectee);

  im.setField(#_setter, 'foo');
  Expect.equals('set foo', c._field);
  im.setField(#_field, 'bar');
  Expect.equals('bar', c._field);

  // ClassMirror.
  ClassMirror cm = reflectClass(C);
  result = cm.invoke(#_staticFunction, [3, 4]);
  Expect.equals('(3,4)', result.reflectee);

  result = cm.getField(#_staticGetter);
  Expect.equals('sget initial', result.reflectee);
  result = cm.getField(#_staticField);
  Expect.equals('initial', result.reflectee);

  cm.setField(#_staticSetter, 'sfoo');
  Expect.equals('sset sfoo', C._staticField);
  cm.setField(#_staticField, 'sbar');
  Expect.equals('sbar', C._staticField);

  result = cm.newInstance(#_named, ['my value']);
  Expect.isTrue(result.reflectee is C);
  Expect.equals('my value', result.reflectee._field);

  // LibraryMirror.
  LibraryMirror lm = cm.owner;
  result = lm.invoke(#_libraryFunction, [':', ')']);
  Expect.equals(':)', result.reflectee);

  result = lm.getField(#_libraryGetter);
  Expect.equals('lget a priori', result.reflectee);
  result = lm.getField(#_libraryField);
  Expect.equals('a priori', result.reflectee);

  lm.setField(#_librarySetter, 'lfoo');
  Expect.equals('lset lfoo', _libraryField);
  lm.setField(#_libraryField, 'lbar');
  Expect.equals('lbar', _libraryField);
}
