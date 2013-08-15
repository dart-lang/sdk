// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.null_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

main() {
  InstanceMirror nullMirror = reflect(null);
  Expect.isTrue(nullMirror.getField(const Symbol('hashCode')).reflectee is int);
  Expect.equals(null.hashCode,
                nullMirror.getField(const Symbol('hashCode')).reflectee);
  Expect.equals('Null',
                nullMirror.getField(const Symbol('runtimeType')).reflectee
                .toString());
  Expect.isTrue(nullMirror.invoke(const Symbol('=='), [null]).reflectee);
  Expect.isFalse(nullMirror.invoke(const Symbol('=='), [new Object()])
                 .reflectee);
  Expect.equals('null',
                nullMirror.invoke(const Symbol('toString'), []).reflectee);
  Expect.throws(() => nullMirror.invoke(const Symbol('notDefined'), []),
                (e) => e is NoSuchMethodError,
                'noSuchMethod');

  ClassMirror NullMirror = nullMirror.type;
  Expect.equals(reflectClass(Null), NullMirror);
  Expect.equals(const Symbol('Null'), NullMirror.simpleName);
  Expect.equals(const Symbol('Object'), NullMirror.superclass.simpleName);
  Expect.equals(null, NullMirror.superclass.superclass);
  Expect.listEquals([], NullMirror.superinterfaces);
  Expect.equals(currentMirrorSystem().libraries[Uri.parse('dart:core')],
                NullMirror.owner);
}
