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