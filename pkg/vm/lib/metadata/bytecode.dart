// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.bytecode;

import 'package:kernel/ast.dart';
import '../bytecode/bytecode_serialization.dart'
    show BufferedWriter, BufferedReader, BytecodeSizeStatistics, StringTable;
import '../bytecode/constant_pool.dart' show ConstantPool;
import '../bytecode/dbc.dart'
    show
        stableBytecodeFormatVersion,
        futureBytecodeFormatVersion,
        bytecodeInstructionsAlignment;
import '../bytecode/disassembler.dart' show BytecodeDisassembler;
import '../bytecode/exceptions.dart' show ExceptionsTable;
import '../bytecode/object_table.dart'
    show ObjectTable, ObjectHandle, NameAndType;
import '../bytecode/source_positions.dart' show SourcePositions;

abstract class BytecodeMetadata {
  void write(BufferedWriter writer);
}

/// Bytecode of a member is encoded in the following way:
///
/// type MemberBytecode {
///   UInt flags (HasExceptionsTable, HasSourcePositions, HasNullableFields,
///               HasClosures)
///
///   (optional, present if HasClosures)
///   List<ClosureDeclaration> closureDeclarations
///
///   ConstantPool constantPool
///
///   UInt bytecodeSizeInBytes
///   Byte[] padding
///   Byte[bytecodeSizeInBytes] bytecodes
///
///   (optional, present if HasExceptionsTable)
///   ExceptionsTable exceptionsTable
///
///   (optional, present if HasSourcePositions)
///   SourcePositions sourcePositionsTabe
///
///   (optional, present if HasNullableFields)
///   List<PackedObject> nullableFields
///
///   (optional, present if HasClosures)
///   ClosureBytecode[] closures
/// }
///
/// type ClosureDeclaration {
///   UInt flags (hasOptionalPositionalParams, hasOptionalNamedParams,
///               hasTypeParams)
///
///   PackedObject parent // Member or Closure
///   PackedObject name
///
///   if hasTypeParams
///     UInt numTypeParameters
///     PackedObject[numTypeParameters] typeParameterNames
///     PackedObject[numTypeParameters] typeParameterBounds
///
///   UInt numParameters
///
///   if hasOptionalPositionalParams || hasOptionalNamedParams
///     UInt numRequiredParameters
///
///   NameAndType[numParameters] parameters
///   PackedObject returnType
/// }
///
/// type ClosureBytecode {
///   UInt flags (HasExceptionsTable, HasSourcePositions)
///
///   UInt bytecodeSizeInBytes
///   Byte[] padding
///   Byte[bytecodeSizeInBytes] bytecodes
///
///   (optional, present if HasExceptionsTable)
///   ExceptionsTable exceptionsTable
///
///   (optional, present if HasSourcePositions)
///   SourcePositions sourcePositionsTabe
/// }
///
/// Encoding of ExceptionsTable is described in
/// pkg/vm/lib/bytecode/exceptions.dart.
///
/// Encoding of ConstantPool is described in
/// pkg/vm/lib/bytecode/constant_pool.dart.
///
class MemberBytecode extends BytecodeMetadata {
  static const hasExceptionsTableFlag = 1 << 0;
  static const hasSourcePositionsFlag = 1 << 1;
  static const hasNullableFieldsFlag = 1 << 2;
  static const hasClosuresFlag = 1 << 3;

  final ConstantPool constantPool;
  final List<int> bytecodes;
  final ExceptionsTable exceptionsTable;
  final SourcePositions sourcePositions;
  final List<ObjectHandle> nullableFields;
  final List<ClosureDeclaration> closures;

  bool get hasExceptionsTable => exceptionsTable.blocks.isNotEmpty;
  bool get hasSourcePositions => sourcePositions.mapping.isNotEmpty;
  bool get hasNullableFields => nullableFields.isNotEmpty;
  bool get hasClosures => closures.isNotEmpty;

  int get flags =>
      (hasExceptionsTable ? hasExceptionsTableFlag : 0) |
      (hasSourcePositions ? hasSourcePositionsFlag : 0) |
      (hasNullableFields ? hasNullableFieldsFlag : 0) |
      (hasClosures ? hasClosuresFlag : 0);

