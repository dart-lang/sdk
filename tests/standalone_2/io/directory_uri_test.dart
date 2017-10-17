// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testFromUri() {
  asyncStart();
  Directory originalWorkingDirectory = Directory.current;
  Directory.systemTemp.createTemp('directory_uri').then((temp) {
    String dirname = temp.path + '/from_uri';
    Uri dirUri = new Uri.file(dirname);
    Directory dir = new Directory.fromUri(dirUri);
    Expect.isTrue(dirUri.isAbsolute);
    Expect.isTrue(dirUri.path.startsWith('/'));
    dir.createSync();
    Expect.isTrue(new Directory.fromUri(dirUri).existsSync());
    Expect.isTrue(
        new Directory.fromUri(Uri.base.resolveUri(dirUri)).existsSync());
    Directory.current = temp.path;
    Expect.isTrue(new Directory.fromUri(Uri.parse('from_uri')).existsSync());
    Expect.isTrue(
        new Directory.fromUri(Uri.base.resolve('from_uri')).existsSync());
    Directory.current = originalWorkingDirectory;
    dir.deleteSync();
    temp.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testFromUriUnsupported() {
  Expect.throwsUnsupportedError(() =>
      new Directory.fromUri(Uri.parse('http://localhost:8080/index.html')));
  Expect.throwsUnsupportedError(
      () => new Directory.fromUri(Uri.parse('ftp://localhost/tmp/xxx')));
  Expect.throwsUnsupportedError(
      () => new Directory.fromUri(Uri.parse('name#fragment')));
}

void main() {
  testFromUri();
  testFromUriUnsupported();
}
