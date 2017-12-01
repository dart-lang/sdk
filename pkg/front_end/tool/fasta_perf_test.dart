// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The only purpose of this file is to enable analyzer tests on `perf.dart`,
/// the code here just has a dummy import to the rest of the code.
library front_end.tool.perf_test;

import 'dart:io' show Platform;
import 'fasta_perf.dart' as m;

main() async {
  var benchIds = [
    'scan',
    'kernel_gen_e2e',
  ];
  var inputFile =
      Platform.script.resolve('../lib/src/api_prototype/file_system.dart').path;
  for (var id in benchIds) {
    print('=== legacy for $id $inputFile');
    await m.main(['--legacy', id, inputFile]);
    print('=== strong for $id $inputFile');
    await m.main([id, inputFile]);
  }
}
