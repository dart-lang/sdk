// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks various command line options related to the Mach-O
// snapshot writer. Note that some of these options may make the written
// snapshot unrunnable, as they are meant to be used in a larger workflow
// (e.g., not emitting a code signature because it will be added later by
// XCode).

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/src/macho.dart' as macho;
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

Future<void> main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and dart_bootstrap not available on the test device.
  }

  // These are the tools we need to be available to run on a given platform:
  if (!await testExecutable(genSnapshot)) {
    throw "Cannot run test as $genSnapshot not available";
  }
  if (!await testExecutable(dartPrecompiledRuntime)) {
    throw "Cannot run test as $dartPrecompiledRuntime not available";
  }
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }

  await withTempDir('use-macho-options-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script = path.join(
      cwDir,
      'use_save_debugging_info_flag_program.dart',
    );
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    final testCases = <TestCase>[
      for (final t in testsToRun) await compileSnapshot(tempDir, scriptDill, t),
    ];
    await checkCases(testCases);
  });
}

final canRetrieveDebugMap =
    // The identifier isn't provided on these platforms due to the lack
    // of a basename implementation, so no debug map can be extracted.
    !Platform.isWindows &&
    !Platform.isFuchsia &&
    // clangBuildToolsDir uses Abi.current(), so it returns the buildtools
    // dir for the architecture being simulated, not the host.
    !isSimulator;

Future<List<String>?> retrieveDebugMap(String snapshotPath) async {
  final dsymutil = llvmTool('dsymutil');
  if (dsymutil == null) {
    if (!canRetrieveDebugMap) return null;
    throw StateError('Expected dsymutil');
  }
  // Don't clutter the log with the output from dsymutil as it's large.
  return await runOutput(dsymutil, [
    '--dump-debug-map',
    snapshotPath,
  ], printStdout: false);
}

Future<TestCase> compileSnapshot(
  String tempDir,
  String scriptDill,
  TestType testType,
) async {
  final additionalOptions = [
    if (testType == TestType.AddRunPaths)
      '--macho-rpath=${machORunPaths.join(',')}',
    if (testType == TestType.MinOSVersion)
      '--macho-min-os-version=$expectedVersion',
    if (testType == TestType.NoLinkerSignature) '--no-macho-linker-signature',
    if (testType == TestType.ReplaceInstallName)
      '--macho-install-name=$machoInstallName',
  ];

  final scriptSnapshot = path.join(tempDir, 'output.so');
  await createSnapshot(
    scriptDill,
    SnapshotType.machoDylib,
    scriptSnapshot,
    additionalOptions,
  );
  return TestCase(
    testType,
    scriptSnapshot,
    macho.MachO.fromFile(scriptSnapshot)!,
    debugMap: await retrieveDebugMap(scriptSnapshot),
  );
}

@pragma('vm:platform-const')
final isApplePlatform = Platform.isMacOS || Platform.isIOS;
@pragma('vm:platform-const')
final expectedVersion = isApplePlatform ? macho.Version(1, 2, 3) : null;
const machoInstallName = '@rpath/App.framework/App';
const machORunPaths = [
  '@executable_path/Frameworks',
  '@loader_path/Frameworks',
];

enum TestType {
  AddRunPaths,
  MinOSVersion,
  NoLinkerSignature,
  ReplaceInstallName,
}

@pragma('vm:platform-const')
final testsToRun = [
  if (isApplePlatform) TestType.MinOSVersion,
  if (isApplePlatform) TestType.AddRunPaths,
  TestType.ReplaceInstallName,
  TestType.NoLinkerSignature,
];

class TestCase {
  final TestType type;
  final String snapshotPath;
  final macho.MachO snapshot;
  final List<String>? debugMap;

  TestCase(this.type, this.snapshotPath, this.snapshot, {this.debugMap});
}

Future<void> checkCases(List<TestCase> testCases) async {
  // We want to make sure the debug maps are consistent across cases.
  checkDebugMaps(testCases);
  for (final c in testCases) {
    checkInstallName(c);
    checkRunPaths(c);
    checkBuildVersion(c);
    checkCodeSignature(c);
  }
  // Unsigned snapshots are not runnable.
  final runnableCases = testCases
      .where((c) => c.type != TestType.NoLinkerSignature)
      .toList();
  await checkRunnable(runnableCases);
}

Future<void> checkRunnable(List<TestCase> testCases) async {
  Expect.isNotEmpty(testCases);
  final traces = [
    for (final c in testCases)
      await runError(dartPrecompiledRuntime, <String>[
        c.snapshotPath,
      ], printStderr: false),
  ];

  // Use the first testcase's stack trace as the expected result.
  final expectedTrace = traces.first;
  print('');
  print("Stack trace 1:");
  expectedTrace.forEach(print);

  if (traces.length == 1) {
    // On non-Apple platforms, there's only one runnable case.
    print('');
    print('No other runnable test cases to compare.');
    return;
  }

  for (int i = 1; i < testCases.length; i++) {
    final gotTrace = traces[i];
    print('');
    print("Stack trace ${i + 1}:");
    print(gotTrace);

    Expect.deepEquals(expectedTrace, gotTrace);
  }
}

final _tripleLineRegExp = RegExp(r'triple:\s+(.*)');
final _timestampLineRegExp = RegExp(r'timestamp:\s+(.*)');
// We only check that the number of symbols were the same.
final _symbolLineRegExp = RegExp(r'{ sym: ');

