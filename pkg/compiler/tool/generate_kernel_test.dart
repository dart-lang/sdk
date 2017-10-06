// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.tool.generate_kernel_test;

import 'dart:io';
import 'generate_kernel.dart' as m;

main() async {
  Directory dir;
  try {
    dir = Directory.systemTemp.createTempSync('generate_kernel_test');
    var file = dir.absolute.uri.resolve('hi.dart');
    new File.fromUri(file).writeAsStringSync("main() => print('hello world');");
    var platformUri = Uri.base
        .resolve(Platform.resolvedExecutable)
        .resolve('dart2js_platform.dill');
    await m.main(['--platform=${platformUri.toFilePath()}', file.toFilePath()]);
  } finally {
    dir.deleteSync(recursive: true);
  }
}
