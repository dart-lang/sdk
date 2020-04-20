// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=5

import "dart:mirrors";
import "package:expect/expect.dart";

void main() {
  for (int i = 0; i < 10; i++) {
    test();
  }
}

void test() {
  ClassMirror cm = reflectClass(Null);

  InstanceMirror im1 = reflect(null);
  Expect.equals(cm, im1.type);
  Expect.isTrue(im1.invoke(const Symbol("=="), [null]).reflectee);
  Expect.isFalse(im1.invoke(const Symbol("=="), [42]).reflectee);

  var obj = confuse(null); // Null value that isn't known at compile-time.
  InstanceMirror im2 = reflect(obj);
  Expect.equals(cm, im2.type);
  Expect.isTrue(im2.invoke(const Symbol("=="), [null]).reflectee);
  Expect.isFalse(im2.invoke(const Symbol("=="), [42]).reflectee);

  InstanceMirror nullMirror = reflect(null);
  Expect.isTrue(nullMirror.getField(#hashCode).reflectee is int);
  Expect.equals(null.hashCode, nullMirror.getField(#hashCode).reflectee);
  Expect.equals('Null', nullMirror.getField(#runtimeType).reflectee.toString());
  Expect.isTrue(nullMirror.invoke(#==, [null]).reflectee);
  Expect.isFalse(nullMirror.invoke(#==, [new Object()]).reflectee);
  Expect.equals('null', nullMirror.invoke(#toString, []).reflectee);
  Expect.throwsNoSuchMethodError(
      () => nullMirror.invoke(#notDefined, []), 'noSuchMethod');

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

// Magic incantation to avoid the compiler recognizing the constant values
// at compile time. If the result is computed at compile time, the dynamic code
// will not be tested.
confuse(x) {
  try {
    if (new DateTime.now().millisecondsSinceEpoch == 42) x = 42;
    throw [x];
  } catch (e) {
    return e[0];
  }
  return 42;
}
