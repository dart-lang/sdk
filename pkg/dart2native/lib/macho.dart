// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is a reimplementation of the header file mach-o/loader.h, which is
// part of the Apple system headers. All comments, which detail the format of
// Mach-O files, have been reproduced from the orginal header.

import 'dart:io';
import 'dart:typed_data';

// Extensions for writing the custom byte types (defined below) to streams
// (RandomAccessFile).
extension ByteWriter on RandomAccessFile {
  void writeUint32(Uint32 value) {
    final intValue = value.asInt();
    for (int i = 0; i < 4; i++) {
      writeByteSync((intValue >> (8 * i)) & 0xff);
    }
  }

  void writeUint64(Uint64 value) {
    final intValue = value.asInt();
    for (int i = 0; i < 8; i++) {
      writeByteSync((intValue >> (8 * i)) & 0xff);
    }
  }

  void writeInt32(Int32 value) {
    final intValue = value.asInt();
    for (int i = 0; i < 4; i++) {
      writeByteSync((intValue >> (8 * i)) & 0xff);
    }
  }
}

// The dart ffi library doesn't have definitions for integer operations (among
// others) on ffi types. Since we use those operations prolifically in handling
// MachO files, these are here as a convenience to avoid polluting the code with
// casts and operations.
abstract class IntLike {
  final int _data;
  const IntLike(this._data);

  int asInt() => _data;

  @override
  String toString() => asInt().toString();
}

class Uint64 extends IntLike {
  const Uint64(int data) : super(data);

  Uint64 operator +(Uint64 other) {
    return Uint64(_data + other._data);
  }

  Uint32 asUint32() {
    if (_data < 0 || _data >= (1 << 32)) {
      throw FormatException(
          "Attempted to cast a Uint64 to a Uint32, but the value will not fit in "
          "32bits: $_data");
    }

    return Uint32(_data);
  }

  bool operator <(int other) {
    // All positively encoded integers are less than negatively encoded ones.
    if (_data < 0 && other > 0) {
      return false;
    }
    if (other < 0) {
      return true;
    }
    return _data < other;
  }

  bool operator >(int other) {
    // All negatively encoded integers are greater than positively encoded ones.
    if (_data < 0 && other > 0) {
      return true;
    }
    if (other < 0) {
      return false;
    }
    return _data > other;
  }

  bool operator ==(other) {
    if (other is Uint64) {
      return _data == other._data;
    } else {
      return false;
    }
  }
}

class Int32 extends IntLike {
  const Int32(int data) : super(data);

  Int32 operator |(Int32 other) {
    return Int32(_data | other._data);
  }

  bool operator ==(other) {
    if (other is Int32) {
      return _data == other._data;
    } else {
      return false;
    }
  }
}

class Uint16 extends IntLike {
  const Uint16(int data) : super(data);
}

class Uint32 extends IntLike {
  const Uint32(int data) : super(data);

  Uint32 operator |(Uint32 other) {
    return Uint32(_data | other._data);
  }

  Uint32 operator +(Uint32 other) {
    return Uint32(_data + other._data);
  }

  Uint32 operator &(Uint32 other) {
    return Uint32(_data & other._data);
  }

  Uint32 operator >>(Uint32 other) {
    return Uint32(_data >> other._data);
  }

  bool operator <(int other) {
    return _data < other;
  }

  bool operator >(int other) {
    return _data > other;
  }

  bool operator >=(int other) {
    return _data >= other;
  }

  bool operator ==(other) {
    if (other is Uint32) {
      return _data == other._data;
    } else {
      return false;
    }
  }

  Uint64 asUint64() {
    return Uint64(_data);
  }
}

// A load command is simply a part of the MachO header that indicates there is
// typed schema that a consumer of the headers can use to understand how to load
// and run various parts of the file (e.g. where to find the TEXT and DATA
// sections). Every load command with a known schema in a MachO header should
// extend this abstract class. This class does not appear in the original MachO
// definitions, but is useful for the object-oriented nature of this
// implementation.
abstract class IMachOLoadCommand<T> {
  /* type of load command (uint32_t) */
  final Uint32 cmd;
  /* total size of command in bytes (uint32_t) */
  final Uint32 cmdsize;

  IMachOLoadCommand(this.cmd, this.cmdsize);
  T asType();

  void writeSync(RandomAccessFile stream) {
    stream.writeUint32(cmd);
    stream.writeUint32(cmdsize);
    writeContentsSync(stream);
  }

  // Subclasses need to implement this serializer, which should NOT
  // attempt to serialize the cmd and the cmdsize to the stream. That
  // logic is handled by the parent class automatically.
  void writeContentsSync(RandomAccessFile stream);
}

// In cases where it's not necessary to actually deserialize a load command into
// its schema, we use this catch-all class.
class MachOGenericLoadCommand
    extends IMachOLoadCommand<MachOGenericLoadCommand> {
  final Uint8List contents;

  MachOGenericLoadCommand(cmd, cmdsize, this.contents) : super(cmd, cmdsize);

  @override
  MachOGenericLoadCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeFromSync(contents);
  }
}

// There are two types of headers: 32bit and 64bit. The only difference is that
// 64bit headers have a reserved field. This class does not appear in the
// original header definitions, but is useful for the object-oriented nature of
// this implementation.
abstract class IMachOHeader {
  /* mach magic number identifier (uint32_t) */
  final Uint32 magic;
  /* cpu specifier (uint32_t) */
  final Uint32 cputype;
  /* machine specifier (uint32_t) */
  final Uint32 cpusubtype;
  /* type of file (uint32_t) */
  final Uint32 filetype;
  /* number of load commands (uint32_t) */
  final Uint32 ncmds;
  /* the size of all the load commands (uint32_t) */
  final Uint32 sizeofcmds;
  /* flags (uint32_t) */
  final Uint32 flags;

  /* reserved (uint32_t) */
  final Uint32 reserved; // Only used in 64bit MachO files

  IMachOHeader(
    this.magic,
    this.cputype,
    this.cpusubtype,
    this.filetype,
    this.ncmds,
    this.sizeofcmds,
    this.flags,
    this.reserved,
  );
}

/*
* The 32-bit mach header appears at the very beginning of the object file for
* 32-bit architectures.
*/
class MachOHeader32 extends IMachOHeader {
  MachOHeader32(
    Uint32 magic,
    Uint32 cputype,
    Uint32 cpusubtype,
    Uint32 filetype,
    Uint32 ncmds,
    Uint32 sizeofcmds,
    Uint32 flags,
  ) : super(
          magic,
          cputype,
          cpusubtype,
          filetype,
          ncmds,
          sizeofcmds,
          flags,
          Uint32(0),
        );
}

/*
* The 64-bit mach header appears at the very beginning of object files for
* 64-bit architectures.
*/
class MachOHeader extends IMachOHeader {
  MachOHeader(
    Uint32 magic,
    Uint32 cputype,
    Uint32 cpusubtype,
    Uint32 filetype,
    Uint32 ncmds,
    Uint32 sizeofcmds,
    Uint32 flags,
    Uint32 reserved,
  ) : super(
          magic,
          cputype,
          cpusubtype,
          filetype,
          ncmds,
          sizeofcmds,
          flags,
          reserved,
        );
}

/*
* The load commands directly follow the mach_header.  The total size of all
* of the commands is given by the sizeofcmds field in the mach_header.  All
* load commands must have as their first two fields cmd and cmdsize.  The cmd
* field is filled in with a constant for that command type.  Each command type
* has a structure specifically for it.  The cmdsize field is the size in bytes
* of the particular load command structure plus anything that follows it that
* is a part of the load command (i.e. section structures, strings, etc.).  To
* advance to the next load command the cmdsize can be added to the offset or
* pointer of the current load command.  The cmdsize for 32-bit architectures
* MUST be a multiple of 4 bytes and for 64-bit architectures MUST be a multiple
* of 8 bytes (these are forever the maximum alignment of any load commands).
* The padded bytes must be zero.  All tables in the object file must also
* follow these rules so the file can be memory mapped.  Otherwise the pointers
* to these tables will not work well or at all on some machines.  With all
* padding zeroed like objects will compare byte for byte.
*/
class MachOLoadCommand {
  /* type of load command (uint32_t) */
  final Uint32 cmd;
  /* total size of command in bytes (uint32_t) */
  final Uint32 cmdsize;

  MachOLoadCommand(this.cmd, this.cmdsize);
}

/*
* The segment load command indicates that a part of this file is to be
* mapped into the task's address space.  The size of this segment in memory,
* vmsize, maybe equal to or larger than the amount to map from this file,
* filesize.  The file is mapped starting at fileoff to the beginning of
* the segment in memory, vmaddr.  The rest of the memory of the segment,
* if any, is allocated zero fill on demand.  The segment's maximum virtual
* memory protection and initial virtual memory protection are specified
* by the maxprot and initprot fields.  If the segment has sections then the
* section structures directly follow the segment command and their size is
* reflected in cmdsize.
*/
class MachOSegmentCommand extends IMachOLoadCommand<MachOSegmentCommand> {
  /* For 32Bit Architectures */
  final Uint8List segname; /* segment name */
  final Uint32 vmaddr; /* memory address of this segment (uint32_t) */
  final Uint32 vmsize; /* memory size of this segment (uint32_t) */
  final Uint32 fileoff; /* file offset of this segment (uint32_t) */
  final Uint32 filesize; /* amount to map from the file (uint32_t) */
  final Int32 maxprot; /* maximum VM protection (int32) */
  final Int32 initprot; /* initial VM protection (int32) */
  final Uint32 nsects; /* number of sections in segment (uint32_t) */
  final Uint32 flags; /* flags (uint32_t) */

  MachOSegmentCommand(
    Uint32 cmdsize,
    this.segname,
    this.vmaddr,
    this.vmsize,
    this.fileoff,
    this.filesize,
    this.maxprot,
    this.initprot,
    this.nsects,
    this.flags,
  ) : super(MachOConstants.LC_SEGMENT, cmdsize);

  @override
  MachOSegmentCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeFromSync(segname);
    stream.writeUint32(vmaddr);
    stream.writeUint32(vmsize);
    stream.writeUint32(fileoff);
    stream.writeUint32(filesize);
    stream.writeInt32(maxprot);
    stream.writeInt32(initprot);
    stream.writeUint32(nsects);
    stream.writeUint32(flags);
  }
}

/*
* The 64-bit segment load command indicates that a part of this file is to be
* mapped into a 64-bit task's address space.  If the 64-bit segment has
* sections then section_64 structures directly follow the 64-bit segment
* command and their size is reflected in cmdsize.
*/
class MachOSegmentCommand64 extends IMachOLoadCommand<MachOSegmentCommand64> {
  /* For 64Bit Architectures */
  final Uint8List segname; //[16] /* segment name */
  final Uint64 vmaddr; /* memory address of this segment (uint64_t) */
  final Uint64 vmsize; /* memory size of this segment (uint64_t) */
  final Uint64 fileoff; /* file offset of this segment (uint64_t) */
  final Uint64 filesize; /* amount to map from the file (uint64_t) */
  final Int32 maxprot; /* maximum VM protection (int32) */
  final Int32 initprot; /* initial VM protection (int32) */
  final Uint32 nsects; /* number of sections in segment (uint32_t) */
  final Uint32 flags; /* flags (uint32_t) */

