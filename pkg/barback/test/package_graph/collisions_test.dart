// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.source_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();

  test("errors if two transformers output the same file", () {
    initGraph(["app|foo.a"], {"app": [
      [
        new RewriteTransformer("a", "b"),
        new RewriteTransformer("a", "b")
      ]
    ]});
    updateSources(["app|foo.a"]);

    buildShouldFail([isAssetCollisionException("app|foo.b")]);
  });

  test("errors if a new transformer outputs the same file as an old "
      "transformer", () {
    initGraph(["app|foo.a", "app|foo.b"], {"app": [
      [
        new RewriteTransformer("a", "c"),
        new RewriteTransformer("b", "c")
      ]
    ]});
    updateSources(["app|foo.a"]);
    expectAsset("app|foo.c", "foo.c");
    buildShouldSucceed();

    updateSources(["app|foo.b"]);
    buildShouldFail([isAssetCollisionException("app|foo.c")]);
  });

  test("a collision returns the first-produced output", () {
    var rewrite1 = new RewriteTransformer("one", "out");
    var rewrite2 = new RewriteTransformer("two", "out");
    initGraph({
      "app|foo.one": "one",
      "app|foo.two": "two"
    }, {"app": [[rewrite1, rewrite2]]});

    rewrite1.pauseApply();
    updateSources(["app|foo.one", "app|foo.two"]);
    // Wait long enough to ensure that rewrite2 has completed.
    schedule(pumpEventQueue);

    rewrite1.resumeApply();
    expectAsset("app|foo.out", "two.out");
    buildShouldFail([isAssetCollisionException("app|foo.out")]);

    // Even after the collision is discovered, the first-produced output should
    // be returned.
    expectAsset("app|foo.out", "two.out");

    // Even if the other output is updated more recently, the first output
    // should continue to take precedence.
    updateSources(["app|foo.one"]);
    expectAsset("app|foo.out", "two.out");
  });

  test("a collision that is later resolved produces an output", () {
    initGraph({
      "app|foo.one": "one",
      "app|foo.two": "two"
    }, {"app": [
      [
        new RewriteTransformer("one", "out"),
        new RewriteTransformer("two", "out")
      ]
    ]});

    updateSources(["app|foo.one"]);
    expectAsset("app|foo.out", "one.out");
    buildShouldSucceed();

    updateSources(["app|foo.two"]);
    expectAsset("app|foo.out", "one.out");
    buildShouldFail([isAssetCollisionException("app|foo.out")]);

    removeSources(["app|foo.one"]);
    expectAsset("app|foo.out", "two.out");
    buildShouldSucceed();
  });

  test("a collision that is later resolved runs transforms", () {
    initGraph({
      "app|foo.one": "one",
      "app|foo.two": "two"
    }, {"app": [
      [
        new RewriteTransformer("one", "mid"),
        new RewriteTransformer("two", "mid")
      ],
      [new RewriteTransformer("mid", "out")]
    ]});

    updateSources(["app|foo.one"]);
    expectAsset("app|foo.out", "one.mid.out");
    buildShouldSucceed();

    updateSources(["app|foo.two"]);
    expectAsset("app|foo.out", "one.mid.out");
    buildShouldFail([isAssetCollisionException("app|foo.mid")]);

    removeSources(["app|foo.one"]);
    expectAsset("app|foo.out", "two.mid.out");
    buildShouldSucceed();
  });

  test("a collision that is partially resolved returns the second completed "
      "output", () {
    var rewrite1 = new RewriteTransformer("one", "out");
    var rewrite2 = new RewriteTransformer("two", "out");
    var rewrite3 = new RewriteTransformer("three", "out");
    initGraph({
      "app|foo.one": "one",
      "app|foo.two": "two",
      "app|foo.three": "three"
    }, {"app": [[rewrite1, rewrite2, rewrite3]]});

    // Make rewrite3 the most-recently-completed transformer from the first run.
    rewrite2.pauseApply();
    rewrite3.pauseApply();
    updateSources(["app|foo.one", "app|foo.two", "app|foo.three"]);
    schedule(pumpEventQueue);
    rewrite2.resumeApply();
    schedule(pumpEventQueue);
    rewrite3.resumeApply();
    buildShouldFail([
      isAssetCollisionException("app|foo.out"),
      isAssetCollisionException("app|foo.out")
    ]);

    // Then update rewrite3 in a separate build. rewrite2 should still be the
    // next version of foo.out in line.
    // TODO(nweiz): Should this emit a collision error as well? Or should they
    // only be emitted when a file is added or removed?
    updateSources(["app|foo.three"]);
    buildShouldSucceed();

    removeSources(["app|foo.one"]);
    expectAsset("app|foo.out", "two.out");
    buildShouldFail([isAssetCollisionException("app|foo.out")]);
  });

  test("a collision with a pass-through asset returns the pass-through asset",
      () {
    initGraph([
      "app|foo.txt",
      "app|foo.in"
    ], {"app": [
      [new RewriteTransformer("in", "txt")]
    ]});

    updateSources(["app|foo.txt", "app|foo.in"]);
    expectAsset("app|foo.txt", "foo");
    buildShouldFail([isAssetCollisionException("app|foo.txt")]);
  });

  test("a new pass-through asset that collides returns the previous asset", () {
    initGraph([
      "app|foo.txt",
      "app|foo.in"
    ], {"app": [
      [new RewriteTransformer("in", "txt")]
    ]});

    updateSources(["app|foo.in"]);
    expectAsset("app|foo.txt", "foo.txt");
    buildShouldSucceed();

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "foo.txt");
    buildShouldFail([isAssetCollisionException("app|foo.txt")]);
  });

  test("a new transform output that collides with a pass-through asset returns "
      "the pass-through asset", () {
    initGraph([
      "app|foo.txt",
      "app|foo.in"
    ], {"app": [
      [new RewriteTransformer("in", "txt")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "foo");
    buildShouldSucceed();

    updateSources(["app|foo.in"]);
    expectAsset("app|foo.txt", "foo");
    buildShouldFail([isAssetCollisionException("app|foo.txt")]);
  });
}
