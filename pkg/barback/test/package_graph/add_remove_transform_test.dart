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
    buildShouldSucceed();

    updateTransformers("app", [[rewrite]]);
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    expect(rewrite.numRuns, completion(equals(1)));
  });

  test("updateTransformers re-runs old transformers in a new phase", () {
    var rewrite1 = new RewriteTransformer("txt", "blub");
    var rewrite2 = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.txt"], {"app": [[rewrite1], [rewrite2]]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.blab", "foo.blub.blab");
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

  test("a transformer is added to an existing phase during isPrimary", () {
    var rewrite = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub", "app|bar.blib"], {"app": [[rewrite]]});

    rewrite.pauseIsPrimary("app|foo.blub");
    updateSources(["app|foo.blub", "app|bar.blib"]);
    // Ensure we're waiting on [rewrite.isPrimary].
    schedule(pumpEventQueue);

    updateTransformers("app", [
      [rewrite, new RewriteTransformer("blib", "blob")]
    ]);
    rewrite.resumeIsPrimary("app|foo.blub");
    expectAsset("app|foo.blab", "foo.blab");
    expectAsset("app|bar.blob", "bar.blob");
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

  group("pass-through", () {
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
      buildShouldSucceed();
    });

    test("a new transformer can overwrite an old asset", () {
      var rewrite = new RewriteTransformer("zip", "zap");
      initGraph(["app|foo.txt"], {"app": [[rewrite]]});

      updateSources(["app|foo.txt"]);
      expectAsset("app|foo.txt", "foo");
      buildShouldSucceed();

      // Add a transformer that will overwrite the previously-passed-through
      // "foo.txt" asset. The transformed asset should be emitted, not the
      // passed-through asset.
      updateTransformers("app", [
        [rewrite, new RewriteTransformer("txt", "txt")]
      ]);
      expectAsset("app|foo.txt", "foo.txt");
      buildShouldSucceed();
    });

    test("passes an asset through when an overwriting transform is removed",
        () {
      initGraph(["app|foo.txt"], {
        "app": [[new RewriteTransformer("txt", "txt")]]
      });

      updateSources(["app|foo.txt"]);
      expectAsset("app|foo.txt", "foo.txt");
      buildShouldSucceed();

      updateTransformers("app", [[]]);
      expectAsset("app|foo.txt", "foo");
      buildShouldSucceed();
    });

    test("passes an asset through when its overwriting transform is removed "
        "during apply", () {
      var rewrite = new RewriteTransformer("txt", "txt");
      initGraph(["app|foo.txt"], {"app": [[rewrite]]});

      rewrite.pauseApply();
      updateSources(["app|foo.txt"]);
      expectAssetDoesNotComplete("app|foo.txt");

      updateTransformers("app", [[]]);
      rewrite.resumeApply();
      expectAsset("app|foo.txt", "foo");
      buildShouldSucceed();
    });

    test("doesn't pass an asset through when its overwriting transform is "
        "removed during apply if another transform overwrites it", () {
      var rewrite1 = new RewriteTransformer("txt", "txt");
      var rewrite2 = new RewriteTransformer("txt", "txt");
      initGraph(["app|foo.txt"], {"app": [[rewrite1, rewrite2]]});

      rewrite1.pauseApply();
      updateSources(["app|foo.txt"]);
      expectAsset("app|foo.txt", "foo.txt");
      // Ensure we're waiting on [rewrite1.apply]
      schedule(pumpEventQueue);

      updateTransformers("app", [[rewrite2]]);
      rewrite1.resumeApply();
      expectAsset("app|foo.txt", "foo.txt");
      buildShouldSucceed();
    });

    test("doesn't pass an asset through when one overwriting transform is "
        "removed if another transform still overwrites it", () {
      var rewrite = new RewriteTransformer("txt", "txt");
      initGraph(["app|foo.txt"], {"app": [[
        rewrite,
        new RewriteTransformer("txt", "txt")
      ]]});

      updateSources(["app|foo.txt"]);
      // This could be either the output of [CheckContentTransformer] or
      // [RewriteTransformer], depending which completes first.
      expectAsset("app|foo.txt", anything);
      buildShouldFail([isAssetCollisionException("app|foo.txt")]);

      updateTransformers("app", [[rewrite]]);
      expectAsset("app|foo.txt", "foo.txt");
      buildShouldSucceed();
    });
  });

  // Regression test.
  test("a phase is added, then an input is removed and re-added", () {
    var rewrite = new RewriteTransformer("txt", "mid");
    initGraph(["app|foo.txt"], {
      "app": [[rewrite]]
    });

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.mid", "foo.mid");
    buildShouldSucceed();

    updateTransformers("app", [
      [rewrite],
      [new RewriteTransformer("mid", "out")]
    ]);
    expectAsset("app|foo.out", "foo.mid.out");
    buildShouldSucceed();

    removeSources(["app|foo.txt"]);
    expectNoAsset("app|foo.out");
    buildShouldSucceed();

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.mid.out");
    buildShouldSucceed();
  });

  // Regression test for issue 19540.
  test("a phase is removed and then one of its inputs is updated", () {
    // Have an empty first phase because the first phase is never removed.
    initGraph(["app|foo.txt"], {
      "app": [[], [new RewriteTransformer("txt", "out")]]
    });

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    // First empty both phases. This allows the second phase to be considered
    // idle even when its transformer is no longer running.
    updateTransformers("app", [[], []]);
    buildShouldSucceed();

    // Now remove the second phase. It should unsubscribe from its input's
    // events.
    updateTransformers("app", [[]]);
    buildShouldSucceed();

    // Update the input. With issue 19540, this would cause the removed phase to
    // try to update its status, which would crash.
    updateSources(["app|foo.txt"]);
    buildShouldSucceed();
  });
}