void checkDebugMaps(List<TestCase> testCases) {
  // Not a platform where we can test debug maps.
  if (!canRetrieveDebugMap) return;

  for (final c in testCases) {
    Expect.isNotNull(c.debugMap, 'Debug map for test ${c.type} missing');
  }

  // Like with the runnable testcases, use the first one as the expected
  // result for the others.
  final expected = testCases.first.debugMap!;
  final got = testCases.skip(1).map((t) => t.debugMap!).toList();

  // The dump should look like the following YAML:
  // ---
  // triple:        '<arch>-<vendor>-<os>'
  // binary-path:   <filename>
  // objects:
  //   - filename:      <filename>
  //   - timestamp:     0
  //   - symbols:
  //     - { sym: <name>, ... }
  //     ...
  // ...
  //
  // The initial --- and ending ... are literal, as those are used to
  // separate multiple YAML documents in a single stream.
  //
  // For all test cases:
  // - The triple should be the same.
  // - The binary-path and filename lines should exist, though the filenames
  //   may be different.
  // - The timestamp should be 0.
  // - The number of symbols should be the same.
  Expect.isTrue(expected.length > 7);
  for (final c in got) {
    Expect.equals(expected.length, c.length);
  }
  for (int i = 0; i < expected.length; i++) {
    final expectedLine = expected[i];
    final isSymbol = _symbolLineRegExp.hasMatch(expectedLine);
    final expectedTriple = _tripleLineRegExp.firstMatch(expectedLine)?.group(1);

    final expectedTimestampMatch = _timestampLineRegExp.firstMatch(
      expectedLine,
    );
    if (expectedTimestampMatch != null) {
      final expectedTimestamp = int.tryParse(expectedTimestampMatch.group(1)!);
      // The timestamp (value of the N_OSO symbol) in our snapshots is always 0.
      Expect.equals(0, expectedTimestamp);
    }

    // Lines that are allowed to have varying field values.
    final prefixOnlyLinePrefixes = ['binary-path: ', '  - filename: '];
    var expectedPrefixEnd = -1;
    if (prefixOnlyLinePrefixes.any((s) => expectedLine.startsWith(s))) {
      expectedPrefixEnd = expectedLine.indexOf(':');
    }

    for (final c in got) {
      final gotLine = c[i];
      if (expectedTriple != null) {
        final gotTriple = _tripleLineRegExp.firstMatch(gotLine)?.group(1);
        Expect.equals(expectedTriple, gotTriple);
      } else if (isSymbol) {
        Expect.isTrue(_symbolLineRegExp.hasMatch(gotLine));
      } else if (expectedPrefixEnd > 0) {
        // If there's a unhandled field name, check that those match and don't
        // check the rest of the line (as, say, the filename will differ).
        Expect.stringEquals(
          expectedLine.substring(0, expectedLine.indexOf(':')),
          gotLine.substring(0, expectedLine.indexOf(':')),
        );
      } else {
        // Check line equality for anything not already covered.
        Expect.stringEquals(expectedLine, gotLine);
      }
    }
  }
}

void checkInstallName(TestCase testCase) {
  final dylibCommands = testCase.snapshot
      .commandsWhereType<macho.DylibCommand>();
  Expect.isNotEmpty(dylibCommands);
  final idDylib = dylibCommands
      .where((c) => c.cmd == macho.LoadCommand.LC_ID_DYLIB)
      .singleOrNull;
  Expect.isNotNull(idDylib);
  if (idDylib == null) return;
  final expectedName = testCase.type == TestType.ReplaceInstallName
      ? machoInstallName
      // No Utils::Basename implementation in runtime/platform for Windows
      // or Fuchsia, so for now an empty string is used instead of the full
      // path (which could leak information).
      : (Platform.isWindows || Platform.isFuchsia)
      ? ""
      : path.basename(testCase.snapshotPath);
  Expect.equals(expectedName, idDylib.info.name);
}

void checkRunPaths(TestCase testCase) {
  final runPathCommands = testCase.snapshot
      .commandsWhereType<macho.RunPathCommand>();
  if (testCase.type != TestType.AddRunPaths) {
    Expect.isEmpty(runPathCommands);
  } else {
    Expect.isNotEmpty(runPathCommands);
    for (final rpath in runPathCommands) {
      Expect.isTrue(
        machORunPaths.contains(rpath.path),
        "${rpath.path} not in [${machORunPaths.join(", ")}]",
      );
    }
  }
}

void checkCodeSignature(TestCase testCase) {
  final codeSignatureCommands = testCase.snapshot.commands.where(
    (s) => s.cmd == macho.LoadCommand.LC_CODE_SIGNATURE,
  );
  if (testCase.type == TestType.NoLinkerSignature) {
    Expect.isEmpty(codeSignatureCommands);
  } else {
    Expect.equals(1, codeSignatureCommands.length);
  }
}

void checkBuildVersion(TestCase testCase) {
  final buildVersion = testCase.snapshot
      .commandsWhereType<macho.BuildVersionCommand>()
      .singleOrNull;
  if (buildVersion == null) {
    Expect.isFalse(isApplePlatform);
    return;
  }
  Expect.isTrue(isApplePlatform);
  final expectedPlatform = Platform.isIOS
      ? macho.Platform.PLATFORM_IOS
      : macho.Platform.PLATFORM_MACOS;
  Expect.equals(expectedPlatform, buildVersion.platform);
  if (testCase.type == TestType.MinOSVersion) {
    Expect.equals(expectedVersion, buildVersion.minOS);
    Expect.equals(expectedVersion, buildVersion.sdk);
  }
  Expect.isEmpty(buildVersion.toolVersions);
}