  MemberBytecode(this.constantPool, this.bytecodes, this.exceptionsTable,
      this.sourcePositions, this.nullableFields, this.closures);

  @override
  void write(BufferedWriter writer) {
    final start = writer.offset;
    writer.writePackedUInt30(flags);
    if (hasClosures) {
      writer.writePackedUInt30(closures.length);
      closures.forEach((c) => c.write(writer));
    }
    constantPool.write(writer);
    _writeBytecodeInstructions(writer, bytecodes);
    if (hasExceptionsTable) {
      exceptionsTable.write(writer);
    }
    if (hasSourcePositions) {
      sourcePositions.write(writer);
    }
    if (hasNullableFields) {
      writer.writePackedList(nullableFields);
    }
    if (hasClosures) {
      closures.forEach((c) => c.bytecode.write(writer));
    }
    BytecodeSizeStatistics.membersSize += (writer.offset - start);
  }

  factory MemberBytecode.read(BufferedReader reader) {
    int flags = reader.readPackedUInt30();
    final List<ClosureDeclaration> closures = ((flags & hasClosuresFlag) != 0)
        ? new List<ClosureDeclaration>.generate(reader.readPackedUInt30(),
            (_) => new ClosureDeclaration.read(reader))
        : const <ClosureDeclaration>[];
    final ConstantPool constantPool = new ConstantPool.read(reader);
    final List<int> bytecodes = _readBytecodeInstructions(reader);
    final exceptionsTable = ((flags & hasExceptionsTableFlag) != 0)
        ? new ExceptionsTable.read(reader)
        : new ExceptionsTable();
    final sourcePositions = ((flags & hasSourcePositionsFlag) != 0)
        ? new SourcePositions.read(reader)
        : new SourcePositions();
    final List<ObjectHandle> nullableFields =
        ((flags & hasNullableFieldsFlag) != 0)
            ? reader.readPackedList<ObjectHandle>()
            : const <ObjectHandle>[];
    for (var c in closures) {
      c.bytecode = new ClosureBytecode.read(reader);
    }
    return new MemberBytecode(constantPool, bytecodes, exceptionsTable,
        sourcePositions, nullableFields, closures);
  }

  // TODO(alexmarkov): Consider printing constant pool before bytecode.
  @override
  String toString() => "\n"
      "Bytecode {\n"
      "${new BytecodeDisassembler().disassemble(bytecodes, exceptionsTable, annotations: [
        sourcePositions.getBytecodeAnnotations()
      ])}}\n"
      "$exceptionsTable"
      "${nullableFields.isEmpty ? '' : 'Nullable fields: $nullableFields}\n'}"
      "$constantPool"
      "${closures.join('\n')}";
}

class ClosureDeclaration {
  static const int flagHasOptionalPositionalParams = 1 << 0;
  static const int flagHasOptionalNamedParams = 1 << 1;
  static const int flagHasTypeParams = 1 << 2;

  final ObjectHandle parent;
  final ObjectHandle name;
  final List<NameAndType> typeParams;
  final int numRequiredParams;
  final int numNamedParams;
  final List<NameAndType> parameters;
  final ObjectHandle returnType;
  ClosureBytecode bytecode;

  ClosureDeclaration(
      this.parent,
      this.name,
      this.typeParams,
      this.numRequiredParams,
      this.numNamedParams,
      this.parameters,
      this.returnType);

  void write(BufferedWriter writer) {
    int flags = 0;
    if (numRequiredParams != parameters.length) {
      if (numNamedParams > 0) {
        flags |= flagHasOptionalNamedParams;
      } else {
        flags |= flagHasOptionalPositionalParams;
      }
    }
    if (typeParams.isNotEmpty) {
      flags |= flagHasTypeParams;
    }
    writer.writePackedUInt30(flags);
    writer.writePackedObject(parent);
    writer.writePackedObject(name);

    if (flags & flagHasTypeParams != 0) {
      writer.writePackedUInt30(typeParams.length);
      for (var tp in typeParams) {
        writer.writePackedObject(tp.name);
      }
      for (var tp in typeParams) {
        writer.writePackedObject(tp.type);
      }
    }
    writer.writePackedUInt30(parameters.length);
    if (flags &
            (flagHasOptionalPositionalParams | flagHasOptionalNamedParams) !=
        0) {
      writer.writePackedUInt30(numRequiredParams);
    }
    for (var param in parameters) {
      writer.writePackedObject(param.name);
      writer.writePackedObject(param.type);
    }
    writer.writePackedObject(returnType);
  }

