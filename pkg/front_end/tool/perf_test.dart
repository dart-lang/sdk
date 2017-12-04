// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.tool.perf_test;

import 'dart:io' show Platform;
import 'perf.dart' as m;

main() async {
  var benchIds = ['scan', 'parse', 'linked_summarize'];
  var inputFile =
      Platform.script.resolve('../lib/src/api_prototype/file_system.dart').path;
  for (var id in benchIds) {
    await m.main([id, inputFile]);
  }
}
