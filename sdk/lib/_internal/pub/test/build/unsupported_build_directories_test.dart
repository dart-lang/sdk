// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("fails if given directories are not buildable", () {
    d.appDir().create();

    schedulePub(args: ["build", "foo", "bar"],
        error: '''
            Unsupported build directories "bar" and "foo".
            The allowed directories are "benchmark", "bin", "example", "test" and "web".

            Usage: pub build [options] [directories...]
            -h, --help      Print usage information for this command.
                --format    How output should be displayed.
                            [text (default), json]

                --mode      Mode to run transformers in.
                            (defaults to "release")

                --all       Build all buildable directories.''',
        exitCode: exit_codes.USAGE);
  });

  integration("fails if given directories are not buildable with json "
      "output", () {
    d.appDir().create();

    schedulePub(args: ["build", "foo", "bar", "--format", "json"],
        outputJson: {
          "error":
            'Unsupported build directories "bar" and "foo".\n'
            'The allowed directories are "benchmark", "bin", "example", '
                '"test" and "web".'
        },
        exitCode: exit_codes.USAGE);
  });
}