  final List<MachOSection64> sections;

  MachOSegmentCommand64(
    Uint32 cmdsize,
    this.segname,
    this.vmaddr,
    this.vmsize,
    this.fileoff,
    this.filesize,
    this.maxprot,
    this.initprot,
    this.nsects,
    this.flags,
    this.sections,
  ) : super(MachOConstants.LC_SEGMENT_64, cmdsize);

  @override
  MachOSegmentCommand64 asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeFromSync(segname);
    stream.writeUint64(vmaddr);
    stream.writeUint64(vmsize);
    stream.writeUint64(fileoff);
    stream.writeUint64(filesize);
    stream.writeInt32(maxprot);
    stream.writeInt32(initprot);
    stream.writeUint32(nsects);
    stream.writeUint32(flags);

    sections.forEach((section) {
      section.writeContentsSync(stream);
    });
  }
}

/*
* A segment is made up of zero or more sections.  Non-MH_OBJECT files have
* all of their segments with the proper sections in each, and padded to the
* specified segment alignment when produced by the link editor.  The first
* segment of a MH_EXECUTE and MH_FVMLIB format file contains the mach_header
* and load commands of the object file before its first section.  The zero
* fill sections are always last in their segment (in all formats).  This
* allows the zeroed segment padding to be mapped into memory where zero fill
* sections might be. The gigabyte zero fill sections, those with the section
* type S_GB_ZEROFILL, can only be in a segment with sections of this type.
* These segments are then placed after all other segments.
*
* The MH_OBJECT format has all of its sections in one segment for
* compactness.  There is no padding to a specified segment boundary and the
* mach_header and load commands are not part of the segment.
*
* Sections with the same section name, sectname, going into the same segment,
* segname, are combined by the link editor.  The resulting section is aligned
* to the maximum alignment of the combined sections and is the new section's
* alignment.  The combined sections are aligned to their original alignment in
* the combined section.  Any padded bytes to get the specified alignment are
* zeroed.
*
* The format of the relocation entries referenced by the reloff and nreloc
* fields of the section structure for mach object files is described in the
* header file <reloc.h>.
*/
class MachOSection {
  /* for 32-bit architectures */
  final Uint8List sectname; /* name of this section */
  final Uint8List segname; /* segment this section goes in */
  final Uint32 addr; /* memory address of this section (uint32_t) */
  final Uint32 size; /* size in bytes of this section (uint32_t) */
  final Uint32 offset; /* file offset of this section (uint32_t) */
  final Uint32 align; /* section alignment (power of 2) (uint32_t) */
  final Uint32 reloff; /* file offset of relocation entries (uint32_t) */
  final Uint32 nreloc; /* number of relocation entries (uint32_t) */
  final Uint32 flags; /* flags (section type and attributes)(uint32_t) */
  final Uint32 reserved1; /* reserved (for offset or index) (uint32_t) */
  final Uint32 reserved2; /* reserved (for count or sizeof) (uint32_t) */

  MachOSection(
    this.sectname,
    this.segname,
    this.addr,
    this.size,
    this.offset,
    this.align,
    this.reloff,
    this.nreloc,
    this.flags,
    this.reserved1,
    this.reserved2,
  ) {
    if (segname.length != 16) {
      throw ArgumentError("segname must be 16 bytes exactly");
    }
  }
}

class MachOSection64 {
  /* for 64-bit architectures */
  final Uint8List sectname; //[16] /* name of this section */
  final Uint8List segname; //[16] /* segment this section goes in */
  final Uint64 addr; /* memory address of this section (uint64_t) */
  final Uint64 size; /* size in bytes of this section (uint64_t) */
  final Uint32 offset; /* file offset of this section (uint32_t) */
  final Uint32 align; /* section alignment (power of 2) (uint32_t) */
  final Uint32 reloff; /* file offset of relocation entries (uint32_t) */
  final Uint32 nreloc; /* number of relocation entries (uint32_t) */
  final Uint32 flags; /* flags (section type and attributes)(uint32_t) */
  final Uint32 reserved1; /* reserved (for offset or index) (uint32_t) */
  final Uint32 reserved2; /* reserved (for count or sizeof) (uint32_t) */
  final Uint32 reserved3; /* reserved (uint32_t) */

  MachOSection64(
    this.sectname,
    this.segname,
    this.addr,
    this.size,
    this.offset,
    this.align,
    this.reloff,
    this.nreloc,
    this.flags,
    this.reserved1,
    this.reserved2,
    this.reserved3,
  ) {
    if (segname.length != 16) {
      throw ArgumentError("segname must be 16 bytes exactly");
    }
  }

  void writeContentsSync(RandomAccessFile stream) {
    stream.writeFromSync(sectname);
    stream.writeFromSync(segname);
    stream.writeUint64(addr);
    stream.writeUint64(size);
    stream.writeUint32(offset);
    stream.writeUint32(align);
    stream.writeUint32(reloff);
    stream.writeUint32(nreloc);
    stream.writeUint32(flags);
    stream.writeUint32(reserved1);
    stream.writeUint32(reserved2);
    stream.writeUint32(reserved3);
  }
}

// This is a stand-in for the lc_str union in the MachO header.
class MachOStr {
  final int offset;
  final Uint8List ptr;

  MachOStr(this.offset, this.ptr);
  // part of the schema so it doesn't contribute to
  // the size of this schema.

  void writeContentsSync(RandomAccessFile stream) {
    stream.writeInt32(Int32(offset));
    stream.writeFromSync(ptr);
  }
}

/*
 * Fixed virtual memory shared libraries are identified by two things.  The
 * target pathname (the name of the library as found for execution), and the
 * minor version number.  The address of where the headers are loaded is in
 * header_addr. (THIS IS OBSOLETE and no longer supported).
 */
class MachOFvmlib {
  final MachOStr name; /* library's target pathname */
  final Uint32 minor_version; /* library's minor version number (uint32_t) */
  final Uint32 header_addr; /* library's header address (uint32_t) */

  MachOFvmlib(
    this.name,
    this.minor_version,
    this.header_addr,
  );

  void writeContentsSync(RandomAccessFile stream) {
    name.writeContentsSync(stream);
    stream.writeUint32(minor_version);
    stream.writeUint32(header_addr);
  }
}

/*
 * A fixed virtual shared library (filetype == MH_FVMLIB in the mach header)
 * contains a fvmlib_command (cmd == LC_IDFVMLIB) to identify the library.
 * An object that uses a fixed virtual shared library also contains a
 * fvmlib_command (cmd == LC_LOADFVMLIB) for each library it uses.
 * (THIS IS OBSOLETE and no longer supported).
 */
class MachOFvmlibCommand extends IMachOLoadCommand<MachOFvmlibCommand> {
  final MachOFvmlib fvmlib; /* the library identification */

  MachOFvmlibCommand(
    Uint32 cmdsize,
    this.fvmlib,
  ) : super(MachOConstants.LC_IDFVMLIB, cmdsize);

  @override
  MachOFvmlibCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    fvmlib.writeContentsSync(stream);
  }
}

/*
 * Dynamicly linked shared libraries are identified by two things.  The
 * pathname (the name of the library as found for execution), and the
 * compatibility version number.  The pathname must match and the compatibility
 * number in the user of the library must be greater than or equal to the
 * library being used.  The time stamp is used to record the time a library was
 * built and copied into user so it can be use to determined if the library used
 * at runtime is exactly the same as used to built the program.
 */
class MachODylib {
  final MachOStr name; /* library's path name */
  final Uint32 timestamp; /* library's build time stamp (uint32_t) */
  final Uint32
      current_version; /* library's current version number (uint32_t) */
  final Uint32
      compatibility_version; /* library's compatibility vers number(uint32_t) */

  MachODylib(
    this.name,
    this.timestamp,
    this.current_version,
    this.compatibility_version,
  );

  void writeContentsSync(RandomAccessFile stream) {
    name.writeContentsSync(stream);
    stream.writeUint32(timestamp);
    stream.writeUint32(current_version);
    stream.writeUint32(compatibility_version);
  }
}

/*
 * A dynamically linked shared library (filetype == MH_DYLIB in the mach header)
 * contains a dylib_command (cmd == LC_ID_DYLIB) to identify the library.
 * An object that uses a dynamically linked shared library also contains a
 * dylib_command (cmd == LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, or
 * LC_REEXPORT_DYLIB) for each library it uses.
 */
class MachODylibCommand extends IMachOLoadCommand<MachODylibCommand> {
  final MachODylib dylib; /* the library identification */

  MachODylibCommand(
    Uint32 cmd,
    Uint32 cmdsize,
    this.dylib,
  ) : super(cmd, cmdsize) {
    if (this.cmd != MachOConstants.LC_ID_DYLIB &&
        this.cmd != MachOConstants.LC_LOAD_WEAK_DYLIB &&
        this.cmd != MachOConstants.LC_REEXPORT_DYLIB) {
      throw ArgumentError(
          "cmd was not one of LC_ID_DYLIB (${MachOConstants.LC_ID_DYLIB}), "
          "LC_LOAD_WEAK_DYLIB (${MachOConstants.LC_LOAD_WEAK_DYLIB}), "
          "LC_REEXPORT_DYLIB (${MachOConstants.LC_REEXPORT_DYLIB}): $cmd");
    }
  }

  @override
  MachODylibCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    dylib.writeContentsSync(stream);
  }
}

/*
 * A dynamically linked shared library may be a subframework of an umbrella
 * framework.  If so it will be linked with "-umbrella umbrella_name" where
 * Where "umbrella_name" is the name of the umbrella framework. A subframework
 * can only be linked against by its umbrella framework or other subframeworks
 * that are part of the same umbrella framework.  Otherwise the static link
 * editor produces an error and states to link against the umbrella framework.
 * The name of the umbrella framework for subframeworks is recorded in the
 * following structure.
 */
class MachOSubFrameworkCommand
    extends IMachOLoadCommand<MachOSubFrameworkCommand> {
  final MachOStr umbrella; /* the umbrella framework name */

  MachOSubFrameworkCommand(
    Uint32 cmdsize,
    this.umbrella,
  ) : super(MachOConstants.LC_SUB_FRAMEWORK, cmdsize);

  @override
  MachOSubFrameworkCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    umbrella.writeContentsSync(stream);
  }
}

/*
 * For dynamically linked shared libraries that are subframework of an umbrella
 * framework they can allow clients other than the umbrella framework or other
 * subframeworks in the same umbrella framework.  To do this the subframework
 * is built with "-allowable_client client_name" and an LC_SUB_CLIENT load
 * command is created for each -allowable_client flag.  The client_name is
 * usually a framework name.  It can also be a name used for bundles clients
 * where the bundle is built with "-client_name client_name".
 */
