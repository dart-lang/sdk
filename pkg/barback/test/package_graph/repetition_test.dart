// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

// This tests the behavior of barback under many operations happening in quick
// succession. Since Barback is so asynchronous, it's easy for it to have subtle
// dependencies on the commonly-used and -tested usage patterns. These tests
// exist to stress-test less-common usage patterns in order to root out
// additional bugs.

main() {
  initConfig();

  test("updates sources many times", () {
    initGraph(["app|foo.txt"], {
      "app": [[new RewriteTransformer("txt", "out")]]
    });

    for (var i = 0; i < 1000; i++) {
      updateSources(["app|foo.txt"]);
    }

    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();
  });

  test("updates and then removes sources many times", () {
    initGraph(["app|foo.txt"], {
      "app": [[new RewriteTransformer("txt", "out")]]
    });

    for (var i = 0; i < 1000; i++) {
      updateSources(["app|foo.txt"]);
      removeSources(["app|foo.txt"]);
    }

    expectNoAsset("app|foo.out");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("updates transformers many times", () {
    var rewrite = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[rewrite]]});
    updateSources(["app|foo.txt"]);

    for (var i = 0; i < 1000; i++) {
      updateTransformers("app", [[rewrite]]);
    }

    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();
  });

  test("updates and removes transformers many times", () {
    var rewrite = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[rewrite]]});
    updateSources(["app|foo.txt"]);

    for (var i = 0; i < 1000; i++) {
      updateTransformers("app", [[rewrite]]);
      updateTransformers("app", [[]]);
    }

    expectAsset("app|foo.txt", "foo");
    expectNoAsset("app|foo.out");
    buildShouldSucceed();
  });
}
