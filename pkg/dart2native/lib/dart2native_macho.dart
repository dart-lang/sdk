// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart2native/macho.dart';
import 'package:dart2native/macho_parser.dart';

const String kSnapshotSegmentName = "__CUSTOM";
const String kSnapshotSectionName = "__dart_app_snap";
const int kMinimumSegmentSize = 0x4000;
// Since arm64 macOS has 16K pages, which is larger than the 4K pages on x64
// macOS, we use this larger page size to ensure the MachO file is aligned
// properly on all architectures.
const int kSegmentAlignment = 0x4000;

int align(int size, int base) {
  final int over = size % base;
  if (over != 0) {
    return size + (base - over);
  }
  return size;
}

// Utility for aligning parts of MachO headers to the defined sizes.
int vmSizeAlign(int size) {
  return align(max(size, kMinimumSegmentSize), kSegmentAlignment);
}

// Returns value + amount only if the original value is within the bounds
// defined by [withinStart, withinStart + withinSize).
Uint32 addIfWithin(
    Uint32 value, Uint64 amount, Uint64 withinStart, Uint64 withinSize) {
  final intWithinStart = withinStart.asInt();
  final intWithinSize = withinSize.asInt();

  if (value >= intWithinStart && value < (intWithinStart + intWithinSize)) {
    return (value.asUint64() + amount).asUint32();
  } else {
    return value;
  }
}

// Trims a bytestring that an arbitrary number of null characters on the end of
// it.
String trimmedBytestring(Uint8List bytestring) {
  return String.fromCharCodes(bytestring.takeWhile((value) => value != 0));
}

// Simplifies casting so we get null values back instead of exceptions.
T? cast<T>(x) => x is T ? x : null;

