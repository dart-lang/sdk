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

  test("a lazy asset piped into a declaring transformer isn't eagerly "
      "compiled", () {
    var transformer1 = new LazyRewriteTransformer("blub", "blab");
    var transformer2 = new DeclaringRewriteTransformer("blab", "blib");
    initGraph(["app|foo.blub"], {"app": [
      [transformer1], [transformer2]
    ]});
    updateSources(["app|foo.blub"]);
    buildShouldSucceed();
    expect(transformer1.numRuns, completion(equals(0)));
    expect(transformer2.numRuns, completion(equals(0)));
  });

  test("a lazy asset piped into a declaring transformer is compiled "
      "on-demand", () {
    initGraph(["app|foo.blub"], {"app": [
      [new LazyRewriteTransformer("blub", "blab")],
      [new DeclaringRewriteTransformer("blab", "blib")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blib", "foo.blab.blib");
    buildShouldSucceed();
  });

  test("a lazy asset piped through many declaring transformers isn't eagerly "
      "compiled", () {
    var transformer1 = new LazyRewriteTransformer("one", "two");
    var transformer2 = new DeclaringRewriteTransformer("two", "three");
    var transformer3 = new DeclaringRewriteTransformer("three", "four");
    var transformer4 = new DeclaringRewriteTransformer("four", "five");
    initGraph(["app|foo.one"], {"app": [
      [transformer1], [transformer2], [transformer3], [transformer4]
    ]});
    updateSources(["app|foo.one"]);
    buildShouldSucceed();
    expect(transformer1.numRuns, completion(equals(0)));
    expect(transformer2.numRuns, completion(equals(0)));
    expect(transformer3.numRuns, completion(equals(0)));
    expect(transformer4.numRuns, completion(equals(0)));
  });

  test("a lazy asset piped through many declaring transformers is compiled "
      "on-demand", () {
    initGraph(["app|foo.one"], {"app": [
      [new LazyRewriteTransformer("one", "two")],
      [new DeclaringRewriteTransformer("two", "three")],
      [new DeclaringRewriteTransformer("three", "four")],
      [new DeclaringRewriteTransformer("four", "five")]
    ]});
    updateSources(["app|foo.one"]);
    expectAsset("app|foo.five", "foo.two.three.four.five");
    buildShouldSucceed();
  });

  test("a lazy asset piped into a non-lazy transformer that doesn't use its "
      "outputs isn't eagerly compiled", () {
    var transformer = new LazyRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [
      [transformer],
      [new RewriteTransformer("txt", "out")]
    ]});
    updateSources(["app|foo.blub"]);
    buildShouldSucceed();
    expect(transformer.numRuns, completion(equals(0)));
  });

  test("a lazy asset piped into a non-lazy transformer that doesn't use its "
      "outputs is compiled on-demand", () {
    initGraph(["app|foo.blub"], {"app": [
      [new LazyRewriteTransformer("blub", "blab")],
      [new RewriteTransformer("txt", "out")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();
  });

  test("a lazy transformer followed by a non-lazy transformer is re-run "
      "eagerly", () {
    var rewrite = new LazyRewriteTransformer("one", "two");
    initGraph(["app|foo.one"], {"app": [
      [rewrite],
      [new RewriteTransformer("two", "three")]
    ]});

    updateSources(["app|foo.one"]);
    expectAsset("app|foo.three", "foo.two.three");
    buildShouldSucceed();

    updateSources(["app|foo.one"]);
    buildShouldSucceed();

    expect(rewrite.numRuns, completion(equals(2)));
  });

  test("a lazy transformer followed by a declaring transformer isn't re-run "
      "eagerly", () {
    var rewrite = new LazyRewriteTransformer("one", "two");
    initGraph(["app|foo.one"], {"app": [
      [rewrite],
      [new DeclaringRewriteTransformer("two", "three")]
    ]});

    updateSources(["app|foo.one"]);
    expectAsset("app|foo.three", "foo.two.three");
    buildShouldSucceed();

    updateSources(["app|foo.one"]);
    buildShouldSucceed();

    expect(rewrite.numRuns, completion(equals(1)));
  });

  test("a declaring transformer added after a materialized lazy transformer "
      "is still deferred", () {
    var lazy = new LazyRewriteTransformer("one", "two");
    var declaring = new DeclaringRewriteTransformer("two", "three");
    initGraph(["app|foo.one"], {"app": [[lazy]]});

    updateSources(["app|foo.one"]);
    expectAsset("app|foo.two", "foo.two");
    buildShouldSucceed();

    updateTransformers("app", [[lazy], [declaring]]);
    expectAsset("app|foo.three", "foo.two.three");
    buildShouldSucceed();

    updateSources(["app|foo.one"]);
    buildShouldSucceed();

    expect(lazy.numRuns, completion(equals(1)));
    expect(declaring.numRuns, completion(equals(1)));
  });

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

  test("after being materialized a lazy transformer is still lazy", () {
    var transformer = new LazyRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});

    updateSources(["app|foo.blub"]);
    buildShouldSucceed();

    // Request the asset once to force it to be materialized.
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    updateSources(["app|foo.blub"]);
    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(1)));
  });

  test("after being materialized a lazy transformer can be materialized again",
      () {
    var transformer = new LazyRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});

    updateSources(["app|foo.blub"]);
    buildShouldSucceed();

    // Request the asset once to force it to be materialized.
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    modifyAsset("app|foo.blub", "bar");
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "bar.blab");
    buildShouldSucceed();
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

  test("a lazy transformer that generates fewer outputs than it declares is "
      "forced when a declared but ungenerated output is requested", () {
    initGraph({"app|foo.txt": "no"}, {"app": [
      [new LazyCheckContentAndRenameTransformer(
          oldExtension: "txt", oldContent: "yes",
          newExtension: "out", newContent: "done")]
    ]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.out");
    buildShouldSucceed();

    modifyAsset("app|foo.txt", "yes");
    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.out", "done");
    buildShouldSucceed();
  });

  // Regression tests.

  test("a lazy transformer that doesn't apply updates its passed-through asset",
      () {
    initGraph(["app|foo.txt"], {"app": [
      [new LazyRewriteTransformer("blub", "blab")]
    ]});

    // Pause the provider so that the transformer will start forwarding the
    // asset while it's dirty.
    pauseProvider();
    updateSources(["app|foo.txt"]);
    expectAssetDoesNotComplete("app|foo.txt");

    resumeProvider();
    expectAsset("app|foo.txt", "foo");
    buildShouldSucceed();

    modifyAsset("app|foo.txt", "bar");
    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "bar");
    buildShouldSucceed();
  });

  test("a lazy transformer is forced while the previous lazy transformer is "
      "available, then the previous transformer becomes unavailable", () {
    var assets = new LazyAssetsTransformer(["app|out.one", "app|out.two"]);
    var rewrite = new LazyRewriteTransformer("two", "three");
    initGraph(["app|foo.in"], {"app": [[assets], [rewrite]]});

    updateSources(["app|foo.in"]);
    // Request out.one so that [assets] runs but the second does not.
    expectAsset("app|out.one", "app|out.one");
    buildShouldSucceed();

    // Start the [rewrite] running. The output from [assets] should still be
    // available.
    rewrite.pauseApply();
    expectAssetDoesNotComplete("app|out.three");

    // Mark [assets] as dirty. It should re-run, since [rewrite] still needs its
    // input.
    updateSources(["app|foo.in"]);
    rewrite.resumeApply();

    expectAsset("app|out.three", "app|out.two.three");
    buildShouldSucceed();

    // [assets] should run once for each time foo.in was updated.
    expect(assets.numRuns, completion(equals(2)));

    // [rewrite] should run once against [assets]'s original output and once
    // against its new output.
    expect(rewrite.numRuns, completion(equals(2)));
  });
}
