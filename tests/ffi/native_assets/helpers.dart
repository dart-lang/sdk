// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file should be standalone (ignoring packages) because it is copied
// with // OtherResources and used for compiling snapshots.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:expect/expect.dart';

final _dylibExtension = () {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia)
    return '.so';
  if (Platform.isMacOS) return '.dylib';
  if (Platform.isWindows) return '.dll';
  throw Exception('Platform not implemented.');
}();

final _dylibPrefix = Platform.isWindows ? '' : 'lib';

String dylibName(String name) => '$_dylibPrefix$name$_dylibExtension';

final ffiTestFunctionsFileName = dylibName('ffi_test_functions');

final cwdUri = Directory.current.uri;

final platformExecutableUriAbsolute =
    cwdUri.resolve(Platform.executable.replaceAll('\\', '/'));

/// The build folder on desktop platforms.
final buildUriAbsolute = platformExecutableUriAbsolute.parent;

final ffiTestFunctionsUriAbsolute =
    buildUriAbsolute.resolve(ffiTestFunctionsFileName);

/// The sdk folder on desktop platforms.
final sdkUriAbsolute = buildUriAbsolute.parent.parent;

final standaloneExtension = (Platform.isWindows ? '.bat' : '');

final standaloneExtensionExe = (Platform.isWindows ? '.exe' : '');

final genKernelUri =
    sdkUriAbsolute.resolve('pkg/vm/tool/gen_kernel$standaloneExtension');

final genSnapshotUri =
    buildUriAbsolute.resolve('gen_snapshot$standaloneExtensionExe');

final dartUri = buildUriAbsolute.resolve('dart$standaloneExtensionExe');

final dartPrecompiledRuntimeUri =
    buildUriAbsolute.resolve('dart_precompiled_runtime$standaloneExtensionExe');

final platformDillUri = buildUriAbsolute.resolve('vm_platform_strong.dill');

final packageConfigUri =
    sdkUriAbsolute.resolve('.dart_tool/package_config.json');

extension on Uri {
  Uri get parent {
    return File(this.toFilePath()).parent.uri;
  }
}

const keepTempKey = 'KEEP_TEMPORARY_DIRECTORIES';

Future<void> withTempDir(
  Future<void> fun(Uri tempUri), {
  String prefix = 'tests_ffi_native_assets_',
}) async {
  final tempDir = await Directory.systemTemp.createTemp(prefix);
  final tempDirResolved = Directory(await tempDir.resolveSymbolicLinks());
  try {
    await fun(tempDirResolved.uri);
  } finally {
    if (!Platform.environment.containsKey(keepTempKey) ||
        Platform.environment[keepTempKey]!.isEmpty) {
      await tempDirResolved.delete(recursive: true);
    }
  }
}

/// Runs process, pipes prints exit code, stdout, and stderr, and throws on
/// exit code not zero.
Future<void> runProcess({
  required String executable,
  required List<String> arguments,
  Uri? workingDirectory,
  bool printProcessOutput = false,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
    workingDirectory: workingDirectory?.toFilePath(),
  );
  if (printProcessOutput || result.exitCode != 0) {
    final processOutputString = '''
invocation : $executable ${arguments.join(' ')}
dir        : ${workingDirectory?.toFilePath() ?? Directory.current.path}
exitCode   : ${result.exitCode}
stdout     : ${result.stdout}
stderr     : ${result.stderr}''';
    print(printProcessOutput);

    if (result.exitCode != 0) {
      throw Exception(processOutputString);
    }
  }
}

enum Runtime {
  aot,
  jit,
}

Future<void> runGenKernel({
  required Runtime runtime,
  required Uri outputUri,
  Uri? inputUri,
  Uri? nativeAssetsUri,
}) =>
    runProcess(
      executable: genKernelUri.toFilePath(),
      arguments: [
        if (runtime == Runtime.aot) '--aot',
        '--platform',
        platformDillUri.toFilePath(),
        '--packages',
        packageConfigUri.toFilePath(),
        '--output',
        outputUri.toFilePath(),
        if (nativeAssetsUri != null) ...[
          '--native-assets',
          nativeAssetsUri.toFilePath(),
        ],
        if (inputUri != null) inputUri.toFilePath(),
      ],
    );

Future<void> createDillFile({
  required Uri outputUri,
  required Uri tempUri,
  required Uri dartProgramUri,
  required Uri nativeAssetsUri,
  required Runtime runtime,
}) =>
    runGenKernel(
      runtime: runtime,
      outputUri: outputUri,
      inputUri: dartProgramUri,
      nativeAssetsUri: nativeAssetsUri,
    );