class MachOSubClientCommand extends IMachOLoadCommand<MachOSubClientCommand> {
  final MachOStr client; /* the client name */

  MachOSubClientCommand(
    Uint32 cmdsize,
    this.client,
  ) : super(MachOConstants.LC_SUB_CLIENT, cmdsize);

  @override
  MachOSubClientCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    client.writeContentsSync(stream);
  }
}

/*
 * A dynamically linked shared library may be a sub_umbrella of an umbrella
 * framework.  If so it will be linked with "-sub_umbrella umbrella_name" where
 * Where "umbrella_name" is the name of the sub_umbrella framework.  When
 * staticly linking when -twolevel_namespace is in effect a twolevel namespace
 * umbrella framework will only cause its subframeworks and those frameworks
 * listed as sub_umbrella frameworks to be implicited linked in.  Any other
 * dependent dynamic libraries will not be linked it when -twolevel_namespace
 * is in effect.  The primary library recorded by the static linker when
 * resolving a symbol in these libraries will be the umbrella framework.
 * Zero or more sub_umbrella frameworks may be use by an umbrella framework.
 * The name of a sub_umbrella framework is recorded in the following structure.
 */
class MachOSubUmbrellaCommand
    extends IMachOLoadCommand<MachOSubUmbrellaCommand> {
  final MachOStr sub_umbrella; /* the sub_umbrella framework name */

  MachOSubUmbrellaCommand(
    Uint32 cmdsize,
    this.sub_umbrella,
  ) : super(
          MachOConstants.LC_SUB_UMBRELLA,
          cmdsize,
        );

  @override
  MachOSubUmbrellaCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    sub_umbrella.writeContentsSync(stream);
  }
}

/*
 * A dynamically linked shared library may be a sub_library of another shared
 * library.  If so it will be linked with "-sub_library library_name" where
 * Where "library_name" is the name of the sub_library shared library.  When
 * staticly linking when -twolevel_namespace is in effect a twolevel namespace
 * shared library will only cause its subframeworks and those frameworks
 * listed as sub_umbrella frameworks and libraries listed as sub_libraries to
 * be implicited linked in.  Any other dependent dynamic libraries will not be
 * linked it when -twolevel_namespace is in effect.  The primary library
 * recorded by the static linker when resolving a symbol in these libraries
 * will be the umbrella framework (or dynamic library). Zero or more sub_library
 * shared libraries may be use by an umbrella framework or (or dynamic library).
 * The name of a sub_library framework is recorded in the following structure.
 * For example /usr/lib/libobjc_profile.A.dylib would be recorded as "libobjc".
 */
class MachOSubLibraryCommand extends IMachOLoadCommand<MachOSubLibraryCommand> {
  final MachOStr sub_library; /* the sub_library name */

  MachOSubLibraryCommand(
    Uint32 cmdsize,
    this.sub_library,
  ) : super(
          MachOConstants.LC_SUB_LIBRARY,
          cmdsize,
        );

  @override
  MachOSubLibraryCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    sub_library.writeContentsSync(stream);
  }
}

/*
 * A program (filetype == MH_EXECUTE) that is
 * prebound to its dynamic libraries has one of these for each library that
 * the static linker used in prebinding.  It contains a bit vector for the
 * modules in the library.  The bits indicate which modules are bound (1) and
 * which are not (0) from the library.  The bit for module 0 is the low bit
 * of the first byte.  So the bit for the Nth module is:
 * (linked_modules[N/8] >> N%8) & 1
 */
class MachOPreboundDylibCommand
    extends IMachOLoadCommand<MachOPreboundDylibCommand> {
  final MachOStr name; /* library's path name */
  final Uint32 nmodules; /* number of modules in library (uint32_t) */
  final MachOStr linked_modules; /* bit vector of linked modules */

  MachOPreboundDylibCommand(
    Uint32 cmdsize,
    this.name,
    this.nmodules,
    this.linked_modules,
  ) : super(
          MachOConstants.LC_PREBOUND_DYLIB,
          cmdsize,
        );

  @override
  MachOPreboundDylibCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    name.writeContentsSync(stream);
    stream.writeUint32(nmodules);
    linked_modules.writeContentsSync(stream);
  }
}

/*
 * A program that uses a dynamic linker contains a dylinker_command to identify
 * the name of the dynamic linker (LC_LOAD_DYLINKER).  And a dynamic linker
 * contains a dylinker_command to identify the dynamic linker (LC_ID_DYLINKER).
 * A file can have at most one of these.
 * This struct is also used for the LC_DYLD_ENVIRONMENT load command and
 * contains string for dyld to treat like environment variable.
 */
class MachODylinkerCommand extends IMachOLoadCommand<MachODylinkerCommand> {
  final MachOStr name; /* dynamic linker's path name */

  MachODylinkerCommand(
    Uint32 cmd,
    Uint32 cmdsize,
    this.name,
  ) : super(
          cmd,
          cmdsize,
        ) {
    if (this.cmd != MachOConstants.LC_ID_DYLINKER &&
        this.cmd != MachOConstants.LC_LOAD_DYLINKER &&
        this.cmd != MachOConstants.LC_DYLD_ENVIRONMENT) {
      throw ArgumentError(
          "cmd was not one of LC_ID_DYLINKER (${MachOConstants.LC_ID_DYLINKER}), "
          "LC_LOAD_DYLINKER (${MachOConstants.LC_LOAD_DYLINKER}), "
          "LC_DYLD_ENVIRONMENT (${MachOConstants.LC_DYLD_ENVIRONMENT}): $cmd");
    }
  }

  @override
  MachODylinkerCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    name.writeContentsSync(stream);
  }
}

/*
 * Thread commands contain machine-specific data structures suitable for
 * use in the thread state primitives.  The machine specific data structures
 * follow the struct thread_command as follows.
 * Each flavor of machine specific data structure is preceded by an uint32_t
 * constant for the flavor of that data structure, an uint32_t that is the
 * count of uint32_t's of the size of the state data structure and then
 * the state data structure follows.  This triple may be repeated for many
 * flavors.  The constants for the flavors, counts and state data structure
 * definitions are expected to be in the header file <machine/thread_status.h>.
 * These machine specific data structures sizes must be multiples of
 * 4 bytes.  The cmdsize reflects the total size of the thread_command
 * and all of the sizes of the constants for the flavors, counts and state
 * data structures.
 *
 * For executable objects that are unix processes there will be one
 * thread_command (cmd == LC_UNIXTHREAD) created for it by the link-editor.
 * This is the same as a LC_THREAD, except that a stack is automatically
 * created (based on the shell's limit for the stack size).  Command arguments
 * and environment variables are copied onto that stack.
 */
class MachOThreadCommand extends IMachOLoadCommand<MachOThreadCommand> {
  /* final int flavor		   flavor of thread state (uint32_t) */
  /* final int count		   count of longs in thread state (uint32_t) */
  /* struct XXX_thread_state state   thread state for this flavor */
  /* ... */

  MachOThreadCommand(
    Uint32 cmd,
    Uint32 cmdsize,
    /* final int flavor		   flavor of thread state (uint32_t) */
    /* final int count		   count of longs in thread state (uint32_t) */
    /* struct XXX_thread_state state   thread state for this flavor */
    /* ... */
  ) : super(
          cmd,
          cmdsize,
        ) {
    if (this.cmd != MachOConstants.LC_THREAD &&
        this.cmd != MachOConstants.LC_UNIXTHREAD) {
      throw ArgumentError(
          "cmd was not one of LC_THREAD (${MachOConstants.LC_THREAD}), "
          "LC_UNIXTHREAD (${MachOConstants.LC_UNIXTHREAD}): $cmd");
    }
  }

  @override
  MachOThreadCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {}
}

/*
 * The routines command contains the address of the dynamic shared library
 * initialization routine and an index into the module table for the module
 * that defines the routine.  Before any modules are used from the library the
 * dynamic linker fully binds the module that defines the initialization routine
 * and then calls it.  This gets called before any module initialization
 * routines (used for C++ static constructors) in the library.
 */
class MachORoutinesCommand extends IMachOLoadCommand<MachORoutinesCommand> {
  final Uint32 init_address; /* address of initialization routine (uint32_t) */
  final Uint32 init_module; /* index into the module table that (uint32_t) */
  /*  the init routine is defined in */
  final Uint32 reserved1; /* (uint32_t) */
  final Uint32 reserved2; /* (uint32_t) */
  final Uint32 reserved3; /* (uint32_t) */
  final Uint32 reserved4; /* (uint32_t) */
  final Uint32 reserved5; /* (uint32_t) */
  final Uint32 reserved6; /* (uint32_t) */

  MachORoutinesCommand(
    Uint32 cmdsize,
    this.init_address,
    this.init_module,
    this.reserved1,
    this.reserved2,
    this.reserved3,
    this.reserved4,
    this.reserved5,
    this.reserved6,
  ) : super(
          MachOConstants.LC_ROUTINES,
          cmdsize,
        );

  @override
  MachORoutinesCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(init_address);
    stream.writeUint32(init_module);
    stream.writeUint32(reserved1);
    stream.writeUint32(reserved2);
    stream.writeUint32(reserved3);
    stream.writeUint32(reserved4);
    stream.writeUint32(reserved5);
    stream.writeUint32(reserved6);
  }
}

/*
 * The 64-bit routines command.  Same use as above.
 */
class MachORoutinesCommand64 extends IMachOLoadCommand<MachORoutinesCommand64> {
  final Uint64 init_address; /* address of initialization routine (uint64_t) */
  final Uint64 init_module; /* index into the module table that (uint64_t) */
  /*  the init routine is defined in */
  final Uint64 reserved1; /* (uint64_t) */
  final Uint64 reserved2; /* (uint64_t) */
  final Uint64 reserved3; /* (uint64_t) */
  final Uint64 reserved4; /* (uint64_t) */
  final Uint64 reserved5; /* (uint64_t) */
  final Uint64 reserved6; /* (uint64_t) */

  MachORoutinesCommand64(
    Uint32 cmdsize,
    this.init_address,
    this.init_module,
    this.reserved1,
    this.reserved2,
    this.reserved3,
    this.reserved4,
    this.reserved5,
    this.reserved6,
  ) : super(
          MachOConstants.LC_ROUTINES_64,
          cmdsize,
        );

  @override
  MachORoutinesCommand64 asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint64(init_address);
    stream.writeUint64(init_module);
    stream.writeUint64(reserved1);
    stream.writeUint64(reserved2);
    stream.writeUint64(reserved3);
    stream.writeUint64(reserved4);
    stream.writeUint64(reserved5);
    stream.writeUint64(reserved6);
  }
}

/*
 * The symtab_command contains the offsets and sizes of the link-edit 4.3BSD
 * "stab" style symbol table information as described in the header files
 * <nlist.h> and <stab.h>.
 */
class MachOSymtabCommand extends IMachOLoadCommand<MachOSymtabCommand> {
  final Uint32 symoff; /* symbol table offset (uint32_t) */
  final Uint32 nsyms; /* number of symbol table entries (uint32_t) */
  final Uint32 stroff; /* string table offset (uint32_t) */
  final Uint32 strsize; /* string table size in bytes (uint32_t) */

