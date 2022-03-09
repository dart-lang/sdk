// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import './macho.dart';

extension ByteReader on RandomAccessFile {
  Uint32 readUint32() {
    Uint8List rawBytes = readSync(4);
    var byteView = ByteData.view(rawBytes.buffer);
    return Uint32(byteView.getUint32(0, Endian.little));
  }

  Uint64 readUint64() {
    Uint8List rawBytes = readSync(8);
    var byteView = ByteData.view(rawBytes.buffer);
    return Uint64(byteView.getUint64(0, Endian.little));
  }

  Int32 readInt32() {
    Uint8List rawBytes = readSync(4);
    var byteView = ByteData.view(rawBytes.buffer);
    return Int32(byteView.getInt32(0, Endian.little));
  }
}

class MachOFile {
  IMachOHeader? header;
  // The headerMaxOffset is set during parsing based on the maximum offset for
  // segment offsets. Assuming the header start at byte 0 (that seems to always
  // be the case), this number represents the total size of the header, which
  // often includes a significant amount of zero-padding.
  int headerMaxOffset = 0;
  // We keep track on whether a code signature was seen so we can recreate it
  // in the case that the binary has a CD hash that nededs updating.
  bool hasCodeSignature = false;

  // This wil contain all of the "load commands" in this MachO file. A load
  // command is really a typed schema that indicates various parts of the MachO
  // file (e.g. where to find the TEXT and DATA sections).
  List<IMachOLoadCommand> commands =
      List<IMachOLoadCommand>.empty(growable: true);

  MachOFile();

  // Returns the number of bytes read from the file.
  Future<int> loadFromFile(File file) async {
    // Ensure the file is long enough to contain the magic bytes.
    final int fileLength = await file.length();
    if (fileLength < 4) {
      throw FormatException(
          "File was not formatted properly. Length was too short: $fileLength");
    }

    // Read the first 4 bytes to see what type of MachO file this is.
    var stream = await file.open();
    var magic = stream.readUint32();

    bool is64Bit = magic == MachOConstants.MH_MAGIC_64 ||
        magic == MachOConstants.MH_CIGAM_64;

    await stream.setPosition(0);

    // Set the max header offset to the maximum file size so that when we read
    // in the header we can correctly set the total header size.
    headerMaxOffset = (1 << 63) - 1;

    header = await _headerFromStream(stream, is64Bit);
    if (header == null) {
      throw FormatException(
          "Could not parse a MachO header from the file: ${file.path}");
    } else {
      commands = await _commandsFromStream(stream, header!);
    }

    return stream.positionSync();
  }

  Future<MachOSymtabCommand> parseSymtabFromStream(
      final Uint32 cmdsize, RandomAccessFile stream) async {
    final symoff = stream.readUint32();
    final nsyms = stream.readUint32();
    final stroff = stream.readUint32();
    final strsize = stream.readUint32();

    return MachOSymtabCommand(cmdsize, symoff, nsyms, stroff, strsize);
  }

  Future<MachODysymtabCommand> parseDysymtabFromStream(
      final Uint32 cmdsize, RandomAccessFile stream) async {
    final ilocalsym = stream.readUint32();
    final nlocalsym = stream.readUint32();
    final iextdefsym = stream.readUint32();
    final nextdefsym = stream.readUint32();
    final iundefsym = stream.readUint32();
    final nundefsym = stream.readUint32();
    final tocoff = stream.readUint32();
    final ntoc = stream.readUint32();
    final modtaboff = stream.readUint32();
    final nmodtab = stream.readUint32();
    final extrefsymoff = stream.readUint32();
    final nextrefsyms = stream.readUint32();
    final indirectsymoff = stream.readUint32();
    final nindirectsyms = stream.readUint32();
    final extreloff = stream.readUint32();
    final nextrel = stream.readUint32();
    final locreloff = stream.readUint32();
    final nlocrel = stream.readUint32();

    return MachODysymtabCommand(
        cmdsize,
        ilocalsym,
        nlocalsym,
        iextdefsym,
        nextdefsym,
        iundefsym,
        nundefsym,
        tocoff,
        ntoc,
        modtaboff,
        nmodtab,
        extrefsymoff,
        nextrefsyms,
        indirectsymoff,
        nindirectsyms,
        extreloff,
        nextrel,
        locreloff,
        nlocrel);
  }

  Future<MachOLinkeditDataCommand> parseLinkeditDataCommand(
      final Uint32 cmd, final Uint32 cmdsize, RandomAccessFile stream) async {
    final dataoff = stream.readUint32();
    final datasize = stream.readUint32();

    return MachOLinkeditDataCommand(
      cmd,
      cmdsize,
      dataoff,
      datasize,
    );
  }

