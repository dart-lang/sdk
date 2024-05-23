// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:kernel/binary/tag.dart' show Tag;
import 'package:path/path.dart' as path;

import 'dart2native_macho.dart' show writeAppendedMachOExecutable;
import 'dart2native_pe.dart' show writeAppendedPortableExecutable;

final binDir = File(Platform.resolvedExecutable).parent;
final executableSuffix = Platform.isWindows ? '.exe' : '';
final genKernel = path.join(
  binDir.path,
  'snapshots',
  'gen_kernel_aot.dart.snapshot',
);
final genSnapshot = path.join(
  binDir.path,
  'utils',
  'gen_snapshot$executableSuffix',
);
final platformDill = path.join(
  binDir.parent.path,
  'lib',
  '_internal',
  'vm_platform_strong.dill',
);
final productPlatformDill = path.join(
  binDir.parent.path,
  'lib',
  '_internal',
  'vm_platform_strong_product.dill',
);

// Maximum page size across all supported architectures (arm64 macOS has 16K
// pages, some arm64 Linux distributions have 64K pages).
const elfPageSize = 65536;
const appJitMagicNumber = <int>[0xdc, 0xdc, 0xf6, 0xf6, 0, 0, 0, 0];

Future<bool> isKernelFile(String path) async {
  const kernelMagicNumber = Tag.ComponentFile;
  // Convert the 32-bit header into a list of 4 bytes.
  final kernelMagicNumberList = Uint8List(4)
    ..buffer.asByteData().setInt32(
          0,
          kernelMagicNumber,
          Endian.big,
        );

  final header = await File(path)
      .openRead(
        0,
        kernelMagicNumberList.length,
      )
      .first;

  return header.equals(kernelMagicNumberList);
}

// WARNING: this method is used within google3, so don't try to refactor so
// [dartaotruntime] is a constant inside this file.
Future<void> writeAppendedExecutable(
  String dartaotruntime,
  String payloadPath,
  String outputPath,
) async {
  if (Platform.isMacOS) {
    return await writeAppendedMachOExecutable(
        dartaotruntime, payloadPath, outputPath);
  } else if (Platform.isWindows) {
    return await writeAppendedPortableExecutable(
        dartaotruntime, payloadPath, outputPath);
  }

  final dartaotruntimeFile = File(dartaotruntime);
  final dartaotruntimeLength = dartaotruntimeFile.lengthSync();

  final padding = (elfPageSize - dartaotruntimeLength) % elfPageSize;
  final padBytes = Uint8List(padding);
  final offset = dartaotruntimeLength + padding;

  // Note: The offset is always Little Endian regardless of host.
  final offsetBytes = ByteData(8) // 64 bit in bytes.
    ..setUint64(0, offset, Endian.little);

  final outputFile = File(outputPath).openWrite();
  outputFile.add(dartaotruntimeFile.readAsBytesSync());
  outputFile.add(padBytes);
  outputFile.add(File(payloadPath).readAsBytesSync());
  outputFile.add(offsetBytes.buffer.asUint8List());
  outputFile.add(appJitMagicNumber);
  await outputFile.close();
}

Future<ProcessResult> markExecutable(String outputFile) {
  return Process.run('chmod', ['+x', outputFile]);
}

/// Generates kernel by running the provided [genKernel] path.
///
/// Also takes a path to the [resourcesFile] JSON file, where the method calls
/// to static functions annotated with `@ResourceIdentifier` will be collected.
Future<ProcessResult> generateKernelHelper({
  required String dartaotruntime,
  String? sourceFile,
  required String kernelFile,
  String? packages,
  List<String> defines = const [],
  String enableExperiment = '',
  String? targetOS,
  List<String> extraGenKernelOptions = const [],
  String? nativeAssets,
  String? resourcesFile,
  String? depFile,
  bool enableAsserts = false,
  bool fromDill = false,
  bool aot = false,
  bool embedSources = false,
  bool linkPlatform = true,
  bool product = true,
}) {
  final args = [
    genKernel,
    '--platform=${product ? productPlatformDill : platformDill}',
    if (product) '-Ddart.vm.product=true',
    if (enableExperiment.isNotEmpty) '--enable-experiment=$enableExperiment',
    if (targetOS != null) '--target-os=$targetOS',
    if (fromDill) '--from-dill=$sourceFile',
    if (aot) '--aot',
    if (!embedSources) '--no-embed-sources',
    if (!linkPlatform) '--no-link-platform',
    if (enableAsserts) '--enable-asserts',
    ...defines.map((d) => '-D$d'),
    if (packages != null) '--packages=$packages',
    if (nativeAssets != null) '--native-assets=$nativeAssets',
    if (resourcesFile != null) '--resources-file=$resourcesFile',
    if (depFile != null) '--depfile=$depFile',
    '--output=$kernelFile',
    ...extraGenKernelOptions,
    if (sourceFile != null) sourceFile,
  ];
  return Process.run(dartaotruntime, args);
}

Future<ProcessResult> generateAotSnapshotHelper(
    String kernelFile,
    String snapshotFile,
    String? debugFile,
    bool enableAsserts,
    List<String> extraGenSnapshotOptions) {
  return Process.run(genSnapshot, [
    '--snapshot-kind=app-aot-elf',
    '--elf=$snapshotFile',
    if (debugFile != null) '--save-debugging-info=$debugFile',
    if (debugFile != null) '--dwarf-stack-traces',
    if (debugFile != null) '--strip',
    if (enableAsserts) '--enable-asserts',
    ...extraGenSnapshotOptions,
    kernelFile
  ]);
}