  MachOSymtabCommand(
    Uint32 cmdsize,
    this.symoff,
    this.nsyms,
    this.stroff,
    this.strsize,
  ) : super(
          MachOConstants.LC_SYMTAB,
          cmdsize,
        );

  @override
  MachOSymtabCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(symoff);
    stream.writeUint32(nsyms);
    stream.writeUint32(stroff);
    stream.writeUint32(strsize);
  }
}

/*
 * This is the second set of the symbolic information which is used to support
 * the data structures for the dynamically link editor.
 *
 * The original set of symbolic information in the symtab_command which contains
 * the symbol and string tables must also be present when this load command is
 * present.  When this load command is present the symbol table is organized
 * into three groups of symbols:
 *	local symbols (static and debugging symbols) - grouped by module
 *	defined external symbols - grouped by module (sorted by name if not lib)
 *	undefined external symbols (sorted by name if MH_BINDATLOAD is not set,
 *	     			    and in order the were seen by the static
 *				    linker if MH_BINDATLOAD is set)
 * In this load command there are offsets and counts to each of the three groups
 * of symbols.
 *
 * This load command contains a the offsets and sizes of the following new
 * symbolic information tables:
 *	table of contents
 *	module table
 *	reference symbol table
 *	indirect symbol table
 * The first three tables above (the table of contents, module table and
 * reference symbol table) are only present if the file is a dynamically linked
 * shared library.  For executable and object modules, which are files
 * containing only one module, the information that would be in these three
 * tables is determined as follows:
 * 	table of contents - the defined external symbols are sorted by name
 *	module table - the file contains only one module so everything in the
 *		       file is part of the module.
 *	reference symbol table - is the defined and undefined external symbols
 *
 * For dynamically linked shared library files this load command also contains
 * offsets and sizes to the pool of relocation entries for all sections
 * separated into two groups:
 *	external relocation entries
 *	local relocation entries
 * For executable and object modules the relocation entries continue to hang
 * off the section structures.
 */
class MachODysymtabCommand extends IMachOLoadCommand<MachODysymtabCommand> {
  /*
     * The symbols indicated by symoff and nsyms of the LC_SYMTAB load command
     * are grouped into the following three groups:
     *    local symbols (further grouped by the module they are from)
     *    defined external symbols (further grouped by the module they are from)
     *    undefined symbols
     *
     * The local symbols are used only for debugging.  The dynamic binding
     * process may have to use them to indicate to the debugger the local
     * symbols for a module that is being bound.
     *
     * The last two groups are used by the dynamic binding process to do the
     * binding (indirectly through the module table and the reference symbol
     * table when this is a dynamically linked shared library file).
     */
  final Uint32 ilocalsym; /* index to local symbols (uint32_t) */
  final Uint32 nlocalsym; /* number of local symbols (uint32_t) */

  final Uint32 iextdefsym; /* index to externally defined symbols (uint32_t) */
  final Uint32 nextdefsym; /* number of externally defined symbols (uint32_t) */

  final Uint32 iundefsym; /* index to undefined symbols (uint32_t) */
  final Uint32 nundefsym; /* number of undefined symbols (uint32_t) */

  /*
     * For the for the dynamic binding process to find which module a symbol
     * is defined in the table of contents is used (analogous to the ranlib
     * structure in an archive) which maps defined external symbols to modules
     * they are defined in.  This exists only in a dynamically linked shared
     * library file.  For executable and object modules the defined external
     * symbols are sorted by name and is use as the table of contents.
     */
  final Uint32 tocoff; /* file offset to table of contents (uint32_t) */
  final Uint32 ntoc; /* number of entries in table of contents (uint32_t) */

  /*
     * To support dynamic binding of "modules" (whole object files) the symbol
     * table must reflect the modules that the file was created from.  This is
     * done by having a module table that has indexes and counts into the merged
     * tables for each module.  The module structure that these two entries
     * refer to is described below.  This exists only in a dynamically linked
     * shared library file.  For executable and object modules the file only
     * contains one module so everything in the file belongs to the module.
     */
  final Uint32 modtaboff; /* file offset to module table (uint32_t) */
  final Uint32 nmodtab; /* number of module table entries (uint32_t) */

  /*
     * To support dynamic module binding the module structure for each module
     * indicates the external references (defined and undefined) each module
     * makes.  For each module there is an offset and a count into the
     * reference symbol table for the symbols that the module references.
     * This exists only in a dynamically linked shared library file.  For
     * executable and object modules the defined external symbols and the
     * undefined external symbols indicates the external references.
     */
  final Uint32 extrefsymoff; /* offset to referenced symbol table (uint32_t) */
  final Uint32
      nextrefsyms; /* number of referenced symbol table entries (uint32_t) */

  /*
     * The sections that contain "symbol pointers" and "routine stubs" have
     * indexes and (implied counts based on the size of the section and fixed
     * size of the entry) into the "indirect symbol" table for each pointer
     * and stub.  For every section of these two types the index into the
     * indirect symbol table is stored in the section header in the field
     * reserved1.  An indirect symbol table entry is simply a 32bit index into
     * the symbol table to the symbol that the pointer or stub is referring to.
     * The indirect symbol table is ordered to match the entries in the section.
     */
  final Uint32
      indirectsymoff; /* file offset to the indirect symbol table (uint32_t) */
  final Uint32
      nindirectsyms; /* number of indirect symbol table entries (uint32_t) */

  /*
     * To support relocating an individual module in a library file quickly the
     * external relocation entries for each module in the library need to be
     * accessed efficiently.  Since the relocation entries can't be accessed
     * through the section headers for a library file they are separated into
     * groups of local and external entries further grouped by module.  In this
     * case the presents of this load command who's extreloff, nextrel,
     * locreloff and nlocrel fields are non-zero indicates that the relocation
     * entries of non-merged sections are not referenced through the section
     * structures (and the reloff and nreloc fields in the section headers are
     * set to zero).
     *
     * Since the relocation entries are not accessed through the section headers
     * this requires the r_address field to be something other than a section
     * offset to identify the item to be relocated.  In this case r_address is
     * set to the offset from the vmaddr of the first LC_SEGMENT command.
     * For MH_SPLIT_SEGS images r_address is set to the the offset from the
     * vmaddr of the first read-write LC_SEGMENT command.
     *
     * The relocation entries are grouped by module and the module table
     * entries have indexes and counts into them for the group of external
     * relocation entries for that the module.
     *
     * For sections that are merged across modules there must not be any
     * remaining external relocation entries for them (for merged sections
     * remaining relocation entries must be local).
     */
  final Uint32 extreloff; /* offset to external relocation entries (uint32_t) */
  final Uint32 nextrel; /* number of external relocation entries (uint32_t) */

  /*
     * All the local relocation entries are grouped together (they are not
     * grouped by their module since they are only used if the object is moved
     * from it staticly link edited address).
     */
  final Uint32 locreloff; /* offset to local relocation entries (uint32_t) */
  final Uint32 nlocrel; /* number of local relocation entries (uint32_t) */

  MachODysymtabCommand(
    Uint32 cmdsize,
    this.ilocalsym,
    this.nlocalsym,
    this.iextdefsym,
    this.nextdefsym,
    this.iundefsym,
    this.nundefsym,
    this.tocoff,
    this.ntoc,
    this.modtaboff,
    this.nmodtab,
    this.extrefsymoff,
    this.nextrefsyms,
    this.indirectsymoff,
    this.nindirectsyms,
    this.extreloff,
    this.nextrel,
    this.locreloff,
    this.nlocrel,
  ) : super(
          MachOConstants.LC_DYSYMTAB,
          cmdsize,
        );

  @override
  MachODysymtabCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(ilocalsym);
    stream.writeUint32(nlocalsym);
    stream.writeUint32(iextdefsym);
    stream.writeUint32(nextdefsym);
    stream.writeUint32(iundefsym);
    stream.writeUint32(nundefsym);
    stream.writeUint32(tocoff);
    stream.writeUint32(ntoc);
    stream.writeUint32(modtaboff);
    stream.writeUint32(nmodtab);
    stream.writeUint32(extrefsymoff);
    stream.writeUint32(nextrefsyms);
    stream.writeUint32(indirectsymoff);
    stream.writeUint32(nindirectsyms);
    stream.writeUint32(extreloff);
    stream.writeUint32(nextrel);
    stream.writeUint32(locreloff);
    stream.writeUint32(nlocrel);
  }
}

/* a table of contents entry */
class MachODylibTableOfContents {
  final Uint32
      symbol_index; /* the defined external symb(uint32_t) ol
				   (index into the symbol table) */
  final Uint32
      module_index; /* index into the module table this symb(uint32_t) ol
				   is defined in */

  MachODylibTableOfContents(
    this.symbol_index,
    this.module_index,
  );
}

/* a module table entry */
class MachODylibModule {
  final Uint32
      module_name; /* the module name (index into string table) (uint32_t) */

  final Uint32
      iextdefsym; /* index into externally defined symbols (uint32_t) */
  final Uint32 nextdefsym; /* number of externally defined symbols (uint32_t) */
  final Uint32 irefsym; /* index into reference symbol table (uint32_t) */
  final Uint32
      nrefsym; /* number of reference symbol table entries (uint32_t) */
  final Uint32 ilocalsym; /* index into symbols for local symbols (uint32_t) */
  final Uint32 nlocalsym; /* number of local symbols (uint32_t) */

  final Uint32 iextrel; /* index into external relocation entries (uint32_t) */
  final Uint32 nextrel; /* number of external relocation entries (uint32_t) */

  final Uint32
      iinit_iterm; /* low 16 bits are the index into the in(uint32_t) it
				   section, high 16 bits are the index into
			           the term section */
  final Uint32
      ninit_nterm; /* low 16 bits are the number of init secti(uint32_t) on
				   entries, high 16 bits are the number of
				   term section entries */

  final Uint32 /* for this module address of the start of (uint32_t) */
      objc_module_info_addr; /*  the (__OBJC,__module_info) section */
  final Uint32 /* for this module size of (uint32_t) */
      objc_module_info_size; /*  the (__OBJC,__module_info) section */

  MachODylibModule(
    this.module_name,
    this.iextdefsym,
    this.nextdefsym,
    this.irefsym,
    this.nrefsym,
    this.ilocalsym,
    this.nlocalsym,
    this.iextrel,
    this.nextrel,
    this.iinit_iterm,
    this.ninit_nterm,
    this.objc_module_info_addr,
    this.objc_module_info_size,
  );
}

/* a 64-bit module table entry */
class MachODylibModule64 {
  final Uint32
      module_name; /* the module name (index into string table) (uint32_t) */

  final Uint32
      iextdefsym; /* index into externally defined symbols (uint32_t) */
  final Uint32 nextdefsym; /* number of externally defined symbols (uint32_t) */
  final Uint32 irefsym; /* index into reference symbol table (uint32_t) */
  final Uint32
      nrefsym; /* number of reference symbol table entries (uint32_t) */
  final Uint32 ilocalsym; /* index into symbols for local symbols (uint32_t) */
  final Uint32 nlocalsym; /* number of local symbols (uint32_t) */

