// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.constant_pool;

import 'dart:typed_data';

import 'package:kernel/ast.dart' hide MapEntry;

import 'dbc.dart' show constantPoolIndexLimit, BytecodeLimitExceededException;
import 'bytecode_serialization.dart'
    show
        BufferedWriter,
        BufferedReader,
        BytecodeSizeStatistics,
        NamedEntryStatistics,
        StringTable;
import 'object_table.dart' show ObjectHandle, ObjectTable;

/*

In kernel binary, constant pool is encoded in the following way
(using notation from pkg/kernel/binary.md):

type ConstantPool {
  List<ConstantPoolEntry>
}

type ConstantIndex = UInt;

abstract type ConstantPoolEntry {
  Byte tag;
}

type ConstantNull extends ConstantPoolEntry {
  Byte tag = 1;
}

type ConstantString extends ConstantPoolEntry {
  Byte tag = 2;
  PackedString value;
}

type ConstantInt extends ConstantPoolEntry {
  Byte tag = 3;
  UInt32 low;
  UInt32 high;
}

type ConstantDouble extends ConstantPoolEntry {
  Byte tag = 4;
  UInt32 low;
  UInt32 high;
}

type ConstantBool extends ConstantPoolEntry {
  Byte tag = 5;
  Byte flag;
}

type ConstantArgDesc extends ConstantPoolEntry {
  Byte tag = 6;
  UInt numArguments;
  UInt numTypeArgs;
  List<PackedString> names;
}

enum InvocationKind {
  method, // x.foo(...) or foo(...)
  getter, // x.foo
  setter  // x.foo = ...
}

type ConstantICData extends ConstantPoolEntry {
  Byte tag = 7;
  Byte flags(invocationKindBit0, invocationKindBit1, isDynamic);
             // Where invocationKind is index into InvocationKind.
  PackedObject targetName;
  ConstantIndex argDesc;
}

type ConstantStaticICData extends ConstantPoolEntry {
  Byte tag = 8;
  PackedObject target;
  ConstantIndex argDesc;
}

type ConstantStaticField extends ConstantPoolEntry {
  Byte tag = 9;
  PackedObject field;
}

// Occupies 2 entries in the constant pool.
type ConstantInstanceField extends ConstantPoolEntry {
  Byte tag = 10;
  PackedObject field;
}

type ConstantClass extends ConstantPoolEntry {
  Byte tag = 11;
  PackedObject class;
}

type ConstantTypeArgumentsField extends ConstantPoolEntry {
  Byte tag = 12;
  PackedObject class;
}

type ConstantTearOff extends ConstantPoolEntry {
  Byte tag = 13;
  PackedObject target;
}

type ConstantType extends ConstantPoolEntry {
  Byte tag = 14;
  PackedObject type;
}

type ConstantTypeArguments extends ConstantPoolEntry {
  Byte tag = 15;
  List<PackedObject> types;
}

type ConstantList extends ConstantPoolEntry {
  Byte tag = 16;
  PackedObject typeArg;
  List<ConstantIndex> entries;
}

type ConstantInstance extends ConstantPoolEntry {
  Byte tag = 17;
  PackedObject class;
  ConstantIndex typeArguments;
  List<Pair<PackedObject, ConstantIndex>> fieldValues;
}

type ConstantTypeArgumentsForInstanceAllocation extends ConstantPoolEntry {
  Byte tag = 18;
  PackedObject instantiatingClass;
  List<PackedObject> types;
}

type ConstantClosureFunction extends ConstantPoolEntry {
  Byte tag = 19;
  UInt closureIndex;
}

type ConstantEndClosureFunctionScope extends ConstantPoolEntry {
  Byte tag = 20;
}

type ConstantNativeEntry extends ConstantPoolEntry {
  Byte tag = 21;
  PackedString nativeName;
}

type ConstantSubtypeTestCache extends ConstantPoolEntry {
  Byte tag = 22;
}

type ConstantPartialTearOffInstantiation extends ConstantPoolEntry {
  Byte tag = 23;
  ConstantIndex tearOffConstant;
  ConstantIndex typeArguments;
}

type ConstantEmptyTypeArguments extends ConstantPoolEntry {
  Byte tag = 24;
}

type ConstantSymbol extends ConstantPoolEntry {
  Byte tag = 25;
  PackedObject name;
}

// Occupies 2 entries in the constant pool.
type ConstantInterfaceCallV1 extends ConstantPoolEntry {
  Byte tag = 26;
  Byte flags(invocationKindBit0, invocationKindBit1);
             // Where invocationKind is index into InvocationKind.
  PackedObject targetName;
  ConstantIndex argDesc;
}

type ConstantObjectRef extends ConstantPoolEntry {
  Byte tag = 27;
  PackedObject object;
}

// Occupies 2 entries in the constant pool.
type ConstantDirectCall extends ConstantPoolEntry {
  Byte tag = 28;
  PackedObject target;
  PackedObject argDesc;
}

// Occupies 2 entries in the constant pool.
type ConstantInterfaceCall extends ConstantPoolEntry {
  Byte tag = 29;
  PackedObject target;
  PackedObject argDesc;
}

*/

