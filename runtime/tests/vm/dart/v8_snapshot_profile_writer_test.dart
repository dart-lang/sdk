// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "dart:io";

import "package:expect/expect.dart";
import "package:vm/v8_snapshot_profile.dart";

String path(List<String> segments) {
  return "/" + segments.join("/");
}

test(bool use_elf) async {
  if (Platform.isWindows) return;

  final List<String> sdkBaseSegments =
      Uri.file(Platform.resolvedExecutable).pathSegments.toList();
  sdkBaseSegments
      .replaceRange(sdkBaseSegments.indexOf("out"), sdkBaseSegments.length, []);

  // Generate the snapshot profile.
  final String thisTestPath = path(sdkBaseSegments) +
      "/runtime/tests/vm/dart/v8_snapshot_profile_writer_test.dart";

  final Directory temp = await Directory.systemTemp.createTemp();
  final String snapshotPath = temp.path + "/test.snap";

  final List<String> precompiler2Args = [
    "--write-v8-snapshot-profile-to=${temp.path}/profile.heapsnapshot",
    thisTestPath,
    snapshotPath,
  ];

  if (use_elf) {
    precompiler2Args.insert(0, "--build-elf");
  }

  final ProcessResult result = await Process.run(
    "pkg/vm/tool/precompiler2",
    precompiler2Args,
    workingDirectory: path(sdkBaseSegments),
    runInShell: true,
  );

  // The precompiler2 script tried using GCC for the wrong architecture. We
  // don't have a workaround for this now.
  if (use_elf &&
      result.exitCode != 0 &&
      result.stderr.contains("Assembler messages")) {
    return;
  }

  print(precompiler2Args);
  print(result.stderr);
  print(result.stdout);

  Expect.equals(result.exitCode, 0);
  Expect.equals(result.stderr, "");
  Expect.equals(result.stdout, "");

  final V8SnapshotProfile profile = V8SnapshotProfile.fromJson(JsonDecoder()
      .convert(File("${temp.path}/profile.heapsnapshot").readAsStringSync()));

  // Verify that there are no "unknown" nodes. These are emitted when we see a
  // reference to an some object but no other metadata about the object was
  // recorded. We should at least record the type for every object in the graph
  // (in some cases the shallow size can legitimately be 0, e.g. for "base
  // objects").
  for (final int node in profile.nodes) {
    if (profile[node].type == "Unknown") {
      print(profile[node].id);
    }
    Expect.notEquals(profile[node].type, "Unknown");
  }

  // Verify that all nodes are reachable from the declared roots.
  int unreachableNodes = 0;
  Set<int> nodesReachableFromRoots = profile.preOrder(profile.root).toSet();
  for (final int node in profile.nodes) {
    if (!nodesReachableFromRoots.contains(node)) {
      ++unreachableNodes;
    }
  }
  Expect.equals(unreachableNodes, 0);

  // Verify that the actual size of the snapshot is close to the sum of the
  // shallow sizes of all objects in the profile. They will not be exactly equal
  // because of global headers and padding.
  if (use_elf) {
    await Process.run("strip", [snapshotPath]);
  }
  final int actual = await File(snapshotPath).length();
  final int expected = profile.accountedBytes;
  Expect.isTrue((actual - expected).abs() / actual < 0.01);
}

main() async {
  test(false);
  test(true);
}