  final Uint32 iextrel; /* index into external relocation entries (uint32_t) */
  final Uint32 nextrel; /* number of external relocation entries (uint32_t) */

  final Uint32
      iinit_iterm; /* low 16 bits are the index into the in(uint32_t) it
				   section, high 16 bits are the index into
				   the term section */
  final Uint32
      ninit_nterm; /* low 16 bits are the number of init secti(uint32_t) on
				  entries, high 16 bits are the number of
				  term section entries */

  final Uint32 /* for this module size of (uint32_t) */
      objc_module_info_size; /*  the (__OBJC,__module_info) section */
  final Uint64 /* for this module address of the start of (uint64_t) */
      objc_module_info_addr; /*  the (__OBJC,__module_info) section */

  MachODylibModule64(
    this.module_name,
    this.iextdefsym,
    this.nextdefsym,
    this.irefsym,
    this.nrefsym,
    this.ilocalsym,
    this.nlocalsym,
    this.iextrel,
    this.nextrel,
    this.iinit_iterm,
    this.ninit_nterm,
    this.objc_module_info_size,
    this.objc_module_info_addr,
  );
}

/*
 * The entries in the reference symbol table are used when loading the module
 * (both by the static and dynamic link editors) and if the module is unloaded
 * or replaced.  Therefore all external symbols (defined and undefined) are
 * listed in the module's reference table.  The flags describe the type of
 * reference that is being made.  The constants for the flags are defined in
 * <mach-o/nlist.h> as they are also used for symbol table entries.
 */
class MachODylibReference {
  final Uint32 isym; //:24,		/* index into the symbol table (uint32_t) */
  final Uint32 flags; //:8;	/* flags to indicate the type of reference */

  MachODylibReference(Uint32 value)
      : isym = value & Uint32(0xffffff),
        flags = value >> Uint32(24);
}

/*
 * The twolevel_hints_command contains the offset and number of hints in the
 * two-level namespace lookup hints table.
 */
class MachOTwolevelHintsCommand
    extends IMachOLoadCommand<MachOTwolevelHintsCommand> {
  final Uint32 offset; /* offset to the hint table (uint32_t) */
  final Uint32 nhints; /* number of hints in the hint table (uint32_t) */

  MachOTwolevelHintsCommand(
    Uint32 cmdsize,
    this.offset,
    this.nhints,
  ) : super(
          MachOConstants.LC_TWOLEVEL_HINTS,
          cmdsize,
        );

  @override
  MachOTwolevelHintsCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(offset);
    stream.writeUint32(nhints);
  }
}

/*
 * The entries in the two-level namespace lookup hints table are twolevel_hint
 * structs.  These provide hints to the dynamic link editor where to start
 * looking for an undefined symbol in a two-level namespace image.  The
 * isub_image field is an index into the sub-images (sub-frameworks and
 * sub-umbrellas list) that made up the two-level image that the undefined
 * symbol was found in when it was built by the static link editor.  If
 * isub-image is 0 the the symbol is expected to be defined in library and not
 * in the sub-images.  If isub-image is non-zero it is an index into the array
 * of sub-images for the umbrella with the first index in the sub-images being
 * 1. The array of sub-images is the ordered list of sub-images of the umbrella
 * that would be searched for a symbol that has the umbrella recorded as its
 * primary library.  The table of contents index is an index into the
 * library's table of contents.  This is used as the starting point of the
 * binary search or a directed linear search.
 */
class MachOTwolevelHint {
  final int isub_image; //:8,	/* index into the sub images */
  final int itoc; //:24;	/* index into the table of contents */

  MachOTwolevelHint(int value)
      : isub_image = value & 0xff,
        itoc = value >> 8;
}

/*
 * The prebind_cksum_command contains the value of the original check sum for
 * prebound files or zero.  When a prebound file is first created or modified
 * for other than updating its prebinding information the value of the check sum
 * is set to zero.  When the file has it prebinding re-done and if the value of
 * the check sum is zero the original check sum is calculated and stored in
 * cksum field of this load command in the output file.  If when the prebinding
 * is re-done and the cksum field is non-zero it is left unchanged from the
 * input file.
 */
class MachOPrebindCksumCommand
    extends IMachOLoadCommand<MachOPrebindCksumCommand> {
  final Uint32 cksum; /* the check sum or zero (uint32_t) */

  MachOPrebindCksumCommand(
    Uint32 cmdsize,
    this.cksum,
  ) : super(
          MachOConstants.LC_PREBIND_CKSUM,
          cmdsize,
        );

  @override
  MachOPrebindCksumCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(cksum);
  }
}

/*
 * The uuid load command contains a single 128-bit unique random number that
 * identifies an object produced by the static link editor.
 */
class MachOUuidCommand extends IMachOLoadCommand<MachOUuidCommand> {
  final Uint8List uuid; //[16];	/* the 128-bit uuid */

  MachOUuidCommand(
    Uint32 cmdsize,
    this.uuid,
  ) : super(
          MachOConstants.LC_UUID,
          cmdsize,
        );

  @override
  MachOUuidCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeFromSync(uuid);
  }
}

/*
 * The rpath_command contains a path which at runtime should be added to
 * the current run path used to find @rpath prefixed dylibs.
 */
class MachORpathCommand extends IMachOLoadCommand<MachORpathCommand> {
  final MachOStr path; /* path to add to run path */

  MachORpathCommand(
    Uint32 cmdsize,
    this.path,
  ) : super(
          MachOConstants.LC_RPATH,
          cmdsize,
        );

  @override
  MachORpathCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    path.writeContentsSync(stream);
  }
}

/*
 * The linkedit_data_command contains the offsets and sizes of a blob
 * of data in the __LINKEDIT segment.
 */
class MachOLinkeditDataCommand
    extends IMachOLoadCommand<MachOLinkeditDataCommand> {
  final Uint32
      dataoff; /* file offset of data in __LINKEDIT segment (uint32_t) */
  final Uint32
      datasize; /* file size of data in __LINKEDIT segment  (uint32_t) */

  MachOLinkeditDataCommand(
    Uint32 cmd,
    Uint32 cmdsize,
    this.dataoff,
    this.datasize,
  ) : super(cmd, cmdsize) {
    if (this.cmd != MachOConstants.LC_CODE_SIGNATURE &&
        this.cmd != MachOConstants.LC_SEGMENT_SPLIT_INFO &&
        this.cmd != MachOConstants.LC_FUNCTION_STARTS &&
        this.cmd != MachOConstants.LC_DATA_IN_CODE &&
        this.cmd != MachOConstants.LC_DYLIB_CODE_SIGN_DRS) {
      throw ArgumentError("cmd was not one of LC_CODE_SIGNATURE "
          "(${MachOConstants.LC_CODE_SIGNATURE}), LC_SEGMENT_SPLIT_INFO "
          "(${MachOConstants.LC_SEGMENT_SPLIT_INFO}), LC_FUNCTION_STARTS "
          "(${MachOConstants.LC_FUNCTION_STARTS}), LC_DATA_IN_CODE "
          "(${MachOConstants.LC_DATA_IN_CODE}), LC_DYLIB_CODE_SIGN_DRS "
          "(${MachOConstants.LC_DYLIB_CODE_SIGN_DRS}): $cmd");
    }
  }

  @override
  MachOLinkeditDataCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(dataoff);
    stream.writeUint32(datasize);
  }
}

/*
 * The encryption_info_command contains the file offset and size of an
 * of an encrypted segment.
 */
class MachOEncryptionInfoCommand
    extends IMachOLoadCommand<MachOEncryptionInfoCommand> {
  final Uint32 cryptoff; /* file offset of encrypted range (uint32_t) */
  final Uint32 cryptsize; /* file size of encrypted range (uint32_t) */
  final Uint32
      cryptid; /* which enryption syste(uint32_t) m,
				   0 means not-encrypted yet */

  MachOEncryptionInfoCommand(
    Uint32 cmdsize,
    this.cryptoff,
    this.cryptsize,
    this.cryptid,
  ) : super(
          MachOConstants.LC_ENCRYPTION_INFO,
          cmdsize,
        );

  @override
  MachOEncryptionInfoCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(cryptoff);
    stream.writeUint32(cryptsize);
    stream.writeUint32(cryptid);
  }
}

/*
 * The version_min_command contains the min OS version on which this
 * binary was built to run.
 */
class MachOVersionMinCommand extends IMachOLoadCommand<MachOVersionMinCommand> {
  final Uint32 version; /* X.Y.Z is encoded in nibbles xxxx.yy.zz (uint32_t) */
  final Uint32 sdk; /* X.Y.Z is encoded in nibbles xxxx.yy.zz (uint32_t) */

  MachOVersionMinCommand(
    Uint32 cmd,
    Uint32 cmdsize,
    this.version,
    this.sdk,
  ) : super(cmd, cmdsize) {
    if (this.cmd != MachOConstants.LC_VERSION_MIN_MACOSX &&
        this.cmd != MachOConstants.LC_VERSION_MIN_IPHONEOS) {
      throw ArgumentError("cmd was not one of: LC_VERSION_MIN_MACOSX "
          "(${MachOConstants.LC_VERSION_MIN_MACOSX}), LC_VERSION_MIN_IPHONEOS "
          "(${MachOConstants.LC_VERSION_MIN_IPHONEOS}): $cmd");
    }
  }

  @override
  MachOVersionMinCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(version);
    stream.writeUint32(sdk);
  }
}

/*
 * The dyld_info_command contains the file offsets and sizes of
 * the new compressed form of the information dyld needs to
 * load the image.  This information is used by dyld on Mac OS X
 * 10.6 and later.  All information pointed to by this command
 * is encoded using byte streams, so no endian swapping is needed
 * to interpret it.
 */
class MachODyldInfoCommand extends IMachOLoadCommand<MachODyldInfoCommand> {
  /*
     * Dyld rebases an image whenever dyld loads it at an address different
     * from its preferred address.  The rebase information is a stream
     * of byte sized opcodes whose symbolic names start with REBASE_OPCODE_.
     * Conceptually the rebase information is a table of tuples:
     *    <seg-index, seg-offset, type>
     * The opcodes are a compressed way to encode the table by only
     * encoding when a column changes.  In addition simple patterns
     * like "every n'th offset for m times" can be encoded in a few
     * bytes.
     */
  final Uint32 rebase_off; /* file offset to rebase info  (uint32_t) */
  final Uint32 rebase_size; /* size of rebase info   (uint32_t) */

  /*
  * Dyld binds an image during the loading process, if the image
  * requires any pointers to be initialized to symbols in other images.
  * The bind information is a stream of byte sized
  * opcodes whose symbolic names start with BIND_OPCODE_.
  * Conceptually the bind information is a table of tuples:
  *   <seg-index, seg-offset, type, symbol-library-ordinal, symbol-name, addend>
  * The opcodes are a compressed way to encode the table by only
  * encoding when a column changes.  In addition simple patterns
  * like for runs of pointers initialzed to the same value can be
  * encoded in a few bytes.
  */
  final Uint32 bind_off; /* file offset to binding info   (uint32_t) */
  final Uint32 bind_size; /* size of binding info  (uint32_t) */

