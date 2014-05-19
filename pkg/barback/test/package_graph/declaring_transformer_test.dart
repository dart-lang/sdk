// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.declaring_transformer_test;

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();

  test("gets a declared output with a different path", () {
    initGraph(["app|foo.blub"], {"app": [
      [new DeclaringRewriteTransformer("blub", "blab")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();
  });

  test("gets a declared output with the same path", () {
    initGraph(["app|foo.blub"], {"app": [
      [new DeclaringRewriteTransformer("blub", "blub")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blub", "foo.blub");
    buildShouldSucceed();
  });

  test("gets a passed-through asset", () {
    initGraph(["app|foo.blub"], {"app": [
      [new DeclaringRewriteTransformer("blub", "blab")]
    ]});
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blub", "foo");
    buildShouldSucceed();
  });

  test("doesn't get a consumed asset", () {
    initGraph(["app|foo.blub"], {"app": [
      [new DeclaringRewriteTransformer("blub", "blab")..consumePrimary = true]
    ]});
    updateSources(["app|foo.blub"]);
    expectNoAsset("app|foo.blub");
    buildShouldSucceed();
  });

  test("gets a passed-through asset before apply is finished", () {
    var transformer = new DeclaringRewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});

    transformer.pauseApply();
    updateSources(["app|foo.blub"]);
    expectAsset("app|foo.blub", "foo");

    transformer.resumeApply();
    buildShouldSucceed();
  });

  test("fails to get a consumed asset before apply is finished", () {
    var transformer = new DeclaringRewriteTransformer("blub", "blab")
        ..consumePrimary = true;
    initGraph(["app|foo.blub"], {"app": [[transformer]]});
  
    transformer.pauseApply();
    updateSources(["app|foo.blub"]);
    expectNoAsset("app|foo.blub");
  
    transformer.resumeApply();
    buildShouldSucceed();
  });

  test("blocks on getting a declared asset that wasn't generated last run", () {
    var transformer = new DeclaringCheckContentAndRenameTransformer(
          oldExtension: "txt", oldContent: "yes",
          newExtension: "out", newContent: "done");
    initGraph({"app|foo.txt": "no"}, {"app": [[transformer]]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.out");
    buildShouldSucceed();

    // The transform should remember that foo.out was declared, so it should
    // expect that it might still be generated even though it wasn't last time.
    transformer.pauseApply();
    modifyAsset("app|foo.txt", "yes");
    updateSources(["app|foo.txt"]);
    expectAssetDoesNotComplete("app|foo.out");

    transformer.resumeApply();
    expectAsset("app|foo.out", "done");
    buildShouldSucceed();
  });

  test("doesn't block on on getting an undeclared asset that wasn't generated "
      "last run", () {
    var transformer = new DeclaringCheckContentAndRenameTransformer(
          oldExtension: "txt", oldContent: "yes",
          newExtension: "out", newContent: "done");
    initGraph({"app|foo.txt": "no"}, {"app": [[transformer]]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|foo.out");
    buildShouldSucceed();

    transformer.pauseApply();
    modifyAsset("app|foo.txt", "yes");
    updateSources(["app|foo.txt"]);
    expectNoAsset("app|undeclared.out");

    transformer.resumeApply();
    buildShouldSucceed();
  });

  test("fails to get a consumed asset before apply is finished when a sibling "
      "has finished applying", () {
    var transformer = new DeclaringRewriteTransformer("blub", "blab")
        ..consumePrimary = true;
    initGraph(["app|foo.blub", "app|foo.txt"], {"app": [[
      transformer,
      new RewriteTransformer("txt", "out")
    ]]});
  
    transformer.pauseApply();
    updateSources(["app|foo.blub", "app|foo.txt"]);
    expectAsset("app|foo.out", "foo.out");
    expectNoAsset("app|foo.blub");
  
    transformer.resumeApply();
    buildShouldSucceed();
  });

  test("blocks getting a consumed asset before apply is finished when a "
      "sibling hasn't finished applying", () {
    var declaring = new DeclaringRewriteTransformer("blub", "blab")
        ..consumePrimary = true;
    var eager = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.blub", "app|foo.txt"], {"app": [[declaring, eager]]});
  
    declaring.pauseApply();
    eager.pauseApply();
    updateSources(["app|foo.blub", "app|foo.txt"]);
    expectAssetDoesNotComplete("app|foo.blub");
  
    declaring.resumeApply();
    eager.resumeApply();
    expectNoAsset("app|foo.blub");
    buildShouldSucceed();
  });

  test("waits until apply is finished to get an overwritten asset", () {
    var transformer = new DeclaringRewriteTransformer("blub", "blub");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});

    transformer.pauseApply();
    updateSources(["app|foo.blub"]);
    expectAssetDoesNotComplete("app|foo.blub");

    transformer.resumeApply();
    expectAsset("app|foo.blub", "foo.blub");
    buildShouldSucceed();
  });

  test("a declaring transformer following a lazy transformer runs eagerly once "
      "its input is available", () {
    var declaring = new DeclaringRewriteTransformer("two", "three");
    initGraph(["app|foo.in"], {"app": [
      [new LazyAssetsTransformer(["app|out.one", "app|out.two"])],
      [declaring]
    ]});

    updateSources(["app|foo.in"]);
    // Give the transformers time to declare their assets.
    schedule(pumpEventQueue);

    expectAsset("app|out.one", "app|out.one");
    buildShouldSucceed();

    expect(declaring.numRuns, completion(equals(1)));
  });

  test("a declaring transformer following a lazy transformer doesn't re-run if "
      "its input becomes available and then unavailable", () {
    var declaring = new DeclaringRewriteTransformer("two", "three");
    initGraph(["app|foo.in"], {"app": [
      [new LazyAssetsTransformer(["app|out.one", "app|out.two"])],
      [declaring]
    ]});

    declaring.pauseApply();
    updateSources(["app|foo.in"]);
    // Give the transformers time to declare their assets.
    schedule(pumpEventQueue);

    // Start [declaring] running, because its input became available.
    expectAsset("app|out.one", "app|out.one");

    // Make sure we're blocking on [declaring.apply].
    schedule(pumpEventQueue);

    // Now [declaring]'s input is dirty, so it shouldn't re-run without an
    // explicit request.
    updateSources(["app|foo.in"]);
    declaring.resumeApply();
    buildShouldSucceed();

    // [declaring] should only have run once, despite its input changing. After
    // the first run, it should be awaiting a force() call.
    expect(declaring.numRuns, completion(equals(1)));

    // Once we make a request, [declaring] should force the lazy transformer and
    // then run itself.
    expectAsset("app|out.three", "app|out.two.three");
    buildShouldSucceed();

    // Now [declaring] should have run twice. This ensures that it didn't use
    // its original output for some reason.
    expect(declaring.numRuns, completion(equals(2)));
  });

  test("a declaring transformer following a lazy transformer does re-run if "
      "its input becomes available, it's forced, and then its input becomes "
      "unavailable", () {
    var declaring = new DeclaringRewriteTransformer("two", "three");
    initGraph(["app|foo.in"], {"app": [
      [new LazyAssetsTransformer(["app|out.one", "app|out.two"])],
      [declaring]
    ]});

    declaring.pauseApply();
    updateSources(["app|foo.in"]);

    // Give the transformers time to declare their assets.
    schedule(pumpEventQueue);

    // Start [declaring] running, because its input became available.
    expectAsset("app|out.one", "app|out.one");

    // This shouldn't complete because [declaring.apply] is paused, but it
    // should force the transformer.
    expectAssetDoesNotComplete("app|out.three");

    // Make sure we're blocking on [declaring.apply]
    schedule(pumpEventQueue);

    // Now [declaring]'s input is dirty, so it shouldn't re-run without an
    // explicit request.
    updateSources(["app|foo.in"]);
    declaring.resumeApply();
    buildShouldSucceed();

    // [declaring] should have run twice, once for its original input and once
    // after the input changed because it was forced.
    expect(declaring.numRuns, completion(equals(2)));
  });

  group("with an error in declareOutputs", () {
    test("still runs apply", () {
      initGraph(["app|foo.txt"], {"app": [[
        new DeclaringBadTransformer("app|out.txt",
            declareError: true, applyError: false)
      ]]});

      updateSources(["app|foo.txt"]);
      expectAsset("app|out.txt", "bad out");
      expectAsset("app|foo.txt", "foo");
      buildShouldFail([isTransformerException(BadTransformer.ERROR)]);
    });

    test("waits for apply to complete before passing through the input even if "
        "consumePrimary was called", () {
      var transformer = new DeclaringBadTransformer("app|out.txt",
            declareError: true, applyError: false)..consumePrimary = true;
      initGraph(["app|foo.txt"], {"app": [[transformer]]});

      transformer.pauseApply();
      updateSources(["app|foo.txt"]);
      expectAssetDoesNotComplete("app|out.txt");
      expectAssetDoesNotComplete("app|foo.txt");

      transformer.resumeApply();
      expectAsset("app|out.txt", "bad out");
      expectNoAsset("app|foo.txt");
      buildShouldFail([isTransformerException(BadTransformer.ERROR)]);
    });
  });

  test("with an error in apply still passes through the input", () {
   initGraph(["app|foo.txt"], {"app": [[
     new DeclaringBadTransformer("app|out.txt",
         declareError: false, applyError: true)
   ]]});

   updateSources(["app|foo.txt"]);
   expectNoAsset("app|out.txt");
   expectAsset("app|foo.txt", "foo");
   buildShouldFail([isTransformerException(BadTransformer.ERROR)]);
  });

  test("can emit outputs it didn't declare", () {
    initGraph(["app|foo.txt"], {"app": [
      [new DeclareAssetsTransformer([], ["app|out.txt"])]
    ]});

    updateSources(["app|foo.txt"]);
    // There's probably going to be some time when "out.txt" is unavailable,
    // since it was undeclared.
    schedule(pumpEventQueue);
    expectAsset("app|out.txt", "app|out.txt");
    buildShouldSucceed();
  });

  test("can overwrite the primary input even if it declared that it wouldn't",
      () {
    var transformer = new DeclareAssetsTransformer([], ["app|foo.txt"]);
    initGraph(["app|foo.txt"], {"app": [[transformer]]});

    transformer.pauseApply();
    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt", "foo");

    transformer.resumeApply();
    schedule(pumpEventQueue);
    expectAsset("app|foo.txt", "app|foo.txt");
    buildShouldSucceed();
  });

  test("can declare outputs it doesn't emit", () {
    initGraph(["app|foo.txt"], {"app": [
      [new DeclareAssetsTransformer(["app|out.txt"], [])]
    ]});

    updateSources(["app|foo.txt"]);
    expectNoAsset("app|out.txt");
    buildShouldSucceed();
  });
}