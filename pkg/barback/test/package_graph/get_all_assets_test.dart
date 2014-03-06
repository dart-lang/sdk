// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.barback_test;

import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();

  test("gets all source assets", () {
    initGraph(["app|a.txt", "app|b.txt", "app|c.txt"]);
    updateSources(["app|a.txt", "app|b.txt", "app|c.txt"]);
    expectAllAssets(["app|a.txt", "app|b.txt", "app|c.txt"]);
    buildShouldSucceed();
  });

  test("includes transformed outputs", () {
    initGraph(["app|a.txt", "app|foo.blub"], {"app": [
      [new RewriteTransformer("blub", "blab")]
    ]});
    updateSources(["app|a.txt", "app|foo.blub"]);
    expectAllAssets(["app|a.txt", "app|foo.blub", "app|foo.blab"]);
    buildShouldSucceed();
  });

  test("includes overwritten outputs", () {
    initGraph(["app|a.txt", "app|foo.blub"], {"app": [
      [new RewriteTransformer("blub", "blub")]
    ]});
    updateSources(["app|a.txt", "app|foo.blub"]);
    expectAllAssets({
      "app|a.txt": "a",
      "app|foo.blub": "foo.blub"
    });
    buildShouldSucceed();
  });

  test("completes to an error if two transformers output the same file", () {
    initGraph(["app|foo.a"], {"app": [
      [
        new RewriteTransformer("a", "b"),
        new RewriteTransformer("a", "b")
      ]
    ]});
    updateSources(["app|foo.a"]);
    expectAllAssetsShouldFail(isAssetCollisionException("app|foo.b"));
  });

  test("completes to an error if a transformer fails", () {
    initGraph(["app|foo.txt"], {"app": [
      [new BadTransformer(["app|foo.out"])]
    ]});

    updateSources(["app|foo.txt"]);
    expectAllAssetsShouldFail(isTransformerException(
        equals(BadTransformer.ERROR)));
  });

  test("completes to an aggregate error if there are multiple errors", () {
    initGraph(["app|foo.txt"], {"app": [
      [
        new BadTransformer(["app|foo.out"]),
        new BadTransformer(["app|foo.out2"])
      ]
    ]});

    updateSources(["app|foo.txt"]);
    expectAllAssetsShouldFail(isAggregateException([
      isTransformerException(equals(BadTransformer.ERROR)),
      isTransformerException(equals(BadTransformer.ERROR))
    ]));
  });
}
