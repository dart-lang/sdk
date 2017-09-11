// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'invoke_private_test.dart' show C;

expectThrowsNSM(f) {
  Expect.throws(f, (e) => e is NoSuchMethodError);
}

main() {
  var result;

  C c = new C();
  InstanceMirror im = reflect(c);
  expectThrowsNSM(() => im.invoke(#_method, [2, 4, 8]));
  expectThrowsNSM(() => im.getField(#_getter));
  expectThrowsNSM(() => im.getField(#_field));
  expectThrowsNSM(() => im.setField(#_setter, 'foo'));
  expectThrowsNSM(() => im.setField(#_field, 'bar'));

  ClassMirror cm = reflectClass(C);
  expectThrowsNSM(() => cm.invoke(#_staticFunction, [3, 4]));
  expectThrowsNSM(() => cm.getField(#_staticGetter));
  expectThrowsNSM(() => cm.getField(#_staticField));
  expectThrowsNSM(() => cm.setField(#_staticSetter, 'sfoo'));
  expectThrowsNSM(() => cm.setField(#_staticField, 'sbar'));
  expectThrowsNSM(() => cm.newInstance(#_named, ['my value']));

  LibraryMirror lm = cm.owner;
  expectThrowsNSM(() => lm.invoke(#_libraryFunction, [':', ')']));
  expectThrowsNSM(() => lm.getField(#_libraryGetter));
  expectThrowsNSM(() => lm.getField(#_libraryField));
  expectThrowsNSM(() => lm.setField(#_librarySetter, 'lfoo'));
  expectThrowsNSM(() => lm.setField(#_libraryField, 'lbar'));
}
