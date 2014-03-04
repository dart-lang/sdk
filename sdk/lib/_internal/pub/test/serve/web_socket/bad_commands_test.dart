// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  // TODO(rnystrom): Split into independent tests.
  initConfig();
  integration("handles bad commands", () {
    d.dir(appPath, [
      d.appPubspec()
    ]).create();

    pubServe();

    expectWebSocketCall("not even valid json", replyMatches: allOf([
      containsPair("code", "BAD_COMMAND"),
      containsPair("error",
          startsWith('"not even valid json" is not valid JSON:'))
    ]), encodeRequest: false);

    expectWebSocketCall({"command": "wat"}, replyEquals: {
      "code": "BAD_COMMAND",
      "error": 'Unknown command "wat".'
    });

    expectWebSocketCall(["not", "a", "map"], replyEquals: {
      "code": "BAD_COMMAND",
      "error": 'Command must be a JSON map. Got ["not","a","map"].'
    });

    expectWebSocketCall({"wat": "there's no command"}, replyEquals: {
      "code": "BAD_COMMAND",
      "error": 'Missing command name. Got {"wat":"there\'s no command"}.'
    });

    endPubServe();
  });
}
