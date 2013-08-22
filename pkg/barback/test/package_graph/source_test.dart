// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.package_graph.source_test;

import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

main() {
  initConfig();
  test("gets a source asset", () {
    initGraph(["app|foo.txt"]);
    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("doesn't get an unknown source", () {
    initGraph();
    expectNoAsset("app|unknown.txt");
  });

  test("doesn't get an unprovided source", () {
    initGraph();
    updateSources(["app|unknown.txt"]);
    expectNoAsset("app|unknown.txt");
  });

  test("doesn't get an asset that isn't an updated source", () {
    initGraph(["app|foo.txt"]);

    // Sources must be explicitly made visible to barback by calling
    // updateSources() on them. It isn't enough for the provider to be able
    // to provide it.
    //
    // This lets you distinguish between sources that you want to be primaries
    // and the larger set of inputs that those primaries are allowed to pull in.
    expectNoAsset("app|foo.txt");
  });

  test("gets a source asset if not transformed", () {
    initGraph(["app|foo.txt"], {"app": [
      [new RewriteTransformer("nottxt", "whatever")]
    ]});

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("doesn't get a removed source", () {
    initGraph(["app|foo.txt"]);

    updateSources(["app|foo.txt"]);
    expectAsset("app|foo.txt");
    buildShouldSucceed();

    removeSources(["app|foo.txt"]);
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("collapses redundant updates", () {
    var transformer = new RewriteTransformer("blub", "blab");
    initGraph(["app|foo.blub"], {"app": [[transformer]]});

    schedule(() {
      // Make a bunch of synchronous update calls.
      updateSourcesSync(["app|foo.blub"]);
      updateSourcesSync(["app|foo.blub"]);
      updateSourcesSync(["app|foo.blub"]);
      updateSourcesSync(["app|foo.blub"]);
    });

    expectAsset("app|foo.blab", "foo.blab");
    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(1)));
  });

  test("a removal cancels out an update", () {
    initGraph(["app|foo.txt"]);

    schedule(() {
      updateSourcesSync(["app|foo.txt"]);
      removeSourcesSync(["app|foo.txt"]);
    });

    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("an update cancels out a removal", () {
    initGraph(["app|foo.txt"]);

    schedule(() {
      removeSourcesSync(["app|foo.txt"]);
      updateSourcesSync(["app|foo.txt"]);
    });

    expectAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("reloads an asset that's updated while loading", () {
    initGraph({"app|foo.txt": "foo"});

    pauseProvider();
    // The mock provider synchronously loads the value of the assets, so this
    // will kick off two loads with different values. The second one should
    // win.
    updateSources(["app|foo.txt"]);
    modifyAsset("app|foo.txt", "bar");
    updateSources(["app|foo.txt"]);

    resumeProvider();
    expectAsset("app|foo.txt", "bar");
    buildShouldSucceed();
  });

  test("restarts a build if a source is updated while sources are loading", () {
    var transformer = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt", "app|other.bar"], {"app": [[transformer]]});

    // Run the whole graph so all nodes are clean.
    updateSources(["app|foo.txt", "app|other.bar"]);
    expectAsset("app|foo.out", "foo.out");
    expectAsset("app|other.bar");

    buildShouldSucceed();

    // Make the provider slow to load a source.
    pauseProvider();

    // Update an asset that doesn't trigger any transformers.
    updateSources(["app|other.bar"]);

    // Now update an asset that does trigger a transformer.
    updateSources(["app|foo.txt"]);

    resumeProvider();

    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(2)));
  });
}
