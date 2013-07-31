// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.source_test;

import 'dart:async';

import 'package:barback/barback.dart';
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

    schedule(() => updateSources(["app|foo.b"]));
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
    expect(() => updateSources(["unknown|foo.txt"]), throwsArgumentError);
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

    buildShouldFail([isMissingInputException("app|a.inc")]);

    updateSources(["app|a.txt"]);

    expectNoAsset("app|a.out");
  });

  test("reports an error if a transformer emits an asset for another package",
      () {
    initGraph(["app|foo.txt"], {
      "app": [[new CreateAssetTransformer("wrong|foo.txt")]]
    });

    buildShouldFail([isInvalidOutputException("app", "wrong|foo.txt")]);

    updateSources(["app|foo.txt"]);
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

    schedule(() {
      removeSources(["app|b.inc"]);
    });

    buildShouldFail([isMissingInputException("app|b.inc")]);
    expectNoAsset("app|a.out");
  });

  test("catches transformer exceptions and reports them", () {
    initGraph(["app|foo.txt"], {"app": [
      [new BadTransformer(["app|foo.out"])]
    ]});

    schedule(() {
      updateSources(["app|foo.txt"]);
    });

    expectNoAsset("app|foo.out");

    buildShouldFail([equals(BadTransformer.ERROR)]);
  });

  test("doesn't yield a source if a transform fails on it", () {
    initGraph(["app|foo.txt"], {"app": [
      [new BadTransformer(["app|foo.txt"])]
    ]});

    schedule(() {
      updateSources(["app|foo.txt"]);
    });

    expectNoAsset("app|foo.txt");
  });

  test("catches errors even if nothing is waiting for process results", () {
    initGraph(["app|foo.txt"], {"app": [[new BadTransformer([])]]});

    schedule(() {
      updateSources(["app|foo.txt"]);
    });

    // Note: No asset requests here.

    buildShouldFail([equals(BadTransformer.ERROR)]);
  });

  test("discards outputs from failed transforms", () {
    initGraph(["app|foo.txt"], {"app": [
      [new BadTransformer(["a.out", "b.out"])]
    ]});

    schedule(() {
      updateSources(["app|foo.txt"]);
    });

    expectNoAsset("app|a.out");
  });

  test("fails if only one package fails", () {
    initGraph(["pkg1|foo.txt", "pkg2|foo.txt"],
        {"pkg1": [[new BadTransformer([])]]});

    schedule(() {
      updateSources(["pkg1|foo.txt", "pkg2|foo.txt"]);
    });

    expectAsset("pkg2|foo.txt", "foo");
    buildShouldFail([equals(BadTransformer.ERROR)]);
  });

  test("emits multiple failures if multiple packages fail", () {
    initGraph(["pkg1|foo.txt", "pkg2|foo.txt"], {
      "pkg1": [[new BadTransformer([])]],
      "pkg2": [[new BadTransformer([])]]
    });

    schedule(() {
      updateSources(["pkg1|foo.txt", "pkg2|foo.txt"]);
    });

    buildShouldFail([
      equals(BadTransformer.ERROR),
      equals(BadTransformer.ERROR)
    ]);
  });

  test("an error loading an asset removes the asset from the graph", () {
    initGraph(["app|foo.txt"]);

    setAssetError("app|foo.txt");
    schedule(() => updateSources(["app|foo.txt"]));
    expectNoAsset("app|foo.txt");
    buildShouldFail([isMockLoadException("app|foo.txt")]);
  });
}
