// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.transform.declaring_aggregate_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../utils.dart';

main() {
  initConfig();
  group("a declaring aggregate transformer", () {
    test("is eager by default", () {
      var transformer = new DeclaringAggregateManyToOneTransformer(
          "txt", "out.txt");
      initGraph(["app|foo.txt"], {"app": [[transformer]]});

      updateSources(["app|foo.txt"]);
      buildShouldSucceed();

      expect(transformer.numRuns, completion(equals(1)));
    });

    test("is deferred if any primary input is deferred", () {
      var rewrite = new LazyRewriteTransformer("in", "txt");
      var aggregate = new DeclaringAggregateManyToOneTransformer(
          "txt", "out.txt");
      initGraph(["app|foo.in", "app|bar.txt", "app|baz.txt"], {"app": [
        [rewrite]
      ]});

      updateSources(["app|foo.in", "app|bar.txt", "app|baz.txt"]);
      buildShouldSucceed();

      // Add [aggregate] to the graph after a build has been completed so that
      // all its inputs are available immediately. Otherwise it could start
      // applying eagerly before receiving its lazy input.
      updateTransformers("app", [[rewrite], [aggregate]]);
      buildShouldSucceed();
      expect(aggregate.numRuns, completion(equals(0)));

      expectAsset("app|out.txt", "bar\nbaz\nfoo.txt");
      buildShouldSucceed();
      expect(aggregate.numRuns, completion(equals(1)));
    });

    test("switches from eager to deferred if a deferred primary input is added",
        () {
      var transformer = new DeclaringAggregateManyToOneTransformer(
          "txt", "out.txt");
      initGraph(["app|foo.in", "app|bar.txt", "app|baz.txt"], {"app": [
        [new LazyRewriteTransformer("in", "txt")],
        [transformer]
      ]});

      updateSources(["app|bar.txt", "app|baz.txt"]);
      buildShouldSucceed();
      expect(transformer.numRuns, completion(equals(1)));

      updateSources(["app|foo.in"]);
      buildShouldSucceed();
      expect(transformer.numRuns, completion(equals(1)));

      expectAsset("app|out.txt", "bar\nbaz\nfoo.txt");
      buildShouldSucceed();
      expect(transformer.numRuns, completion(equals(2)));
    });

    test("switches from deferred to eager if its last deferred primary input "
        "is removed", () {
      var rewrite = new LazyRewriteTransformer("in", "txt");
      var aggregate = new DeclaringAggregateManyToOneTransformer(
          "txt", "out.txt");
      initGraph(["app|foo.in", "app|bar.txt", "app|baz.txt"], {"app": [
        [rewrite]
      ]});

      updateSources(["app|foo.in", "app|bar.txt", "app|baz.txt"]);
      buildShouldSucceed();

      // Add [aggregate] to the graph after a build has been completed so that
      // all its inputs are available immediately. Otherwise it could start
      // applying eagerly before receiving its lazy input.
      updateTransformers("app", [[rewrite], [aggregate]]);
      buildShouldSucceed();
      expect(aggregate.numRuns, completion(equals(0)));

      removeSources(["app|foo.in"]);
      buildShouldSucceed();
      expect(aggregate.numRuns, completion(equals(1)));
    });

    test("begins running eagerly when all its deferred primary inputs become "
        "available", () {
      var lazyPhase = [
        new LazyAssetsTransformer(["app|foo.txt", "app|foo.x"],
            input: "app|foo.in"),
        new LazyAssetsTransformer(["app|bar.txt", "app|bar.x"],
            input: "app|bar.in")
      ];
      var transformer = new DeclaringAggregateManyToOneTransformer(
          "txt", "out.txt");
      initGraph(["app|foo.in", "app|bar.in", "app|baz.txt"], {"app": [
        lazyPhase,
      ]});

      updateSources(["app|foo.in", "app|bar.in", "app|baz.txt"]);
      buildShouldSucceed();

      // Add [transformer] to the graph after a build has been completed so that
      // all its inputs are available immediately. Otherwise it could start
      // applying eagerly before receiving its lazy inputs.
      updateTransformers("app", [lazyPhase, [transformer]]);
      buildShouldSucceed();
      expect(transformer.numRuns, completion(equals(0)));

      // Now "app|foo.txt" will be available, but "app|bar.txt" won't, so the
      // [transformer] shouldn't run.
      expectAsset("app|foo.x", "app|foo.x");
      buildShouldSucceed();
      expect(transformer.numRuns, completion(equals(0)));

      // Now "app|foo.txt" and "app|bar.txt" will both be available, so the
      // [transformer] should run.
      expectAsset("app|bar.x", "app|bar.x");
      buildShouldSucceed();
      expect(transformer.numRuns, completion(equals(1)));
    });

    test("stops running eagerly when any of its deferred primary inputs become "
        "unavailable", () {
      var lazyPhase = [
        new LazyAssetsTransformer(["app|foo.txt", "app|foo.x"],
            input: "app|foo.in"),
        new LazyAssetsTransformer(["app|bar.txt", "app|bar.x"],
            input: "app|bar.in")
      ];
      var transformer = new DeclaringAggregateManyToOneTransformer(
          "txt", "out.txt");
      initGraph(["app|foo.in", "app|bar.in", "app|baz.txt"], {"app": [
        lazyPhase
      ]});

      updateSources(["app|foo.in", "app|bar.in", "app|baz.txt"]);
      expectAsset("app|foo.x", "app|foo.x");
      expectAsset("app|bar.x", "app|bar.x");
      buildShouldSucceed();

      // Add [transformer] to the graph after a build has been completed so that
      // all its inputs are available immediately. Otherwise it could start
      // applying eagerly before receiving its lazy inputs.
      updateTransformers("app", [lazyPhase, [transformer]]);
      buildShouldSucceed();
      expect(transformer.numRuns, completion(equals(1)));

      // Now "app|foo.txt" is unavailable, so the [transformer] shouldn't run.
      updateSources(["app|foo.in"]);
      buildShouldSucceed();
      expect(transformer.numRuns, completion(equals(1)));
    });

    test("re-declares its outputs for a new primary input", () {
      initGraph(["app|foo.in", "app|bar.txt", "app|baz.txt"], {"app": [
        [new LazyRewriteTransformer("in", "txt")],
        [new DeclaringAggregateManyToManyTransformer("txt")]
      ]});

      updateSources(["app|foo.in", "app|bar.txt"]);
      buildShouldSucceed();

      updateSources(["app|baz.txt"]);
      buildShouldSucceed();

      // If the aggregate transformer didn't re-declare its outputs upon getting
      // a new primary input, getting "baz.txt" wouldn't trigger an apply and
      // would just return the unmodified baz.
      expectAsset("app|baz.txt", "modified baz");
    });

    test("re-declares its outputs for a new primary input received while "
        "applying", () {
      var transformer = new DeclaringAggregateManyToManyTransformer("txt");
      initGraph(["app|foo.in", "app|bar.txt", "app|baz.txt"], {"app": [
        [new LazyRewriteTransformer("in", "txt")],
        [transformer]
      ]});

      transformer.pauseApply();
      updateSources(["app|foo.in", "app|bar.txt"]);

      // Ensure we're waiting on `apply()`.
      schedule(pumpEventQueue);

      updateSources(["app|baz.txt"]);
      transformer.resumeApply();
      buildShouldSucceed();

      expectAsset("app|baz.txt", "modified baz");
    });

    test("re-declares its outputs for a new primary input received while "
        "applying after a primary input was modified", () {
      var transformer = new DeclaringAggregateManyToManyTransformer("txt");
      initGraph(["app|foo.in", "app|bar.txt", "app|baz.txt"], {"app": [
        [new LazyRewriteTransformer("in", "txt")],
        [transformer]
      ]});

      transformer.pauseApply();
      updateSources(["app|foo.in", "app|bar.txt"]);

      // Ensure we're waiting on `apply()`.
      schedule(pumpEventQueue);

      updateSources(["app|bar.txt"]);

      // Make sure the change to "bar.txt" is fully processed.
      schedule(pumpEventQueue);

      updateSources(["app|baz.txt"]);
      transformer.resumeApply();
      buildShouldSucceed();

      expectAsset("app|baz.txt", "modified baz");
    });
  });

  group("a lazy aggregate transformer", () {
    test("doesn't run eagerly", () {
      var transformer = new LazyAggregateManyToOneTransformer("txt", "out.txt");
      initGraph(["app|foo.txt"], {"app": [[transformer]]});

      updateSources(["app|foo.txt"]);
      buildShouldSucceed();

      expect(transformer.numRuns, completion(equals(0)));
    });

    test("runs when an output is requested", () {
      initGraph(["app|foo.txt"], {"app": [[
        new LazyAggregateManyToOneTransformer("txt", "out.txt")
      ]]});

      updateSources(["app|foo.txt"]);
      buildShouldSucceed();
      expectAsset("app|out.txt", "foo");
    });
  });
}
