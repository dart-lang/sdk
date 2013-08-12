// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.source_test;

import 'dart:async';

import 'package:barback/barback.dart';
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

  test("does not report asset not found errors in results", () {
    initGraph(["app|bar.txt"]);

    // Trigger a build.
    updateSources(["app|bar.txt"]);

    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("reports an error for an unprovided package", () {
    initGraph();
    expect(() => updateSourcesSync(["unknown|foo.txt"]), throwsArgumentError);
  });

  test("reports an error for an unprovided source", () {
    initGraph(["app|known.txt"]);
    updateSources(["app|unknown.txt"]);

    buildShouldFail([isAssetNotFoundException("app|unknown.txt")]);
  });

  test("reports missing input errors in results", () {
    initGraph({"app|a.txt": "a.inc"}, {"app": [
      [new ManyToOneTransformer("txt")]
    ]});

    updateSources(["app|a.txt"]);
    expectNoAsset("app|a.out");
    buildShouldFail([isMissingInputException("app|a.inc")]);
  });

  test("reports an error if a transformer emits an asset for another package",
      () {
    initGraph(["app|foo.txt"], {
      "app": [[new CreateAssetTransformer("wrong|foo.txt")]]
    });

    updateSources(["app|foo.txt"]);
    buildShouldFail([isInvalidOutputException("app", "wrong|foo.txt")]);
  });

  test("fails if a non-primary input is removed", () {
    initGraph({
      "app|a.txt": "a.inc,b.inc,c.inc",
      "app|a.inc": "a",
      "app|b.inc": "b",
      "app|c.inc": "c"
    }, {"app": [
      [new ManyToOneTransformer("txt")]
    ]});

    updateSources(["app|a.txt", "app|a.inc", "app|b.inc", "app|c.inc"]);
    expectAsset("app|a.out", "abc");
    buildShouldSucceed();

    removeSources(["app|b.inc"]);
    buildShouldFail([isMissingInputException("app|b.inc")]);
    expectNoAsset("app|a.out");
  });

  test("catches transformer exceptions and reports them", () {
    initGraph(["app|foo.txt"], {"app": [
      [new BadTransformer(["app|foo.out"])]
    ]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.out");
    buildShouldFail([equals(BadTransformer.ERROR)]);
  });

  test("doesn't yield a source if a transform fails on it", () {
    initGraph(["app|foo.txt"], {"app": [
      [new BadTransformer(["app|foo.txt"])]
    ]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.txt");
  });

  test("catches errors even if nothing is waiting for process results", () {
    initGraph(["app|foo.txt"], {"app": [[new BadTransformer([])]]});

    updateSources(["app|foo.txt"]);
    // Note: No asset requests here.
    buildShouldFail([equals(BadTransformer.ERROR)]);
  });

  test("discards outputs from failed transforms", () {
    initGraph(["app|foo.txt"], {"app": [
      [new BadTransformer(["a.out", "b.out"])]
    ]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|a.out");
  });

  test("fails if only one package fails", () {
    initGraph(["pkg1|foo.txt", "pkg2|foo.txt"],
        {"pkg1": [[new BadTransformer([])]]});

    updateSources(["pkg1|foo.txt", "pkg2|foo.txt"]);
    expectAsset("pkg2|foo.txt", "foo");
    buildShouldFail([equals(BadTransformer.ERROR)]);
  });

  test("emits multiple failures if multiple packages fail", () {
    initGraph(["pkg1|foo.txt", "pkg2|foo.txt"], {
      "pkg1": [[new BadTransformer([])]],
      "pkg2": [[new BadTransformer([])]]
    });

    updateSources(["pkg1|foo.txt", "pkg2|foo.txt"]);
    buildShouldFail([
      equals(BadTransformer.ERROR),
      equals(BadTransformer.ERROR)
    ]);
  });

  test("an error loading an asset removes the asset from the graph", () {
    initGraph(["app|foo.txt"]);

    setAssetError("app|foo.txt");
    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.txt");
    buildShouldFail([isMockLoadException("app|foo.txt")]);
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
    buildShouldFail([isAssetCollisionException("app|foo.out")]);

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
}
