// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  integration("converts a Dart isolate entrypoint in web to JS", () {
    // Increase the timeout because dart2js takes a lot longer than usual to
    // compile isolate entrypoints.
    currentSchedule.timeout *= 2;

    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.file(
                        "isolate.dart",
                        "void main(List<String> args, SendPort "
                            "sendPort) => print('hello');")])]).create();

    pubServe();
    requestShouldSucceed("isolate.dart.js", contains("hello"));
    endPubServe();
  });
}
