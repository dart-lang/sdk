// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

const appSnapshotPageSize = 4096;
const appjitMagicNumber = <int>[0xdc, 0xdc, 0xf6, 0xf6, 0, 0, 0, 0];

enum Kind { aot, exe }

Future writeAppendedExecutable(
    String dartaotruntimePath, String payloadPath, String outputPath) async {
  final dartaotruntime = File(dartaotruntimePath);
  final int dartaotruntimeLength = dartaotruntime.lengthSync();

  final padding =
      ((appSnapshotPageSize - dartaotruntimeLength) % appSnapshotPageSize);
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

Future generateAotKernel(String dart, String genKernel, String platformDill,
    String sourceFile, String kernelFile, String packages, List<String> defines,
    {String enableExperiment = '',
    List<String> extraGenKernelOptions = const []}) {
  return Process.run(dart, [
    genKernel,
    '--platform',
    platformDill,
    if (enableExperiment.isNotEmpty) '--enable-experiment=${enableExperiment}',
    '--aot',
    '-Ddart.vm.product=true',
    ...(defines.map((d) => '-D${d}')),
    if (packages != null) ...['--packages', packages],
    '-o',
    kernelFile,
    ...extraGenKernelOptions,
    sourceFile
  ]);
}

Future generateAotSnapshot(
    String genSnapshot,
    String kernelFile,
    String snapshotFile,
    String debugFile,
    bool enableAsserts,
    List<String> extraGenSnapshotOptions) {
  return Process.run(genSnapshot, [
    '--snapshot-kind=app-aot-elf',
    '--elf=${snapshotFile}',
    if (debugFile != null) '--save-debugging-info=$debugFile',
    if (debugFile != null) '--dwarf-stack-traces',
    if (debugFile != null) '--strip',
    if (enableAsserts) '--enable-asserts',
    ...extraGenSnapshotOptions,
    kernelFile
  ]);
}
