// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'unix_socket_test.dart' show withTempDir, testListenCloseListenClose;

void main() async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }
  final futures = <Future>[];
  for (int i = 0; i < 10; ++i) {
    futures.add(withTempDir('unix_socket_test', (Directory dir) async {
      await testListenCloseListenClose('${dir.path}');
    }));
  }
  await Future.wait(futures);
}