enum ConstantTag {
  kInvalid,
  kNull, // TODO(alexmarkov): obsolete, remove
  kString, // TODO(alexmarkov): obsolete, remove
  kInt, // TODO(alexmarkov): obsolete, remove
  kDouble, // TODO(alexmarkov): obsolete, remove
  kBool, // TODO(alexmarkov): obsolete, remove
  kArgDesc, // TODO(alexmarkov): obsolete, remove
  kICData,
  kStaticICData, // TODO(alexmarkov): obsolete, remove
  kStaticField,
  kInstanceField,
  kClass,
  kTypeArgumentsField,
  kTearOff, // TODO(alexmarkov): obsolete, remove
  kType,
  kTypeArguments, // TODO(alexmarkov): obsolete, remove
  kList, // TODO(alexmarkov): obsolete, remove
  kInstance, // TODO(alexmarkov): obsolete, remove
  kTypeArgumentsForInstanceAllocation, // TODO(alexmarkov): obsolete, remove
  kClosureFunction,
  kEndClosureFunctionScope,
  kNativeEntry,
  kSubtypeTestCache,
  kPartialTearOffInstantiation, // TODO(alexmarkov): obsolete, remove
  kEmptyTypeArguments,
  kSymbol, // TODO(alexmarkov): obsolete, remove
  kInterfaceCallV1, // TODO(alexmarkov): obsolete, remove
  kObjectRef,
  kDirectCall,
  kInterfaceCall,
}

String constantTagToString(ConstantTag tag) =>
    tag.toString().substring('ConstantTag.k'.length);

abstract class ConstantPoolEntry {
  const ConstantPoolEntry();

  ConstantTag get tag;

  // Returns number of extra reserved constant pool entries
  // following this entry.
  int get numReservedEntries => 0;

  void write(BufferedWriter writer) {
    writer.writeByte(tag.index);
    writeValue(writer);
  }

  void writeValue(BufferedWriter writer);

  factory ConstantPoolEntry.read(BufferedReader reader) {
    ConstantTag tag = ConstantTag.values[reader.readByte()];
    switch (tag) {
      case ConstantTag.kInvalid:
        break;
      case ConstantTag.kNull:
        return new ConstantNull.read(reader);
      case ConstantTag.kString:
        return new ConstantString.read(reader);
      case ConstantTag.kInt:
        return new ConstantInt.read(reader);
      case ConstantTag.kDouble:
        return new ConstantDouble.read(reader);
      case ConstantTag.kBool:
        return new ConstantBool.read(reader);
      case ConstantTag.kICData:
        return new ConstantICData.read(reader);
      case ConstantTag.kStaticICData:
        return new ConstantStaticICData.read(reader);
      case ConstantTag.kArgDesc:
        return new ConstantArgDesc.read(reader);
      case ConstantTag.kStaticField:
        return new ConstantStaticField.read(reader);
      case ConstantTag.kInstanceField:
        return new ConstantInstanceField.read(reader);
      case ConstantTag.kClass:
        return new ConstantClass.read(reader);
      case ConstantTag.kTypeArgumentsField:
        return new ConstantTypeArgumentsField.read(reader);
      case ConstantTag.kTearOff:
        return new ConstantTearOff.read(reader);
      case ConstantTag.kType:
        return new ConstantType.read(reader);
      case ConstantTag.kTypeArguments:
        return new ConstantTypeArguments.read(reader);
      case ConstantTag.kList:
        return new ConstantList.read(reader);
      case ConstantTag.kInstance:
        return new ConstantInstance.read(reader);
      case ConstantTag.kTypeArgumentsForInstanceAllocation:
        return new ConstantTypeArgumentsForInstanceAllocation.read(reader);
      case ConstantTag.kClosureFunction:
        return new ConstantClosureFunction.read(reader);
      case ConstantTag.kEndClosureFunctionScope:
        return new ConstantEndClosureFunctionScope.read(reader);
      case ConstantTag.kNativeEntry:
        return new ConstantNativeEntry.read(reader);
      case ConstantTag.kSubtypeTestCache:
        return new ConstantSubtypeTestCache.read(reader);
      case ConstantTag.kPartialTearOffInstantiation:
        return new ConstantPartialTearOffInstantiation.read(reader);
      case ConstantTag.kEmptyTypeArguments:
        return new ConstantEmptyTypeArguments.read(reader);
      case ConstantTag.kSymbol:
        return new ConstantSymbol.read(reader);
      case ConstantTag.kInterfaceCallV1:
        return new ConstantInterfaceCallV1.read(reader);
      case ConstantTag.kObjectRef:
        return new ConstantObjectRef.read(reader);
      case ConstantTag.kDirectCall:
        return new ConstantDirectCall.read(reader);
      case ConstantTag.kInterfaceCall:
        return new ConstantInterfaceCall.read(reader);
    }
    throw 'Unexpected constant tag $tag';
  }
}