Future<void> runGenSnapshot({
  required Uri dillUri,
  required Uri outputUri,
}) =>
    runProcess(
      executable: genSnapshotUri.toFilePath(),
      arguments: [
        '--snapshot-kind=app-aot-elf',
        '--elf=${outputUri.toFilePath()}',
        '--strip',
        dillUri.toFilePath(),
      ],
    );

Future<void> runDart({
  required Uri scriptUri,
  List<String> arguments = const [],
  Uri? workingDirectory,
  Uri? packageConfigUri,
  List<String> toolArgs = const [],
}) =>
    runProcess(
      executable: dartUri.toFilePath(),
      arguments: [
        // Prevent subprocesses holding on to [workingDirectory] on Windows.
        '--suppress-core-dump',
        ...toolArgs,
        if (packageConfigUri != null)
          '--packages=${packageConfigUri.toFilePath()}',
        scriptUri.toFilePath(),
        ...arguments,
      ],
      workingDirectory: workingDirectory,
    );

Future<void> runDartKernelSnapshot({
  required Uri outputUri,
  required Uri inputUri,
  Uri? packageConfigUri,
  Uri? workingDirectory,
}) =>
    runDart(
      workingDirectory: workingDirectory,
      toolArgs: [
        '--snapshot-kind=kernel',
        '--snapshot=${outputUri.toFilePath()}',
      ],
      packageConfigUri: packageConfigUri,
      scriptUri: inputUri,
    );

Future<void> runDartAotRuntime({
  required Uri aotSnapshotUri,
  List<String> arguments = const [],
}) =>
    runProcess(
      executable: dartPrecompiledRuntimeUri.toFilePath(),
      arguments: [
        aotSnapshotUri.toFilePath(),
        ...arguments,
      ],
    );

Future<void> testIsolateSpawnUri({
  required Uri spawnUri,
  required List<String> arguments,
}) async {
  final receivePort = ReceivePort();
  await Isolate.spawnUri(spawnUri, arguments, receivePort.sendPort);
  final result = await receivePort.first;
  if (result != null) {
    print(result);
  }
  Expect.isNull(result);
}

/// Compiles and runs the provided script.
///
/// Runs both through `Isolate.spawnUri` and `Process.run`.
Future<void> compileAndRun({
  required Uri tempUri,
  required Uri dartProgramUri,
  required String nativeAssetsYaml,
  required Runtime runtime,
  required List<String> runArguments,
}) async {
  final nativeAssetsUri = tempUri.resolve('native_assets.yaml');
  await File(nativeAssetsUri.toFilePath()).writeAsString(nativeAssetsYaml);

  final outDillUri = tempUri.resolve('out.dill');
  await createDillFile(
    outputUri: outDillUri,
    tempUri: tempUri,
    dartProgramUri: dartProgramUri,
    nativeAssetsUri: nativeAssetsUri,
    runtime: runtime,
  );

  if (runtime == Runtime.jit) {
    await runDart(scriptUri: outDillUri, arguments: runArguments);
  } else {
    final snapshotUri = tempUri.resolve('out.snapshot');
    await runGenSnapshot(dillUri: outDillUri, outputUri: snapshotUri);
    await runDartAotRuntime(
        aotSnapshotUri: snapshotUri, arguments: runArguments);
  }
}

/// [target] defaults to `Abi.current().toString()`.
///
/// [asset] defaults to `'file://${Platform.script.toFilePath()}'`. This works
/// for tests invoking themselves.
///
/// [assetMapping] is automatically json encoded.
String createNativeAssetYaml({
  String? target,
  required String asset,
  required List<String> assetMapping,
  String? asset2,
  List<String>? asset2Mapping,
}) {
  target ??= Abi.current().toString();
  return jsonEncode({
    'format-version': [1, 0, 0],
    'native-assets': {
      target: {
        asset: assetMapping,
        if (asset2 != null && asset2Mapping != null) asset2: asset2Mapping,
      },
    },
  });
}

Future<void> invokeSelf({
  required Uri selfSourceUri,
  required List<String> arguments,
  required String nativeAssetsYaml,
  Runtime runtime = Runtime.jit,
}) async {
  await withTempDir((Uri tempUri) async {
    await compileAndRun(
      tempUri: tempUri,
      dartProgramUri: selfSourceUri,
      nativeAssetsYaml: nativeAssetsYaml,
      runtime: runtime,
      runArguments: arguments,
    );
    print([selfSourceUri.toFilePath(), runtime.name, 'done'].join(' '));
  });
}