  /*
     * Some C++ programs require dyld to unique symbols so that all
     * images in the process use the same copy of some code/data.
     * This step is done after binding. The content of the weak_bind
     * info is an opcode stream like the bind_info.  But it is sorted
     * alphabetically by symbol name.  This enable dyld to walk
     * all images with weak binding information in order and look
     * for collisions.  If there are no collisions, dyld does
     * no updating.  That means that some fixups are also encoded
     * in the bind_info.  For instance, all calls to "operator new"
     * are first bound to libstdc++.dylib using the information
     * in bind_info.  Then if some image overrides operator new
     * that is detected when the weak_bind information is processed
     * and the call to operator new is then rebound.
     */
  final Uint32
      weak_bind_off; /* file offset to weak binding info   (uint32_t) */
  final Uint32 weak_bind_size; /* size of weak binding info  (uint32_t) */

  /*
     * Some uses of external symbols do not need to be bound immediately.
     * Instead they can be lazily bound on first use.  The lazy_bind
     * are contains a stream of BIND opcodes to bind all lazy symbols.
     * Normal use is that dyld ignores the lazy_bind section when
     * loading an image.  Instead the static linker arranged for the
     * lazy pointer to initially point to a helper function which
     * pushes the offset into the lazy_bind area for the symbol
     * needing to be bound, then jumps to dyld which simply adds
     * the offset to lazy_bind_off to get the information on what
     * to bind.
     */
  final Uint32 lazy_bind_off; /* file offset to lazy binding info (uint32_t) */
  final Uint32 lazy_bind_size; /* size of lazy binding infs (uint32_t) */

  /*
     * The symbols exported by a dylib are encoded in a trie.  This
     * is a compact representation that factors out common prefixes.
     * It also reduces LINKEDIT pages in RAM because it encodes all
     * information (name, address, flags) in one small, contiguous range.
     * The export area is a stream of nodes.  The first node sequentially
     * is the start node for the trie.
     *
     * Nodes for a symbol start with a uleb128 that is the length of
     * the exported symbol information for the string so far.
     * If there is no exported symbol, the node starts with a zero byte.
     * If there is exported info, it follows the length.
	 *
	 * First is a uleb128 containing flags. Normally, it is followed by
     * a uleb128 encoded offset which is location of the content named
     * by the symbol from the mach_header for the image.  If the flags
     * is EXPORT_SYMBOL_FLAGS_REEXPORT, then following the flags is
     * a uleb128 encoded library ordinal, then a zero terminated
     * UTF8 string.  If the string is zero length, then the symbol
     * is re-export from the specified dylib with the same name.
	 * If the flags is EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER, then following
	 * the flags is two uleb128s: the stub offset and the resolver offset.
	 * The stub is used by non-lazy pointers.  The resolver is used
	 * by lazy pointers and must be called to get the actual address to use.
     *
     * After the optional exported symbol information is a byte of
     * how many edges (0-255) that this node has leaving it,
     * followed by each edge.
     * Each edge is a zero terminated UTF8 of the addition chars
     * in the symbol, followed by a uleb128 offset for the node that
     * edge points to.
     *
     */
  final Uint32 export_off; /* file offset to lazy binding info (uint32_t) */
  final Uint32 export_size; /* size of lazy binding infs (uint32_t) */

  MachODyldInfoCommand(
    Uint32 cmd,
    Uint32 cmdsize,
    this.rebase_off,
    this.rebase_size,
    this.bind_off,
    this.bind_size,
    this.weak_bind_off,
    this.weak_bind_size,
    this.lazy_bind_off,
    this.lazy_bind_size,
    this.export_off,
    this.export_size,
  ) : super(
          cmd,
          cmdsize,
        ) {
    if (this.cmd != MachOConstants.LC_DYLD_INFO &&
        this.cmd != MachOConstants.LC_DYLD_INFO_ONLY) {
      throw ArgumentError(
          "cmd was not one of LC_DYLD_INFO (${MachOConstants.LC_DYLD_INFO}), "
          "LC_DYLD_INFO_ONLY (${MachOConstants.LC_DYLD_INFO_ONLY}): $cmd");
    }
  }

  @override
  MachODyldInfoCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(rebase_off);
    stream.writeUint32(rebase_size);
    stream.writeUint32(bind_off);
    stream.writeUint32(bind_size);
    stream.writeUint32(weak_bind_off);
    stream.writeUint32(weak_bind_size);
    stream.writeUint32(lazy_bind_off);
    stream.writeUint32(lazy_bind_size);
    stream.writeUint32(export_off);
    stream.writeUint32(export_size);
  }
}

/*
 * The symseg_command contains the offset and size of the GNU style
 * symbol table information as described in the header file <symseg.h>.
 * The symbol roots of the symbol segments must also be aligned properly
 * in the file.  So the requirement of keeping the offsets aligned to a
 * multiple of a 4 bytes translates to the length field of the symbol
 * roots also being a multiple of a long.  Also the padding must again be
 * zeroed. (THIS IS OBSOLETE and no longer supported).
 */
class MachOSymsegCommand extends IMachOLoadCommand<MachOSymsegCommand> {
  final Uint32 offset; /* symbol segment offset (uint32_t) */
  final Uint32 size; /* symbol segment size in bytes (uint32_t) */

  MachOSymsegCommand(
    Uint32 cmdsize,
    this.offset,
    this.size,
  ) : super(
          MachOConstants.LC_SYMSEG,
          cmdsize,
        );

  @override
  MachOSymsegCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint32(offset);
    stream.writeUint32(size);
  }
}

/*
 * The ident_command contains a free format string table following the
 * ident_command structure.  The strings are null terminated and the size of
 * the command is padded out with zero bytes to a multiple of 4 bytes/
 * (THIS IS OBSOLETE and no longer supported).
 */
class MachOIdentCommand extends IMachOLoadCommand<MachOIdentCommand> {
  MachOIdentCommand(
    Uint32 cmdsize,
  ) : super(
          MachOConstants.LC_IDENT,
          cmdsize,
        );

  @override
  MachOIdentCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {}
}

/*
 * The fvmfile_command contains a reference to a file to be loaded at the
 * specified virtual address.  (Presently, this command is reserved for
 * internal use.  The kernel ignores this command when loading a program into
 * memory).
 */
class MachOFvmfileCommand extends IMachOLoadCommand<MachOFvmfileCommand> {
  final MachOStr name; /* files pathname */
  final Uint32 header_addr; /* files virtual address (uint32_t) */

  MachOFvmfileCommand(
    Uint32 cmdsize,
    this.name,
    this.header_addr,
  ) : super(
          MachOConstants.LC_FVMFILE,
          cmdsize,
        );

  @override
  MachOFvmfileCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    name.writeContentsSync(stream);
    stream.writeUint32(header_addr);
  }
}

/*
 * The entry_point_command is a replacement for thread_command.
 * It is used for main executables to specify the location (file offset)
 * of main().  If -stack_size was used at link time, the stacksize
 * field will contain the stack size need for the main thread.
 */
class MachOEntryPointCommand extends IMachOLoadCommand<MachOEntryPointCommand> {
  final Uint64 entryoff; /* file (__TEXT) offset of main (uint64_t)() */
  final Uint64 stacksize; /* if not zero, initial stack size (uint64_t) */

  MachOEntryPointCommand(
    Uint32 cmdsize,
    this.entryoff,
    this.stacksize,
  ) : super(
          MachOConstants.LC_MAIN,
          cmdsize,
        );

  @override
  MachOEntryPointCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint64(entryoff);
    stream.writeUint64(stacksize);
  }
}

/*
 * The source_version_command is an optional load command containing
 * the version of the sources used to build the binary.
 */
class MachOSourceVersionCommand
    extends IMachOLoadCommand<MachOSourceVersionCommand> {
  final Uint64 version; /* A.B.C.D.E packed as a24.b10.c10.d10.e10 (uint64_t) */

  MachOSourceVersionCommand(
    Uint32 cmdsize,
    this.version,
  ) : super(
          MachOConstants.LC_SOURCE_VERSION,
          cmdsize,
        );

  @override
  MachOSourceVersionCommand asType() => this;

  @override
  void writeContentsSync(RandomAccessFile stream) {
    stream.writeUint64(version);
  }
}

/*
 * The LC_DATA_IN_CODE load commands uses a linkedit_data_command
 * to point to an array of data_in_code_entry entries. Each entry
 * describes a range of data in a code section.  This load command
 * is only used in final linked images.
 */
class MachODataInCodeEntry {
  final Uint32 offset; /* from mach_header to start of data range(uint32_t) */
  final Uint16 length; /* number of bytes in data range (uint16_t) */
  final Uint16 kind; /* a DICE_KIND_* value  (uint16_t) */

  MachODataInCodeEntry(
    this.offset,
    this.length,
    this.kind,
  );
}

/*
 * Sections of type S_THREAD_LOCAL_VARIABLES contain an array
 * of tlv_descriptor structures.
 */
// class MachOTlvDescriptor {
// 	void*		(*thunk)(struct tlv_descriptor*);
// 	unsigned long	key;
// 	unsigned long	offset;

// 	MachOTlvDescriptor(
//     void*		(*thunk)(struct tlv_descriptor*);
// 	unsigned long	key;
// 	unsigned long	offset;
// );

// }

class MachOConstants {
  /* Constant for the magic field of the mach_header (32-bit architectures) */
  static const Uint32 MH_MAGIC = Uint32(0xfeedface); /* the mach magic number */
  static const Uint32 MH_CIGAM = Uint32(0xcefaedfe); /* NXSwapInt(MH_MAGIC) */

  /* Constant for the magic field of the mach_header_64 (64-bit architectures) */
  static const Uint32 MH_MAGIC_64 =
      Uint32(0xfeedfacf); /* the 64-bit mach magic number */
  static const Uint32 MH_CIGAM_64 =
      Uint32(0xcffaedfe); /* NXSwapInt(MH_MAGIC_64) */

  /*
  * After MacOS X 10.1 when a new load command is added that is required to be
  * understood by the dynamic linker for the image to execute properly the
  * LC_REQ_DYLD bit will be or'ed into the load command constant. If the dynamic
  * linker sees such a load command it it does not understand will issue a
  * "unknown load command required for execution" error and refuse to use the
  * image.  Other load commands without this bit that are not understood will
  * simply be ignored.
  */
  static const Uint32 LC_REQ_DYLD = Uint32(0x80000000);
  // This one is a convenience so we can define other constants in this class as
  // actual const.
  static const int _LC_REQ_DYLD = 0x80000000;