  factory ClosureDeclaration.read(BufferedReader reader) {
    final int flags = reader.readPackedUInt30();
    final parent = reader.readPackedObject();
    final name = reader.readPackedObject();
    List<NameAndType> typeParams;
    if ((flags & flagHasTypeParams) != 0) {
      final int numTypeParams = reader.readPackedUInt30();
      List<ObjectHandle> names = new List<ObjectHandle>.generate(
          numTypeParams, (_) => reader.readPackedObject());
      List<ObjectHandle> bounds = new List<ObjectHandle>.generate(
          numTypeParams, (_) => reader.readPackedObject());
      typeParams = new List<NameAndType>.generate(
          numTypeParams, (int i) => new NameAndType(names[i], bounds[i]));
    } else {
      typeParams = const <NameAndType>[];
    }
    final numParams = reader.readPackedUInt30();
    final numRequiredParams = (flags &
                (flagHasOptionalPositionalParams |
                    flagHasOptionalNamedParams) !=
            0)
        ? reader.readPackedUInt30()
        : numParams;
    final numNamedParams = (flags & flagHasOptionalNamedParams != 0)
        ? (numParams - numRequiredParams)
        : 0;
    final List<NameAndType> parameters = new List<NameAndType>.generate(
        numParams,
        (_) => new NameAndType(
            reader.readPackedObject(), reader.readPackedObject()));
    final returnType = reader.readPackedObject();
    return new ClosureDeclaration(parent, name, typeParams, numRequiredParams,
        numNamedParams, parameters, returnType);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('Closure $parent::$name');
    if (typeParams.isNotEmpty) {
      sb.write(' <${typeParams.join(', ')}>');
    }
    sb.write(' (');
    sb.write(parameters.sublist(0, numRequiredParams).join(', '));
    if (numRequiredParams != parameters.length) {
      if (numRequiredParams > 0) {
        sb.write(', ');
      }
      if (numNamedParams > 0) {
        sb.write('{ ${parameters.sublist(numRequiredParams).join(', ')} }');
      } else {
        sb.write('[ ${parameters.sublist(numRequiredParams).join(', ')} ]');
      }
    }
    sb.write(') -> ');
    sb.writeln(returnType);
    if (bytecode != null) {
      sb.write(bytecode.toString());
    }
    return sb.toString();
  }
}

/// Bytecode of a nested function (closure).
/// Closures share the constant pool of a top-level member.
class ClosureBytecode {
  final List<int> bytecodes;
  final ExceptionsTable exceptionsTable;
  final SourcePositions sourcePositions;

  bool get hasExceptionsTable => exceptionsTable.blocks.isNotEmpty;
  bool get hasSourcePositions => sourcePositions.mapping.isNotEmpty;

  int get flags =>
      (hasExceptionsTable ? MemberBytecode.hasExceptionsTableFlag : 0) |
      (hasSourcePositions ? MemberBytecode.hasSourcePositionsFlag : 0);

  ClosureBytecode(this.bytecodes, this.exceptionsTable, this.sourcePositions);

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(flags);
    _writeBytecodeInstructions(writer, bytecodes);
    if (hasExceptionsTable) {
      exceptionsTable.write(writer);
    }
    if (hasSourcePositions) {
      sourcePositions.write(writer);
    }
  }

  factory ClosureBytecode.read(BufferedReader reader) {
    final int flags = reader.readPackedUInt30();
    final List<int> bytecodes = _readBytecodeInstructions(reader);
    final exceptionsTable =
        ((flags & MemberBytecode.hasExceptionsTableFlag) != 0)
            ? new ExceptionsTable.read(reader)
            : new ExceptionsTable();
    final sourcePositions =
        ((flags & MemberBytecode.hasSourcePositionsFlag) != 0)
            ? new SourcePositions.read(reader)
            : new SourcePositions();
    return new ClosureBytecode(bytecodes, exceptionsTable, sourcePositions);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln('ClosureBytecode {');
    sb.writeln(new BytecodeDisassembler().disassemble(
        bytecodes, exceptionsTable,
        annotations: [sourcePositions.getBytecodeAnnotations()]));
    sb.writeln('}');
    return sb.toString();
  }
}

