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
    initGraph(["app|foo.a"], [
      [
        new RewriteTransformer("a", "b"),
        new RewriteTransformer("a", "b")
      ]
    ]);
    updateSources(["app|foo.a"]);

    expectCollision("app|foo.b");
  });

  test("does not report asset not found errors in results", () {
    initGraph();

    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("reports an error for an unprovided source", () {
    initGraph();
    updateSources(["app|unknown.txt"]);

    buildShouldFail((error) {
      expect(error, new isInstanceOf<AssetNotFoundException>());
      expect(error.id, equals(new AssetId.parse("app|unknown.txt")));
    });
  });

  test("reports missing input errors in results", () {
    initGraph({"app|a.txt": "a.inc"}, [
      [new ManyToOneTransformer("txt")]
    ]);

    buildShouldFail((error) {
      expect(error, new isInstanceOf<MissingInputException>());
      expect(error.id, equals(new AssetId.parse("app|a.inc")));
    });

    updateSources(["app|a.txt"]);

    expectNoAsset("app|a.out");
  });

  test("fails if a non-primary input is removed", () {
    initGraph({
      "app|a.txt": "a.inc,b.inc,c.inc",
      "app|a.inc": "a",
      "app|b.inc": "b",
      "app|c.inc": "c"
    }, [
      [new ManyToOneTransformer("txt")]
    ]);

    updateSources(["app|a.txt", "app|a.inc", "app|b.inc", "app|c.inc"]);
    expectAsset("app|a.out", "abc");
    buildShouldSucceed();

    schedule(() {
      removeSources(["app|b.inc"]);
    });

    buildShouldFail((error) {
      expect(error, new isInstanceOf<MissingInputException>());
      expect(error.id, equals(new AssetId.parse("app|b.inc")));
    });
    expectNoAsset("app|a.out");
  });

  test("catches transformer exceptions and reports them", () {
    initGraph(["app|foo.txt"], [
      [new BadTransformer(["app|foo.out"])]
    ]);

    schedule(() {
      updateSources(["app|foo.txt"]);
    });

    expectNoAsset("app|foo.out");

    buildShouldFail((error) {
      expect(error, equals(BadTransformer.ERROR));
    });
  });

  // TODO(rnystrom): Is this the behavior we expect? If a transformer fails
  // to transform a file, should we just skip past it to the source?
  test("yields a source if a transform fails on it", () {
    initGraph(["app|foo.txt"], [
      [new BadTransformer(["app|foo.txt"])]
    ]);

    schedule(() {
      updateSources(["app|foo.txt"]);
    });

    expectAsset("app|foo.txt");
  });

  test("catches errors even if nothing is waiting for process results", () {
    initGraph(["app|foo.txt"], [[new BadTransformer([])]]);

    schedule(() {
      updateSources(["app|foo.txt"]);
    });

    // Note: No asset requests here.

    buildShouldFail((error) {
      expect(error, equals(BadTransformer.ERROR));
    });
  });

  test("discards outputs from failed transforms", () {
    initGraph(["app|foo.txt"], [
      [new BadTransformer(["a.out", "b.out"])]
    ]);

    schedule(() {
      updateSources(["app|foo.txt"]);
    });

    expectNoAsset("app|a.out");
  });
}
