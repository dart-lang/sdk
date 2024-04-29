// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'dart2native.dart';
import 'src/generate_utils.dart';

export 'dart2native.dart' show genKernel, genSnapshot;

final dartaotruntime = path.join(
  binDir.path,
  'dartaotruntime$executableSuffix',
);

/// The kinds of native executables supported by [generateNative].
enum Kind {
  aot,
  exe;

  String appendFileExtension(String fileName) {
    return switch (this) {
      Kind.aot => '$fileName.aot',
      Kind.exe => '$fileName.exe',
    };
  }
}

/// Generates a self-contained executable or AOT snapshot.
///
/// [sourceFile] can be the path to either a Dart source file containing `main`
/// or a kernel file generated with `--link-platform`.
///
/// [defines] is the list of Dart defines to be set in the compiled program.
///
/// [kind] is the type of executable to be generated ([Kind.exe] or [Kind.aot]).
///
/// [outputFile] is the location the generated output will be written. If null,
/// the generated output will be written adjacent to [sourceFile] with the file
/// extension matching the executable type specified by [kind].
///
/// [debugFile] specifies the file debugging information should be written to.
///
/// [packages] is the path to the `.dart_tool/package_config.json`.
///
/// [targetOS] specifies the operating system the executable is being generated
/// for. This must be provided when [kind] is [Kind.exe], and it must match the
/// current operating system.
///
/// [nativeAssets] is the path to `native_assets.yaml`.
///
/// [resourcesFile] is the path to `resources.json`.
///
/// [enableExperiment] is a comma separated list of language experiments to be
/// enabled.
///
/// [verbosity] specifies the logging verbosity of the CFE.
///
/// [extraOptions] is a set of extra options to be passed to `genSnapshot`.
Future<void> generateNative({
  required String sourceFile,
  required List<String> defines,
  Kind kind = Kind.exe,
  String? outputFile,
  String? debugFile,
  String? packages,
  String? targetOS,
  String? nativeAssets,
  String? resourcesFile,
  String enableExperiment = '',
  bool enableAsserts = false,
  bool verbose = false,
  String verbosity = 'all',
  List<String> extraOptions = const [],
}) async {
  final tempDir = Directory.systemTemp.createTempSync();
  final programKernelFile = path.join(tempDir.path, 'program.dill');

  final sourcePath = _normalize(sourceFile)!;
  final sourceWithoutDartOrDill = sourcePath.replaceFirst(
    RegExp(r'\.(dart|dill)$'),
    '',
  );
  final outputPath = _normalize(
    outputFile ?? kind.appendFileExtension(sourceWithoutDartOrDill),
  )!;
  final debugPath = _normalize(debugFile);
  packages = _normalize(packages);

  if (kind == Kind.exe) {
    if (targetOS == null) {
      throw ArgumentError('targetOS must be specified for executables.');
    } else if (targetOS != Platform.operatingSystem) {
      throw UnsupportedError(
          'Cross compilation not supported for executables.');
    }
  }

  if (verbose) {
    if (targetOS != null) {
      print('Specializing Platform getters for target OS $targetOS.');
    }
    print('Compiling $sourcePath to $outputPath using format $kind:');
    print('Generating AOT kernel dill.');
  }

  try {
    final kernelResult = await generateKernelHelper(
      dartaotruntime: dartaotruntime,
      sourceFile: sourcePath,
      kernelFile: programKernelFile,
      packages: packages,
      defines: defines,
      fromDill: await isKernelFile(sourcePath),
      enableAsserts: enableAsserts,
      enableExperiment: enableExperiment,
      targetOS: targetOS,
      extraGenKernelOptions: [
        '--invocation-modes=compile',
        '--verbosity=$verbosity',
      ],
      resourcesFile: resourcesFile,
      aot: true,
    );
    await _forwardOutput(kernelResult);
    if (kernelResult.exitCode != 0) {
      throw StateError('Generating AOT kernel dill failed!');
    }
    String kernelFile;
    if (nativeAssets == null) {
      kernelFile = programKernelFile;
    } else {
      // TODO(dacoharkes): This method will need to be split in two parts. Then
      // the link hooks can be run in between those two parts.
      final nativeAssetsDillFile =
          path.join(tempDir.path, 'native_assets.dill');
      final kernelResult = await generateKernelHelper(
        dartaotruntime: dartaotruntime,
        kernelFile: nativeAssetsDillFile,
        packages: packages,
        defines: defines,
        enableAsserts: enableAsserts,
        enableExperiment: enableExperiment,
        targetOS: targetOS,
        extraGenKernelOptions: [
          '--invocation-modes=compile',
          '--verbosity=$verbosity',
        ],
        nativeAssets: nativeAssets,
        aot: true,
      );
      await _forwardOutput(kernelResult);
      if (kernelResult.exitCode != 0) {
        throw StateError('Generating AOT kernel dill failed!');
      }
      kernelFile = path.join(tempDir.path, 'kernel.dill');
      final programKernelBytes = await File(programKernelFile).readAsBytes();
      final nativeAssetKernelBytes =
          await File(nativeAssetsDillFile).readAsBytes();
      await File(kernelFile).writeAsBytes(
        [
          ...programKernelBytes,
          ...nativeAssetKernelBytes,
        ],
        flush: true,
      );
    }

    if (verbose) {
      print('Generating AOT snapshot. $genSnapshot $extraOptions');
    }
    final snapshotFile =
        kind == Kind.aot ? outputPath : path.join(tempDir.path, 'snapshot.aot');
    final snapshotResult = await generateAotSnapshotHelper(
      kernelFile,
      snapshotFile,
      debugPath,
      enableAsserts,
      extraOptions,
    );

    if (verbose || snapshotResult.exitCode != 0) {
      await _forwardOutput(snapshotResult);
    }
    if (snapshotResult.exitCode != 0) {
      throw StateError('Generating AOT snapshot failed!');
    }

    if (kind == Kind.exe) {
      if (verbose) {
        print('Generating executable.');
      }
      await writeAppendedExecutable(dartaotruntime, snapshotFile, outputPath);

      if (Platform.isLinux || Platform.isMacOS) {
        if (verbose) {
          print('Marking binary executable.');
        }
        await markExecutable(outputPath);
      }
    }

    print('Generated: $outputPath');
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

/// Generates a kernel file.
///
/// [sourceFile] can be the path to either a Dart source file containing `main`
/// or a kernel file.
///
/// [outputFile] is the location the generated output will be written. If null,
/// the generated output will be written adjacent to [sourceFile] with the file
/// extension matching the executable type specified by its [Kind].
///
/// [defines] is the list of Dart defines to be set in the compiled program.
///
/// [packages] is the path to the `.dart_tool/package_config.json`.
///
/// [verbosity] specifies the logging verbosity of the CFE.
///
/// [enableExperiment] is a comma separated list of language experiments to be
/// enabled.
///
/// [linkPlatform] controls whether or not the platform kernel is included in
/// the output kernel file. This must be `true` if the resulting kernel is
/// meant to be used with `dart compile {exe, aot-snapshot}`.
///
/// [embedSources] controls whether or not Dart source code is included in the
/// output kernel file.
///
/// [product] specifies whether or not the resulting kernel should be generated
/// using PRODUCT mode platform binaries.
///
/// [nativeAssets] is the path to `native_assets.yaml`.
///
/// [resourcesFile] is the path to `resources.json`.
Future<void> generateKernel({
  required String sourceFile,
  required String outputFile,
  required List<String> defines,
  required String? packages,
  required String verbosity,
  required String enableExperiment,
  bool linkPlatform = false,
  bool embedSources = true,
  // TODO: Do we want to allow for users to generate non-product mode kernel?
  //   What are the implications of using a product mode kernel
  //   in a non-product runtime?
  bool product = true,
  bool verbose = false,
  String? nativeAssets,
  String? resourcesFile,
}) async {
  final sourcePath = _normalize(sourceFile)!;
  final outputPath = _normalize(outputFile)!;
  packages = _normalize(packages);

  final kernelResult = await generateKernelHelper(
    dartaotruntime: dartaotruntime,
    sourceFile: sourcePath,
    kernelFile: outputPath,
    packages: packages,
    defines: defines,
    linkPlatform: linkPlatform,
    embedSources: embedSources,
    fromDill: await isKernelFile(sourcePath),
    enableExperiment: enableExperiment,
    extraGenKernelOptions: [
      '--invocation-modes=compile',
      '--verbosity=$verbosity',
    ],
    nativeAssets: nativeAssets,
    resourcesFile: resourcesFile,
    product: product,
  );
  await _forwardOutput(kernelResult);
  if (kernelResult.exitCode != 0) {
    throw StateError('Generating kernel failed!');
  }
}

String? _normalize(String? p) {
  if (p == null) return null;
  return path.canonicalize(path.normalize(p));
}

/// Forward the output of [result] to stdout and stderr.
Future<void> _forwardOutput(ProcessResult result) async {
  if (result.stdout case final resultOutput
      when processOutputIsNotEmpty(resultOutput)) {
    final needsNewLine =
        resultOutput is! String || !resultOutput.endsWith('\n');
    if (result.exitCode == 0) {
      stdout.write(resultOutput);
      if (needsNewLine) stdout.writeln();
      await stdout.flush();
    } else {
      stderr.write(resultOutput);
      if (needsNewLine) stderr.writeln();
    }
  }
  if (result.stderr case final resultErrorOutput
      when processOutputIsNotEmpty(resultErrorOutput)) {
    final needsNewLine =
        resultErrorOutput is! String || !resultErrorOutput.endsWith('\n');
    stderr.write(resultErrorOutput);
    if (needsNewLine) {
      stderr.writeln();
    }
    await stderr.flush();
  }
}
