// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library MirrorsTest;

import 'dart:mirrors';
import 'package:expect/expect.dart';

bool isNSMContainingFieldName(e, String fieldName, bool isSetter) {
  print(e);
  if (e is! NoSuchMethodError) return false;
  String needle = fieldName;
  if (isSetter) needle += "=";
  return "$e".contains(needle) && ! "$e".contains(needle + "=");
}

class A {}

main() {
  var mirrors = currentMirrorSystem();
  var libMirror = mirrors.findLibrary(#MirrorsTest);
  Expect.throws(() => libMirror.invoke(#foo, []),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => libMirror.getField(#foo),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => libMirror.setField(#foo, null),             /// vm: ok
                (e) => isNSMContainingFieldName(e, "foo", true)); /// vm: continued

  var classMirror = reflect(A);
  Expect.throws(() => classMirror.invoke(#foo, []),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => classMirror.getField(#foo),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => classMirror.setField(#foo, null),
                (e) => isNSMContainingFieldName(e, "foo", true));

  var instanceMirror = reflect(new A());
  Expect.throws(() => instanceMirror.invoke(#foo, []),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => instanceMirror.getField(#foo),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => instanceMirror.setField(#foo, null),
                (e) => isNSMContainingFieldName(e, "foo", true));

}
