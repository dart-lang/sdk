// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:convert";
import "dart:io";

import "package:expect/expect.dart";
import "package:path/path.dart" as path;

import "use_flag_test_helper.dart";

main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree not available on the test device.
  }

  // These are the tools we need to be available to run on a given platform:
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }
  if (!await testExecutable(genSnapshot)) {
    throw "Cannot run test as $genSnapshot not available";
  }

  sanitizedPartitioning(manifest) {
    // Filter core libraries, relativize URIs, and sort to make the results less
    // sensitive to compiler or test harness changes.
    print(manifest);
    var units = <List<String>>[];
    for (var unit in manifest['loadingUnits']) {
      var uris = <String>[];
      for (var uri in unit['libraries']) {
        if (uri.startsWith("dart:")) continue;
        uris.add(Uri.parse(uri).pathSegments.last);
      }
      uris.sort();
      units.add(uris);
    }
    units.sort((a, b) => a.first.compareTo(b.first));
    print(units);
    return units;
  }

  await withTempDir("split-literals-test", (String tempDir) async {
    final source =
        path.join(sdkDir, "runtime/tests/vm/dart_2/split_literals.dart");
    final dill = path.join(tempDir, "split_literals.dart.dill");
    final snapshot = path.join(tempDir, "split_literals.so");
    final manifest = path.join(tempDir, "split_literals.txt");
    final deferredSnapshot = snapshot + "-2.part.so";

    // Compile source to kernel.
    await run(genKernel, <String>[
      "--aot",
      "--platform=$platformDill",
      "-o",
      dill,
      source,
    ]);

    // Compile kernel to ELF.
    await run(genSnapshot, <String>[
      "--snapshot-kind=app-aot-elf",
      "--elf=$snapshot",
      "--loading-unit-manifest=$manifest",
      dill,
    ]);
    var manifestContent = jsonDecode(await new File(manifest).readAsString());
    Expect.equals(2, manifestContent["loadingUnits"].length);
    // Note package:expect doesn't do deep equals on collections.
    Expect.equals(
        "[[split_literals.dart],"
        " [split_literals_deferred.dart]]",
        sanitizedPartitioning(manifestContent).toString());
    Expect.isTrue(await new File(deferredSnapshot).exists());

    bool containsSubsequence(haystack, needle) {
      outer:
      for (var i = 0, n = haystack.length - needle.length; i < n; i++) {
        for (var j = 0; j < needle.length; j++) {
          if (haystack[i + j] != needle.codeUnitAt(j)) continue outer;
        }
        return true;
      }
      return false;
    }

    var unit_1 = await new File(snapshot).readAsBytes();
    Expect.isTrue(containsSubsequence(unit_1, "Root literal!"));
    Expect.isTrue(containsSubsequence(unit_1, "Root literal in a list!"));
    Expect.isTrue(containsSubsequence(unit_1, "Root literal in a map!"));
    Expect.isTrue(containsSubsequence(unit_1, "Root literal in a box!"));
    Expect.isTrue(!containsSubsequence(unit_1, "Deferred literal!"));
    Expect.isTrue(!containsSubsequence(unit_1, "Deferred literal in a list!"));
    Expect.isTrue(!containsSubsequence(unit_1, "Deferred literal in a map!"));
    Expect.isTrue(!containsSubsequence(unit_1, "Deferred literal in a box!"));

    var unit_2 = await new File(deferredSnapshot).readAsBytes();
    Expect.isTrue(!containsSubsequence(unit_2, "Root literal!"));
    Expect.isTrue(!containsSubsequence(unit_2, "Root literal in a list!"));
    Expect.isTrue(!containsSubsequence(unit_2, "Root literal in a map!"));
    Expect.isTrue(!containsSubsequence(unit_2, "Root literal in a box!"));
    Expect.isTrue(containsSubsequence(unit_2, "Deferred literal!"));
    Expect.isTrue(containsSubsequence(unit_2, "Deferred literal in a list!"));
    Expect.isTrue(containsSubsequence(unit_2, "Deferred literal in a map!"));
    Expect.isTrue(containsSubsequence(unit_2, "Deferred literal in a box!"));
  });
}
