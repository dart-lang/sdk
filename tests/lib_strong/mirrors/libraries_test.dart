// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.libraries_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

main() {
  MirrorSystem mirrors = currentMirrorSystem();
  Expect.isNotNull(mirrors, 'mirrors is null');

  Map<Uri, LibraryMirror> libraries = mirrors.libraries;
  Expect.isNotNull(libraries, 'libraries is null');

  Expect.isTrue(libraries.isNotEmpty);
  LibraryMirror mirrorsLibrary = libraries[Uri.parse('dart:mirrors')];
  if (mirrorsLibrary == null) {
    // In minified mode we don't preserve the URIs.
    mirrorsLibrary = libraries.values
        .firstWhere((LibraryMirror lm) => lm.simpleName == #dart.mirrors);
    Uri uri = mirrorsLibrary.uri;
    Expect.equals("https", uri.scheme);
    Expect.equals("dartlang.org", uri.host);
    Expect.equals("/dart2js-stripped-uri", uri.path);
  }

  ClassMirror cls = mirrorsLibrary.declarations[#LibraryMirror];
  Expect.isNotNull(cls, 'cls is null');

  Expect.equals(#dart.mirrors.LibraryMirror, cls.qualifiedName);
  Expect.equals(reflectClass(LibraryMirror), cls);
}
