// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'test_utils.dart' show withTempDir;

main() async {
  await withTempDir('issue_30687', (Directory tempDir) async {
    final link1 = Link(tempDir.path + Platform.pathSeparator + 'link1.lnk');
    final link2 = Link(tempDir.path + Platform.pathSeparator + 'link2.lnk');

    final target1 = Directory(path.join(tempDir.path, 'target1'));
    final target2 = Directory(path.join(tempDir.path, 'target2'));

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
      target1.deleteSync();
      target2.deleteSync();
      link2.deleteSync();
      if (link1.existsSync()) {
        link1.deleteSync();
      }
    }
  });
}
