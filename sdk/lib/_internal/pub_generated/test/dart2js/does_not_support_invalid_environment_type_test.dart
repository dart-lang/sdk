// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  integration("doesn't support invalid environment type", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": [{
            "\$dart2js": {
              "environment": "foo",
            }
          }]
      }), d.dir("web", [d.file("main.dart", "void main() {}")])]).create();

    var server = pubServe();
    // Make a request first to trigger compilation.
    requestShould404("main.dart.js");
    server.stderr.expect(
        emitsLines(
            'Build error:\n' 'Transform Dart2JS on myapp|web/main.dart threw error: '
                'Invalid value for \$dart2js.environment: "foo" '
                '(expected map from strings to strings).'));
    endPubServe();
  });
}
