// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  integration("doesn't support an invalid dart2js option", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": [{
          "\$dart2js": {"invalidOption": true}
        }]
      })
    ]).create();

    // TODO(nweiz): This should provide more context about how the option got
    // passed to dart2js. See issue 16008.
    var pub = startPubServe();
    pub.stderr.expect('Unrecognized dart2js option "invalidOption".');
    pub.shouldExit(exit_codes.DATA);
  });
}
