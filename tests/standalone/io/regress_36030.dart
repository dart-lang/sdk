// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

void main() async {
  // Test that renaming a file doesn't change the modified time.
  final temp = await Directory.systemTemp.createTemp('regress_36030');
  final file = await File('${temp.path}/before').create();
  final modifiedTime = await file.lastModified();
  await Future.delayed(Duration(seconds: 1));
  final renamed = await file.rename('${temp.path}/after');
  final renamedTime = await renamed.lastModified();
  Expect.equals(renamedTime, modifiedTime);
}
