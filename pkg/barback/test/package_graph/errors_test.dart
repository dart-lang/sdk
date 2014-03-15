// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.source_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();

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
    initGraph(["app|known.txt"], {"app": [
      // Have a dummy transformer so that barback at least tries to load the
      // asset.
      [new RewriteTransformer("a", "b")]
    ]});

    updateSources(["app|unknown.txt"]);

    buildShouldFail([
      isAssetLoadException("app|unknown.txt",
          isAssetNotFoundException("app|unknown.txt"))
    ]);
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
    buildShouldFail([isInvalidOutputException("wrong|foo.txt")]);
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
    buildShouldFail([isTransformerException(equals(BadTransformer.ERROR))]);
  });

  test("catches errors even if nothing is waiting for process results", () {
    initGraph(["app|foo.txt"], {"app": [[new BadTransformer([])]]});

    updateSources(["app|foo.txt"]);
    // Note: No asset requests here.
    buildShouldFail([isTransformerException(equals(BadTransformer.ERROR))]);
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
    buildShouldFail([isTransformerException(equals(BadTransformer.ERROR))]);
  });

  test("emits multiple failures if multiple packages fail", () {
    initGraph(["pkg1|foo.txt", "pkg2|foo.txt"], {
      "pkg1": [[new BadTransformer([])]],
      "pkg2": [[new BadTransformer([])]]
    });

    updateSources(["pkg1|foo.txt", "pkg2|foo.txt"]);
    buildShouldFail([
      isTransformerException(equals(BadTransformer.ERROR)),
      isTransformerException(equals(BadTransformer.ERROR))
    ]);
  });

  test("an error loading an asset removes the asset from the graph", () {
    initGraph(["app|foo.txt"], {"app": [
      // Have a dummy transformer so that barback at least tries to load the
      // asset.
      [new RewriteTransformer("a", "b")]
    ]});

    setAssetError("app|foo.txt");
    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.txt");
    buildShouldFail([
      isAssetLoadException("app|foo.txt", isMockLoadException("app|foo.txt"))
    ]);
  });

  test("an asset isn't passed through a transformer with an error", () {
    initGraph(["app|foo.txt"], {"app": [[new BadTransformer([])]]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.txt");
    buildShouldFail([isTransformerException(equals(BadTransformer.ERROR))]);
  });

  test("a transformer that logs errors shouldn't produce output", () {
    initGraph(["app|foo.txt"], {"app": [
      [new BadLogTransformer(["app|out.txt"])]
    ]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.txt");
    expectNoAsset("app|out.txt");
    buildShouldFail([
      isTransformerException(equals("first error")),
      isTransformerException(equals("second error"))
    ]);
  });

  test("a transformer can catch an error loading a secondary input", () {
    initGraph(["app|foo.txt"], {"app": [
      [new CatchAssetNotFoundTransformer(".txt", "app|nothing")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "failed to load app|nothing");
    buildShouldSucceed();
  });

  test("a transformer that fails due to a missing secondary input is re-run "
      "when that input appears", () {
    initGraph({
      "app|foo.txt": "bar.inc",
      "app|bar.inc": "bar"
    }, {"app": [
      [new ManyToOneTransformer("txt")]
    ]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.out");
    buildShouldFail([isMissingInputException("app|bar.inc")]);

    updateSources(["app|bar.inc"]);
    expectAsset("app|foo.out", "bar");
    buildShouldSucceed();
  });
}
