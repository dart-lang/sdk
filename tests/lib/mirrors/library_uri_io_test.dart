// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test library uri for a library read as a file.

library MirrorsTest;

import 'dart:io';
import 'dart:mirrors';

import 'package:async_helper/async_minitest.dart';

class Class {}

testLibraryUri(var value, Uri expectedUri) {
  var valueMirror = reflect(value);
  ClassMirror valueClass = valueMirror.type;
  LibraryMirror valueLibrary = valueClass.owner as LibraryMirror;
  expect(valueLibrary.uri, equals(expectedUri));
}

main() {
  var mirrors = currentMirrorSystem();
  test("Test current library uri", () {
    if (!Platform.script.toString().endsWith('.dart')) {
      print("Skipping library uri test as not running from source "
          "(Platform.script = ${Platform.script})");
      return;
    }
    Uri uri = Uri.base.resolveUri(Platform.script);
    testLibraryUri(new Class(), uri);
  });
}
