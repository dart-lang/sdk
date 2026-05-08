// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test library uri for a library read as a file.

import 'dart:io';
import 'dart:mirrors';

import 'package:expect/expect.dart';

class Class {}

void testLibraryUri(value, Uri expectedUri) {
  var valueMirror = reflect(value);
  ClassMirror valueClass = valueMirror.type;
  LibraryMirror valueLibrary = valueClass.owner as LibraryMirror;
  Expect.equals(expectedUri, valueLibrary.uri);
}

void main() {
  if (!Platform.script.toString().endsWith('.dart')) {
    print(
      "Skipping library uri test as not running from source "
      "(Platform.script = ${Platform.script})",
    );
    return;
  }
  Uri uri = Uri.base.resolveUri(Platform.script);
  testLibraryUri(new Class(), uri);
}