// Inserts a segment definition into a MachOFile. This does NOT insert the
// actual segment into the file. It only inserts the definition of that segment
// into the MachO header.
//
// In addition to simply specifying the definition for the segment, this
// function also moves the existing __LINKEDIT segment to the end of the header
// definition as is required by the MachO specification (or at least MacOS's
// implementation of it). In doing so there are several offsets in the original
// __LINKEDIT segment that must be updated to point to their new location
// because the __LINKEDIT segment and sections are now in a different
// place. This function takes care of those shifts as well.
//
// Returns the original, unmodified, __LINKEDIT segment.
Future<MachOSegmentCommand64> insertSegmentDefinition(MachOFile file,
    File segment, String segmentName, String sectionName) async {
  // Load in the data to be inserted.
  final segmentData = await segment.readAsBytes();

  // Find the existing __LINKEDIT segment
  final linkedit = cast<MachOSegmentCommand64>(file.commands
      .where((segment) =>
          segment.asType() is MachOSegmentCommand64 &&
          MachOConstants.SEG_LINKEDIT ==
              trimmedBytestring((segment as MachOSegmentCommand64).segname))
      .first);

  final linkeditIndex = file.commands.indexWhere((segment) =>
      segment.asType() is MachOSegmentCommand64 &&
      MachOConstants.SEG_LINKEDIT ==
          trimmedBytestring((segment as MachOSegmentCommand64).segname));

  if (linkedit == null) {
    throw FormatException(
        "Could not find a __LINKEDIT section in the specified binary.");
  } else {
    // Create the new segment.
    final Uint8List segname = Uint8List(16);
    segname.setRange(0, segmentName.length, ascii.encode(segmentName));
    segname.fillRange(segmentName.length, 16, 0);

    final Uint64 vmaddr = linkedit.vmaddr;
    final Uint64 vmsize = Uint64(vmSizeAlign(segmentData.length));
    final Uint64 fileoff = linkedit.fileoff;
    final Uint64 filesize = vmsize;
    final Int32 maxprot = MachOConstants.VM_PROT_READ;
    final Int32 initprot = maxprot;
    final Uint32 nsects = Uint32(1);

    final Uint8List sectname = Uint8List(16);
    sectname.setRange(0, sectionName.length, ascii.encode(sectionName));
    sectname.fillRange(sectionName.length, 16, 0);

    final Uint64 addr = vmaddr;
    final Uint64 size = Uint64(segmentData.length);
    final Uint32 offset = fileoff.asUint32();
    final Uint32 flags = MachOConstants.S_REGULAR;

    final Uint32 zero = Uint32(0);

    final loadCommandDefinitionSize = 4 * 2;
    final sectionDefinitionSize = 16 * 2 + 8 * 2 + 4 * 8;
    final segmentDefinitionSize = 16 + 8 * 4 + 4 * 4;
    final commandSize = loadCommandDefinitionSize +
        segmentDefinitionSize +
        sectionDefinitionSize;

    final loadCommand =
        MachOLoadCommand(MachOConstants.LC_SEGMENT_64, Uint32(commandSize));

    final section = MachOSection64(sectname, segname, addr, size, offset, zero,
        zero, zero, flags, zero, zero, zero);

    final segment = MachOSegmentCommand64(Uint32(commandSize), segname, vmaddr,
        vmsize, fileoff, filesize, maxprot, initprot, nsects, zero, [section]);

    // Setup the new linkedit command.
    final shiftedLinkeditVmaddr = linkedit.vmaddr + segment.vmsize;
    final shiftedLinkeditFileoff = linkedit.fileoff + segment.filesize;
    final shiftedLinkedit = MachOSegmentCommand64(
        linkedit.cmdsize,
        linkedit.segname,
        shiftedLinkeditVmaddr,
        linkedit.vmsize,
        shiftedLinkeditFileoff,
        linkedit.filesize,
        linkedit.maxprot,
        linkedit.initprot,
        linkedit.nsects,
        linkedit.flags,
        linkedit.sections);

    // Shift all of the related commands that need to reference the new file
    // position of the linkedit segment.
    for (var i = 0; i < file.commands.length; i++) {
      final command = file.commands[i];

      final offsetAmount = segment.filesize;
      final withinStart = linkedit.fileoff;
      final withinSize = linkedit.filesize;

      // For the specific command that we need to adjust, we need to move the
      // commands' various offsets forward by the new segment's size in the file
      // (segment.filesize). However, we need to ensure that when we move the
      // offset forward, we exclude cases where the offset was originally
      // outside of the linkedit segment (i.e. offset < linkedit.fileoff or
      // offset >= linkedit.fileoff + linkedit.filesize). The DRY-ing function
      // addIfWithin takes care of that repeated logic.
      if (command is MachODyldInfoCommand) {
        file.commands[i] = MachODyldInfoCommand(
            command.cmd,
            command.cmdsize,
            addIfWithin(
                command.rebase_off, offsetAmount, withinStart, withinSize),
            command.rebase_size,
            addIfWithin(
                command.bind_off, offsetAmount, withinStart, withinSize),
            command.bind_size,
            addIfWithin(
                command.weak_bind_off, offsetAmount, withinStart, withinSize),
            command.weak_bind_size,
            addIfWithin(
                command.lazy_bind_off, offsetAmount, withinStart, withinSize),
            command.lazy_bind_size,
            addIfWithin(
                command.export_off, offsetAmount, withinStart, withinSize),
            command.export_size);
      } else if (command is MachOSymtabCommand) {
        file.commands[i] = MachOSymtabCommand(
            command.cmdsize,
            addIfWithin(command.symoff, offsetAmount, withinStart, withinSize),
            command.nsyms,
            addIfWithin(command.stroff, offsetAmount, withinStart, withinSize),
            command.strsize);
      } else if (command is MachODysymtabCommand) {
        file.commands[i] = MachODysymtabCommand(
            command.cmdsize,
            command.ilocalsym,
            command.nlocalsym,
            command.iextdefsym,
            command.nextdefsym,
            command.iundefsym,
            command.nundefsym,
            addIfWithin(command.tocoff, offsetAmount, withinStart, withinSize),
            command.ntoc,
            addIfWithin(
                command.modtaboff, offsetAmount, withinStart, withinSize),
            command.nmodtab,
            addIfWithin(
                command.extrefsymoff, offsetAmount, withinStart, withinSize),
            command.nextrefsyms,
            addIfWithin(
                command.indirectsymoff, offsetAmount, withinStart, withinSize),
            command.nindirectsyms,
            addIfWithin(
                command.extreloff, offsetAmount, withinStart, withinSize),
            command.nextrel,
            addIfWithin(
                command.locreloff, offsetAmount, withinStart, withinSize),
            command.nlocrel);
      } else if (command is MachOLinkeditDataCommand) {
        file.commands[i] = MachOLinkeditDataCommand(
            command.cmd,
            command.cmdsize,
            addIfWithin(command.dataoff, offsetAmount, withinStart, withinSize),
            command.datasize);
      }
    }

    // Now we need to build the new header from these modified pieces.
    file.header = MachOHeader(
        file.header!.magic,
        file.header!.cputype,
        file.header!.cpusubtype,
        file.header!.filetype,
        file.header!.ncmds + Uint32(1),
        file.header!.sizeofcmds + loadCommand.cmdsize,
        file.header!.flags,
        file.header!.reserved);

    file.commands[linkeditIndex] = shiftedLinkedit;
    file.commands.insert(linkeditIndex, segment);
  }

  return linkedit;
}

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
  File originalExecutableFile = File(dartaotruntimePath);

  MachOFile machOFile = MachOFile();
  await machOFile.loadFromFile(originalExecutableFile);

  // Insert the new segment that contains our snapshot data.
  File newSegmentFile = File(payloadPath);

  // Note that these two values MUST match the ones in
  // runtime/bin/snapshot_utils.cc, which looks specifically for the snapshot in
  // this segment/section.
  final linkeditCommand = await insertSegmentDefinition(
      machOFile, newSegmentFile, kSnapshotSegmentName, kSnapshotSectionName);

  // Write out the new executable, with the same contents except the new header.
  File outputFile = File(outputPath);
  RandomAccessFile stream = await outputFile.open(mode: FileMode.write);

  // Write the MachO header.
  machOFile.writeSync(stream);
  final int headerBytesWritten = stream.positionSync();

  RandomAccessFile newSegmentFileStream = await newSegmentFile.open();
  RandomAccessFile originalFileStream = await originalExecutableFile.open();
  await originalFileStream.setPosition(headerBytesWritten);

  // Write the unchanged data from the original file.
  await pipeStream(originalFileStream, stream,
      numToWrite: linkeditCommand.fileoff.asInt() - headerBytesWritten);

  // Write the inserted section data, ensuring that the data is padded to the
  // segment size.
  await pipeStream(newSegmentFileStream, stream);
  final int newSegmentLength = newSegmentFileStream.lengthSync();
  final int alignedSegmentSize = vmSizeAlign(newSegmentLength);
  await stream.writeFrom(List.filled(alignedSegmentSize - newSegmentLength, 0));

  // Copy the rest of the file from the original to the new one.
  await pipeStream(originalFileStream, stream);

  await stream.close();

  if (machOFile.hasCodeSignature) {
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
      print('Failed to replace the dartaotruntime signature, ');
      print('subcommand terminated with exit code ${signingProcess.exitCode}.');
      if (signingProcess.stdout.isNotEmpty) {
        print('Subcommand stdout:');
        print(signingProcess.stdout);
      }
      if (signingProcess.stderr.isNotEmpty) {
        print('Subcommand stderr:');
        print(signingProcess.stderr);
      }
      throw 'Could not sign the new executable';
    }
  }
}
