// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();

  setUp(() {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.dir(
                        "sub1",
                        [
                            d.file("file.txt", "contents"),
                            d.dir("sub2", [d.file("file.txt", "contents")]),
                            d.dir("sub3", [d.file("file.txt", "contents")])])])]).create();
  });

  var webSub1 = path.join("web", "sub1");
  var webSub1Sub2 = path.join("web", "sub1", "sub2");
  var webSub1Sub3 = path.join("web", "sub1", "sub3");

  pubBuildAndServeShouldFail(
      "if a superdirectory follows a subdirectory",
      args: [webSub1Sub2, webSub1],
      error: 'Directories "$webSub1Sub2" and "$webSub1" cannot overlap.',
      exitCode: exit_codes.USAGE);

  pubBuildAndServeShouldFail(
      "if a subdirectory follows a superdirectory",
      args: [webSub1, webSub1Sub2],
      error: 'Directories "$webSub1" and "$webSub1Sub2" cannot overlap.',
      exitCode: exit_codes.USAGE);

  pubBuildAndServeShouldFail(
      "if multiple directories overlap",
      args: [webSub1, webSub1Sub2, webSub1Sub3],
      error: 'Directories "$webSub1", "$webSub1Sub2" and "$webSub1Sub3" '
          'cannot overlap.',
      exitCode: exit_codes.USAGE);
}
