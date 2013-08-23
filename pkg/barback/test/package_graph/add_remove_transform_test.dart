// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();
  test("a new transformer is applied to a matching asset", () {
    initGraph(["app|foo.blub"]);

    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blub", "foo");
    buildShouldSucceed();

    updateTransformers("app", [[new RewriteTransformer("blub", "blab")]]);
    expectAsset("app|foo.blab", "foo.blab");
    expectNoAsset("app|foo.blub");
    buildShouldSucceed();
  });

  test("a new transformer is not applied to a non-matching asset", () {
    initGraph(["app|foo.blub"]);

    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blub", "foo");
    buildShouldSucceed();

    updateTransformers("app", [[new RewriteTransformer("zip", "zap")]]);
    expectAsset("app|foo.blub", "foo");
    expectNoAsset("app|foo.zap");
    buildShouldSucceed();
  });

  test("updateTransformers doesn't re-run an old transformer", () {
    var rewrite = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[rewrite]]});

    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    expectNoAsset("app|foo.blub");
    buildShouldSucceed();

    updateTransformers("app", [[rewrite]]);
    expectAsset("app|foo.blab", "foo.blab");
    expectNoAsset("app|foo.blub");
    buildShouldSucceed();

    expect(rewrite.numRuns, completion(equals(1)));
  });

  test("updateTransformers re-runs old transformers in a new phase", () {
    var rewrite1 = new RewriteTransformer("txt", "blub");
    var rewrite2 = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.txt"], {"app": [[rewrite1], [rewrite2]]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.blab", "foo.blub.blab");
    expectNoAsset("app|foo.blub");
    buildShouldSucceed();

    updateTransformers("app", [[rewrite2], [rewrite1]]);
    expectAsset("app|foo.blub", "foo.blub");
    expectNoAsset("app|foo.blab");
    buildShouldSucceed();
  });

  test("updateTransformers re-runs an old transformer when a previous phase "
      "changes", () {
    var rewrite = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[], [rewrite]]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    updateTransformers("app", [
      [new RewriteTransformer("txt", "txt")],
      [rewrite]
    ]);
    expectAsset("app|foo.out", "foo.txt.out");
    buildShouldSucceed();
  });

  test("a removed transformer is no longer applied", () {
    initGraph(["app|foo.blub"], {"app": [
      [new RewriteTransformer("blub", "blab")]
    ]});

    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    expectNoAsset("app|foo.blub");
    buildShouldSucceed();

    updateTransformers("app", []);
    expectAsset("app|foo.blub", "foo");
    expectNoAsset("app|foo.blab");
    buildShouldSucceed();
  });

  test("a new transformer is pipelined", () {
    var rewrite1 = new RewriteTransformer("source", "phase1");
    var rewrite3 = new RewriteTransformer("phase2", "phase3");
    initGraph(["app|foo.source"], {"app": [
      [rewrite1],
      [rewrite3]
    ]});

    updateSources(["app|foo.source"]);
    expectNoAsset("app|foo.phase3");
    buildShouldSucceed();

    updateTransformers("app", [
      [rewrite1],
      [new RewriteTransformer("phase1", "phase2")],
      [rewrite3]
    ]);
    expectAsset("app|foo.phase3", "foo.phase1.phase2.phase3");
    buildShouldSucceed();
  });

  test("a removed transformer is un-pipelined", () {
    var rewrite1 = new RewriteTransformer("source", "phase1");
    var rewrite3 = new RewriteTransformer("phase2", "phase3");
    initGraph(["app|foo.source"], {"app": [
      [rewrite1],
      [new RewriteTransformer("phase1", "phase2")],
      [rewrite3]
    ]});

    updateSources(["app|foo.source"]);
    expectAsset("app|foo.phase3", "foo.phase1.phase2.phase3");
    buildShouldSucceed();

    updateTransformers("app", [[rewrite1], [rewrite3]]);
    expectNoAsset("app|foo.phase3");
    buildShouldSucceed();
  });

  test("a transformer is removed during isPrimary", () {
    var rewrite = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[rewrite]]});

    rewrite.pauseIsPrimary("app|foo.blub");
    updateSources(["app|foo.blub"]);
    // Ensure we're waiting on [rewrite.isPrimary].
    schedule(pumpEventQueue);

    updateTransformers("app", []);
    rewrite.resumeIsPrimary("app|foo.blub");
    expectAsset("app|foo.blub", "foo");
    expectNoAsset("app|foo.blab");
    buildShouldSucceed();
  });

  test("a transformer is removed during apply", () {
    var rewrite = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[rewrite]]});

    rewrite.pauseApply();
    updateSources(["app|foo.blub"]);
    // Ensure we're waiting on [rewrite.apply].
    schedule(pumpEventQueue);

    updateTransformers("app", []);
    rewrite.resumeApply();
    expectAsset("app|foo.blub", "foo");
    expectNoAsset("app|foo.blab");
    buildShouldSucceed();
  });

  test("a new transformer can see pass-through assets", () {
    var rewrite = new RewriteTransformer("zip", "zap");
    initGraph(["app|foo.blub"], {"app": [[rewrite]]});

    updateSources(["app|foo.blub"]);
    buildShouldSucceed();

    updateTransformers("app", [
      [rewrite],
      [new RewriteTransformer("blub", "blab")]
    ]);
    expectAsset("app|foo.blab", "foo.blab");
    expectNoAsset("app|foo.blub");
    buildShouldSucceed();
  });

  test("a cross-package transform sees a new transformer in a new phase", () {
    var rewrite = new RewriteTransformer("inc", "inc");
    initGraph({
      "pkg1|foo.txt": "pkg2|foo.inc",
      "pkg2|foo.inc": "foo"
    }, {
      "pkg1": [[new ManyToOneTransformer("txt")]],
      "pkg2": [[rewrite]]
    });

    updateSources(["pkg1|foo.txt", "pkg2|foo.inc"]);
    expectAsset("pkg1|foo.out", "foo.inc");
    buildShouldSucceed();

    updateTransformers("pkg2", [
      [rewrite],
      [new RewriteTransformer("inc", "inc")]
    ]);
    expectAsset("pkg1|foo.out", "foo.inc.inc");
    buildShouldSucceed();
  });

  test("a cross-package transform doesn't see a removed transformer in a "
      "removed phase", () {
    var rewrite = new RewriteTransformer("inc", "inc");
    initGraph({
      "pkg1|foo.txt": "pkg2|foo.inc",
      "pkg2|foo.inc": "foo"
    }, {
      "pkg1": [[new ManyToOneTransformer("txt")]],
      "pkg2": [
        [rewrite],
        [new RewriteTransformer("inc", "inc")]
      ]
    });

    updateSources(["pkg1|foo.txt", "pkg2|foo.inc"]);
    expectAsset("pkg1|foo.out", "foo.inc.inc");
    buildShouldSucceed();

    updateTransformers("pkg2", [[rewrite]]);
    expectAsset("pkg1|foo.out", "foo.inc");
    buildShouldSucceed();
  });
}