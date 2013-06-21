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

  test("errors if two transformers output the same file", () {
    var provider = new MockProvider(["app|foo.a"]);
    var graph = new AssetGraph(provider, [
      [
        new RewriteTransformer("a", "b"),
        new RewriteTransformer("a", "b")
      ]
    ]);
    graph.updateSources([new AssetId.parse("app|foo.a")]);

    expectCollision(graph, "app|foo.b");
  });

  test("reports asset not found errors in results", () {
    var provider = new MockProvider([]);
    var graph = new AssetGraph(provider, []);

    // TODO(rnystrom): This is verbose and ugly. Better would be to have
    // utils.dart register this on the graph and then have functions to expect
    // certain build results.
    var numResults = 0;
    var gotError = false;
    graph.results.listen(wrapAsync((result) {
      numResults++;
      expect(numResults, lessThan(3));

      if (numResults == 1) {
        // Should complete the build first.
        expect(result.error, isNull);
      } else if (numResults == 2) {
        // Then have the error.
        expect(result.error, new isInstanceOf<AssetNotFoundException>());
        expect(result.error.id, equals(new AssetId.parse("app|foo.txt")));
        gotError = true;
      }
    }));

    expectNoAsset(graph, "app|foo.txt");

    schedule(() {
      expect(gotError, isTrue);
    });
  });

  test("reports an error for an unprovided source", () {
    var provider = new MockProvider([]);
    var graph = new AssetGraph(provider, []);
    var resultFuture = graph.results.first;

    graph.updateSources([new AssetId.parse("app|unknown.txt")]);

    schedule(() {
      return resultFuture.then((result) {
        expect(result.error, new isInstanceOf<AssetNotFoundException>());
        expect(result.error.id, equals(new AssetId.parse("app|unknown.txt")));
      });
    });
  });

  test("reports missing input errors in results", () {
    var provider = new MockProvider({"app|a.txt": "a.inc"});

    var graph = new AssetGraph(provider, [
      [new ManyToOneTransformer("txt")]
    ]);

    var gotError = false;
    graph.results.listen(wrapAsync((result) {
      expect(result.error is MissingInputException, isTrue);
      expect(result.error.id, equals(new AssetId.parse("app|a.inc")));
      gotError = true;
    }));

    graph.updateSources([new AssetId.parse("app|a.txt")]);

    expectNoAsset(graph, "app|a.out");

    schedule(() {
      expect(gotError, isTrue);
    });
  });

  test("fails if a non-primary input is removed", () {
    var provider = new MockProvider({
      "app|a.txt": "a.inc,b.inc,c.inc",
      "app|a.inc": "a",
      "app|b.inc": "b",
      "app|c.inc": "c"
    });

    var graph = new AssetGraph(provider, [
      [new ManyToOneTransformer("txt")]
    ]);

    // TODO(rnystrom): This is verbose and ugly. Better would be to have
    // utils.dart register this on the graph and then have functions to expect
    // certain build results.
    var numResults = 0;
    var gotError = false;
    graph.results.listen(wrapAsync((result) {
      numResults++;
      expect(numResults, lessThan(3));

      if (numResults == 1) {
        // Should complete the build first.
        expect(result.error, isNull);
      } else if (numResults == 2) {
        // Then have the error.
        expect(result.error is MissingInputException, isTrue);
        expect(result.error.id, equals(new AssetId.parse("app|b.inc")));
        gotError = true;
      }
    }));

    graph.updateSources([
      new AssetId.parse("app|a.txt"),
      new AssetId.parse("app|a.inc"),
      new AssetId.parse("app|b.inc"),
      new AssetId.parse("app|c.inc")
    ]);

    expectAsset(graph, "app|a.out", "abc");

    schedule(() {
      graph.removeSources([new AssetId.parse("app|b.inc")]);
    });

    expectNoAsset(graph, "app|a.out");

    schedule(() {
      expect(gotError, isTrue);
    });
  });

  test("catches transformer exceptions and reports them", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, [
      [new BadTransformer(["app|foo.out"])]
    ]);

    var gotError = false;
    graph.results.listen(wrapAsync((result) {
      expect(result.error, equals(BadTransformer.ERROR));
      gotError = true;
    }));

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.txt")]);
    });

    expectNoAsset(graph, "app|foo.out");

    schedule(() {
      expect(gotError, isTrue);
    });
  });

  // TODO(rnystrom): Is this the behavior we expect? If a transformer fails
  // to transform a file, should we just skip past it to the source?
  test("yields a source if a transform fails on it", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, [
      [new BadTransformer(["app|foo.txt"])]
    ]);

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.txt")]);
    });

    expectAsset(graph, "app|foo.txt");
  });

  test("catches errors even if nothing is waiting for process results", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, [[new BadTransformer([])]]);
    var resultFuture = graph.results.first;

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.txt")]);
    });

    // Note: No asset requests here.

    schedule(() {
      return resultFuture.then((result) {
        expect(result.error, equals(BadTransformer.ERROR));
      });
    });
  });

  test("discards outputs from failed transforms", () {
    var provider = new MockProvider(["app|foo.txt"]);
    var graph = new AssetGraph(provider, [
      [new BadTransformer(["a.out", "b.out"])]
    ]);

    schedule(() {
      graph.updateSources([new AssetId.parse("app|foo.txt")]);
    });

    expectNoAsset(graph, "app|a.out");
  });
}
