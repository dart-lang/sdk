// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../test_pub.dart';

main() {
  initConfig();
  integration('deactivates an active hosted package', () {
    servePackages((builder) => builder.serve("foo", "1.0.0"));

    schedulePub(args: ["global", "activate", "foo"]);

    schedulePub(args: ["global", "deactivate", "foo"],
        output: "Deactivated package foo 1.0.0.");
  });
}