class ConstantNull extends ConstantPoolEntry {
  const ConstantNull();

  @override
  ConstantTag get tag => ConstantTag.kNull;

  @override
  void writeValue(BufferedWriter writer) {}

  ConstantNull.read(BufferedReader reader);

  @override
  String toString() => 'Null';

  @override
  int get hashCode => 1961;

  @override
  bool operator ==(other) => other is ConstantNull;
}

class ConstantString extends ConstantPoolEntry {
  final String value;

  ConstantString(this.value);
  ConstantString.fromLiteral(StringLiteral literal) : this(literal.value);

  @override
  ConstantTag get tag => ConstantTag.kString;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedStringReference(value);
  }

  ConstantString.read(BufferedReader reader)
      : value = reader.readPackedStringReference();

  @override
  String toString() => 'String \'$value\'';

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantString && this.value == other.value;
}

class ConstantInt extends ConstantPoolEntry {
  final int value;

  ConstantInt(this.value);

  @override
  ConstantTag get tag => ConstantTag.kInt;

  @override
  void writeValue(BufferedWriter writer) {
    // TODO(alexmarkov): more efficient encoding
    writer.writeUInt32(value & 0xffffffff);
    writer.writeUInt32((value >> 32) & 0xffffffff);
  }

  ConstantInt.read(BufferedReader reader)
      : value = reader.readUInt32() | (reader.readUInt32() << 32);

  @override
  String toString() => 'Int $value';

  @override
  int get hashCode => value;

  @override
  bool operator ==(other) => other is ConstantInt && this.value == other.value;
}

class ConstantDouble extends ConstantPoolEntry {
  final double value;

  ConstantDouble(this.value);

  @override
  ConstantTag get tag => ConstantTag.kDouble;

  static int doubleToIntBits(double value) {
    final buf = new ByteData(8);
    buf.setFloat64(0, value, Endian.host);
    return buf.getInt64(0, Endian.host);
  }

  static double intBitsToDouble(int bits) {
    final buf = new ByteData(8);
    buf.setInt64(0, bits, Endian.host);
    return buf.getFloat64(0, Endian.host);
  }

  @override
  void writeValue(BufferedWriter writer) {
    // TODO(alexmarkov): more efficient encoding
    int bits = doubleToIntBits(value);
    writer.writeUInt32(bits & 0xffffffff);
    writer.writeUInt32((bits >> 32) & 0xffffffff);
  }

  ConstantDouble.read(BufferedReader reader)
      : value =
            intBitsToDouble(reader.readUInt32() | (reader.readUInt32() << 32));

  @override
  String toString() => 'Double $value';

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantDouble && value.compareTo(other.value) == 0;
}

class ConstantBool extends ConstantPoolEntry {
  final bool value;

  ConstantBool(this.value);
  ConstantBool.fromLiteral(BoolLiteral literal) : this(literal.value);

  @override
  ConstantTag get tag => ConstantTag.kBool;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writeByte(value ? 1 : 0);
  }

  ConstantBool.read(BufferedReader reader) : value = reader.readByte() != 0;

  @override
  String toString() => 'Bool $value';

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(other) => other is ConstantBool && this.value == other.value;
}

class ConstantArgDesc extends ConstantPoolEntry {
  final int numArguments;
  final int numTypeArgs;
  final List<String> argNames;

  ConstantArgDesc(this.numArguments, this.numTypeArgs, this.argNames);

  ConstantArgDesc.fromArguments(
      Arguments args, bool hasReceiver, bool isFactory)
      : this(
            args.positional.length +
                args.named.length +
                (hasReceiver ? 1 : 0) +
                // VM expects that type arguments vector passed to a factory
                // constructor is counted in numArguments, and not counted in
                // numTypeArgs.
                // TODO(alexmarkov): Clean this up.
                (isFactory ? 1 : 0),
            isFactory ? 0 : args.types.length,
            new List<String>.from(args.named.map((ne) => ne.name)));

  @override
  ConstantTag get tag => ConstantTag.kArgDesc;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedUInt30(numArguments);
    writer.writePackedUInt30(numTypeArgs);
    writer.writePackedUInt30(argNames.length);
    argNames.forEach(writer.writePackedStringReference);
  }

  ConstantArgDesc.read(BufferedReader reader)
      : numArguments = reader.readPackedUInt30(),
        numTypeArgs = reader.readPackedUInt30(),
        argNames = new List<String>.generate(reader.readPackedUInt30(),
            (_) => reader.readPackedStringReference());

  @override
  String toString() =>
      'ArgDesc num-args $numArguments, num-type-args $numTypeArgs, names $argNames';

  @override
  int get hashCode => _combineHashes(
      _combineHashes(numArguments, numTypeArgs), listHashCode(argNames));

  @override
  bool operator ==(other) =>
      other is ConstantArgDesc &&
      this.numArguments == other.numArguments &&
      this.numTypeArgs == other.numTypeArgs &&
      listEquals(this.argNames, other.argNames);
}