/// Spawns an isolate running [fun] and fails with [Expect] if any
/// [Exception]s are thrown, including [Expect] failures.
Future<void> testIsolateSpawn(Future Function() fun) async {
  const successMessage = 'success';
  final receivePort = ReceivePort();
  await Isolate.spawn((SendPort sendPort) async {
    try {
      await fun();
      sendPort.send(successMessage);
    } catch (e) {
      sendPort.send(e);
    }
  }, receivePort.sendPort);
  final isolateResult = await receivePort.first;
  receivePort.close();
  Expect.equals(successMessage, isolateResult);
}

/// Scaffold for a test that invokes itself in multiple ways.
///
/// This test can be run in multiple modes from test.py.
///
/// 1. On development machines, it will likely be run in JIT mode.
/// 2. On CI bots, it will likely only be run in AOT mode, because these are the
///    configurations that are guaranteed to have a `gen_kernel`, and
///    `gen_snapshot`, etc.
///
/// The test scaffold distinguishes between three types of invocation.
///
/// 1. The [doOnOuterInvocation]. In this, we do not have control over whether
///    we're running in JIT or AOT mode. In this we can call [runGenKernel] and
///    [runGenSnapshot] to create snapshots and either [runDart] and
///    [runDartAotRuntime] with these snapshots.
///    For the purpose of native asset tests we will create these snapshots
///    _with_ a native asset mapping.
/// 2. The [doOnProcessInvocation]. In this, we know that we have a snapshot
///    from the outer invocation and are in the corresponding Dart runtime.
///    This means we have an asset mapping and can use `@Native` bindings.
///    In this invocation, we can call [Isolate.spawn] which should then reuse
///    native asset mapping, because this mapping is shared among the isolate
///    group.
///    Moreover, we can call [Isolate.spawnUri] with [Platform.script], because
///    we know that snapshot lines up with the runtime. (If we tried to do this
///    in 1, we could try to run an aot snapshot with the JIT runtime.)
/// 3. The [doOnSpawnUriInvocation]. In this, we have been invoked with
///    [Isolate.spawnUri], so we can run our tests (again).
///
/// It uses the `main`s' `args` and `message` for distinguishing these
/// invocations.
Future<void> Function(List<String> args, Object? message) selfInvokingTest({
  required Future<void> Function() doOnOuterInvocation,
  required Future<void> Function() doOnProcessInvocation,
  required Future<void> Function() doOnSpawnUriInvocation,
  bool verbose = false,
}) =>
    (List<String> args, Object? message) async {
      if (verbose) print('main');
      if (args.isEmpty) {
        if (verbose) print('doOnOuterInvocation');
        // Outer invocation: compile and run this file.
        // We're likely in `dartaotruntime` when running tests on the bot, because
        // those configurations are guaranteed to have the dartaotruntime available.
        // However we might be in JIT mode when tests are run locally.
        // This means, we cannot call `Isolate.spawnUri` on the snapshots we
        // create directly.
        await doOnOuterInvocation();
        if (verbose) print('doOnOuterInvocation done');
        return;
      }

      final sendPort = message as SendPort?;
      if (sendPort == null) {
        // First self-invocation, we are now guaranteed to be in the right runtime:
        // `Platform.resolvedExecutable` will be dartaotruntime if the
        // `Platform.script` is an aot snapshot. So, it's valid to call
        // `Isolate.spawnUri` with `Platform.script`.
        if (verbose) print('doOnProcessInvocation');
        await doOnProcessInvocation();
        if (verbose) print('doOnProcessInvocation done');
        return;
      }

      // Second self-invocation. This time through `Isolate.spawnUri`.
      try {
        if (verbose) print('doOnSpawnUriInvocation');
        await doOnSpawnUriInvocation();
        if (verbose) print('doOnSpawnUriInvocation done');
      } catch (e, st) {
        sendPort.send([e.toString(), st.toString()]);
        rethrow;
      }
      // Done, no errors.
      sendPort.send(null);
    };

const doesNotExistName = 'doesnotexist92304';

@Native<Int32 Function(Int32, Int32)>()
external int doesnotexist92304(int a, int b);

void testNonExistingFunction() {
  final argumentError2 = Expect.throws<ArgumentError>(() {
    doesnotexist92304(2, 3);
  });
  Expect.contains(doesNotExistName, argumentError2.message);
}
