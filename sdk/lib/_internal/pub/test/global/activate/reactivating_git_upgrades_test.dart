// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('ignores previously activated git commit',
        () {
    ensureGit();

    d.git('foo.git', [
      d.libPubspec("foo", "1.0.0")
    ]).create();

    schedulePub(args: ["global", "activate", "-sgit", "../foo.git"],
        output: '''
Resolving dependencies...
Activated foo 1.0.0 from Git repository "../foo.git".''');

    d.git('foo.git', [
      d.libPubspec("foo", "1.0.1")
    ]).commit();

    // Activating it again pulls down the latest commit.
    schedulePub(args: ["global", "activate", "-sgit", "../foo.git"],
        output: '''
Package foo is currently active from Git repository "../foo.git".
Resolving dependencies...
Activated foo 1.0.1 from Git repository "../foo.git".''');
  });
}
