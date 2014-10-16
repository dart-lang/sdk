// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("does not watch changes to compiled JS files in the package", () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "body")])]).create();

    pubServe();
    waitForBuildSuccess();
    requestShouldSucceed("index.html", "body");

    d.dir(
        appPath,
        [
            d.dir(
                "web",
                [
                    d.file('file.dart', 'void main() => print("hello");'),
                    d.file("other.dart.js", "should be ignored"),
                    d.file("other.dart.js.map", "should be ignored"),
                    d.file("other.dart.precompiled.js", "should be ignored")])]).create();

    waitForBuildSuccess();
    requestShouldSucceed("file.dart", 'void main() => print("hello");');
    requestShould404("other.dart.js");
    requestShould404("other.dart.js.map");
    requestShould404("other.dart.precompiled.js");
    endPubServe();
  });
}
