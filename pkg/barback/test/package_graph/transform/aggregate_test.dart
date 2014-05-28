// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform.aggregate_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../utils.dart';

main() {
  initConfig();
  test("an aggregate transformer can read from multiple primary inputs", () {
    var sources = [
      "app|dir/foo.txt",
      "app|dir/bar.txt",
      "app|dir/baz.jpg",
      "app|dir/subdir/bang.txt",
      "app|dir/subdir/qux.txt",
      "app|dir/subdir/zap.png"
    ];

    initGraph(sources, {"app": [
      [new AggregateManyToOneTransformer("txt", "out.txt")]
    ]});

    updateSources(sources);
    expectAsset("app|dir/out.txt", "bar\nfoo");
    expectAsset("app|dir/subdir/out.txt", "bang\nqux");
    buildShouldSucceed();
  });

  test("an aggregate transformer isn't run if there are no primary inputs", () {
    var transformer = new AggregateManyToOneTransformer("txt", "out.txt");
    initGraph(["app|foo.zip", "app|bar.zap"], {"app": [
      [transformer]
    ]});

    updateSources(["app|foo.zip", "app|bar.zap"]);
    expectNoAsset("app|out.txt");
    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(0)));
  });

  test("an aggregate transformer is re-run if a primary input changes", () {
    initGraph(["app|foo.txt", "app|bar.txt"], {"app": [
      [new AggregateManyToOneTransformer("txt", "out.txt")]
    ]});

    updateSources(["app|foo.txt", "app|bar.txt"]);
    expectAsset("app|out.txt", "bar\nfoo");
    buildShouldSucceed();

    modifyAsset("app|foo.txt", "new foo");
    updateSources(["app|foo.txt"]);
    expectAsset("app|out.txt", "bar\nnew foo");
    buildShouldSucceed();
  });

  test("an aggregate transformer is re-run if a primary input is removed", () {
    initGraph(["app|foo.txt", "app|bar.txt"], {"app": [
      [new AggregateManyToOneTransformer("txt", "out.txt")]
    ]});

    updateSources(["app|foo.txt", "app|bar.txt"]);
    expectAsset("app|out.txt", "bar\nfoo");
    buildShouldSucceed();

    removeSources(["app|foo.txt"]);
    expectAsset("app|out.txt", "bar");
    buildShouldSucceed();
  });

  test("an aggregate transformer is re-run if a primary input is added", () {
    initGraph(["app|foo.txt", "app|bar.txt", "app|baz.txt"], {"app": [
      [new AggregateManyToOneTransformer("txt", "out.txt")]
    ]});

    updateSources(["app|foo.txt", "app|bar.txt"]);
    expectAsset("app|out.txt", "bar\nfoo");
    buildShouldSucceed();

    updateSources(["app|baz.txt"]);
    expectAsset("app|out.txt", "bar\nbaz\nfoo");
    buildShouldSucceed();
  });

  test("an aggregate transformer ceases to run if all primary inputs are "
      "removed", () {
    initGraph(["app|foo.txt", "app|bar.txt"], {"app": [
      [new AggregateManyToOneTransformer("txt", "out.txt")]
    ]});

    updateSources(["app|foo.txt", "app|bar.txt"]);
    expectAsset("app|out.txt", "bar\nfoo");
    buildShouldSucceed();

    removeSources(["app|foo.txt", "app|bar.txt"]);
    expectNoAsset("app|out.txt");
    buildShouldSucceed();
  });

  test("an aggregate transformer starts to run if new primary inputs are "
      "added", () {
    initGraph(["app|foo.txt", "app|bar.txt"], {"app": [
      [new AggregateManyToOneTransformer("txt", "out.txt")]
    ]});

    updateSources([]);
    expectNoAsset("app|out.txt");
    buildShouldSucceed();

    updateSources(["app|foo.txt", "app|bar.txt"]);
    expectAsset("app|out.txt", "bar\nfoo");
    buildShouldSucceed();
  });

  group("pass-through", () {
    test("an aggregate transformer passes through its primary inputs by "
        "default", () {
      initGraph(["app|foo.txt", "app|bar.txt"], {"app": [
        [new AggregateManyToOneTransformer("txt", "out.txt")]
      ]});

      updateSources(["app|foo.txt", "app|bar.txt"]);
      expectAsset("app|foo.txt", "foo");
      expectAsset("app|bar.txt", "bar");
      buildShouldSucceed();

      modifyAsset("app|foo.txt", "new foo");
      updateSources(["app|foo.txt"]);
      expectAsset("app|foo.txt", "new foo");
      buildShouldSucceed();
    });

    test("an aggregate transformer can overwrite its primary inputs", () {
      initGraph(["app|foo.txt", "app|bar.txt"], {"app": [
        [new AggregateManyToManyTransformer("txt")]
      ]});

      updateSources(["app|foo.txt", "app|bar.txt"]);
      expectAsset("app|foo.txt", "modified foo");
      expectAsset("app|bar.txt", "modified bar");
      buildShouldSucceed();
    });

    test("an aggregate transformer can consume its primary inputs", () {
      var transformer = new AggregateManyToOneTransformer("txt", "out.txt");
      transformer.consumePrimaries
          ..add("app|foo.txt")
          ..add("app|bar.txt");

      initGraph(["app|foo.txt", "app|bar.txt"], {"app": [[transformer]]});

      updateSources(["app|foo.txt", "app|bar.txt"]);
      expectNoAsset("app|foo.txt");
      expectNoAsset("app|bar.txt");
      buildShouldSucceed();
    });

    test("an aggregate transformer passes through non-primary inputs", () {
      initGraph(["app|foo.jpg", "app|bar.png"], {"app": [
        [new AggregateManyToManyTransformer("txt")]
      ]});

      updateSources(["app|foo.jpg", "app|bar.png"]);
      expectAsset("app|foo.jpg", "foo");
      expectAsset("app|bar.png", "bar");
      buildShouldSucceed();

      modifyAsset("app|foo.jpg", "new foo");
      updateSources(["app|foo.jpg"]);
      expectAsset("app|foo.jpg", "new foo");
      buildShouldSucceed();
    });
  });

  group("apply() transform stream", () {
    test("the primary input stream doesn't close if a previous phase is still "
        "running", () {
      var rewrite = new RewriteTransformer("a", "b");
      initGraph(["app|foo.txt", "app|bar.a"], {"app": [
        [rewrite],
        [new AggregateManyToOneTransformer("txt", "out.txt")]
      ]});

      rewrite.pauseApply();
      updateSources(["app|foo.txt", "app|bar.a"]);
      expectAssetDoesNotComplete("app|out.txt");

      rewrite.resumeApply();
      expectAsset("app|out.txt", "foo");
      buildShouldSucceed();
    });

    test("the primary input stream doesn't close if a previous phase is "
        "materializing a primary input", () {
      var rewrite = new DeclaringRewriteTransformer("in", "txt");
      initGraph(["app|foo.txt", "app|bar.in"], {"app": [
        [rewrite],
        [new AggregateManyToOneTransformer("txt", "out.txt")]
      ]});

      rewrite.pauseApply();
      updateSources(["app|foo.txt", "app|bar.in"]);
      expectAssetDoesNotComplete("app|out.txt");

      rewrite.resumeApply();
      expectAsset("app|out.txt", "bar.txt\nfoo");
      buildShouldSucceed();
    });

    test("the primary input stream closes if a previous phase is only "
        "materializing non-primary inputs", () {
      var rewrite = new DeclaringRewriteTransformer("a", "b");
      initGraph(["app|foo.txt", "app|bar.a"], {"app": [
        [rewrite],
        [new AggregateManyToOneTransformer("txt", "out.txt")]
      ]});

      rewrite.pauseApply();
      updateSources(["app|foo.txt", "app|bar.a"]);
      expectAsset("app|out.txt", "foo");

      rewrite.resumeApply();
      buildShouldSucceed();
    });

    test("a new primary input that arrives before the stream closes doesn't "
        "cause apply to restart", () {
      var rewrite = new RewriteTransformer("a", "b");
      var aggregate = new AggregateManyToOneTransformer("txt", "out.txt");
      initGraph(["app|foo.txt", "app|bar.txt", "app|baz.a"], {"app": [
        [rewrite],
        [aggregate]
      ]});

      // The stream won't close until [rewrite] finishes running `apply()`.
      rewrite.pauseApply();

      updateSources(["app|foo.txt", "app|baz.a"]);
      expectAssetDoesNotComplete("app|out.txt");

      updateSources(["app|bar.txt"]);
      expectAssetDoesNotComplete("app|out.txt");

      rewrite.resumeApply();
      expectAsset("app|out.txt", "bar\nfoo");
      buildShouldSucceed();

      expect(aggregate.numRuns, completion(equals(1)));
    });

    test("a new primary input that arrives after the stream closes causes "
        "apply to restart", () {
      var aggregate = new AggregateManyToOneTransformer("txt", "out.txt");
      initGraph(["app|foo.txt", "app|bar.txt"], {"app": [[aggregate]]});

      aggregate.pauseApply();
      updateSources(["app|foo.txt"]);
      expectAssetDoesNotComplete("app|out.txt");

      updateSources(["app|bar.txt"]);
      expectAssetDoesNotComplete("app|out.txt");

      aggregate.resumeApply();
      expectAsset("app|out.txt", "bar\nfoo");
      buildShouldSucceed();

      expect(aggregate.numRuns, completion(equals(2)));
    });

    test("a primary input that's modified before the stream closes causes "
        "apply to restart", () {
      var rewrite = new RewriteTransformer("a", "b");
      var aggregate = new AggregateManyToOneTransformer("txt", "out.txt");
      initGraph(["app|foo.txt", "app|bar.a"], {"app": [
        [rewrite],
        [aggregate]
      ]});

      // The stream won't close until [rewrite] finishes running `apply()`.
      rewrite.pauseApply();

      updateSources(["app|foo.txt", "app|bar.a"]);
      expectAssetDoesNotComplete("app|out.txt");

      modifyAsset("app|foo.txt", "new foo");
      updateSources(["app|foo.txt"]);
      expectAssetDoesNotComplete("app|out.txt");

      rewrite.resumeApply();
      expectAsset("app|out.txt", "new foo");
      buildShouldSucceed();

      expect(aggregate.numRuns, completion(equals(2)));
    });

    test("a primary input that's removed before the stream closes causes apply "
        "to restart", () {
      var rewrite = new RewriteTransformer("a", "b");
      var aggregate = new AggregateManyToOneTransformer("txt", "out.txt");
      initGraph(["app|foo.txt", "app|bar.txt", "app|baz.a"], {"app": [
        [rewrite],
        [aggregate]
      ]});

      // The stream won't close until [rewrite] finishes running `apply()`.
      rewrite.pauseApply();

      updateSources(["app|foo.txt", "app|bar.txt", "app|baz.a"]);
      expectAssetDoesNotComplete("app|out.txt");

      removeSources(["app|bar.txt"]);
      expectAssetDoesNotComplete("app|out.txt");

      rewrite.resumeApply();
      expectAsset("app|out.txt", "foo");
      buildShouldSucceed();

      expect(aggregate.numRuns, completion(equals(2)));
    });
  });
}