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

test(String sdkRoot, {bool useElf: false}) async {
  if (Platform.isMacOS && useElf) return;

  // Generate the snapshot profile.
  final String thisTestPath =
      "$sdkRoot/runtime/tests/vm/dart/v8_snapshot_profile_writer_test.dart";

  final Directory temp = await Directory.systemTemp.createTemp();
  final String snapshotPath = temp.path + "/test.snap";

  final List<String> precompiler2Args = [
    "--write-v8-snapshot-profile-to=${temp.path}/profile.heapsnapshot",
    thisTestPath,
    snapshotPath,
  ];

  if (useElf) {
    precompiler2Args.insert(0, "--build-elf");
  }

  final ProcessResult result = await Process.run(
    "pkg/vm/tool/precompiler2",
    precompiler2Args,
    workingDirectory: sdkRoot,
    runInShell: true,
  );

  // The precompiler2 script tried using GCC for the wrong architecture. We
  // don't have a workaround for this now.
  if (useElf &&
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
  if (useElf) {
    await Process.run("strip", [snapshotPath]);
  }
  final int actual = await File(snapshotPath).length();
  final int expected = profile.accountedBytes;
  Expect.isTrue((actual - expected).abs() / actual < 0.01);
}

Match matchComplete(RegExp regexp, String line) {
  Match match = regexp.firstMatch(line);
  if (match == null) return match;
  if (match.start != 0 || match.end != line.length) return null;
  return match;
}

// All fields of "Raw..." classes defined in "raw_object.h" must be included in
// the giant macro in "raw_object_fields.cc". This function attempts to check
// that with some basic regexes.
testMacros(String sdkRoot) async {
  const String className = "([a-z0-9A-Z]+)";
  const String rawClass = "Raw$className";
  const String fieldName = "([a-z0-9A-Z_]+)";

  final Map<String, Set<String>> fields = {};

  final String rawObjectFieldsPath = "$sdkRoot/runtime/vm/raw_object_fields.cc";
  final RegExp fieldEntry = RegExp(" *F\\($className, $fieldName\\) *\\\\?");

  await for (String line in File(rawObjectFieldsPath)
      .openRead()
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(LineSplitter())) {
    Match match = matchComplete(fieldEntry, line);
    if (match != null) {
      fields
          .putIfAbsent(match.group(1), () => Set<String>())
          .add(match.group(2));
    }
  }

  final RegExp classStart = RegExp("class $rawClass : public $rawClass {");
  final RegExp classEnd = RegExp("}");
  final RegExp field = RegExp("  $rawClass. +$fieldName;.*");

  final String rawObjectPath = "$sdkRoot/runtime/vm/raw_object.h";

  String currentClass;
  bool hasMissingFields = false;
  await for (String line in File(rawObjectPath)
      .openRead()
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(LineSplitter())) {
    Match match = matchComplete(classStart, line);
    if (match != null) {
      currentClass = match.group(1);
      continue;
    }

    match = matchComplete(classEnd, line);
    if (match != null) {
      currentClass = null;
      continue;
    }

    match = matchComplete(field, line);
    if (match != null && currentClass != null) {
      if (fields[currentClass] == null) {
        hasMissingFields = true;
        print("$currentClass is missing entirely.");
        continue;
      }
      if (!fields[currentClass].contains(match.group(2))) {
        hasMissingFields = true;
        print("$currentClass is missing ${match.group(2)}.");
      }
    }
  }

  if (hasMissingFields) {
    Expect.fail(
        "runtime/vm/raw_object_fields.cc misses some fields. Please update it to match raw_object.h.");
  }
}

main() async {
  if (Platform.isWindows) return;

  final List<String> sdkBaseSegments =
      Uri.file(Platform.resolvedExecutable).pathSegments.toList();
  sdkBaseSegments
      .replaceRange(sdkBaseSegments.length - 3, sdkBaseSegments.length, []);
  String sdkRoot = path(sdkBaseSegments);

  test(sdkRoot, useElf: false);
  test(sdkRoot, useElf: true);
  testMacros(sdkRoot);
}
