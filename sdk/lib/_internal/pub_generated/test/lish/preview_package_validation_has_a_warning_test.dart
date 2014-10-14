// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/scheduled_stream.dart';

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  setUp(d.validPackage.create);

  integration('preview package validation has a warning', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["author"] = "Natalie Weizenbaum";
    d.dir(appPath, [d.pubspec(pkg)]).create();

    var server = new ScheduledServer();
    var pub = startPublish(server, args: ['--dry-run']);

    pub.shouldExit(exit_codes.SUCCESS);
    pub.stderr.expect(consumeThrough('Suggestions:'));
    pub.stderr.expect(
        emitsLines(
            '* Author "Natalie Weizenbaum" in pubspec.yaml should have an email '
                'address\n' '  (e.g. "name <email>").\n' '\n' 'Package has 1 warning.'));
  });
}
