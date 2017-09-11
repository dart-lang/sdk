// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.set_field_with_final;

@MirrorsUsed(targets: "test.set_field_with_final")
import 'dart:mirrors';
import 'package:expect/expect.dart';

class C {
  final instanceField = 1;
  get instanceGetter => 2;
  static final staticFinal = 3;
  static get staticGetter => 4;
}

final toplevelFinal = 5;
get toplevelGetter => 6;

main() {
  InstanceMirror im = reflect(new C());
  Expect.throws(
      () => im.setField(#instanceField, 7), (e) => e is NoSuchMethodError);
  Expect.throws(
      () => im.setField(#instanceGetter, 8), (e) => e is NoSuchMethodError);

  ClassMirror cm = im.type;
  Expect.throws(
      () => cm.setField(#staticFinal, 9), (e) => e is NoSuchMethodError);
  Expect.throws(
      () => cm.setField(#staticGetter, 10), (e) => e is NoSuchMethodError);

  LibraryMirror lm = cm.owner;
  Expect.throws(
      () => lm.setField(#toplevelFinal, 11), (e) => e is NoSuchMethodError);
  Expect.throws(
      () => lm.setField(#toplevelGetter, 12), (e) => e is NoSuchMethodError);
}
