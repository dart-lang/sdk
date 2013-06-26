// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test library uri for a library read as a file.

library MirrorsTest;

import 'dart:mirrors';
import 'dart:io';
import '../../../pkg/unittest/lib/unittest.dart';

class Class {
}

testLibraryUri(var value, Uri expectedUri) {
  var valueMirror = reflect(value);
  ClassMirror valueClass = valueMirror.type;
  LibraryMirror valueLibrary = valueClass.owner;
  expect(valueLibrary.uri, equals(expectedUri));
}

main() {
  var mirrors = currentMirrorSystem();
  test("Test current library uri", () {
    String appendSlash(String path) => path.endsWith('/') ? path : '$path/';
    Uri cwd = new Uri(
        scheme: 'file',
        path: appendSlash(new Path(new File('.').fullPathSync()).toString()));
    Uri uri = cwd.resolve(new Path(Platform.script).toString());
    testLibraryUri(new Class(), uri);
  });
}
