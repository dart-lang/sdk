// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_stream.dart';

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("reports Dart parse errors", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                'web',
                [
                    d.file('file.txt', 'contents'),
                    d.file('file.dart', 'void void;'),
                    d.dir('subdir', [d.file('subfile.dart', 'void void;')])])]).create();

    var pub = startPub(args: ["build"]);
    pub.stdout.expect(startsWith("Loading source assets..."));
    pub.stdout.expect(startsWith("Building myapp..."));

    var consumeFile = consumeThrough(
        inOrder(
            ["[Error from Dart2JS]:", startsWith(p.join("web", "file.dart") + ":")]));
    var consumeSubfile = consumeThrough(
        inOrder(
            [
                "[Error from Dart2JS]:",
                startsWith(p.join("web", "subdir", "subfile.dart") + ":")]));

    // It's nondeterministic what order the dart2js transformers start running,
    // so we allow the error messages to be emitted in either order.
    pub.stderr.expect(
        either(
            inOrder([consumeFile, consumeSubfile]),
            inOrder([consumeSubfile, consumeFile])));

    pub.shouldExit(exit_codes.DATA);

    // Doesn't output anything if an error occurred.
    d.dir(appPath, [d.dir('build', [d.nothing('web')])]).validate();
  });
}