  Future<MachODyldInfoCommand> parseDyldInfoFromStream(
      final Uint32 cmd, final Uint32 cmdsize, RandomAccessFile stream) async {
    // Note that we're relying on the fact that the mirror returns the list of
    // fields in the same order they're defined ni the class definition.

    final rebaseOff = stream.readUint32();
    final rebaseSize = stream.readUint32();
    final bindOff = stream.readUint32();
    final bindSize = stream.readUint32();
    final weakBindOff = stream.readUint32();
    final weakBindSize = stream.readUint32();
    final lazyBindOff = stream.readUint32();
    final lazyBindSize = stream.readUint32();
    final exportOff = stream.readUint32();
    final exportSize = stream.readUint32();

    return MachODyldInfoCommand(
        cmd,
        cmdsize,
        rebaseOff,
        rebaseSize,
        bindOff,
        bindSize,
        weakBindOff,
        weakBindSize,
        lazyBindOff,
        lazyBindSize,
        exportOff,
        exportSize);
  }

  Future<MachOSegmentCommand64> parseSegmentCommand64FromStream(
      final Uint32 cmdsize, RandomAccessFile stream) async {
    final Uint8List segname = await stream.read(16);
    final vmaddr = stream.readUint64();
    final vmsize = stream.readUint64();
    final fileoff = stream.readUint64();
    final filesize = stream.readUint64();
    final maxprot = stream.readInt32();
    final initprot = stream.readInt32();
    final nsects = stream.readUint32();
    final flags = stream.readUint32();

    if (nsects.asInt() == 0 && filesize.asInt() != 0) {
      headerMaxOffset = min(headerMaxOffset, fileoff.asInt());
    }

    final sections = List.filled(nsects.asInt(), 0).map((_) {
      final Uint8List sectname = stream.readSync(16);
      final Uint8List segname = stream.readSync(16);
      final addr = stream.readUint64();
      final size = stream.readUint64();
      final offset = stream.readUint32();
      final align = stream.readUint32();
      final reloff = stream.readUint32();
      final nreloc = stream.readUint32();
      final flags = stream.readUint32();
      final reserved1 = stream.readUint32();
      final reserved2 = stream.readUint32();
      final reserved3 = stream.readUint32();

      final notZerofill =
          (flags & MachOConstants.S_ZEROFILL) != MachOConstants.S_ZEROFILL;
      if (offset > 0 && size > 0 && notZerofill) {
        headerMaxOffset = min(headerMaxOffset, offset.asInt());
      }

      return MachOSection64(sectname, segname, addr, size, offset, align,
          reloff, nreloc, flags, reserved1, reserved2, reserved3);
    }).toList();

    return MachOSegmentCommand64(cmdsize, segname, vmaddr, vmsize, fileoff,
        filesize, maxprot, initprot, nsects, flags, sections);
  }

  Future<IMachOHeader> _headerFromStream(
      RandomAccessFile stream, bool is64Bit) async {
    final magic = stream.readUint32();
    final cputype = stream.readUint32();
    final cpusubtype = stream.readUint32();
    final filetype = stream.readUint32();
    final ncmds = stream.readUint32();
    final sizeofcmds = stream.readUint32();
    final flags = stream.readUint32();

    if (is64Bit) {
      final reserved = stream.readUint32();
      return MachOHeader(magic, cputype, cpusubtype, filetype, ncmds,
          sizeofcmds, flags, reserved);
    } else {
      return MachOHeader32(
          magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags);
    }
  }

  void writeLoadCommandToStream(
      IMachOLoadCommand command, RandomAccessFile stream) {
    command.writeSync(stream);
  }

  void writeSync(RandomAccessFile stream) {
    // Write the header.
    stream.writeUint32(header!.magic);
    stream.writeUint32(header!.cputype);
    stream.writeUint32(header!.cpusubtype);
    stream.writeUint32(header!.filetype);
    stream.writeUint32(header!.ncmds);
    stream.writeUint32(header!.sizeofcmds);
    stream.writeUint32(header!.flags);

    if (header is MachOHeader) {
      stream.writeUint32(header!.reserved);
    }

    // Write all of the commands.
    commands.forEach((command) {
      writeLoadCommandToStream(command, stream);
    });

    // Pad the header according to the offset.
    final int paddingAmount = headerMaxOffset - stream.positionSync();
    if (paddingAmount > 0) {
      stream.writeFromSync(List.filled(paddingAmount, 0));
    }
  }

