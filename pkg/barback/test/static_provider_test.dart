// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.static_provider_test;

import 'package:scheduled_test/scheduled_test.dart';

import 'utils.dart';

main() {
  initConfig();
  test("gets a static source asset", () {
    initStaticGraph(["app|foo.txt"], staticPackages: ["app"]);
    expectAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("doesn't get a nonexistent static source asset", () {
    initStaticGraph(["app|foo.txt"], staticPackages: ["app"]);
    expectNoAsset("app|bar.txt");
  });

  test("a transformer can see a static asset", () {
    initStaticGraph({
      "static|b.inc": "b",
      "app|a.txt": "static|b.inc"
    }, staticPackages: ["static"], transformers: {
      "app": [[new ManyToOneTransformer("txt")]]
    });
    updateSources(["app|a.txt"]);
    expectAsset("app|a.out", "b");
  });
}
