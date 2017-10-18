// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.null_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

main() {
  InstanceMirror nullMirror = reflect(null);
  Expect.isTrue(nullMirror.getField(#hashCode).reflectee is int);
  Expect.equals(null.hashCode, nullMirror.getField(#hashCode).reflectee);
  Expect.equals('Null', nullMirror.getField(#runtimeType).reflectee.toString());
  Expect.isTrue(nullMirror.invoke(#==, [null]).reflectee);
  Expect.isFalse(nullMirror.invoke(#==, [new Object()]).reflectee);
  Expect.equals('null', nullMirror.invoke(#toString, []).reflectee);
  Expect.throwsNoSuchMethodError(() => nullMirror.invoke(#notDefined, []),
      'noSuchMethod');

  ClassMirror NullMirror = nullMirror.type;
  Expect.equals(reflectClass(Null), NullMirror);
  Expect.equals(#Null, NullMirror.simpleName);
  Expect.equals(#Object, NullMirror.superclass.simpleName);
  Expect.equals(null, NullMirror.superclass.superclass);
  Expect.listEquals([], NullMirror.superinterfaces);
  Map<Uri, LibraryMirror> libraries = currentMirrorSystem().libraries;
  LibraryMirror coreLibrary = libraries[Uri.parse('dart:core')];
  if (coreLibrary == null) {
    // In minified mode we don't preserve the URIs.
    coreLibrary = libraries.values
        .firstWhere((LibraryMirror lm) => lm.simpleName == #dart.core);
    Uri uri = coreLibrary.uri;
    Expect.equals("https", uri.scheme);
    Expect.equals("dartlang.org", uri.host);
    Expect.equals("/dart2js-stripped-uri", uri.path);
  }
  Expect.equals(coreLibrary, NullMirror.owner);
}
