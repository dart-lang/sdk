// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test library uri for a library read as a package.

import 'dart:mirrors';

import 'package:expect/expect.dart';

void testLibraryUri(Object value, Uri expectedUri) {
  var valueMirror = reflect(value);
  ClassMirror valueClass = valueMirror.type;
  LibraryMirror valueLibrary = valueClass.owner as LibraryMirror;
  Uri uri = valueLibrary.uri;
  if (!uri.isScheme("https") || uri.host != "dartlang.org") {
    Expect.equals(expectedUri, uri);
  }
}

void main() {
  testLibraryUri(ExpectException(""), Uri.parse('package:expect/expect.dart'));
}
