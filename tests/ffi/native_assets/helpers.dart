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

final platformExecutableUriAbsolute = cwdUri.resolve(
  Platform.executable.replaceAll('\\', '/'),
);

/// The build folder on desktop platforms.
final buildUriAbsolute = platformExecutableUriAbsolute.parent;

final ffiTestFunctionsUriAbsolute = buildUriAbsolute.resolve(
  ffiTestFunctionsFileName,
);

/// The sdk folder on desktop platforms.
final sdkUriAbsolute = buildUriAbsolute.parent.parent;

final standaloneExtension = (Platform.isWindows ? '.bat' : '');

final standaloneExtensionExe = (Platform.isWindows ? '.exe' : '');

final genKernelUri = sdkUriAbsolute.resolve(
  'pkg/vm/tool/gen_kernel$standaloneExtension',
);

final protobufAwareTreeshakerUri = sdkUriAbsolute.resolve(
  'pkg/vm/bin/protobuf_aware_treeshaker.dart',
);

final genSnapshotUri = buildUriAbsolute.resolve(
  'gen_snapshot$standaloneExtensionExe',
);

final dartUri = buildUriAbsolute.resolve('dart$standaloneExtensionExe');

final dartPrecompiledRuntimeUri = buildUriAbsolute.resolve(
  'dartaotruntime$standaloneExtensionExe',
);

final platformDillUri = buildUriAbsolute.resolve('vm_platform_strong.dill');

final packageConfigUri = sdkUriAbsolute.resolve(
  '.dart_tool/package_config.json',
);

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
    } else {
      print('Keeping $tempDirResolved');
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

enum KernelCombine { source, concatenation }

enum Runtime { aot, appjit, jit }

enum AotCompile { assembly, elf }

Future<void> runGenKernel({
  required Runtime runtime,
  required Uri outputUri,
  Uri? inputUri,
  Uri? nativeAssetsUri,
}) => runProcess(
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
  required KernelCombine kernelCombine,
  required bool protobufAwareTreeshaking,
}) async {
  final preTreeshakenDill = tempUri.resolve('pre_treeshaken.dill');

  switch (kernelCombine) {
    case KernelCombine.source:
      await runGenKernel(
        runtime: runtime,
        outputUri: protobufAwareTreeshaking ? preTreeshakenDill : outputUri,
        inputUri: dartProgramUri,
        nativeAssetsUri: nativeAssetsUri,
      );
    case KernelCombine.concatenation:
      final programDillUri = tempUri.resolve('program.dill');
      final nativeAssetsDillUri = tempUri.resolve('native_assets.dill');
      await Future.wait([
        runGenKernel(
          runtime: runtime,
          outputUri: programDillUri,
          inputUri: dartProgramUri,
        ),
        runGenKernel(
          runtime: runtime,
          outputUri: nativeAssetsDillUri,
          nativeAssetsUri: nativeAssetsUri,
        ),
      ]);
      final programKernelBytes =
          await File.fromUri(programDillUri).readAsBytes();
      final nativeAssetKernelBytes =
          await File.fromUri(nativeAssetsDillUri).readAsBytes();
      await File.fromUri(
        protobufAwareTreeshaking ? preTreeshakenDill : outputUri,
      ).writeAsBytes([
        ...programKernelBytes,
        ...nativeAssetKernelBytes,
      ], flush: true);
  }

  if (protobufAwareTreeshaking) {
    await runDart(
      scriptUri: protobufAwareTreeshakerUri,
      arguments: [
        if (runtime == Runtime.aot) '--aot',
        /*<input.dill>*/ preTreeshakenDill.toFilePath(),
        /*<output.dill>*/ outputUri.toFilePath(),
      ],
    );
  }
}

Future<void> runGenSnapshot({
  required Uri tempUri,
  required Uri dillUri,
  required Uri outputUri,
  required AotCompile aotCompile,
}) async {
  switch (aotCompile) {
    case AotCompile.elf:
      await runProcess(
        executable: genSnapshotUri.toFilePath(),
        arguments: [
          '--snapshot-kind=app-aot-elf',
          '--elf=${outputUri.toFilePath()}',
          '--strip',
          dillUri.toFilePath(),
        ],
      );
    case AotCompile.assembly:
      if (!(Platform.isLinux || Platform.isMacOS)) {
        // Windows doesn't support assembly snapshots.
        throw UnsupportedError('Not yet implemented for MSVC');
      }
      final assemblyUri = tempUri.resolve('out.S');
      await runProcess(
        executable: genSnapshotUri.toFilePath(),
        arguments: [
          '--snapshot-kind=app-aot-assembly',
          '--assembly=${assemblyUri.toFilePath()}',
          dillUri.toFilePath(),
        ],
      );
      if (!await File.fromUri(assemblyUri).exists()) {
        throw Error();
      }

      // Executables and arguments taken from
      // pkg/test_runner/lib/src/compiler_configuration.dart
      // `computeAssembleCommand`.
      if (Platform.isMacOS) {
        await runProcess(
          executable: 'clang',
          arguments: [
            '-Wl,-undefined,error',
            '-Wl,-no_compact_unwind',
            '-dynamiclib',
            '-o',
            outputUri.toFilePath(),
            assemblyUri.toFilePath(),
          ],
        );
      } else if (Platform.isLinux) {
        await runProcess(
          executable: 'gcc',
          arguments: [
            '-shared',
            '-Wl,--no-undefined',
            '-o',
            outputUri.toFilePath(),
            assemblyUri.toFilePath(),
          ],
        );
      }
  }
}

