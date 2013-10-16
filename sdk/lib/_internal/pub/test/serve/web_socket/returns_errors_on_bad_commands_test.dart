// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();
  integration("handles bad commands", () {
    d.dir(appPath, [
      d.appPubspec()
    ]).create();

    startPubServe();

    webSocketShouldReply(
        "not even valid json",
        equals({"error": '"not even valid json" is not valid JSON: '
            'Unexpected character at 0: \'not even valid json\''}),
        encodeRequest: false);

    webSocketShouldReply(
        {"command": "wat"},
        equals({"error": 'Unknown command "wat".'}));

    webSocketShouldReply(
        ["not", "a", "map"],
        equals({"error": 'Command must be a JSON map. '
            'Got: ["not","a","map"].'}));

    webSocketShouldReply(
        {"wat": "there's no command"},
        equals({"error": 'Missing command name. '
            'Got: {"wat":"there\'s no command"}.'}));

    webSocketShouldReply(
        {"command": "urlToAsset", "path": 123},
        equals({"error": '"path" must be a string. Got: 123.'}));

    webSocketShouldReply(
        {"command": "assetToUrl", "package": 123, "path": "index.html"},
        equals({"error": '"package" must be a string. Got: 123.'}));

    webSocketShouldReply(
        {"command": "assetToUrl", "package": "foo", "path": 123},
        equals({"error": '"path" must be a string. Got: 123.'}));

    endPubServe();
  });
}