class BytecodeComponent extends BytecodeMetadata {
  int version;
  StringTable stringTable;
  ObjectTable objectTable;

  BytecodeComponent(this.version)
      : stringTable = new StringTable(),
        objectTable = new ObjectTable();

  @override
  void write(BufferedWriter writer) {
    final start = writer.offset;
    objectTable.allocateIndexTable();

    // Writing object table may add new strings to strings table,
    // so serialize object table first.
    BufferedWriter objectsWriter = new BufferedWriter.fromWriter(writer);
    objectTable.write(objectsWriter);

    BufferedWriter stringsWriter = new BufferedWriter.fromWriter(writer);
    stringTable.write(stringsWriter);

    writer.writePackedUInt30(version);
    writer.writePackedUInt30(stringsWriter.offset);
    writer.writePackedUInt30(objectsWriter.offset);

    writer.writeBytes(stringsWriter.takeBytes());
    writer.writeBytes(objectsWriter.takeBytes());
    BytecodeSizeStatistics.componentSize += (writer.offset - start);
  }

  BytecodeComponent.read(BufferedReader reader) {
    version = reader.readPackedUInt30();
    if (version != stableBytecodeFormatVersion &&
        version != futureBytecodeFormatVersion) {
      throw 'Error: unexpected bytecode version $version';
    }
    reader.formatVersion = version;
    reader.readPackedUInt30(); // Strings size
    reader.readPackedUInt30(); // Objects size

    stringTable = new StringTable.read(reader);
    reader.stringReader = stringTable;

    objectTable = new ObjectTable.read(reader);
    reader.objectReader = objectTable;
  }

  String toString() => "\n"
      "Bytecode"
      " (version: "
      "${version == stableBytecodeFormatVersion ? 'stable' : version == futureBytecodeFormatVersion ? 'future' : "v$version"}"
      ")\n"
//      "$objectTable\n"
//      "$stringTable\n"
      ;
}

/// Repository for [BytecodeMetadata].
class BytecodeMetadataRepository extends MetadataRepository<BytecodeMetadata> {
  @override
  final String tag = 'vm.bytecode';

  @override
  final Map<TreeNode, BytecodeMetadata> mapping =
      <TreeNode, BytecodeMetadata>{};

  BytecodeComponent bytecodeComponent;

  @override
  void writeToBinary(BytecodeMetadata metadata, Node node, BinarySink sink) {
    if (node is Component) {
      bytecodeComponent = metadata as BytecodeComponent;
    } else {
      assert(bytecodeComponent != null);
    }
    final writer = new BufferedWriter(bytecodeComponent.version,
        bytecodeComponent.stringTable, bytecodeComponent.objectTable,
        baseOffset: sink.getBufferOffset());
    metadata.write(writer);
    sink.writeBytes(writer.takeBytes());
  }

  @override
  BytecodeMetadata readFromBinary(Node node, BinarySource source) {
    if (node is Component) {
      final reader = new BufferedReader(-1, null, null, source.bytes,
          baseOffset: source.currentOffset);
      bytecodeComponent = new BytecodeComponent.read(reader);
      return bytecodeComponent;
    } else {
      final reader = new BufferedReader(
          bytecodeComponent.version,
          bytecodeComponent.stringTable,
          bytecodeComponent.objectTable,
          source.bytes,
          baseOffset: source.currentOffset);
      return new MemberBytecode.read(reader);
    }
  }
}

void _writeBytecodeInstructions(BufferedWriter writer, List<int> bytecodes) {
  writer.writePackedUInt30(bytecodes.length);
  writer.align(bytecodeInstructionsAlignment);
  writer.writeBytes(bytecodes);
  BytecodeSizeStatistics.instructionsSize += bytecodes.length;
}

List<int> _readBytecodeInstructions(BufferedReader reader) {
  int len = reader.readPackedUInt30();
  reader.align(bytecodeInstructionsAlignment);
  return reader.readBytesAsUint8List(len);
}
