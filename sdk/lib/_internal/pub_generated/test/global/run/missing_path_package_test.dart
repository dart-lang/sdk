// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('errors if the local package does not exist', () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();

    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);

    schedule(() => deleteEntry(p.join(sandboxDir, "foo")));

    var pub = pubRun(global: true, args: ["foo"]);
    var path = canonicalize(p.join(sandboxDir, "foo"));
    pub.stderr.expect('Could not find a file named "pubspec.yaml" in "$path".');
    pub.shouldExit(1);
  });
}