  /*; Constants for the cmd field of all load commands, the type */
  static const Uint32 LC_SEGMENT =
      Uint32(0x1); /* segment of this file to be mapped */
  static const Uint32 LC_SYMTAB =
      Uint32(0x2); /* link-edit stab symbol table info */
  static const Uint32 LC_SYMSEG =
      Uint32(0x3); /* link-edit gdb symbol table info (obsolete) */
  static const Uint32 LC_THREAD = Uint32(0x4); /* thread */
  static const Uint32 LC_UNIXTHREAD =
      Uint32(0x5); /* unix thread (includes a stack) */
  static const Uint32 LC_LOADFVMLIB =
      Uint32(0x6); /* load a specified fixed VM shared library */
  static const Uint32 LC_IDFVMLIB =
      Uint32(0x7); /* fixed VM shared library identification */
  static const Uint32 LC_IDENT =
      Uint32(0x8); /* object identification info (obsolete) */
  static const Uint32 LC_FVMFILE =
      Uint32(0x9); /* fixed VM file inclusion (internal use) */
  static const Uint32 LC_PREPAGE =
      Uint32(0xa); /* prepage command (internal use) */
  static const Uint32 LC_DYSYMTAB =
      Uint32(0xb); /* dynamic link-edit symbol table info */
  static const Uint32 LC_LOAD_DYLIB =
      Uint32(0xc); /* load a dynamically linked shared library */
  static const Uint32 LC_ID_DYLIB =
      Uint32(0xd); /* dynamically linked shared lib ident */
  static const Uint32 LC_LOAD_DYLINKER =
      Uint32(0xe); /* load a dynamic linker */
  static const Uint32 LC_ID_DYLINKER =
      Uint32(0xf); /* dynamic linker identification */
  static const Uint32 LC_PREBOUND_DYLIB =
      Uint32(0x10); /* modules prebound for a dynamically */
  /*  linked shared library */
  static const Uint32 LC_ROUTINES = Uint32(0x11); /* image routines */
  static const Uint32 LC_SUB_FRAMEWORK = Uint32(0x12); /* sub framework */
  static const Uint32 LC_SUB_UMBRELLA = Uint32(0x13); /* sub umbrella */
  static const Uint32 LC_SUB_CLIENT = Uint32(0x14); /* sub client */
  static const Uint32 LC_SUB_LIBRARY = Uint32(0x15); /* sub library */
  static const Uint32 LC_TWOLEVEL_HINTS =
      Uint32(0x16); /* two-level namespace lookup hints */
  static const Uint32 LC_PREBIND_CKSUM = Uint32(0x17); /* prebind checksum */

  /*
  * load a dynamically linked shared library that is allowed to be missing
  * (all symbols are weak imported).
  */
  static const Uint32 LC_LOAD_WEAK_DYLIB = Uint32(0x18 | _LC_REQ_DYLD);

  static const Uint32 LC_SEGMENT_64 = Uint32(0x19);
  /* 64-bit segment of this file to be
	mapped */
  static const Uint32 LC_ROUTINES_64 = Uint32(0x1a); /* 64-bit image routines */
  static const Uint32 LC_UUID = Uint32(0x1b); /* the uuid */
  static const Uint32 LC_RPATH =
      Uint32(0x1c | _LC_REQ_DYLD); /* runpath additions */
  static const Uint32 LC_CODE_SIGNATURE =
      Uint32(0x1d); /* local of code signature */
  static const Uint32 LC_SEGMENT_SPLIT_INFO =
      Uint32(0x1e); /* local of info to split segments */
  static const Uint32 LC_REEXPORT_DYLIB =
      Uint32(0x1f | _LC_REQ_DYLD); /* load and re-export dylib */
  static const Uint32 LC_LAZY_LOAD_DYLIB =
      Uint32(0x20); /* delay load of dylib until first use */
  static const Uint32 LC_ENCRYPTION_INFO =
      Uint32(0x21); /* encrypted segment information */
  static const Uint32 LC_DYLD_INFO =
      Uint32(0x22); /* compressed dyld information */
  static const Uint32 LC_DYLD_INFO_ONLY =
      Uint32(0x22 | _LC_REQ_DYLD); /* compressed dyld information only */
  static const Uint32 LC_LOAD_UPWARD_DYLIB =
      Uint32(0x23 | _LC_REQ_DYLD); /* load upward dylib */
  static const Uint32 LC_VERSION_MIN_MACOSX =
      Uint32(0x24); /* build for MacOSX min OS version */
  static const Uint32 LC_VERSION_MIN_IPHONEOS =
      Uint32(0x25); /* build for iPhoneOS min OS version */
  static const Uint32 LC_FUNCTION_STARTS =
      Uint32(0x26); /* compressed table of function start addresses */
  static const Uint32 LC_DYLD_ENVIRONMENT = Uint32(0x27);
  /* string for dyld to treat
	like environment variable */
  static const Uint32 LC_MAIN =
      Uint32(0x28 | _LC_REQ_DYLD); /* replacement for LC_UNIXTHREAD */
  static const Uint32 LC_DATA_IN_CODE =
      Uint32(0x29); /* table of non-instructions in __text */
  static const Uint32 LC_SOURCE_VERSION =
      Uint32(0x2A); /* source version used to build binary */
  static const Uint32 LC_DYLIB_CODE_SIGN_DRS =
      Uint32(0x2B); /* Code signing DRs copied from linked dylibs */
  static const Uint32 LC_BUILD_VERSION =
      Uint32(0x32); /* Platform min OS version */

  /* Constants for the flags field of the segment_command */

  /* the file contents for this segment is for the high part of the VM space,
	the low part is zero filled (for stacks in core files) */
  static const Uint32 SG_HIGHVM = Uint32(0x1);
  /* this segment is the VM that is allocated by a fixed VM library, for overlap
	checking in the link editor */
  static const Uint32 SG_FVMLIB = Uint32(0x2);
  /* this segment has nothing that was relocated in it and nothing relocated to
	it, that is it maybe safely replaced without relocation */
  static const Uint32 SG_NORELOC = Uint32(0x4);
  /* This segment is protected.  If the segment starts at file offset 0, the
	first page of the segment is not protected.  All other pages of the segment
	are protected. */
  static const Uint32 SG_PROTECTED_VERSION_1 = Uint32(0x8);

/*
 * The flags field of a section structure is separated into two parts a section
 * type and section attributes.  The section types are mutually exclusive (it
 * can only have one type) but the section attributes are not (it may have more
 * than one attribute).
 */
  static const Uint32 SECTION_TYPE = Uint32(0x000000ff); /* 256 section types */
  static const Uint32 SECTION_ATTRIBUTES =
      Uint32(0xffffff00); /*  24 section attributes */

/* Constants for the type of a section */
  static const Uint32 S_REGULAR = Uint32(0x0); /* regular section */
  static const Uint32 S_ZEROFILL =
      Uint32(0x1); /* zero fill on demand section */
  static const Uint32 S_CSTRING_LITERALS =
      Uint32(0x2); /* section with only literal C strings*/
  static const Uint32 S_4BYTE_LITERALS =
      Uint32(0x3); /* section with only 4 byte literals */
  static const Uint32 S_8BYTE_LITERALS =
      Uint32(0x4); /* section with only 8 byte literals */
  static const Uint32 S_LITERAL_POINTERS =
      Uint32(0x5); /* section with only pointers to */
  /*  literals */
/*
 * For the two types of symbol pointers sections and the symbol stubs section
 * they have indirect symbol table entries.  For each of the entries in the
 * section the indirect symbol table entries, in corresponding order in the
 * indirect symbol table, start at the index stored in the reserved1 field
 * of the section structure.  Since the indirect symbol table entries
 * correspond to the entries in the section the number of indirect symbol table
 * entries is inferred from the size of the section divided by the size of the
 * entries in the section.  For symbol pointers sections the size of the entries
 * in the section is 4 bytes and for symbol stubs sections the byte size of the
 * stubs is stored in the reserved2 field of the section structure.
 */
  static const Uint32 S_NON_LAZY_SYMBOL_POINTERS =
      Uint32(0x6); /* section with only non-lazy
						   symbol pointers */
  static const Uint32 S_LAZY_SYMBOL_POINTERS =
      Uint32(0x7); /* section with only lazy symbol
 pointers */
  static const Uint32 S_SYMBOL_STUBS = Uint32(
      0x8); /* section with only symbol
 stubs, byte size of stub in
 the reserved2 field */
  static const Uint32 S_MOD_INIT_FUNC_POINTERS =
      Uint32(0x9); /* section with only function
 pointers for initialization*/
  static const Uint32 S_MOD_TERM_FUNC_POINTERS =
      Uint32(0xa); /* section with only function
 pointers for termination */
  static const Uint32 S_COALESCED =
      Uint32(0xb); /* section contains symbols that
 are to be coalesced */
  static const Uint32 S_GB_ZEROFILL = Uint32(
      0xc); /* zero fill on demand section
 (that can be larger than 4
 gigabytes) */
  static const Uint32 S_INTERPOSING = Uint32(
      0xd); /* section with only pairs of
 function pointers for
 interposing */
  static const Uint32 S_16BYTE_LITERALS =
      Uint32(0xe); /* section with only 16 byte
 literals */
  static const Uint32 S_DTRACE_DOF =
      Uint32(0xf); /* section contains
 DTrace Object Format */
  static const Uint32 S_LAZY_DYLIB_SYMBOL_POINTERS = Uint32(
      0x10); /* section with only lazy
 symbol pointers to lazy
 loaded dylibs */
  /*
 * Section types to support thread local variables
 */
  static const Uint32 S_THREAD_LOCAL_REGULAR =
      Uint32(0x11); /* template of initial
 values for TLVs */
  static const Uint32 S_THREAD_LOCAL_ZEROFILL =
      Uint32(0x12); /* template of initial
 values for TLVs */
  static const Uint32 S_THREAD_LOCAL_VARIABLES =
      Uint32(0x13); /* TLV descriptors */
  static const Uint32 S_THREAD_LOCAL_VARIABLE_POINTERS =
      Uint32(0x14); /* pointers to TLV
 descriptors */
  static const Uint32 S_THREAD_LOCAL_INIT_FUNCTION_POINTERS =
      Uint32(0x15); /* functions to call
 to initialize TLV
 values */

