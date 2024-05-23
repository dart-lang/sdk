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

/// The kinds of native executables supported by [KernelGenerator].
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

/// First step of generating a snapshot, generating a kernel.
///
/// See also the docs for [_Generator].
extension type KernelGenerator._(_Generator _generator) {
  KernelGenerator({
    required String sourceFile,
    required List<String> defines,
    Kind kind = Kind.exe,
    String? outputFile,
    String? debugFile,
    String? packages,
    String? targetOS,
    String? depFile,
    String enableExperiment = '',
    bool enableAsserts = false,
    bool verbose = false,
    String verbosity = 'all',
    required Directory tempDir,
  }) : _generator = _Generator(
          sourceFile: sourceFile,
          defines: defines,
          tempDir: tempDir,
          debugFile: debugFile,
          enableAsserts: enableAsserts,
          enableExperiment: enableExperiment,
          kind: kind,
          outputFile: outputFile,
          packages: packages,
          targetOS: targetOS,
          verbose: verbose,
          verbosity: verbosity,
          depFile: depFile,
        );

  /// Generate a kernel file,
  ///
  /// [resourcesFile] is the path to `resources.json`, where the tree-shaking
  /// information collected during kernel compilation is stored.
  Future<SnapshotGenerator> generate({
    String? resourcesFile,
    List<String>? extraOptions,
  }) =>
      _generator.generateKernel(
        resourcesFile: resourcesFile,
        extraOptions: extraOptions,
      );
}

/// Second step of generating a snapshot is generating the snapshot itself.
///
/// See also the docs for [_Generator].
extension type SnapshotGenerator._(_Generator _generator) {
  /// Generate a snapshot or executable.
  ///
  /// This means concatenating the list of assets to the kernel and then calling
  /// `genSnapshot`. [nativeAssets] is the path to `native_assets.yaml`, and
  /// [extraOptions] is a set of extra options to be passed to `genSnapshot`.
  Future<void> generate({
    String? nativeAssets,
    List<String> extraOptions = const [],
  }) =>
      _generator.generateSnapshotWithAssets(
        nativeAssets: nativeAssets,
        extraOptions: extraOptions,
      );
}

/// Generates a self-contained executable or AOT snapshot.
///
/// This is a two-step process. First, a kernel is generated. Then, if present,
/// the list of assets is concatenated to the kernel as a library. In a final
/// step, the snapshot or executable itself is generated.
///
/// To reduce possible errors in calling order of the steps, this class is only
/// exposed through [KernelGenerator] and [SnapshotGenerator], which make it
/// impossible to call steps out of order.
class _Generator {
  /// The list of Dart defines to be set in the compiled program.
  final List<String> _defines;

  /// The type of executable to be generated, either [Kind.exe] or [Kind.aot].
  final Kind _kind;

  /// The location the generated output will be written. If null the generated
  /// output will be written adjacent to [_sourcePath] with the file extension
  /// matching the executable type specified by [_kind].
  final String? _outputFile;

  /// Specifies the file debugging information should be written to.
  final String? _debugFile;

  /// Specifies the operating system the executable is being generated for. This
  /// must be provided when [_kind] is [Kind.exe], and it must match the current
  /// operating system.
  final String? _targetOS;

  /// A comma separated list of language experiments to be enabled.
  final String _enableExperiment;

  ///
  final bool _enableAsserts;
  final bool _verbose;

  /// Specifies the logging verbosity of the CFE.
  final String _verbosity;

  /// A temporary directory specified by the caller, who also has to clean it
  /// up.
  final Directory _tempDir;

  /// The location of the compiled kernel file, which will be written on a call
  /// to [generateKernel].
  final String _programKernelFile;

  /// The path to either a Dart source file containing `main` or a kernel file
  /// generated with `--link-platform`.
  final String _sourcePath;

  /// The path to the `.dart_tool/package_config.json`.
  final String? _packages;

  /// The path to the [depfile](https://ninja-build.org/manual.html#_depfile).
  final String? _depFile;

  _Generator({
    required String sourceFile,
    required List<String> defines,
    required Kind kind,
    String? outputFile,
    String? debugFile,
    String? packages,
    String? targetOS,
    String? depFile,
    required String enableExperiment,
    required bool enableAsserts,
    required bool verbose,
    required String verbosity,
    required Directory tempDir,
  })  : _kind = kind,
        _verbose = verbose,
        _tempDir = tempDir,
        _verbosity = verbosity,
        _enableAsserts = enableAsserts,
        _enableExperiment = enableExperiment,
        _targetOS = targetOS,
        _debugFile = debugFile,
        _outputFile = outputFile,
        _defines = defines,
        _depFile = depFile,
        _programKernelFile = path.join(tempDir.path, 'program.dill'),
        _sourcePath = _normalize(sourceFile)!,
        _packages = _normalize(packages) {
    if (_kind == Kind.exe) {
      if (_targetOS == null) {
        throw ArgumentError('targetOS must be specified for executables.');
      } else if (_targetOS != Platform.operatingSystem) {
        throw UnsupportedError(
            'Cross compilation not supported for executables.');
      }
    }
  }

