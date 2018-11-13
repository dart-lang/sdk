// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';

main() async {
  Link link1 = new Link(
      Directory.systemTemp.path + Platform.pathSeparator + 'link1.lnk');
  Link link2 = new Link(
      Directory.systemTemp.path + Platform.pathSeparator + 'link2.lnk');

  Directory target1 = new Directory(
      Directory.systemTemp.path + Platform.pathSeparator + 'target1');
  Directory target2 = new Directory(
      Directory.systemTemp.path + Platform.pathSeparator + 'target2');

  target1.createSync();
  target2.createSync();

  Expect.isTrue(target1.existsSync());
  Expect.isTrue(target2.existsSync());

  link1.createSync(target1.path);
  link2.createSync(target2.path);
  Expect.isTrue(link1.existsSync());
  Expect.isTrue(link2.existsSync());

  try {
    Link renamed = await link1.rename(link2.path);
    Expect.isFalse(link1.existsSync());
    Expect.isTrue(renamed.existsSync());
    Expect.equals(renamed.path, link2.path);
  } finally {
    target1.delete();
    target2.delete();
    link2.delete();
    if (link1.existsSync()) {
      link1.delete();
    }
  }
}
