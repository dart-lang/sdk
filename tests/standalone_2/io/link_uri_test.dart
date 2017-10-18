// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testFromUri() {
  asyncStart();
  Directory originalWorkingDirectory = Directory.current;
  Directory.systemTemp.createTemp('dart_file').then((temp) {
    File target = new File(temp.path + '/target');
    target.createSync();

    String linkname = temp.path + '/from_uri';
    Uri linkUri = new Uri.file(linkname);
    Link link = new Link.fromUri(linkUri);
    Expect.isTrue(linkUri.isAbsolute);
    Expect.isTrue(linkUri.path.startsWith('/'));
    link.createSync(target.path);
    Expect.isTrue(new Link.fromUri(linkUri).existsSync());
    Expect.isTrue(new Link.fromUri(Uri.base.resolveUri(linkUri)).existsSync());
    Directory.current = temp.path;
    Expect.isTrue(new Link.fromUri(Uri.parse('from_uri')).existsSync());
    Expect.isTrue(new Link.fromUri(Uri.base.resolve('from_uri')).existsSync());
    Directory.current = originalWorkingDirectory;
    link.deleteSync();
    target.deleteSync();
    temp.deleteSync();
    asyncEnd();
  });
}

void testFromUriUnsupported() {
  Expect.throwsUnsupportedError(
      () => new Link.fromUri(Uri.parse('http://localhost:8080/index.html')));
  Expect.throwsUnsupportedError(
      () => new Link.fromUri(Uri.parse('ftp://localhost/tmp/xxx')));
  Expect.throwsUnsupportedError(
      () => new Link.fromUri(Uri.parse('name#fragment')));
}

void main() {
  testFromUri();
  testFromUriUnsupported();
}
