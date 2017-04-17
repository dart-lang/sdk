// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testFromUri() {
  asyncStart();
  Directory originalWorkingDirectory = Directory.current;
  Directory.systemTemp.createTemp('file_uri').then((temp) {
    String filename = temp.path + '/from_uri';
    Uri fileUri = new Uri.file(filename);
    File file = new File.fromUri(fileUri);
    Expect.isTrue(fileUri.isAbsolute);
    Expect.isTrue(fileUri.path.startsWith('/'));
    file.createSync();
    Expect.isTrue(new File.fromUri(fileUri).existsSync());
    Expect.isTrue(new File.fromUri(Uri.base.resolveUri(fileUri)).existsSync());
    Directory.current = temp.path;
    Expect.isTrue(new File.fromUri(Uri.parse('from_uri')).existsSync());
    Expect.isTrue(new File.fromUri(Uri.base.resolve('from_uri')).existsSync());
    Directory.current = originalWorkingDirectory;
    file.deleteSync();
    temp.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testFromUriUnsupported() {
  Expect.throws(
      () => new File.fromUri(Uri.parse('http://localhost:8080/index.html')),
      (e) => e is UnsupportedError);
  Expect.throws(() => new File.fromUri(Uri.parse('ftp://localhost/tmp/xxx')),
      (e) => e is UnsupportedError);
  Expect.throws(() => new File.fromUri(Uri.parse('name#fragment')),
      (e) => e is UnsupportedError);
}

void main() {
  testFromUri();
  testFromUriUnsupported();
}