enum InvocationKind { method, getter, setter }

String _invocationKindToString(InvocationKind kind) {
  switch (kind) {
    case InvocationKind.method:
      return '';
    case InvocationKind.getter:
      return 'get ';
    case InvocationKind.setter:
      return 'set ';
  }
  throw 'Unexpected InvocationKind $kind';
}

class ConstantICData extends ConstantPoolEntry {
  static const int invocationKindMask = 3;
  static const int flagDynamic = 1 << 2;

  final int _flags;
  final ObjectHandle targetName;
  final int argDescConstantIndex;

  ConstantICData(InvocationKind invocationKind, this.targetName,
      this.argDescConstantIndex, bool isDynamic)
      : assert(invocationKind.index <= invocationKindMask),
        _flags = invocationKind.index | (isDynamic ? flagDynamic : 0);

  InvocationKind get invocationKind =>
      InvocationKind.values[_flags & invocationKindMask];

  bool get isDynamic => (_flags & flagDynamic) != 0;

  @override
  ConstantTag get tag => ConstantTag.kICData;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writeByte(_flags);
    writer.writePackedObject(targetName);
    writer.writePackedUInt30(argDescConstantIndex);
  }

  ConstantICData.read(BufferedReader reader)
      : _flags = reader.readByte(),
        targetName = reader.readPackedObject(),
        argDescConstantIndex = reader.readPackedUInt30();

  @override
  String toString() => 'ICData '
      '${isDynamic ? 'dynamic ' : ''}'
      '${_invocationKindToString(invocationKind)}'
      'target-name $targetName, arg-desc CP#$argDescConstantIndex';

  // ConstantICData entries are created per call site and should not be merged,
  // so ConstantICData class uses identity [hashCode] and [operator ==].

  @override
  int get hashCode => identityHashCode(this);

  @override
  bool operator ==(other) => identical(this, other);
}

class ConstantStaticICData extends ConstantPoolEntry {
  final ObjectHandle target;
  final int argDescConstantIndex;

  ConstantStaticICData(this.target, this.argDescConstantIndex);

  @override
  ConstantTag get tag => ConstantTag.kStaticICData;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(target);
    writer.writePackedUInt30(argDescConstantIndex);
  }

  ConstantStaticICData.read(BufferedReader reader)
      : target = reader.readPackedObject(),
        argDescConstantIndex = reader.readPackedUInt30();

  @override
  String toString() => 'StaticICData '
      'target \'$target\', arg-desc CP#$argDescConstantIndex';

  // ConstantStaticICData entries are created per call site and should not be
  // merged, so ConstantStaticICData class uses identity [hashCode] and
  // [operator ==].

  @override
  int get hashCode => identityHashCode(this);

  @override
  bool operator ==(other) => identical(this, other);
}

class ConstantStaticField extends ConstantPoolEntry {
  final ObjectHandle field;

  ConstantStaticField(this.field);

  @override
  ConstantTag get tag => ConstantTag.kStaticField;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(field);
  }

  ConstantStaticField.read(BufferedReader reader)
      : field = reader.readPackedObject();

  @override
  String toString() => 'StaticField $field';

  @override
  int get hashCode => field.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantStaticField && this.field == other.field;
}

class ConstantInstanceField extends ConstantPoolEntry {
  final ObjectHandle field;

  int get numReservedEntries => 1;

  ConstantInstanceField(this.field);

  @override
  ConstantTag get tag => ConstantTag.kInstanceField;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(field);
  }

  ConstantInstanceField.read(BufferedReader reader)
      : field = reader.readPackedObject();

  @override
  String toString() => 'InstanceField $field';

  @override
  int get hashCode => field.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantInstanceField && this.field == other.field;
}

class ConstantClass extends ConstantPoolEntry {
  final ObjectHandle classHandle;

  ConstantClass(this.classHandle);

  @override
  ConstantTag get tag => ConstantTag.kClass;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(classHandle);
  }

  ConstantClass.read(BufferedReader reader)
      : classHandle = reader.readPackedObject();

  @override
  String toString() => 'Class $classHandle';

  @override
  int get hashCode => classHandle.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantClass && this.classHandle == other.classHandle;
}

class ConstantTypeArgumentsField extends ConstantPoolEntry {
  final ObjectHandle classHandle;

  ConstantTypeArgumentsField(this.classHandle);

  @override
  ConstantTag get tag => ConstantTag.kTypeArgumentsField;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(classHandle);
  }

  ConstantTypeArgumentsField.read(BufferedReader reader)
      : classHandle = reader.readPackedObject();

  @override
  String toString() => 'TypeArgumentsField $classHandle';

  @override
  int get hashCode => classHandle.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantTypeArgumentsField &&
      this.classHandle == other.classHandle;
}

class ConstantTearOff extends ConstantPoolEntry {
  final ObjectHandle procedure;

  ConstantTearOff(this.procedure);

