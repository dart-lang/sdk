// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform.pass_through_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../utils.dart';

main() {
  initConfig();
  test("passes an asset through a phase in which no transforms apply", () {
    initGraph([
      "app|foo.in",
      "app|bar.zip",
    ], {"app": [
      [new RewriteTransformer("in", "mid")],
      [new RewriteTransformer("zip", "zap")],
      [new RewriteTransformer("mid", "out")],
    ]});

    updateSources(["app|foo.in", "app|bar.zip"]);
    expectAsset("app|foo.out", "foo.mid.out");
    expectAsset("app|bar.zap", "bar.zap");
    buildShouldSucceed();
  });

  test("passes an asset through a phase in which a transform uses it", () {
    initGraph([
      "app|foo.in",
    ], {"app": [
      [new RewriteTransformer("in", "mid")],
      [new RewriteTransformer("mid", "phase2")],
      [new RewriteTransformer("mid", "phase3")],
    ]});

    updateSources(["app|foo.in"]);
    expectAsset("app|foo.in", "foo");
    expectAsset("app|foo.mid", "foo.mid");
    expectAsset("app|foo.phase2", "foo.mid.phase2");
    expectAsset("app|foo.phase3", "foo.mid.phase3");
    buildShouldSucceed();
  });

  // If the asset were to get passed through, it might either cause a collision
  // or silently supersede the overwriting asset. We want to assert that that
  // doesn't happen.
  test("doesn't pass an asset through a phase in which a transform "
      "overwrites it", () {
    initGraph([
      "app|foo.txt"
    ], {"app": [[new RewriteTransformer("txt", "txt")]]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "foo.txt");
    buildShouldSucceed();
  });

  test("removes a pass-through asset when the source is removed", () {
    initGraph([
      "app|foo.in",
      "app|bar.zip",
    ], {"app": [
      [new RewriteTransformer("zip", "zap")],
      [new RewriteTransformer("in", "out")],
    ]});

    updateSources(["app|foo.in", "app|bar.zip"]);
    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    removeSources(["app|foo.in"]);
    expectNoAsset("app|foo.in");
    expectNoAsset("app|foo.out");
    buildShouldSucceed();
  });

  test("updates a pass-through asset when the source is updated", () {
    initGraph([
      "app|foo.in",
      "app|bar.zip",
    ], {"app": [
      [new RewriteTransformer("zip", "zap")],
      [new RewriteTransformer("in", "out")],
    ]});

    updateSources(["app|foo.in", "app|bar.zip"]);
    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    modifyAsset("app|foo.in", "boo");
    updateSources(["app|foo.in"]);
    expectAsset("app|foo.out", "boo.out");
    buildShouldSucceed();
  });

  test("passes an asset through a phase in which transforms have ceased to "
      "apply", () {
    initGraph([
      "app|foo.in",
    ], {"app": [
      [new RewriteTransformer("in", "mid")],
      [new CheckContentTransformer("foo.mid", ".phase2")],
      [new CheckContentTransformer(new RegExp(r"\.mid$"), ".phase3")],
    ]});

    updateSources(["app|foo.in"]);
    expectAsset("app|foo.mid", "foo.mid.phase2");
    buildShouldSucceed();

    modifyAsset("app|foo.in", "bar");
    updateSources(["app|foo.in"]);
    expectAsset("app|foo.mid", "bar.mid.phase3");
    buildShouldSucceed();
  });

  test("doesn't pass an asset through a phase in which transforms have "
      "started to apply", () {
    initGraph([
      "app|foo.in",
    ], {"app": [
      [new RewriteTransformer("in", "mid")],
      [new CheckContentTransformer("bar.mid", ".phase2")],
      [new CheckContentTransformer(new RegExp(r"\.mid$"), ".phase3")],
    ]});

    updateSources(["app|foo.in"]);
    expectAsset("app|foo.mid", "foo.mid.phase3");
    buildShouldSucceed();

    modifyAsset("app|foo.in", "bar");
    updateSources(["app|foo.in"]);
    expectAsset("app|foo.mid", "bar.mid.phase2");
    buildShouldSucceed();
  });

  test("doesn't pass an asset through if it's removed during isPrimary", () {
    var check = new CheckContentTransformer("bar", " modified");
    initGraph(["app|foo.txt"], {"app": [[check]]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "foo");
    buildShouldSucceed();

    check.pauseIsPrimary("app|foo.txt");
    modifyAsset("app|foo.txt", "bar");
    updateSources(["app|foo.txt"]);
    // Ensure we're waiting on [check.isPrimary]
    schedule(pumpEventQueue);

    removeSources(["app|foo.txt"]);
    check.resumeIsPrimary("app|foo.txt");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("passes an asset through when its overwriting transform becomes "
      "non-primary during apply", () {
    var check = new CheckContentTransformer("yes", " modified");
    initGraph({"app|foo.txt": "yes"}, {"app": [[check]]});

    check.pauseApply();
    updateSources(["app|foo.txt"]);
    expectAssetDoesNotComplete("app|foo.txt");

    modifyAsset("app|foo.txt", "no");
    updateSources(["app|foo.txt"]);
    check.resumeApply();

    expectAsset("app|foo.txt", "no");
    buildShouldSucceed();
  });

  test("doesn't pass an asset through when its overwriting transform becomes "
      "non-primary during apply if another transform overwrites it", () {
    var check = new CheckContentTransformer("yes", " modified");
    initGraph({
      "app|foo.txt": "yes"
    }, {
      "app": [[check, new RewriteTransformer("txt", "txt")]]
    });

    check.pauseApply();
    updateSources(["app|foo.txt"]);
    // Ensure we're waiting on [check.apply]
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "no");
    updateSources(["app|foo.txt"]);
    check.resumeApply();

    expectAsset("app|foo.txt", "no.txt");
    buildShouldSucceed();
  });

  test("doesn't pass an asset through when one overwriting transform becomes "
      "non-primary if another transform still overwrites it", () {
    initGraph({
      "app|foo.txt": "yes"
    }, {
      "app": [[
        new CheckContentTransformer("yes", " modified"),
        new RewriteTransformer("txt", "txt")
      ]]
    });

    updateSources(["app|foo.txt"]);
    // This could be either the output of [CheckContentTransformer] or
    // [RewriteTransformer], depending which completes first.
    expectAsset("app|foo.txt", anything);
    buildShouldFail([isAssetCollisionException("app|foo.txt")]);

    modifyAsset("app|foo.txt", "no");
    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "no.txt");
    buildShouldSucceed();
  });

  test("doesn't return a pass-through asset until we know it won't be "
      "overwritten", () {
    var rewrite = new RewriteTransformer("txt", "txt");
    initGraph(["app|foo.a"], {"app": [[rewrite]]});

    rewrite.pauseIsPrimary("app|foo.a");
    updateSources(["app|foo.a"]);
    expectAssetDoesNotComplete("app|foo.a");

    rewrite.resumeIsPrimary("app|foo.a");
    expectAsset("app|foo.a", "foo");
    buildShouldSucceed();
  });

  test("doesn't return a pass-through asset until we know it won't be "
      "overwritten when secondary inputs change", () {
    var manyToOne = new ManyToOneTransformer("txt");
    initGraph({
      "app|foo.txt": "bar.in",
      "app|bar.in": "bar"
    }, {"app": [[manyToOne]]});

    updateSources(["app|foo.txt", "app|bar.in"]);
    expectAsset("app|foo.txt", "bar.in");
    expectAsset("app|foo.out", "bar");

    manyToOne.pauseApply();
    updateSources(["app|bar.in"]);
    expectAssetDoesNotComplete("app|foo.txt");

    manyToOne.resumeApply();
    expectAsset("app|foo.txt", "bar.in");
    buildShouldSucceed();
  });
}