Future<void> runDart({
  required Uri scriptUri,
  List<String> arguments = const [],
  Uri? workingDirectory,
  Uri? packageConfigUri,
  List<String> toolArgs = const [],
}) => runProcess(
  executable: dartUri.toFilePath(),
  arguments: [
    // Prevent subprocesses holding on to [workingDirectory] on Windows.
    '--suppress-core-dump',
    ...toolArgs,
    if (packageConfigUri != null) '--packages=${packageConfigUri.toFilePath()}',
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
}) => runDart(
  workingDirectory: workingDirectory,
  toolArgs: ['--snapshot-kind=kernel', '--snapshot=${outputUri.toFilePath()}'],
  packageConfigUri: packageConfigUri,
  scriptUri: inputUri,
);

Future<void> runDartAotRuntime({
  required Uri aotSnapshotUri,
  List<String> arguments = const [],
}) => runProcess(
  executable: dartPrecompiledRuntimeUri.toFilePath(),
  arguments: [aotSnapshotUri.toFilePath(), ...arguments],
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
  required KernelCombine kernelCombine,
  required bool protobufAwareTreeshaking,
  AotCompile aotCompile = AotCompile.elf,
  required List<String> runArguments,
  bool useSymlink = false,
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
    kernelCombine: kernelCombine,
    protobufAwareTreeshaking: protobufAwareTreeshaking,
  );

  switch (runtime) {
    case Runtime.aot:
      final snapshotUri = tempUri.resolve('out.snapshot');
      await runGenSnapshot(
        tempUri: tempUri,
        dillUri: outDillUri,
        outputUri: snapshotUri,
        aotCompile: aotCompile,
      );
      if (useSymlink) {
        await withTempDir(prefix: 'link dir', (tempDir) async {
          final link = Link.fromUri(tempDir.resolve('my_link'));
          await link.create(snapshotUri.toFilePath());
          await runDartAotRuntime(
            aotSnapshotUri: link.uri,
            arguments: runArguments,
          );
        });
      } else {
        await runDartAotRuntime(
          aotSnapshotUri: snapshotUri,
          arguments: runArguments,
        );
      }
    case Runtime.appjit:
      final outJitUri = tempUri.resolve('out.jit');
      await runDart(
        toolArgs: [
          '--snapshot-kind=app-jit',
          '--snapshot=${outJitUri.toFilePath()}',
        ],
        scriptUri: outDillUri,
        arguments: runArguments,
      );
      if (useSymlink) {
        await withTempDir(prefix: 'link dir', (tempDir) async {
          final link = Link.fromUri(tempDir.resolve('my_link'));
          await link.create(outDillUri.toFilePath());
          await runDart(scriptUri: link.uri, arguments: runArguments);
        });
      } else {
        await runDart(scriptUri: outJitUri, arguments: runArguments);
      }
    case Runtime.jit:
      if (useSymlink) {
        await withTempDir(prefix: 'link dir', (tempDir) async {
          final link = Link.fromUri(tempDir.resolve('my_link'));
          await link.create(outDillUri.toFilePath());
          await runDart(scriptUri: link.uri, arguments: runArguments);
        });
      } else {
        await runDart(scriptUri: outDillUri, arguments: runArguments);
      }
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
  KernelCombine kernelCombine = KernelCombine.source,
  AotCompile aotCompile = AotCompile.elf,
  bool protobufAwareTreeshaking = false,
}) async {
  await withTempDir((Uri tempUri) async {
    await compileAndRun(
      tempUri: tempUri,
      dartProgramUri: selfSourceUri,
      nativeAssetsYaml: nativeAssetsYaml,
      runtime: runtime,
      kernelCombine: kernelCombine,
      protobufAwareTreeshaking: protobufAwareTreeshaking,
      aotCompile: aotCompile,
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
}) => (List<String> args, Object? message) async {
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
  Expect.contains('No asset with id', argumentError2.message);
  Expect.contains('Available native assets: ', argumentError2.message);
  Expect.contains(
    'Attempted to fallback to process lookup.',
    argumentError2.message,
  );

  final addressOfError = Expect.throws<ArgumentError>(() {
    Native.addressOf<NativeFunction<Int32 Function(Int32, Int32)>>(
      doesnotexist92304,
    );
  });
  Expect.contains(doesNotExistName, addressOfError.message);
  Expect.contains('No asset with id', addressOfError.message);
  Expect.contains('Available native assets: ', addressOfError.message);
  Expect.contains(
    'Attempted to fallback to process lookup.',
    addressOfError.message,
  );
}
