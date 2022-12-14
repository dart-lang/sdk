// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import './macho.dart';

// Simplifies casting so we get null values back instead of exceptions.
T? cast<T>(x) => x is T ? x : null;

// Pipe from one file stream into another. We do this in chunks to avoid
// excessive memory load.
Future<int> pipeStream(RandomAccessFile from, RandomAccessFile to,
    {int? numToWrite, int chunkSize = 1 << 30}) async {
  int numWritten = 0;
  final int fileLength = from.lengthSync();
  while (from.positionSync() != fileLength) {
    final int availableBytes = fileLength - from.positionSync();
    final int numToRead = numToWrite == null
        ? min(availableBytes, chunkSize)
        : min(numToWrite - numWritten, min(availableBytes, chunkSize));

    final buffer = await from.read(numToRead);
    await to.writeFrom(buffer);

    numWritten += numToRead;

    if (numToWrite != null && numWritten >= numToWrite) {
      break;
    }
  }

  return numWritten;
}

class _MacOSVersion {
  final int? _major;
  final int? _minor;

  static final _regexp = RegExp(r'Version (?<major>\d+).(?<minor>\d+)');
  static const _parseFailure = 'Could not determine macOS version';

  const _MacOSVersion._internal(this._major, this._minor);

  static const _unknown = _MacOSVersion._internal(null, null);

  factory _MacOSVersion() {
    if (!Platform.isMacOS) return _unknown;
    final match =
        _regexp.matchAsPrefix(Platform.operatingSystemVersion) as RegExpMatch?;
    if (match == null) return _unknown;
    final minor = int.tryParse(match.namedGroup('minor')!);
    final major = int.tryParse(match.namedGroup('major')!);
    return _MacOSVersion._internal(major, minor);
  }

  bool get isValid => _major != null;
  int get major => _major ?? (throw _parseFailure);
  int get minor => _minor ?? (throw _parseFailure);
}

// Writes an "appended" dart runtime + script snapshot file in a format
// compatible with MachO executables.
Future writeAppendedMachOExecutable(
    String dartaotruntimePath, String payloadPath, String outputPath) async {
  final aotRuntimeFile = File(dartaotruntimePath);

  final aotRuntimeHeaders = MachOFile.fromFile(aotRuntimeFile);
  final oldLinkEdit = aotRuntimeHeaders.linkEditSegment;
  if (oldLinkEdit == null) {
    throw FormatException("__LINKEDIT segment not found");
  }

  // Get the length of the contents of the section to be added.
  final snapshotFile = File(payloadPath);
  final payloadLength = snapshotFile.lengthSync();

  // Add the header information for where the snapshot will live, and retrieve
  // the needed parts back out of the new headers.
  final outputHeaders =
      aotRuntimeHeaders.adjustHeaderForSnapshot(payloadLength);
  final snapshotNote = outputHeaders.snapshotNote!;
  final newLinkEdit = outputHeaders.linkEditSegment!;

  final output = await File(outputPath).open(mode: FileMode.write);

  void addPadding(int start, int end) {
    assert(end >= start);
    output.writeFromSync(List.filled(end - start, 0));
  }

  // First, write the new headers.
  outputHeaders.writeSync(output);
  // If the newer headers are smaller, add appropriate padding to fit.
  addPadding(outputHeaders.size, aotRuntimeHeaders.size);

  // Now write the original contents from the header to the __LINKEDIT segment
  // contents.
  final aotRuntimeStream = await aotRuntimeFile.open();
  await aotRuntimeStream.setPosition(aotRuntimeHeaders.size);
  await pipeStream(aotRuntimeStream, output,
      numToWrite: oldLinkEdit.fileOffset - aotRuntimeHeaders.size);

  // Now insert the snapshot contents at this position in the file.
  // There may be additional padding needed between the old __LINKEDIT file
  // offset and the start of the new snapshot.
  addPadding(oldLinkEdit.fileOffset, snapshotNote.fileOffset);
  final snapshotStream = await snapshotFile.open();
  await pipeStream(snapshotStream, output);
  // Now add appropriate padding after the snapshot to reach the expected offset
  // of the __LINKEDIT segment in the new file.
  final snapshotEnd = snapshotNote.fileOffset + snapshotNote.fileSize;
  addPadding(snapshotEnd, newLinkEdit.fileOffset);

  // Copy the rest of the file from the original to the new one.
  await pipeStream(aotRuntimeStream, output);
  await output.close();

  if (outputHeaders.hasCodeSignature) {
    if (!Platform.isMacOS) {
      throw 'Cannot sign MachO binary on non-macOS platform';
    }

    // After writing the modified file, we perform ad-hoc signing (no identity)
    // to ensure that any LC_CODE_SIGNATURE block has the correct CD hashes.
    // This is necessary for platforms where signature verification is always on
    // (e.g., OS X on M1).
    //
    // We use the `-f` flag to force signature overwriting as the official
    // Dart binaries (including dartaotruntime) are fully signed.
    final args = ['-f', '-s', '-', outputPath];

    // If running on macOS >=11.0, then the linker-signed option flag can be
    // used to create a signature that does not need to be force overridden.
    final version = _MacOSVersion();
    if (version.isValid && version.major >= 11) {
      final signingProcess =
          await Process.run('codesign', ['-o', 'linker-signed', ...args]);
      if (signingProcess.exitCode == 0) {
        return;
      }
      print('Failed to add a linker signed signature, '
          'adding a regular signature instead.');
    }

    // If that fails or we're running on an older or undetermined version of
    // macOS, we fall back to signing without the linker-signed option flag.
    // Thus, to sign the binary, the developer must force signature overwriting.
    final signingProcess = await Process.run('codesign', args);
    if (signingProcess.exitCode != 0) {
      stderr
        ..write('Failed to replace the dartaotruntime signature, ')
        ..write('subcommand terminated with exit code ')
        ..write(signingProcess.exitCode)
        ..writeln('.');
      if (signingProcess.stdout.isNotEmpty) {
        stderr
          ..writeln('Subcommand stdout:')
          ..writeln(signingProcess.stdout);
      }
      if (signingProcess.stderr.isNotEmpty) {
        stderr
          ..writeln('Subcommand stderr:')
          ..writeln(signingProcess.stderr);
      }
      throw 'Could not sign the new executable';
    }
  }
}