  @override
  ConstantTag get tag => ConstantTag.kTearOff;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(procedure);
  }

  ConstantTearOff.read(BufferedReader reader)
      : procedure = reader.readPackedObject();

  @override
  String toString() => 'TearOff $procedure';

  @override
  int get hashCode => procedure.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantTearOff && this.procedure == other.procedure;
}

class ConstantType extends ConstantPoolEntry {
  final ObjectHandle type;

  ConstantType(this.type);

  @override
  ConstantTag get tag => ConstantTag.kType;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(type);
  }

  ConstantType.read(BufferedReader reader) : type = reader.readPackedObject();

  @override
  String toString() => 'Type $type';

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(other) => other is ConstantType && this.type == other.type;
}

class ConstantTypeArguments extends ConstantPoolEntry {
  final List<ObjectHandle> typeArgs;

  ConstantTypeArguments(this.typeArgs);

  @override
  ConstantTag get tag => ConstantTag.kTypeArguments;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedList(typeArgs);
  }

  ConstantTypeArguments.read(BufferedReader reader)
      : typeArgs = reader.readPackedList();

  @override
  String toString() => 'TypeArgs $typeArgs';

  @override
  int get hashCode => listHashCode(typeArgs);

  @override
  bool operator ==(other) =>
      other is ConstantTypeArguments &&
      listEquals(this.typeArgs, other.typeArgs);
}

class ConstantList extends ConstantPoolEntry {
  final ObjectHandle typeArg;
  final List<int> entries;

  ConstantList(this.typeArg, this.entries);

  @override
  ConstantTag get tag => ConstantTag.kList;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(typeArg);
    writer.writePackedUInt30(entries.length);
    entries.forEach(writer.writePackedUInt30);
  }

  ConstantList.read(BufferedReader reader)
      : typeArg = reader.readPackedObject(),
        entries = new List<int>.generate(
            reader.readPackedUInt30(), (_) => reader.readPackedUInt30());

  @override
  String toString() => 'List type-arg $typeArg, entries CP# $entries';

  @override
  int get hashCode => typeArg.hashCode ^ listHashCode(entries);

  @override
  bool operator ==(other) =>
      other is ConstantList &&
      this.typeArg == other.typeArg &&
      listEquals(this.entries, other.entries);
}

class ConstantInstance extends ConstantPoolEntry {
  final ObjectHandle classHandle;
  final int _typeArgumentsConstantIndex;
  final Map<ObjectHandle, int> _fieldValues;

  ConstantInstance(
      this.classHandle, this._typeArgumentsConstantIndex, this._fieldValues);

  @override
  ConstantTag get tag => ConstantTag.kInstance;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(classHandle);
    writer.writePackedUInt30(_typeArgumentsConstantIndex);
    writer.writePackedUInt30(_fieldValues.length);
    _fieldValues.forEach((ObjectHandle field, int valueIndex) {
      writer.writePackedObject(field);
      writer.writePackedUInt30(valueIndex);
    });
  }

  ConstantInstance.read(BufferedReader reader)
      : classHandle = reader.readPackedObject(),
        _typeArgumentsConstantIndex = reader.readPackedUInt30(),
        _fieldValues = new Map<ObjectHandle, int>() {
    final fieldValuesLen = reader.readPackedUInt30();
    for (int i = 0; i < fieldValuesLen; i++) {
      final field = reader.readPackedObject();
      final valueIndex = reader.readPackedUInt30();
      _fieldValues[field] = valueIndex;
    }
  }

  @override
  String toString() {
    final values = _fieldValues.map<String, String>(
        (ObjectHandle field, int valueIndex) =>
            new MapEntry(field.toString(), 'CP#$valueIndex'));
    return 'Instance $classHandle type-args CP#$_typeArgumentsConstantIndex $values';
  }

  @override
  int get hashCode => _combineHashes(
      _combineHashes(classHandle.hashCode, _typeArgumentsConstantIndex),
      mapHashCode(_fieldValues));

  @override
  bool operator ==(other) =>
      other is ConstantInstance &&
      this.classHandle == other.classHandle &&
      this._typeArgumentsConstantIndex == other._typeArgumentsConstantIndex &&
      mapEquals(this._fieldValues, other._fieldValues);
}

class ConstantTypeArgumentsForInstanceAllocation extends ConstantPoolEntry {
  final ObjectHandle instantiatingClass;
  final List<ObjectHandle> typeArgs;

  ConstantTypeArgumentsForInstanceAllocation(
      this.instantiatingClass, this.typeArgs);

  @override
  ConstantTag get tag => ConstantTag.kTypeArgumentsForInstanceAllocation;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(instantiatingClass);
    writer.writePackedList(typeArgs);
  }

  ConstantTypeArgumentsForInstanceAllocation.read(BufferedReader reader)
      : instantiatingClass = reader.readPackedObject(),
        typeArgs = reader.readPackedList();

  @override
  String toString() =>
      'TypeArgumentsForInstanceAllocation $instantiatingClass $typeArgs';

  @override
  int get hashCode =>
      _combineHashes(instantiatingClass.hashCode, listHashCode(typeArgs));

  @override
  bool operator ==(other) =>
      other is ConstantTypeArgumentsForInstanceAllocation &&
      this.instantiatingClass == other.instantiatingClass &&
      listEquals(this.typeArgs, other.typeArgs);
}