  /*
 * Constants for the section attributes part of the flags field of a section
 * structure.
 */
  static const Uint32 SECTION_ATTRIBUTES_USR =
      Uint32(0xff000000); /* User setable attributes */
  static const Uint32 S_ATTR_PURE_INSTRUCTIONS =
      Uint32(0x80000000); /* section contains only true
 machine instructions */
  static const Uint32 S_ATTR_NO_TOC = Uint32(
      0x40000000); /* section contains coalesced
 symbols that are not to be
 in a ranlib table of
 contents */
  static const Uint32 S_ATTR_STRIP_STATIC_SYMS = Uint32(
      0x20000000); /* ok to strip static symbols
 in this section in files
 with the MH_DYLDLINK flag */
  static const Uint32 S_ATTR_NO_DEAD_STRIP =
      Uint32(0x10000000); /* no dead stripping */
  static const Uint32 S_ATTR_LIVE_SUPPORT =
      Uint32(0x08000000); /* blocks are live if they
 reference live blocks */
  static const Uint32 S_ATTR_SELF_MODIFYING_CODE =
      Uint32(0x04000000); /* Used with i386 code stubs
 written on by dyld */
  /*
 * If a segment contains any sections marked with S_ATTR_DEBUG then all
 * sections in that segment must have this attribute.  No section other than
 * a section marked with this attribute may reference the contents of this
 * section.  A section with this attribute may contain no symbols and must have
 * a section type S_REGULAR.  The static linker will not copy section contents
 * from sections with this attribute into its output file.  These sections
 * generally contain DWARF debugging info.
 */
  static const Uint32 S_ATTR_DEBUG = Uint32(0x02000000); /* a debug section */
  static const Uint32 SECTION_ATTRIBUTES_SYS =
      Uint32(0x00ffff00); /* system setable attributes */
  static const Uint32 S_ATTR_SOME_INSTRUCTIONS =
      Uint32(0x00000400); /* section contains some
 machine instructions */
  static const Uint32 S_ATTR_EXT_RELOC =
      Uint32(0x00000200); /* section has external
 relocation entries */
  static const Uint32 S_ATTR_LOC_RELOC =
      Uint32(0x00000100); /* section has local
 relocation entries */

  /*
 * The names of segments and sections in them are mostly meaningless to the
 * link-editor.  But there are few things to support traditional UNIX
 * executables that require the link-editor and assembler to use some names
 * agreed upon by convention.
 *
 * The initial protection of the "__TEXT" segment has write protection turned
 * off (not writeable).
 *
 * The link-editor will allocate common symbols at the end of the "__common"
 * section in the "__DATA" segment.  It will create the section and segment
 * if needed.
 */

/* The currently known segment names and the section names in those segments */

  static final String SEG_PAGEZERO =
      "__PAGEZERO"; /* the pagezero segment which has no */
  /* protections and catches NULL */
  /* references for MH_EXECUTE files */

  static final String SEG_TEXT = "__TEXT"; /* the tradition UNIX text segment */
  static final String SECT_TEXT = "__text"; /* the real text part of the text */
  /* section no headers, and no padding */
  static final String SECT_FVMLIB_INIT0 =
      "__fvmlib_init0"; /* the fvmlib initialization */
  /*  section */
  static final String SECT_FVMLIB_INIT1 =
      "__fvmlib_init1"; /* the section following the */
  /*  fvmlib initialization */
  /*  section */

  static final String SEG_DATA = "__DATA"; /* the tradition UNIX data segment */
  static final String SECT_DATA =
      "__data"; /* the real initialized data section */
  /* no padding, no bss overlap */
  static final String SECT_BSS =
      "__bss"; /* the real uninitialized data section*/
  /* no padding */
  static final String SECT_COMMON =
      "__common"; /* the section common symbols are */
  /* allocated in by the link editor */

  static final String SEG_OBJC = "__OBJC"; /* objective-C runtime segment */
  static final String SECT_OBJC_SYMBOLS = "__symbol_table"; /* symbol table */
  static final String SECT_OBJC_MODULES =
      "__module_info"; /* module information */
  static final String SECT_OBJC_STRINGS = "__selector_strs"; /* string table */
  static final String SECT_OBJC_REFS = "__selector_refs"; /* string table */

  static final String SEG_ICON = "__ICON"; /* the icon segment */
  static final String SECT_ICON_HEADER = "__header"; /* the icon headers */
  static final String SECT_ICON_TIFF = "__tiff"; /* the icons in tiff format */

  static final String SEG_LINKEDIT =
      "__LINKEDIT"; /* the segment containing all structs */
  /* created and maintained by the link */
  /* editor.  Created with -seglinkedit */
  /* option to ld(1) for MH_EXECUTE and */
  /* FVMLIB file types only */

  static final String SEG_UNIXSTACK =
      "__UNIXSTACK"; /* the unix stack segment */

  static final String SEG_IMPORT =
      "__IMPORT"; /* the segment for the self (dyld) */
  /* modifing code stubs that has read, */
  /* write and execute permissions */

  /*
 * An indirect symbol table entry is simply a 32bit index into the symbol table
 * to the symbol that the pointer or stub is refering to.  Unless it is for a
 * non-lazy symbol pointer section for a defined symbol which strip(1) as
 * removed.  In which case it has the value INDIRECT_SYMBOL_LOCAL.  If the
 * symbol was also absolute INDIRECT_SYMBOL_ABS is or'ed with that.
 */
  static const Uint32 INDIRECT_SYMBOL_LOCAL = Uint32(0x80000000);
  static const Uint32 INDIRECT_SYMBOL_ABS = Uint32(0x40000000);

  /*
 * The following are used to encode rebasing information
 */
  static const Uint32 REBASE_TYPE_POINTER = Uint32(1);
  static const Uint32 REBASE_TYPE_TEXT_ABSOLUTE32 = Uint32(2);
  static const Uint32 REBASE_TYPE_TEXT_PCREL32 = Uint32(3);

  static const Uint32 REBASE_OPCODE_MASK = Uint32(0xF0);
  static const Uint32 REBASE_IMMEDIATE_MASK = Uint32(0x0F);
  static const Uint32 REBASE_OPCODE_DONE = Uint32(0x00);
  static const Uint32 REBASE_OPCODE_SET_TYPE_IMM = Uint32(0x10);
  static const Uint32 REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB = Uint32(0x20);
  static const Uint32 REBASE_OPCODE_ADD_ADDR_ULEB = Uint32(0x30);
  static const Uint32 REBASE_OPCODE_ADD_ADDR_IMM_SCALED = Uint32(0x40);
  static const Uint32 REBASE_OPCODE_DO_REBASE_IMM_TIMES = Uint32(0x50);
  static const Uint32 REBASE_OPCODE_DO_REBASE_ULEB_TIMES = Uint32(0x60);
  static const Uint32 REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB = Uint32(0x70);
  static const Uint32 REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB =
      Uint32(0x80);

/*
 * The following are used to encode binding information
 */
  static const Uint32 BIND_TYPE_POINTER = Uint32(1);
  static const Uint32 BIND_TYPE_TEXT_ABSOLUTE32 = Uint32(2);
  static const Uint32 BIND_TYPE_TEXT_PCREL32 = Uint32(3);

  static const Uint32 BIND_SPECIAL_DYLIB_SELF = Uint32(0);
  static const Uint32 BIND_SPECIAL_DYLIB_MAIN_EXECUTABLE = Uint32(-1);
  static const Uint32 BIND_SPECIAL_DYLIB_FLAT_LOOKUP = Uint32(-2);

  static const Uint32 BIND_SYMBOL_FLAGS_WEAK_IMPORT = Uint32(0x1);
  static const Uint32 BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION = Uint32(0x8);

  static const Uint32 BIND_OPCODE_MASK = Uint32(0xF0);
  static const Uint32 BIND_IMMEDIATE_MASK = Uint32(0x0F);
  static const Uint32 BIND_OPCODE_DONE = Uint32(0x00);
  static const Uint32 BIND_OPCODE_SET_DYLIB_ORDINAL_IMM = Uint32(0x10);
  static const Uint32 BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB = Uint32(0x20);
  static const Uint32 BIND_OPCODE_SET_DYLIB_SPECIAL_IMM = Uint32(0x30);
  static const Uint32 BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM = Uint32(0x40);
  static const Uint32 BIND_OPCODE_SET_TYPE_IMM = Uint32(0x50);
  static const Uint32 BIND_OPCODE_SET_ADDEND_SLEB = Uint32(0x60);
  static const Uint32 BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB = Uint32(0x70);
  static const Uint32 BIND_OPCODE_ADD_ADDR_ULEB = Uint32(0x80);
  static const Uint32 BIND_OPCODE_DO_BIND = Uint32(0x90);
  static const Uint32 BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB = Uint32(0xA0);
  static const Uint32 BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED = Uint32(0xB0);
  static const Uint32 BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB =
      Uint32(0xC0);

/*
 * The following are used on the flags byte of a terminal node
 * in the export information.
 */
  static const Uint32 EXPORT_SYMBOL_FLAGS_KIND_MASK = Uint32(0x03);
  static const Uint32 EXPORT_SYMBOL_FLAGS_KIND_REGULAR = Uint32(0x00);
  static const Uint32 EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL = Uint32(0x01);
  static const Uint32 EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION = Uint32(0x04);
  static const Uint32 EXPORT_SYMBOL_FLAGS_REEXPORT = Uint32(0x08);
  static const Uint32 EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER = Uint32(0x10);

  static const Uint32 DICE_KIND_DATA =
      Uint32(0x0001); /* L$start$data$...  label */
  static const Uint32 DICE_KIND_JUMP_TABLE8 =
      Uint32(0x0002); /* L$start$jt8$...   label */
  static const Uint32 DICE_KIND_JUMP_TABLE16 =
      Uint32(0x0003); /* L$start$jt16$...  label */
  static const Uint32 DICE_KIND_JUMP_TABLE32 =
      Uint32(0x0004); /* L$start$jt32$...  label */
  static const Uint32 DICE_KIND_ABS_JUMP_TABLE32 =
      Uint32(0x0005); /* L$start$jta32$... label */

/*
 *	Protection values, defined as bits within the vm_prot_t type
 */

  static const Int32 VM_PROT_NONE = Int32(0x00);
  static const Int32 VM_PROT_READ = Int32(0x01); /* read permission */
  static const Int32 VM_PROT_WRITE = Int32(0x02); /* write permission */
  static const Int32 VM_PROT_EXECUTE = Int32(0x04); /* execute permission */

/*
 *	The default protection for newly-created virtual memory
 */

  static final Int32 VM_PROT_DEFAULT = VM_PROT_READ | VM_PROT_WRITE;

/*
 *	The maximum privileges possible, for parameter checking.
 */

  static final Int32 VM_PROT_ALL =
      VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE;

/*
 *	An invalid protection value.
 *	Used only by memory_object_lock_request to indicate no change
 *	to page locks.  Using -1 here is a bad idea because it
 *	looks like VM_PROT_ALL and then some.
 */

  static const Int32 VM_PROT_NO_CHANGE = Int32(0x08);

/*
 *      When a caller finds that he cannot obtain write permission on a
 *      mapped entry, the following flag can be used.  The entry will
 *      be made "needs copy" effectively copying the object (using COW),
 *      and write permission will be added to the maximum protections
 *      for the associated entry.
 */

  static const Int32 VM_PROT_COPY = Int32(0x10);

/*
 *	Another invalid protection value.
 *	Used only by memory_object_data_request upon an object
 *	which has specified a copy_call copy strategy. It is used
 *	when the kernel wants a page belonging to a copy of the
 *	object, and is only asking the object as a result of
 *	following a shadow chain. This solves the race between pages
 *	being pushed up by the memory manager and the kernel
 *	walking down the shadow chain.
 */

  static const Int32 VM_PROT_WANTS_COPY = Int32(0x10);
}
