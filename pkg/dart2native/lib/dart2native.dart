// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'dart2native_macho.dart' show writeAppendedMachOExecutable;
import 'dart2native_pe.dart' show writeAppendedPortableExecutable;

// Maximum page size across all supported architectures (arm64 macOS has 16K
// pages, some arm64 Linux distributions have 64K pages).
const elfPageSize = 65536;
const appjitMagicNumber = <int>[0xdc, 0xdc, 0xf6, 0xf6, 0, 0, 0, 0];

enum Kind { aot, exe }

Future writeAppendedExecutable(
    String dartaotruntimePath, String payloadPath, String outputPath) async {
  if (Platform.isMacOS) {
    return await writeAppendedMachOExecutable(
        dartaotruntimePath, payloadPath, outputPath);
  } else if (Platform.isWindows) {
    return await writeAppendedPortableExecutable(
        dartaotruntimePath, payloadPath, outputPath);
  }

  final dartaotruntime = File(dartaotruntimePath);
  final int dartaotruntimeLength = dartaotruntime.lengthSync();

  final padding = ((elfPageSize - dartaotruntimeLength) % elfPageSize);
  final padBytes = Uint8List(padding);
  final offset = dartaotruntimeLength + padding;

  // Note: The offset is always Little Endian regardless of host.
  final offsetBytes = ByteData(8) // 64 bit in bytes.
    ..setUint64(0, offset, Endian.little);

  final outputFile = File(outputPath).openWrite();
  outputFile.add(dartaotruntime.readAsBytesSync());
  outputFile.add(padBytes);
  outputFile.add(File(payloadPath).readAsBytesSync());
  outputFile.add(offsetBytes.buffer.asUint8List());
  outputFile.add(appjitMagicNumber);
  await outputFile.close();
}

Future markExecutable(String outputFile) {
  return Process.run('chmod', ['+x', outputFile]);
}

Future<ProcessResult> generateAotKernel(
  String dart,
  String genKernel,
  String platformDill,
  String sourceFile,
  String kernelFile,
  String? packages,
  List<String> defines, {
  String enableExperiment = '',
  String? targetOS,
  List<String> extraGenKernelOptions = const [],
  String? nativeAssets,
}) {
  return Process.run(dart, [
    genKernel,
    '--platform',
    platformDill,
    if (enableExperiment.isNotEmpty) '--enable-experiment=$enableExperiment',
    if (targetOS != null) '--target-os=$targetOS',
    '--aot',
    '-Ddart.vm.product=true',
    ...(defines.map((d) => '-D$d')),
    if (packages != null) ...['--packages', packages],
    '-o',
    kernelFile,
    ...extraGenKernelOptions,
    if (nativeAssets != null) ...['--native-assets', nativeAssets],
    sourceFile
  ]);
}

Future generateAotSnapshot(
    String genSnapshot,
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
