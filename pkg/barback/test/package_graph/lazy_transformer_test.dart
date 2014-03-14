// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.lazy_asset_test;

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();
  test("requesting a lazy asset should cause it to be generated", () {
    initGraph(["app|foo.blub"], {"app": [
      [new LazyRewriteTransformer("blub", "blab")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();
  });

  test("calling getAllAssets should cause a lazy asset to be generated", () {
    var transformer = new LazyRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});
    updateSources(["app|foo.blub"]);
    expectAllAssets(["app|foo.blub", "app|foo.blab"]);
    buildShouldSucceed();
    expect(transformer.numRuns, completion(equals(1)));
  });

  test("requesting a lazy asset multiple times should only cause it to be "
      "generated once", () {
    var transformer = new LazyRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    expectAsset("app|foo.blab", "foo.blab");
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();
    expect(transformer.numRuns, completion(equals(1)));
  });

  test("a lazy asset can be consumed by a non-lazy transformer", () {
    initGraph(["app|foo.blub"], {"app": [
      [new LazyRewriteTransformer("blub", "blab")],
      [new RewriteTransformer("blab", "blib")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blib", "foo.blab.blib");
    buildShouldSucceed();
  });

  test("a lazy asset isn't eagerly compiled", () {
    var transformer = new LazyRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});
    updateSources(["app|foo.blub"]);
    buildShouldSucceed();
    expect(transformer.numRuns, completion(equals(0)));
  });

  test("a lazy asset emitted by a group isn't eagerly compiled", () {
    var transformer = new LazyRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [
      [new TransformerGroup([[transformer]])]
    ]});
    updateSources(["app|foo.blub"]);
    buildShouldSucceed();
    expect(transformer.numRuns, completion(equals(0)));
  });

  test("a lazy asset piped into a non-lazy transformer is eagerly compiled",
      () {
    var transformer = new LazyRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [
      [transformer],
      [new RewriteTransformer("blab", "blib")]
    ]});
    updateSources(["app|foo.blub"]);
    buildShouldSucceed();
    expect(transformer.numRuns, completion(equals(1)));
  });

  // TODO(nweiz): enable these once DeclaringTransformers forward laziness
  // properly (issue 16442).
  //
  // test("a lazy asset piped into a declaring transformer isn't eagerly "
  //     "compiled", () {
  //   var transformer1 = new LazyRewriteTransformer("blub", "blab");
  //   var transformer2 = new DeclaringRewriteTransformer("blab", "blib");
  //   initGraph(["app|foo.blub"], {"app": [
  //     [transformer1], [transformer2]
  //   ]});
  //   updateSources(["app|foo.blub"]);
  //   buildShouldSucceed();
  //   expect(transformer1.numRuns, completion(equals(0)));
  //   expect(transformer2.numRuns, completion(equals(0)));
  // });
  //
  // test("a lazy asset piped into a declaring transformer is compiled "
  //     "on-demand", () {
  //   initGraph(["app|foo.blub"], {"app": [
  //     [new LazyRewriteTransformer("blub", "blab")],
  //     [new DeclaringRewriteTransformer("blab", "blib")]
  //   ]});
  //   updateSources(["app|foo.blub"]);
  //   expectAsset("app|foo.blib", "foo.blab.blib");
  //   buildShouldSucceed();
  // });

  test("a lazy asset works as a cross-package input", () {
    initGraph({
      "pkg1|foo.blub": "foo",
      "pkg2|a.txt": "pkg1|foo.blab"
    }, {"pkg1": [
      [new LazyRewriteTransformer("blub", "blab")],
    ], "pkg2": [
      [new ManyToOneTransformer("txt")]
    ]});

    updateSources(["pkg1|foo.blub", "pkg2|a.txt"]);
    expectAsset("pkg2|a.out", "foo.blab");
    buildShouldSucceed();
  });

  test("a lazy transformer can consume secondary inputs lazily", () {
    initGraph({
      "app|a.inc": "a",
      "app|a.txt": "a.inc"
    }, {"app": [
      [new LazyManyToOneTransformer("txt")]
    ]});

    updateSources(["app|a.inc", "app|a.txt"]);
    expectAsset("app|a.out", "a");
    buildShouldSucceed();
  });

  test("once a lazy transformer is materialized, it runs eagerly afterwards",
      () {
    var transformer = new LazyRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});

    updateSources(["app|foo.blub"]);
    buildShouldSucceed();

    // Request the asset once to force it to be materialized.
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    updateSources(["app|foo.blub"]);
    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(2)));
  });

  test("an error emitted in a lazy transformer's declareOutputs method is "
      "caught and reported", () {
    initGraph(["app|foo.txt"], {"app": [
      [new LazyBadTransformer("app|foo.out")]
    ]});

    updateSources(["app|foo.txt"]);
    buildShouldFail([isTransformerException(equals(LazyBadTransformer.ERROR))]);
  });

  test("an error emitted in a lazy transformer's declareOuputs method prevents "
      "it from being materialized", () {
    var transformer = new LazyBadTransformer("app|foo.out");
    initGraph(["app|foo.txt"], {"app": [[transformer]]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.out");
    buildShouldFail([isTransformerException(equals(LazyBadTransformer.ERROR))]);
    expect(transformer.numRuns, completion(equals(0)));
  });

  test("a lazy transformer passes through inputs it doesn't apply to", () {
    initGraph(["app|foo.txt"], {"app": [
      [new LazyRewriteTransformer("blub", "blab")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("a lazy transformer passes through inputs it doesn't overwrite", () {
    initGraph(["app|foo.txt"], {"app": [
      [new LazyRewriteTransformer("txt", "out")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("a lazy transformer doesn't pass through inputs it overwrites", () {
    initGraph(["app|foo.txt"], {"app": [
      [new LazyRewriteTransformer("txt", "txt")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "foo.txt");
    buildShouldSucceed();
  });

  test("a lazy transformer doesn't pass through inputs it consumes", () {
    initGraph(["app|foo.txt"], {"app": [
      [new LazyRewriteTransformer("txt", "out")..consumePrimary = true]
    ]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("a lazy transformer that doesn't apply does nothing when forced", () {
    initGraph(["app|foo.txt"], {"app": [
      [new LazyRewriteTransformer("blub", "blab")]
    ]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.blab");

    // Getting all assets will force every lazy transformer. This shouldn't
    // cause the rewrite to apply, because foo.txt isn't primary.
    expectAllAssets(["app|foo.txt"]);
    buildShouldSucceed();
  });
}
