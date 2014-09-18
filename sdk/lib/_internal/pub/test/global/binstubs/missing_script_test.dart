// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_stream.dart';

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("errors if an executable's script can't be found", () {
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "executables": {
          "missing": "not_here",
          "nope": null
        }
      })
    ]).create();

    var pub = startPub(args: ["global", "activate", "-spath", "../foo"]);

    pub.stderr.expect('Warning: Executable "missing" runs '
        '"bin/not_here.dart", which was not found in foo.');
    pub.stderr.expect('Warning: Executable "nope" runs "bin/nope.dart", which '
        'was not found in foo.');
    pub.shouldExit();
  });
}