class ConstantClosureFunction extends ConstantPoolEntry {
  final int closureIndex;

  ConstantClosureFunction(this.closureIndex);

  @override
  ConstantTag get tag => ConstantTag.kClosureFunction;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedUInt30(closureIndex);
  }

  ConstantClosureFunction.read(BufferedReader reader)
      : closureIndex = reader.readPackedUInt30();

  @override
  String toString() {
    return 'ClosureFunction $closureIndex';
  }

  @override
  int get hashCode => closureIndex;

  @override
  bool operator ==(other) =>
      other is ConstantClosureFunction &&
      this.closureIndex == other.closureIndex;
}

class ConstantEndClosureFunctionScope extends ConstantPoolEntry {
  ConstantEndClosureFunctionScope();

  @override
  ConstantTag get tag => ConstantTag.kEndClosureFunctionScope;

  @override
  void writeValue(BufferedWriter writer) {}

  ConstantEndClosureFunctionScope.read(BufferedReader reader) {}

  @override
  String toString() => 'EndClosureFunctionScope';

  // ConstantEndClosureFunctionScope entries are created per closure and should
  // not be merged, so ConstantEndClosureFunctionScope class uses identity
  // [hashCode] and [operator ==].
}

class ConstantNativeEntry extends ConstantPoolEntry {
  final String nativeName;

  ConstantNativeEntry(this.nativeName);

  @override
  ConstantTag get tag => ConstantTag.kNativeEntry;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedStringReference(nativeName);
  }

  ConstantNativeEntry.read(BufferedReader reader)
      : nativeName = reader.readPackedStringReference();

  @override
  String toString() => 'NativeEntry $nativeName';

  @override
  int get hashCode => nativeName.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantNativeEntry && this.nativeName == other.nativeName;
}

class ConstantSubtypeTestCache extends ConstantPoolEntry {
  ConstantSubtypeTestCache();

  @override
  ConstantTag get tag => ConstantTag.kSubtypeTestCache;

  @override
  void writeValue(BufferedWriter writer) {}

  ConstantSubtypeTestCache.read(BufferedReader reader);

  @override
  String toString() => 'SubtypeTestCache';

  // ConstantSubtypeTestCache entries are created per subtype test site and
  // should not be merged, so ConstantSubtypeTestCache class uses identity
  // [hashCode] and [operator ==].

  @override
  int get hashCode => identityHashCode(this);

  @override
  bool operator ==(other) => identical(this, other);
}

class ConstantPartialTearOffInstantiation extends ConstantPoolEntry {
  final int tearOffConstantIndex;
  final int typeArgumentsConstantIndex;

  ConstantPartialTearOffInstantiation(
      this.tearOffConstantIndex, this.typeArgumentsConstantIndex);

  @override
  ConstantTag get tag => ConstantTag.kPartialTearOffInstantiation;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedUInt30(tearOffConstantIndex);
    writer.writePackedUInt30(typeArgumentsConstantIndex);
  }

  ConstantPartialTearOffInstantiation.read(BufferedReader reader)
      : tearOffConstantIndex = reader.readPackedUInt30(),
        typeArgumentsConstantIndex = reader.readPackedUInt30();

  @override
  String toString() {
    return 'PartialTearOffInstantiation tear-off CP#$tearOffConstantIndex type-args CP#$typeArgumentsConstantIndex';
  }

  @override
  int get hashCode =>
      _combineHashes(tearOffConstantIndex, typeArgumentsConstantIndex);

  @override
  bool operator ==(other) =>
      other is ConstantPartialTearOffInstantiation &&
      this.tearOffConstantIndex == other.tearOffConstantIndex &&
      this.typeArgumentsConstantIndex == other.typeArgumentsConstantIndex;
}

class ConstantEmptyTypeArguments extends ConstantPoolEntry {
  const ConstantEmptyTypeArguments();

  @override
  ConstantTag get tag => ConstantTag.kEmptyTypeArguments;

  @override
  void writeValue(BufferedWriter writer) {}

  ConstantEmptyTypeArguments.read(BufferedReader reader);

  @override
  String toString() => 'EmptyTypeArguments';

  @override
  int get hashCode => 997;

  @override
  bool operator ==(other) => other is ConstantEmptyTypeArguments;
}

class ConstantSymbol extends ConstantPoolEntry {
  final ObjectHandle name;

  ConstantSymbol(this.name);

  @override
  ConstantTag get tag => ConstantTag.kSymbol;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(name);
  }

  ConstantSymbol.read(BufferedReader reader) : name = reader.readPackedObject();

  @override
  String toString() => 'Symbol $name';

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(other) => other is ConstantSymbol && this.name == other.name;
}

