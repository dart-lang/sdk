// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.local_file_index;

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_file_index.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  test('createLocalFileIndex', () {
    Index index = createLocalFileIndex();
    expect(index, isNotNull);
    index.clear();
  });
}