  Future<SnapshotGenerator> generateKernel({
    String? resourcesFile,
    List<String>? extraOptions,
  }) async {
    if (_verbose) {
      if (_targetOS != null) {
        print('Specializing Platform getters for target OS $_targetOS.');
      }
      print('Generating AOT kernel dill.');
    }

    final kernelResult = await generateKernelHelper(
      dartaotruntime: dartaotruntime,
      sourceFile: _sourcePath,
      kernelFile: _programKernelFile,
      packages: _packages,
      defines: _defines,
      depFile: _depFile,
      fromDill: await isKernelFile(_sourcePath),
      enableAsserts: _enableAsserts,
      enableExperiment: _enableExperiment,
      targetOS: _targetOS,
      extraGenKernelOptions: [
        '--invocation-modes=compile',
        '--verbosity=$_verbosity',
        if (_depFile != null) '--depfile-target=$_outputPath',
        ...?extraOptions,
      ],
      resourcesFile: resourcesFile,
      aot: true,
    );
    await _forwardOutput(kernelResult);
    if (kernelResult.exitCode != 0) {
      throw StateError('Generating AOT kernel dill failed!');
    }
    return SnapshotGenerator._(this);
  }

  Future<void> generateSnapshotWithAssets({
    String? nativeAssets,
    required List<String> extraOptions,
  }) async {
    final kernelFile = await _concatenateAssetsToKernel(nativeAssets);
    await _generateSnapshot(extraOptions, kernelFile);
  }

  String get _outputPath {
    final sourceWithoutDartOrDill = _sourcePath.replaceFirst(
      RegExp(r'\.(dart|dill)$'),
      '',
    );
    return _normalize(
      _outputFile ?? _kind.appendFileExtension(sourceWithoutDartOrDill),
    )!;
  }

  Future<void> _generateSnapshot(
    List<String> extraOptions,
    String kernelFile,
  ) async {
    final outputPath = _outputPath;
    final debugPath = _normalize(_debugFile);

    if (_verbose) {
      print('Compiling $_sourcePath to $outputPath using format $_kind:');
      print('Generating AOT snapshot. $genSnapshot $extraOptions');
    }
    final snapshotFile = _kind == Kind.aot
        ? outputPath
        : path.join(_tempDir.path, 'snapshot.aot');
    final snapshotResult = await generateAotSnapshotHelper(
      kernelFile,
      snapshotFile,
      debugPath,
      _enableAsserts,
      extraOptions,
    );

    if (_verbose || snapshotResult.exitCode != 0) {
      await _forwardOutput(snapshotResult);
    }
    if (snapshotResult.exitCode != 0) {
      throw StateError('Generating AOT snapshot failed!');
    }

    if (_kind == Kind.exe) {
      if (_verbose) {
        print('Generating executable.');
      }
      await writeAppendedExecutable(dartaotruntime, snapshotFile, outputPath);

      if (Platform.isLinux || Platform.isMacOS) {
        if (_verbose) {
          print('Marking binary executable.');
        }
        await markExecutable(outputPath);
      }
    }

    print('Generated: $outputPath');
  }

  Future<String> _concatenateAssetsToKernel(String? nativeAssets) async {
    if (nativeAssets == null) {
      return _programKernelFile;
    } else {
      // TODO(dacoharkes): This method will need to be split in two parts. Then
      // the link hooks can be run in between those two parts.
      final nativeAssetsDillFile =
          path.join(_tempDir.path, 'native_assets.dill');
      final kernelResult = await generateKernelHelper(
        dartaotruntime: dartaotruntime,
        kernelFile: nativeAssetsDillFile,
        packages: _packages,
        defines: _defines,
        enableAsserts: _enableAsserts,
        enableExperiment: _enableExperiment,
        targetOS: _targetOS,
        extraGenKernelOptions: [
          '--invocation-modes=compile',
          '--verbosity=$_verbosity',
        ],
        nativeAssets: nativeAssets,
        aot: true,
      );
      await _forwardOutput(kernelResult);
      if (kernelResult.exitCode != 0) {
        throw StateError('Generating AOT kernel dill failed!');
      }
      final kernelFile = path.join(_tempDir.path, 'kernel.dill');
      final programKernelBytes = await File(_programKernelFile).readAsBytes();
      final nativeAssetKernelBytes =
          await File(nativeAssetsDillFile).readAsBytes();
      await File(kernelFile).writeAsBytes(
        [
          ...programKernelBytes,
          ...nativeAssetKernelBytes,
        ],
        flush: true,
      );
      return kernelFile;
    }
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
  String? depFile,
  List<String>? extraOptions,
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
    depFile: depFile,
    extraGenKernelOptions: [
      '--invocation-modes=compile',
      '--verbosity=$verbosity',
      ...?extraOptions,
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