class ConstantInterfaceCallV1 extends ConstantPoolEntry {
  final InvocationKind invocationKind;
  final ObjectHandle targetName;
  final int argDescConstantIndex;

  ConstantInterfaceCallV1(
      this.invocationKind, this.targetName, this.argDescConstantIndex);

  // Reserve 1 extra slot for arguments descriptor, following target name slot.
  int get numReservedEntries => 1;

  @override
  ConstantTag get tag => ConstantTag.kInterfaceCallV1;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writeByte(invocationKind.index);
    writer.writePackedObject(targetName);
    writer.writePackedUInt30(argDescConstantIndex);
  }

  ConstantInterfaceCallV1.read(BufferedReader reader)
      : invocationKind = InvocationKind.values[reader.readByte()],
        targetName = reader.readPackedObject(),
        argDescConstantIndex = reader.readPackedUInt30();

  @override
  String toString() => 'InterfaceCallV1 '
      '${_invocationKindToString(invocationKind)}'
      'target-name $targetName, arg-desc CP#$argDescConstantIndex';

  @override
  int get hashCode => _combineHashes(
      _combineHashes(invocationKind.index, targetName.hashCode),
      argDescConstantIndex);

  @override
  bool operator ==(other) =>
      other is ConstantInterfaceCallV1 &&
      this.invocationKind == other.invocationKind &&
      this.targetName == other.targetName &&
      this.argDescConstantIndex == other.argDescConstantIndex;
}

class ConstantObjectRef extends ConstantPoolEntry {
  final ObjectHandle object;

  ConstantObjectRef(this.object);

  @override
  ConstantTag get tag => ConstantTag.kObjectRef;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(object);
  }

  ConstantObjectRef.read(BufferedReader reader)
      : object = reader.readPackedObject();

  @override
  String toString() => 'ObjectRef $object';

  @override
  int get hashCode => object.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantObjectRef && this.object == other.object;
}

class ConstantDirectCall extends ConstantPoolEntry {
  final ObjectHandle target;
  final ObjectHandle argDesc;

  ConstantDirectCall(this.target, this.argDesc);

  // Reserve 1 extra slot for arguments descriptor, following target slot.
  int get numReservedEntries => 1;

  @override
  ConstantTag get tag => ConstantTag.kDirectCall;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(target);
    writer.writePackedObject(argDesc);
  }

  ConstantDirectCall.read(BufferedReader reader)
      : target = reader.readPackedObject(),
        argDesc = reader.readPackedObject();

  @override
  String toString() => "DirectCall '$target', $argDesc";

  @override
  int get hashCode => _combineHashes(target.hashCode, argDesc.hashCode);

  @override
  bool operator ==(other) =>
      other is ConstantDirectCall &&
      this.target == other.target &&
      this.argDesc == other.argDesc;
}

class ConstantInterfaceCall extends ConstantPoolEntry {
  final ObjectHandle target;
  final ObjectHandle argDesc;

  ConstantInterfaceCall(this.target, this.argDesc);

  // Reserve 1 extra slot for arguments descriptor, following target slot.
  int get numReservedEntries => 1;

  @override
  ConstantTag get tag => ConstantTag.kInterfaceCall;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(target);
    writer.writePackedObject(argDesc);
  }

  ConstantInterfaceCall.read(BufferedReader reader)
      : target = reader.readPackedObject(),
        argDesc = reader.readPackedObject();

  @override
  String toString() => "InterfaceCall '$target', $argDesc";

  @override
  int get hashCode => _combineHashes(target.hashCode, argDesc.hashCode);

  @override
  bool operator ==(other) =>
      other is ConstantInterfaceCall &&
      this.target == other.target &&
      this.argDesc == other.argDesc;
}

/// Reserved constant pool entry.
class _ReservedConstantPoolEntry extends ConstantPoolEntry {
  const _ReservedConstantPoolEntry();

  ConstantTag get tag => throw 'This constant pool entry is reserved';
  void writeValue(BufferedWriter writer) =>
      throw 'This constant pool entry is reserved';

  @override
  String toString() => 'Reserved';
}

class ConstantPool {
  final StringTable stringTable;
  final ObjectTable objectTable;
  final List<ConstantPoolEntry> entries = <ConstantPoolEntry>[];
  final Map<ConstantPoolEntry, int> _canonicalizationCache =
      <ConstantPoolEntry, int>{};

  ConstantPool(this.stringTable, this.objectTable);

  int addString(String value) => addObjectRef(new StringConstant(value));

  int addArgDesc(int numArguments,
          {int numTypeArgs = 0, List<String> argNames = const <String>[]}) =>
      _add(new ConstantObjectRef(
          objectTable.getArgDescHandle(numArguments, numTypeArgs, argNames)));

  int addArgDescByArguments(Arguments args,
          {bool hasReceiver: false, bool isFactory: false}) =>
      _add(new ConstantObjectRef(objectTable.getArgDescHandleByArguments(args,
          hasReceiver: hasReceiver, isFactory: isFactory)));

