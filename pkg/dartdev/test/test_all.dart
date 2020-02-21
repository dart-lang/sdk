// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'commands/analyze_test.dart' as analyze;
import 'commands/create_test.dart' as create;
import 'commands/flag_test.dart' as flag;
import 'commands/format_test.dart' as format;
import 'commands/pub_test.dart' as pub;
import 'utils_test.dart' as utils;

main() {
  group('dartdev', () {
    analyze.main();
    create.main();
    flag.main();
    format.main();
    pub.main();
    utils.main();
  });
}
