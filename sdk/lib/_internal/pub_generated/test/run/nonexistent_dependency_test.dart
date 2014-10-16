// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('Errors if the script is in an unknown package.', () {
    d.dir(appPath, [d.appPubspec()]).create();

    var pub = pubRun(args: ["foo:script"]);
    pub.stderr.expect(
        'Could not find package "foo". Did you forget to add a ' 'dependency?');
    pub.shouldExit(exit_codes.DATA);
  });
}
