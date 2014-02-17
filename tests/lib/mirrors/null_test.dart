// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.null_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

main() {
  InstanceMirror nullMirror = reflect(null);
  Expect.isTrue(nullMirror.getField(#hashCode).reflectee is int);
  Expect.equals(null.hashCode,
                nullMirror.getField(#hashCode).reflectee);
  Expect.equals('Null',
                nullMirror.getField(#runtimeType).reflectee
                .toString());
  Expect.isTrue(nullMirror.invoke(#==, [null]).reflectee);
  Expect.isFalse(nullMirror.invoke(#==, [new Object()])
                 .reflectee);
  Expect.equals('null',
                nullMirror.invoke(#toString, []).reflectee);
  Expect.throws(() => nullMirror.invoke(#notDefined, []),
                (e) => e is NoSuchMethodError,
                'noSuchMethod');

  ClassMirror NullMirror = nullMirror.type;
  Expect.equals(reflectClass(Null), NullMirror);
  Expect.equals(#Null, NullMirror.simpleName);
  Expect.equals(#Object, NullMirror.superclass.simpleName);  /// 00: ok
  Expect.equals(null, NullMirror.superclass.superclass);  /// 00: continued
  Expect.listEquals([], NullMirror.superinterfaces);
  Expect.equals(currentMirrorSystem().libraries[Uri.parse('dart:core')],
                NullMirror.owner);
}