  Future<List<IMachOLoadCommand>> _commandsFromStream(
      RandomAccessFile stream, IMachOHeader header) async {
    final loadCommands = List<MachOLoadCommand>.empty(growable: true);
    for (int i = 0; i < header.ncmds.asInt(); i++) {
      final cmd = stream.readUint32();
      final cmdsize = stream.readUint32();

      // We need to read cmdsize bytes to get to the next command definition,
      // but the cmdsize does includes the 2 bytes we just read (cmd +
      // cmdsize) so we need to subtract those.
      await stream
          .setPosition((await stream.position()) + cmdsize.asInt() - 2 * 4);

      loadCommands.add(MachOLoadCommand(cmd, cmdsize));
    }

    // Un-read all the bytes we just read.
    var loadCommandsOffset = loadCommands
        .map((command) => command.cmdsize)
        .reduce((value, element) => value + element);
    await stream
        .setPosition((await stream.position()) - loadCommandsOffset.asInt());

    final commands = List<IMachOLoadCommand>.empty(growable: true);
    for (int i = 0; i < header.ncmds.asInt(); i++) {
      final cmd = stream.readUint32();
      final cmdsize = stream.readUint32();

      // TODO(sarietta): Handle all MachO load command types. For now, since
      // this implementation is exclusively being used to handle generating
      // MacOS-compatible MachO executables for compiled dart scripts, only the
      // load commands that are currently implemented are strictly necessary. It
      // may be useful to handle all cases and pull this functionality out to a
      // separate MachO library.
      if (cmd == MachOConstants.LC_SEGMENT_64) {
        commands.add(await parseSegmentCommand64FromStream(cmdsize, stream));
      } else if (cmd == MachOConstants.LC_DYLD_INFO_ONLY ||
          cmd == MachOConstants.LC_DYLD_INFO) {
        commands.add(await parseDyldInfoFromStream(cmd, cmdsize, stream));
      } else if (cmd == MachOConstants.LC_SYMTAB) {
        commands.add(await parseSymtabFromStream(cmdsize, stream));
      } else if (cmd == MachOConstants.LC_DYSYMTAB) {
        commands.add(await parseDysymtabFromStream(cmdsize, stream));
      } else if (cmd == MachOConstants.LC_CODE_SIGNATURE ||
          cmd == MachOConstants.LC_SEGMENT_SPLIT_INFO ||
          cmd == MachOConstants.LC_FUNCTION_STARTS ||
          cmd == MachOConstants.LC_DATA_IN_CODE ||
          cmd == MachOConstants.LC_DYLIB_CODE_SIGN_DRS) {
        if (cmd == MachOConstants.LC_CODE_SIGNATURE) {
          hasCodeSignature = true;
        }
        commands.add(await parseLinkeditDataCommand(cmd, cmdsize, stream));
      } else if (cmd == MachOConstants.LC_SEGMENT ||
          cmd == MachOConstants.LC_SYMSEG ||
          cmd == MachOConstants.LC_THREAD ||
          cmd == MachOConstants.LC_UNIXTHREAD ||
          cmd == MachOConstants.LC_LOADFVMLIB ||
          cmd == MachOConstants.LC_IDFVMLIB ||
          cmd == MachOConstants.LC_IDENT ||
          cmd == MachOConstants.LC_FVMFILE ||
          cmd == MachOConstants.LC_PREPAGE ||
          cmd == MachOConstants.LC_LOAD_DYLIB ||
          cmd == MachOConstants.LC_ID_DYLIB ||
          cmd == MachOConstants.LC_LOAD_DYLINKER ||
          cmd == MachOConstants.LC_ID_DYLINKER ||
          cmd == MachOConstants.LC_PREBOUND_DYLIB ||
          cmd == MachOConstants.LC_ROUTINES ||
          cmd == MachOConstants.LC_SUB_FRAMEWORK ||
          cmd == MachOConstants.LC_SUB_UMBRELLA ||
          cmd == MachOConstants.LC_SUB_CLIENT ||
          cmd == MachOConstants.LC_SUB_LIBRARY ||
          cmd == MachOConstants.LC_TWOLEVEL_HINTS ||
          cmd == MachOConstants.LC_PREBIND_CKSUM ||
          cmd == MachOConstants.LC_LOAD_WEAK_DYLIB ||
          cmd == MachOConstants.LC_ROUTINES_64 ||
          cmd == MachOConstants.LC_UUID ||
          cmd == MachOConstants.LC_RPATH ||
          cmd == MachOConstants.LC_REEXPORT_DYLIB ||
          cmd == MachOConstants.LC_LAZY_LOAD_DYLIB ||
          cmd == MachOConstants.LC_ENCRYPTION_INFO ||
          cmd == MachOConstants.LC_LOAD_UPWARD_DYLIB ||
          cmd == MachOConstants.LC_VERSION_MIN_MACOSX ||
          cmd == MachOConstants.LC_VERSION_MIN_IPHONEOS ||
          cmd == MachOConstants.LC_DYLD_ENVIRONMENT ||
          cmd == MachOConstants.LC_MAIN ||
          cmd == MachOConstants.LC_SOURCE_VERSION ||
          cmd == MachOConstants.LC_BUILD_VERSION) {
        // cmdsize includes the size of the contents + cmd + cmdsize
        final contents = await stream.read(cmdsize.asInt() - 2 * 4);
        commands.add(MachOGenericLoadCommand(cmd, cmdsize, contents));
      } else {
        // cmdsize includes the size of the contents + cmd + cmdsize
        final contents = await stream.read(cmdsize.asInt() - 2 * 4);
        commands.add(MachOGenericLoadCommand(cmd, cmdsize, contents));
        final cmdString = "0x${cmd.asInt().toRadixString(16)}";
        print("Found unknown MachO load command: $cmdString");
      }
    }

    return commands;
  }
}
