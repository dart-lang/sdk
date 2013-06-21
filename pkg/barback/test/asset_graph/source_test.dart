// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.asset_graph.source_test;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/asset_graph.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();
  test("gets a source asset", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, []);
    graph.updateSources([new AssetId.parse("app|foo.txt")]);

    expectAsset(graph, "app|foo.txt");
  });

  test("doesn't get an unknown source", () {
    var provider = new MockProvider([]);
    var graph = new AssetGraph(provider, []);

    expectNoAsset(graph, "app|unknown.txt");
  });

  test("doesn't get an unprovided source", () {
    var provider = new MockProvider([]);
    var graph = new AssetGraph(provider, []);

    graph.updateSources([new AssetId.parse("app|unknown.txt")]);
    expectNoAsset(graph, "app|unknown.txt");
  });

  test("doesn't get an asset that isn't an updated source", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, []);

    // Sources must be explicitly made visible to barback by calling
    // updateSources() on them. It isn't enough for the provider to be able
    // to provide it.
    //
    // This lets you distinguish between sources that you want to be primaries
    // and the larger set of inputs that those primaries are allowed to pull in.
    expectNoAsset(graph, "app|foo.txt");
  });

  test("gets a source asset if not transformed", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, [
      [new RewriteTransformer("nottxt", "whatever")]
    ]);
    graph.updateSources([new AssetId.parse("app|foo.txt")]);

    expectAsset(graph, "app|foo.txt");
  });

  test("doesn't get a removed source", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, [[]]);
    graph.updateSources([new AssetId.parse("app|foo.txt")]);

    expectAsset(graph, "app|foo.txt");

    schedule(() {
      graph.removeSources([new AssetId.parse("app|foo.txt")]);
    });

    expectNoAsset(graph, "app|foo.txt");
  });

  test("collapses redundant updates", () {
    var provider = new MockProvider(["app|foo.blub"]);
    var transformer = new RewriteTransformer("blub", "blab");
    var graph = new AssetGraph(provider, [[transformer]]);

    schedule(() {
      // Make a bunch of synchronous update calls.
      graph.updateSources([new AssetId.parse("app|foo.blub")]);
      graph.updateSources([new AssetId.parse("app|foo.blub")]);
      graph.updateSources([new AssetId.parse("app|foo.blub")]);
      graph.updateSources([new AssetId.parse("app|foo.blub")]);
    });

    expectAsset(graph, "app|foo.blab", "foo.blab");

    schedule(() {
      expect(transformer.numRuns, equals(1));
    });
  });

  test("a removal cancels out an update", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, [[]]);

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.txt")]);
      graph.removeSources([new AssetId.parse("app|foo.txt")]);
    });

    expectNoAsset(graph, "app|foo.txt");
  });

  test("an update cancels out a removal", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, [[]]);

    schedule(() {
      graph.removeSources([new AssetId.parse("app|foo.txt")]);
      graph.updateSources([new AssetId.parse("app|foo.txt")]);
    });

    expectAsset(graph, "app|foo.txt");
  });

  test("restarts a build if a source is updated while sources are loading", () {
    var provider = new MockProvider(["app|foo.txt", "app|other.bar"]);
    var transformer = new RewriteTransformer("txt", "out");
    var graph = new AssetGraph(provider, [[transformer]]);

    var numBuilds = 0;
    var buildCompleter = new Completer();
    graph.results.listen(wrapAsync((result) {
      expect(result.error, isNull);
      numBuilds++;

      // There should be two builds, one for each update call.
      if (numBuilds == 2) buildCompleter.complete();
    }));

    // Run the whole graph so all nodes are clean.
    graph.updateSources([
      new AssetId.parse("app|foo.txt"),
      new AssetId.parse("app|other.bar")
    ]);
    expectAsset(graph, "app|foo.out", "foo.out");
    expectAsset(graph, "app|other.bar");

    schedule(() {
      // Make the provider slow to load a source.
      provider.wait();

      // Update an asset that doesn't trigger any transformers.
      graph.updateSources([new AssetId.parse("app|other.bar")]);
    });

    schedule(() {
      // Now update an asset that does trigger a transformer.
      graph.updateSources([new AssetId.parse("app|foo.txt")]);
    });

    schedule(() {
      provider.complete();
    });

    schedule(() {
      // Wait until the build has completed.
      return buildCompleter.future;
    });

    schedule(() {
      expect(transformer.numRuns, equals(2));
    });
  });
}