  int addICData(
          InvocationKind invocationKind, Name targetName, int argDescCpIndex,
          {bool isDynamic: false}) =>
      _add(new ConstantICData(
          invocationKind,
          objectTable.getSelectorNameHandle(targetName,
              isGetter: invocationKind == InvocationKind.getter,
              isSetter: invocationKind == InvocationKind.setter),
          argDescCpIndex,
          isDynamic));

  int addDirectCall(
          InvocationKind invocationKind, Member target, ObjectHandle argDesc) =>
      _add(new ConstantDirectCall(
          objectTable.getMemberHandle(target,
              isGetter: invocationKind == InvocationKind.getter,
              isSetter: invocationKind == InvocationKind.setter),
          argDesc));

  int addInterfaceCall(
          InvocationKind invocationKind, Member target, ObjectHandle argDesc) =>
      _add(new ConstantInterfaceCall(
          objectTable.getMemberHandle(target,
              isGetter: invocationKind == InvocationKind.getter,
              isSetter: invocationKind == InvocationKind.setter),
          argDesc));

  int addInstanceCall(InvocationKind invocationKind, Member target,
          Name targetName, ObjectHandle argDesc) =>
      (target == null)
          ? addICData(
              invocationKind, targetName, _add(new ConstantObjectRef(argDesc)),
              isDynamic: true)
          : addInterfaceCall(invocationKind, target, argDesc);

  int addStaticField(Field field) =>
      _add(new ConstantStaticField(objectTable.getHandle(field)));

  int addInstanceField(Field field) =>
      _add(new ConstantInstanceField(objectTable.getHandle(field)));

  int addClass(Class node) =>
      _add(new ConstantClass(objectTable.getHandle(node)));

  int addTypeArgumentsField(Class node) =>
      _add(new ConstantTypeArgumentsField(objectTable.getHandle(node)));

  int addType(DartType type) =>
      _add(new ConstantType(objectTable.getHandle(type)));

  int addTypeArguments(List<DartType> typeArgs) =>
      _add(new ConstantObjectRef(objectTable.getTypeArgumentsHandle(typeArgs)));

  int addClosureFunction(int closureIndex) =>
      _add(new ConstantClosureFunction(closureIndex));

  int addEndClosureFunctionScope() =>
      _add(new ConstantEndClosureFunctionScope());

  int addNativeEntry(String nativeName) =>
      _add(new ConstantNativeEntry(_indexString(nativeName)));

  int addSubtypeTestCache() => _add(new ConstantSubtypeTestCache());

  int addEmptyTypeArguments() => _add(const ConstantEmptyTypeArguments());

  int addObjectRef(Node node) =>
      _add(new ConstantObjectRef(objectTable.getHandle(node)));

  int _add(ConstantPoolEntry entry) {
    return _canonicalizationCache.putIfAbsent(entry, () {
      int index = entries.length;
      if (index >= constantPoolIndexLimit) {
        throw new ConstantPoolIndexOverflowException();
      }
      _addEntry(entry);
      return index;
    });
  }

  void _addEntry(ConstantPoolEntry entry) {
    entries.add(entry);
    for (int i = 0; i < entry.numReservedEntries; ++i) {
      entries.add(const _ReservedConstantPoolEntry());
    }
  }

  // Currently, string table is written as a part of Component's metadata
  // *before* constant pools are written.
  // So we need to index all strings when filling up constant pools.
  String _indexString(String str) {
    stringTable.put(str);
    return str;
  }

  void write(BufferedWriter writer) {
    final start = writer.offset;
    if (BytecodeSizeStatistics.constantPoolStats.isEmpty) {
      for (var tag in ConstantTag.values) {
        BytecodeSizeStatistics.constantPoolStats
            .add(new NamedEntryStatistics(constantTagToString(tag)));
      }
    }
    writer.writePackedUInt30(entries.length);
    entries.forEach((e) {
      if (e is _ReservedConstantPoolEntry) {
        return;
      }

      final entryStart = writer.offset;

      e.write(writer);

      final entryStat = BytecodeSizeStatistics.constantPoolStats[e.tag.index];
      entryStat.size += (writer.offset - entryStart);
      ++entryStat.count;
    });
    BytecodeSizeStatistics.constantPoolSize += (writer.offset - start);
  }

  ConstantPool.read(BufferedReader reader)
      : stringTable = reader.stringReader,
        objectTable = reader.objectReader {
    int len = reader.readPackedUInt30();
    for (int i = 0; i < len; i++) {
      final e = new ConstantPoolEntry.read(reader);
      _addEntry(e);
      i += e.numReservedEntries;
    }
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln('ConstantPool {');
    for (int i = 0; i < entries.length; i++) {
      sb.writeln('  [$i] = ${entries[i]}');
    }
    sb.writeln('}');
    return sb.toString();
  }
}

int _combineHashes(int hash1, int hash2) =>
    (((hash1 * 31) & 0x3fffffff) + hash2) & 0x3fffffff;

class ConstantPoolIndexOverflowException
    extends BytecodeLimitExceededException {}
