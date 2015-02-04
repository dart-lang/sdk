// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../serve/utils.dart';
import '../test_pub.dart';

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
                    d.dir("one", [d.dir("inner", [d.file("file.txt", "one")])]),
                    d.dir("two", [d.dir("inner", [d.file("file.txt", "two")])]),
                    d.dir("nope", [d.dir("inner", [d.file("file.txt", "nope")])])])]).create();
  });

  var webOne = p.join("web", "one");
  var webTwoInner = p.join("web", "two", "inner");

  integration("builds subdirectories", () {
    schedulePub(
        args: ["build", webOne, webTwoInner],
        output: new RegExp(r'Built 2 files to "build".'));

    d.dir(
        appPath,
        [
            d.dir(
                "build",
                [
                    d.dir(
                        "web",
                        [
                            d.dir("one", [d.dir("inner", [d.file("file.txt", "one")])]),
                            d.dir("two", [d.dir("inner", [d.file("file.txt", "two")])]),
                            d.nothing("nope")])])]).validate();
  });

  integration("serves subdirectories", () {
    pubServe(args: [webOne, webTwoInner]);

    requestShouldSucceed("inner/file.txt", "one", root: webOne);
    requestShouldSucceed("file.txt", "two", root: webTwoInner);
    expectNotServed("web");
    expectNotServed(p.join("web", "three"));

    endPubServe();
  });
}
