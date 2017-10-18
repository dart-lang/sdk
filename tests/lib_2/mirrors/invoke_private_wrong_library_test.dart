// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'invoke_private_test.dart' show C;

main() {
  var result;

  C c = new C();
  InstanceMirror im = reflect(c);
  Expect.throwsNoSuchMethodError(() => im.invoke(#_method, [2, 4, 8]));
  Expect.throwsNoSuchMethodError(() => im.getField(#_getter));
  Expect.throwsNoSuchMethodError(() => im.getField(#_field));
  Expect.throwsNoSuchMethodError(() => im.setField(#_setter, 'foo'));
  Expect.throwsNoSuchMethodError(() => im.setField(#_field, 'bar'));

  ClassMirror cm = reflectClass(C);
  Expect.throwsNoSuchMethodError(() => cm.invoke(#_staticFunction, [3, 4]));
  Expect.throwsNoSuchMethodError(() => cm.getField(#_staticGetter));
  Expect.throwsNoSuchMethodError(() => cm.getField(#_staticField));
  Expect.throwsNoSuchMethodError(() => cm.setField(#_staticSetter, 'sfoo'));
  Expect.throwsNoSuchMethodError(() => cm.setField(#_staticField, 'sbar'));
  Expect.throwsNoSuchMethodError(() => cm.newInstance(#_named, ['my value']));

  LibraryMirror lm = cm.owner;
  Expect.throwsNoSuchMethodError(
      () => lm.invoke(#_libraryFunction, [':', ')']));
  Expect.throwsNoSuchMethodError(() => lm.getField(#_libraryGetter));
  Expect.throwsNoSuchMethodError(() => lm.getField(#_libraryField));
  Expect.throwsNoSuchMethodError(() => lm.setField(#_librarySetter, 'lfoo'));
  Expect.throwsNoSuchMethodError(() => lm.setField(#_libraryField, 'lbar'));
}
