// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../test_pub.dart';

main() {
  initConfig();
  integration('fails if the Git repo does not exist', () {
    ensureGit();

    schedulePub(args: ["global", "activate", "-sgit", "../nope.git"],
        error: contains("repository '../nope.git' does not exist"),
        exitCode: 1);
  });
}
