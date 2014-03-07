// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains tests for transformer behavior that relates to actions
/// happening concurrently or other complex asynchronous timing behavior.
library barback.test.package_graph.transform.concurrency_test;

import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../utils.dart';

main() {
  initConfig();
  test("runs transforms in the same phase in parallel", () {
    var transformerA = new RewriteTransformer("txt", "a");
    var transformerB = new RewriteTransformer("txt", "b");
    initGraph(["app|foo.txt"], {"app": [[transformerA, transformerB]]});

    transformerA.pauseApply();
    transformerB.pauseApply();

    updateSources(["app|foo.txt"]);

    transformerA.waitUntilStarted();
    transformerB.waitUntilStarted();

    // They should both still be running.
    expect(transformerA.isRunning, completion(isTrue));
    expect(transformerB.isRunning, completion(isTrue));

    transformerA.resumeApply();
    transformerB.resumeApply();

    expectAsset("app|foo.a", "foo.a");
    expectAsset("app|foo.b", "foo.b");
    buildShouldSucceed();
  });

  test("discards outputs from a transform whose primary input is removed "
      "during processing", () {
    var rewrite = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[rewrite]]});

    rewrite.pauseApply();
    updateSources(["app|foo.txt"]);
    rewrite.waitUntilStarted();

    removeSources(["app|foo.txt"]);
    rewrite.resumeApply();
    expectNoAsset("app|foo.out");
    buildShouldSucceed();
  });

  test("applies the correct transform if an asset is modified during isPrimary",
      () {
    var check1 = new CheckContentTransformer("first", "#1");
    var check2 = new CheckContentTransformer("second", "#2");
    initGraph({
      "app|foo.txt": "first",
    }, {"app": [[check1, check2]]});

    check1.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Ensure that we're waiting on check1's isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "second");
    updateSources(["app|foo.txt"]);
    check1.resumeIsPrimary("app|foo.txt");

    expectAsset("app|foo.txt", "second#2");
    buildShouldSucceed();
  });

  test("applies the correct transform if an asset is removed and added during "
      "isPrimary", () {
    var check1 = new CheckContentTransformer("first", "#1");
    var check2 = new CheckContentTransformer("second", "#2");
    initGraph({
      "app|foo.txt": "first",
    }, {"app": [[check1, check2]]});

    check1.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Ensure that we're waiting on check1's isPrimary.
    schedule(pumpEventQueue);

    removeSources(["app|foo.txt"]);
    modifyAsset("app|foo.txt", "second");
    updateSources(["app|foo.txt"]);
    check1.resumeIsPrimary("app|foo.txt");

    expectAsset("app|foo.txt", "second#2");
    buildShouldSucceed();
  });

  test("restarts processing if a change occurs during processing", () {
    var transformer = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[transformer]]});

    transformer.pauseApply();

    updateSources(["app|foo.txt"]);
    transformer.waitUntilStarted();

    // Now update the graph during it.
    updateSources(["app|foo.txt"]);
    transformer.resumeApply();

    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(2)));
  });

  test("aborts processing if the primary input is removed during processing",
      () {
    var transformer = new RewriteTransformer("txt", "out");
    initGraph(["app|foo.txt"], {"app": [[transformer]]});

    transformer.pauseApply();

    updateSources(["app|foo.txt"]);
    transformer.waitUntilStarted();

    // Now remove its primary input while it's running.
    removeSources(["app|foo.txt"]);
    transformer.resumeApply();

    expectNoAsset("app|foo.out");
    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(1)));
  });

  test("restarts processing if a change to a new secondary input occurs during "
      "processing", () {
    var transformer = new ManyToOneTransformer("txt");
    initGraph({
      "app|foo.txt": "bar.inc",
      "app|bar.inc": "bar"
    }, {"app": [[transformer]]});

    transformer.pauseApply();

    updateSources(["app|foo.txt", "app|bar.inc"]);
    transformer.waitUntilStarted();

    // Give the transform time to load bar.inc the first time.
    schedule(pumpEventQueue);

    // Now update the secondary input before the transform finishes.
    modifyAsset("app|bar.inc", "baz");
    updateSources(["app|bar.inc"]);
    // Give bar.inc enough time to be loaded and marked available before the
    // transformer completes.
    schedule(pumpEventQueue);

    transformer.resumeApply();

    expectAsset("app|foo.out", "baz");
    buildShouldSucceed();

    expect(transformer.numRuns, completion(equals(2)));
  });

  test("doesn't restart processing if a change to an old secondary input "
      "occurs during processing", () {
    var transformer = new ManyToOneTransformer("txt");
    initGraph({
      "app|foo.txt": "bar.inc",
      "app|bar.inc": "bar",
      "app|baz.inc": "baz"
    }, {"app": [[transformer]]});

    updateSources(["app|foo.txt", "app|bar.inc", "app|baz.inc"]);
    expectAsset("app|foo.out", "bar");
    buildShouldSucceed();

    transformer.pauseApply();
    modifyAsset("app|foo.txt", "baz.inc");
    updateSources(["app|foo.txt"]);
    transformer.waitUntilStarted();

    // Now update the old secondary input before the transform finishes.
    modifyAsset("app|bar.inc", "new bar");
    updateSources(["app|bar.inc"]);
    // Give bar.inc enough time to be loaded and marked available before the
    // transformer completes.
    schedule(pumpEventQueue);

    transformer.resumeApply();
    expectAsset("app|foo.out", "baz");
    buildShouldSucceed();

    // Should have run once the first time, then again when switching to
    // baz.inc. Should not run a third time because of bar.inc being modified.
    expect(transformer.numRuns, completion(equals(2)));
  });

  test("restarts before finishing later phases when a change occurs", () {
    var txtToInt = new RewriteTransformer("txt", "int");
    var intToOut = new RewriteTransformer("int", "out");
    initGraph(["app|foo.txt", "app|bar.txt"],
        {"app": [[txtToInt], [intToOut]]});

    txtToInt.pauseApply();

    updateSources(["app|foo.txt"]);
    txtToInt.waitUntilStarted();

    // Now update the graph during it.
    updateSources(["app|bar.txt"]);
    txtToInt.resumeApply();

    expectAsset("app|foo.out", "foo.int.out");
    expectAsset("app|bar.out", "bar.int.out");
    buildShouldSucceed();

    // Should only have run each transform once for each primary.
    expect(txtToInt.numRuns, completion(equals(2)));
    expect(intToOut.numRuns, completion(equals(2)));
  });

  test("doesn't return an asset until it's finished rebuilding", () {
    initGraph(["app|foo.in"], {"app": [
      [new RewriteTransformer("in", "mid")],
      [new RewriteTransformer("mid", "out")]
    ]});

    updateSources(["app|foo.in"]);
    expectAsset("app|foo.out", "foo.mid.out");
    buildShouldSucceed();

    pauseProvider();
    modifyAsset("app|foo.in", "new");
    updateSources(["app|foo.in"]);
    expectAssetDoesNotComplete("app|foo.out");
    buildShouldNotBeDone();

    resumeProvider();
    expectAsset("app|foo.out", "new.mid.out");
    buildShouldSucceed();
  });

  test("doesn't return an asset until its in-place transform is done", () {
    var rewrite = new RewriteTransformer("txt", "txt");
    initGraph(["app|foo.txt"], {"app": [[rewrite]]});

    rewrite.pauseApply();
    updateSources(["app|foo.txt"]);
    expectAssetDoesNotComplete("app|foo.txt");

    rewrite.resumeApply();
    expectAsset("app|foo.txt", "foo.txt");
    buildShouldSucceed();
  });

  test("doesn't return an asset that's removed during isPrimary", () {
    var rewrite = new RewriteTransformer("txt", "txt");
    initGraph(["app|foo.txt"], {"app": [[rewrite]]});

    rewrite.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Make sure we're waiting on isPrimary.
    schedule(pumpEventQueue);

    removeSources(["app|foo.txt"]);
    rewrite.resumeIsPrimary("app|foo.txt");
    expectNoAsset("app|foo.txt");
    buildShouldSucceed();
  });

  test("doesn't transform an asset that goes from primary to non-primary "
      "during isPrimary", () {
    var check = new CheckContentTransformer(new RegExp(r"^do$"), "ne");
    initGraph({
      "app|foo.txt": "do"
    }, {"app": [[check]]});

    check.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Make sure we're waiting on isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "don't");
    updateSources(["app|foo.txt"]);
    check.resumeIsPrimary("app|foo.txt");

    expectAsset("app|foo.txt", "don't");
    buildShouldSucceed();
  });

  test("transforms an asset that goes from non-primary to primary "
      "during isPrimary", () {
    var check = new CheckContentTransformer("do", "ne");
    initGraph({
      "app|foo.txt": "don't"
    }, {"app": [[check]]});

    check.pauseIsPrimary("app|foo.txt");
    updateSources(["app|foo.txt"]);
    // Make sure we're waiting on isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "do");
    updateSources(["app|foo.txt"]);
    check.resumeIsPrimary("app|foo.txt");

    expectAsset("app|foo.txt", "done");
    buildShouldSucceed();
  });

  test("doesn't return an asset that's removed during another transformer's "
      "isPrimary", () {
    var rewrite1 = new RewriteTransformer("txt", "txt");
    var rewrite2 = new RewriteTransformer("md", "md");
    initGraph(["app|foo.txt", "app|foo.md"], {"app": [[rewrite1, rewrite2]]});

    rewrite2.pauseIsPrimary("app|foo.md");
    updateSources(["app|foo.txt", "app|foo.md"]);
    // Make sure we're waiting on the correct isPrimary.
    schedule(pumpEventQueue);

    removeSources(["app|foo.txt"]);
    rewrite2.resumeIsPrimary("app|foo.md");
    expectNoAsset("app|foo.txt");
    expectAsset("app|foo.md", "foo.md");
    buildShouldSucceed();
  });

  test("doesn't transform an asset that goes from primary to non-primary "
      "during another transformer's isPrimary", () {
    var rewrite = new RewriteTransformer("md", "md");
    var check = new CheckContentTransformer(new RegExp(r"^do$"), "ne");
    initGraph({
      "app|foo.txt": "do",
      "app|foo.md": "foo"
    }, {"app": [[rewrite, check]]});

    rewrite.pauseIsPrimary("app|foo.md");
    updateSources(["app|foo.txt", "app|foo.md"]);
    // Make sure we're waiting on the correct isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "don't");
    updateSources(["app|foo.txt"]);
    rewrite.resumeIsPrimary("app|foo.md");

    expectAsset("app|foo.txt", "don't");
    expectAsset("app|foo.md", "foo.md");
    buildShouldSucceed();
  });

  test("transforms an asset that goes from non-primary to primary "
      "during another transformer's isPrimary", () {
    var rewrite = new RewriteTransformer("md", "md");
    var check = new CheckContentTransformer("do", "ne");
    initGraph({
      "app|foo.txt": "don't",
      "app|foo.md": "foo"
    }, {"app": [[rewrite, check]]});

    rewrite.pauseIsPrimary("app|foo.md");
    updateSources(["app|foo.txt", "app|foo.md"]);
    // Make sure we're waiting on the correct isPrimary.
    schedule(pumpEventQueue);

    modifyAsset("app|foo.txt", "do");
    updateSources(["app|foo.txt"]);
    rewrite.resumeIsPrimary("app|foo.md");

    expectAsset("app|foo.txt", "done");
    expectAsset("app|foo.md", "foo.md");
    buildShouldSucceed();
  });

  test("returns an asset even if an unrelated build is running", () {
    initGraph([
      "app|foo.in",
      "app|bar.in",
    ], {"app": [[new RewriteTransformer("in", "out")]]});

    updateSources(["app|foo.in", "app|bar.in"]);
    expectAsset("app|foo.out", "foo.out");
    expectAsset("app|bar.out", "bar.out");
    buildShouldSucceed();

    pauseProvider();
    modifyAsset("app|foo.in", "new");
    updateSources(["app|foo.in"]);
    expectAssetDoesNotComplete("app|foo.out");
    expectAsset("app|bar.out", "bar.out");
    buildShouldNotBeDone();

    resumeProvider();
    expectAsset("app|foo.out", "new.out");
    buildShouldSucceed();
  });

  test("doesn't report AssetNotFound until all builds are finished", () {
    initGraph([
      "app|foo.in",
    ], {"app": [[new RewriteTransformer("in", "out")]]});

    updateSources(["app|foo.in"]);
    expectAsset("app|foo.out", "foo.out");
    buildShouldSucceed();

    pauseProvider();
    updateSources(["app|foo.in"]);
    expectAssetDoesNotComplete("app|foo.out");
    expectAssetDoesNotComplete("app|non-existent.out");
    buildShouldNotBeDone();

    resumeProvider();
    expectAsset("app|foo.out", "foo.out");
    expectNoAsset("app|non-existent.out");
    buildShouldSucceed();
  });

  test("doesn't emit a result until all builds are finished", () {
    var rewrite = new RewriteTransformer("txt", "out");
    initGraph([
      "pkg1|foo.txt",
      "pkg2|foo.txt"
    ], {"pkg1": [[rewrite]], "pkg2": [[rewrite]]});

    // First, run both packages' transformers so both packages are successful.
    updateSources(["pkg1|foo.txt", "pkg2|foo.txt"]);
    expectAsset("pkg1|foo.out", "foo.out");
    expectAsset("pkg2|foo.out", "foo.out");
    buildShouldSucceed();

    // pkg1 is still successful, but pkg2 is waiting on the provider, so the
    // overall build shouldn't finish.
    pauseProvider();
    updateSources(["pkg2|foo.txt"]);
    expectAsset("pkg1|foo.out", "foo.out");
    buildShouldNotBeDone();

    // Now that the provider is unpaused, pkg2's transforms finish and the
    // overall build succeeds.
    resumeProvider();
    buildShouldSucceed();
  });

  test("one transformer takes a long time while the other finishes, then "
      "the input is removed", () {
    var rewrite1 = new RewriteTransformer("txt", "out1");
    var rewrite2 = new RewriteTransformer("txt", "out2");
    initGraph(["app|foo.txt"], {"app": [[rewrite1, rewrite2]]});

    rewrite1.pauseApply();

    updateSources(["app|foo.txt"]);

    // Wait for rewrite1 to pause and rewrite2 to finish.
    schedule(pumpEventQueue);

    removeSources(["app|foo.txt"]);

    // Make sure the removal is processed completely before we restart rewrite2.
    schedule(pumpEventQueue);
    rewrite1.resumeApply();

    buildShouldSucceed();
    expectNoAsset("app|foo.out1");
    expectNoAsset("app|foo.out2");
  });

  test("a transformer in a later phase gets a slow secondary input from an "
      "earlier phase", () {
    var rewrite = new RewriteTransformer("in", "in");
    initGraph({
      "app|foo.in": "foo",
      "app|bar.txt": "foo.in"
    }, {"app": [
      [rewrite],
      [new ManyToOneTransformer("txt")]
    ]});

    rewrite.pauseApply();
    updateSources(["app|foo.in", "app|bar.txt"]);
    expectAssetDoesNotComplete("app|bar.out");

    rewrite.resumeApply();
    expectAsset("app|bar.out", "foo.in");
    buildShouldSucceed();
  });
}
