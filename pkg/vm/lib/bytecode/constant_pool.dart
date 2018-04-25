// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.constant_pool;

import 'dart:typed_data';

import 'package:kernel/ast.dart' hide MapEntry;

/*

In kernel binary, constant pool is encoded in the following way
(using notation from pkg/kernel/binary.md):

type ConstantPool {
  List<ConstantPoolEntry>
}

abstract type ConstantPoolEntry {
  Byte tag;
}

type ConstantNull extends ConstantPoolEntry {
  Byte tag = 1;
}

type ConstantString extends ConstantPoolEntry {
  Byte tag = 2;
  StringReference value;
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
  UInt flag;
}

type ConstantArgDesc extends ConstantPoolEntry {
  Byte tag = 6;
  UInt numArguments;
  UInt numTypeArgs;
  List<StringReference> names;
}

type ConstantICData extends ConstantPoolEntry {
  Byte tag = 7;
  StringReference targetName;
  UInt argDescConstantIndex;
}

type ConstantStaticICData extends ConstantPoolEntry {
  Byte tag = 8;
  CanonicalNameReference target;
  UInt argDescConstantIndex;
}

type ConstantField extends ConstantPoolEntry {
  Byte tag = 9;
  CanonicalNameReference field;
}

type ConstantFieldOffset extends ConstantPoolEntry {
  Byte tag = 10;
  CanonicalNameReference field;
}

type ConstantClass extends ConstantPoolEntry {
  Byte tag = 11;
  CanonicalNameReference class;
}

type ConstantTypeArgumentsFieldOffset extends ConstantPoolEntry {
  Byte tag = 12;
  CanonicalNameReference class;
}

type ConstantTearOff extends ConstantPoolEntry {
  Byte tag = 13;
  CanonicalNameReference target;
}

type ConstantType extends ConstantPoolEntry {
  Byte tag = 14;
  NodeReference type;
}

type ConstantTypeArguments extends ConstantPoolEntry {
  Byte tag = 15;
  List<NodeReference> types;
}

type ConstantList extends ConstantPoolEntry {
  Byte tag = 16;
  NodeReference typeArg;
  List<UInt> entries;
}

type ConstantInstance extends ConstantPoolEntry {
  Byte tag = 17;
  CanonicalNameReference class;
  UInt typeArgumentsConstantIndex;
  List<Pair<CanonicalNameReference, UInt>> fieldValues;
}

type ConstantSymbol extends ConstantPoolEntry {
  Byte tag = 18;
  StringReference value;
}

*/

enum ConstantTag {
  kInvalid,
  kNull,
  kString,
  kInt,
  kDouble,
  kBool,
  kArgDesc,
  kICData,
  kStaticICData,
  kField,
  kFieldOffset,
  kClass,
  kTypeArgumentsFieldOffset,
  kTearOff,
  kType,
  kTypeArguments,
  kList,
  kInstance,
  kSymbol,
}

abstract class ConstantPoolEntry {
  const ConstantPoolEntry();

  ConstantTag get tag;

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(tag.index);
    writeValueToBinary(sink);
  }

  void writeValueToBinary(BinarySink sink);

  factory ConstantPoolEntry.readFromBinary(BinarySource source) {
    ConstantTag tag = ConstantTag.values[source.readUInt()];
    switch (tag) {
      case ConstantTag.kInvalid:
        break;
      case ConstantTag.kNull:
        return new ConstantNull.readFromBinary(source);
      case ConstantTag.kString:
        return new ConstantString.readFromBinary(source);
      case ConstantTag.kInt:
        return new ConstantInt.readFromBinary(source);
      case ConstantTag.kDouble:
        return new ConstantDouble.readFromBinary(source);
      case ConstantTag.kBool:
        return new ConstantBool.readFromBinary(source);
      case ConstantTag.kICData:
        return new ConstantICData.readFromBinary(source);
      case ConstantTag.kStaticICData:
        return new ConstantStaticICData.readFromBinary(source);
      case ConstantTag.kArgDesc:
        return new ConstantArgDesc.readFromBinary(source);
      case ConstantTag.kField:
        return new ConstantField.readFromBinary(source);
      case ConstantTag.kFieldOffset:
        return new ConstantFieldOffset.readFromBinary(source);
      case ConstantTag.kClass:
        return new ConstantClass.readFromBinary(source);
      case ConstantTag.kTypeArgumentsFieldOffset:
        return new ConstantTypeArgumentsFieldOffset.readFromBinary(source);
      case ConstantTag.kTearOff:
        return new ConstantTearOff.readFromBinary(source);
      case ConstantTag.kType:
        return new ConstantType.readFromBinary(source);
      case ConstantTag.kTypeArguments:
        return new ConstantTypeArguments.readFromBinary(source);
      case ConstantTag.kList:
        return new ConstantList.readFromBinary(source);
      case ConstantTag.kInstance:
        return new ConstantInstance.readFromBinary(source);
      case ConstantTag.kSymbol:
        return new ConstantSymbol.readFromBinary(source);
    }
    throw 'Unexpected constant tag $tag';
  }
}

class ConstantNull extends ConstantPoolEntry {
  const ConstantNull();

  @override
  ConstantTag get tag => ConstantTag.kNull;

  @override
  void writeValueToBinary(BinarySink sink) {}

  ConstantNull.readFromBinary(BinarySource source);

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
  void writeValueToBinary(BinarySink sink) {
    sink.writeStringReference(value);
  }

  ConstantString.readFromBinary(BinarySource source)
      : value = source.readStringReference();

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
  ConstantInt.fromLiteral(IntLiteral literal) : this(literal.value);

  @override
  ConstantTag get tag => ConstantTag.kInt;

  @override
  void writeValueToBinary(BinarySink sink) {
    // TODO(alexmarkov): more efficient encoding
    sink.writeUInt32(value & 0xffffffff);
    sink.writeUInt32((value >> 32) & 0xffffffff);
  }

  ConstantInt.readFromBinary(BinarySource source)
      : value = source.readUint32() | (source.readUint32() << 32);

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
  ConstantDouble.fromLiteral(DoubleLiteral literal) : this(literal.value);

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
  void writeValueToBinary(BinarySink sink) {
    // TODO(alexmarkov): more efficient encoding
    int bits = doubleToIntBits(value);
    sink.writeUInt32(bits & 0xffffffff);
    sink.writeUInt32((bits >> 32) & 0xffffffff);
  }

  ConstantDouble.readFromBinary(BinarySource source)
      : value =
            intBitsToDouble(source.readUint32() | (source.readUint32() << 32));

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
  void writeValueToBinary(BinarySink sink) {
    sink.writeUInt30(value ? 1 : 0);
  }

  ConstantBool.readFromBinary(BinarySource source)
      : value = source.readUInt() != 0;

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

  ConstantArgDesc(this.numArguments,
      {this.numTypeArgs = 0, this.argNames = const <String>[]});

  ConstantArgDesc.fromArguments(Arguments args, {bool hasReceiver: false})
      : this(args.positional.length + args.named.length + (hasReceiver ? 1 : 0),
            numTypeArgs: args.types.length,
            argNames: new List<String>.from(args.named.map((ne) => ne.name)));

  @override
  ConstantTag get tag => ConstantTag.kArgDesc;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeUInt30(numArguments);
    sink.writeUInt30(numTypeArgs);
    sink.writeUInt30(argNames.length);
    argNames.forEach(sink.writeStringReference);
  }

  ConstantArgDesc.readFromBinary(BinarySource source)
      : numArguments = source.readUInt(),
        numTypeArgs = source.readUInt(),
        argNames = new List<String>.generate(
            source.readUInt(), (_) => source.readStringReference());

  @override
  String toString() =>
      'ArgDesc num-args $numArguments, num-type-args $numTypeArgs, names $argNames';

  @override
  int get hashCode =>
      (numArguments * 31 + numTypeArgs) * 31 + listHashCode(argNames);

  @override
  bool operator ==(other) =>
      other is ConstantArgDesc &&
      this.numArguments == other.numArguments &&
      this.numTypeArgs == other.numTypeArgs &&
      listEquals(this.argNames, other.argNames);
}

class ConstantICData extends ConstantPoolEntry {
  final String targetName;
  final int argDescConstantIndex;

  ConstantICData(this.targetName, this.argDescConstantIndex);

  @override
  ConstantTag get tag => ConstantTag.kICData;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeStringReference(targetName);
    sink.writeUInt30(argDescConstantIndex);
  }

  ConstantICData.readFromBinary(BinarySource source)
      : targetName = source.readStringReference(),
        argDescConstantIndex = source.readUInt();

  @override
  String toString() =>
      'ICData target-name \'$targetName\', arg-desc CP#$argDescConstantIndex';

  // ConstantICData entries are created per call site and should not be merged,
  // so ConstantICData class uses identity [hashCode] and [operator ==].

  @override
  int get hashCode => identityHashCode(this);

  @override
  bool operator ==(other) => identical(this, other);
}

class ConstantStaticICData extends ConstantPoolEntry {
  final Reference _reference;
  final int argDescConstantIndex;

  ConstantStaticICData(Member member, int argDescConstantIndex)
      : this.byReference(member.reference, argDescConstantIndex);
  ConstantStaticICData.byReference(this._reference, this.argDescConstantIndex);

  Member get target => _reference.asMember;

  @override
  ConstantTag get tag => ConstantTag.kStaticICData;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeCanonicalNameReference(getCanonicalNameOfMember(target));
    sink.writeUInt30(argDescConstantIndex);
  }

  ConstantStaticICData.readFromBinary(BinarySource source)
      : _reference = source.readCanonicalNameReference().getReference(),
        argDescConstantIndex = source.readUInt();

  @override
  String toString() =>
      'StaticICData target \'$target\', arg-desc CP#$argDescConstantIndex';

  // ConstantStaticICData entries are created per call site and should not be
  // merged, so ConstantStaticICData class uses identity [hashCode] and
  // [operator ==].

  @override
  int get hashCode => identityHashCode(this);

  @override
  bool operator ==(other) => identical(this, other);
}

class ConstantField extends ConstantPoolEntry {
  final Reference _reference;

  Field get field => _reference.asField;

  ConstantField(Field field) : this.byReference(field.reference);
  ConstantField.byReference(this._reference);

  @override
  ConstantTag get tag => ConstantTag.kField;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeCanonicalNameReference(getCanonicalNameOfMember(field));
  }

  ConstantField.readFromBinary(BinarySource source)
      : _reference = source.readCanonicalNameReference().getReference();

  @override
  String toString() => 'Field $field';

  @override
  int get hashCode => field.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantField && this.field == other.field;
}

class ConstantFieldOffset extends ConstantPoolEntry {
  final Reference _reference;

  Field get field => _reference.asField;

  ConstantFieldOffset(Field field) : this.byReference(field.reference);
  ConstantFieldOffset.byReference(this._reference);

  @override
  ConstantTag get tag => ConstantTag.kFieldOffset;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeCanonicalNameReference(getCanonicalNameOfMember(field));
  }

  ConstantFieldOffset.readFromBinary(BinarySource source)
      : _reference = source.readCanonicalNameReference().getReference();

  @override
  String toString() => 'FieldOffset $field';

  @override
  int get hashCode => field.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantFieldOffset && this.field == other.field;
}

class ConstantClass extends ConstantPoolEntry {
  final Reference _reference;

  Class get classNode => _reference.asClass;

  ConstantClass(Class class_) : this.byReference(class_.reference);
  ConstantClass.byReference(this._reference);

  @override
  ConstantTag get tag => ConstantTag.kClass;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeCanonicalNameReference(getCanonicalNameOfClass(classNode));
  }

  ConstantClass.readFromBinary(BinarySource source)
      : _reference = source.readCanonicalNameReference().getReference();

  @override
  String toString() => 'Class $classNode';

  @override
  int get hashCode => classNode.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantClass && this.classNode == other.classNode;
}

class ConstantTypeArgumentsFieldOffset extends ConstantPoolEntry {
  final Reference _reference;

  Class get classNode => _reference.asClass;

  ConstantTypeArgumentsFieldOffset(Class class_)
      : this.byReference(class_.reference);
  ConstantTypeArgumentsFieldOffset.byReference(this._reference);

  @override
  ConstantTag get tag => ConstantTag.kTypeArgumentsFieldOffset;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeCanonicalNameReference(getCanonicalNameOfClass(classNode));
  }

  ConstantTypeArgumentsFieldOffset.readFromBinary(BinarySource source)
      : _reference = source.readCanonicalNameReference().getReference();

  @override
  String toString() => 'TypeArgumentsFieldOffset $classNode';

  @override
  int get hashCode => classNode.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantTypeArgumentsFieldOffset &&
      this.classNode == other.classNode;
}

class ConstantTearOff extends ConstantPoolEntry {
  final Reference _reference;

  Procedure get procedure => _reference.asProcedure;

  ConstantTearOff(Procedure procedure) : this.byReference(procedure.reference);
  ConstantTearOff.byReference(this._reference);

  @override
  ConstantTag get tag => ConstantTag.kTearOff;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeCanonicalNameReference(getCanonicalNameOfMember(procedure));
  }

  ConstantTearOff.readFromBinary(BinarySource source)
      : _reference = source.readCanonicalNameReference().getReference();

  @override
  String toString() => 'TearOff $procedure';

  @override
  int get hashCode => procedure.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantTearOff && this.procedure == other.procedure;
}

class ConstantType extends ConstantPoolEntry {
  final DartType type;

  ConstantType(this.type);

  @override
  ConstantTag get tag => ConstantTag.kType;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeNodeReference(type);
  }

  ConstantType.readFromBinary(BinarySource source)
      : type = source.readNodeReference() as DartType;

  @override
  String toString() => 'Type $type';

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(other) => other is ConstantType && this.type == other.type;
}

class ConstantTypeArguments extends ConstantPoolEntry {
  final List<DartType> typeArgs;

  ConstantTypeArguments(this.typeArgs);

  @override
  ConstantTag get tag => ConstantTag.kTypeArguments;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeUInt30(typeArgs.length);
    typeArgs.forEach(sink.writeNodeReference);
  }

  ConstantTypeArguments.readFromBinary(BinarySource source)
      : typeArgs = new List<DartType>.generate(
            source.readUInt(), (_) => source.readNodeReference() as DartType);

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
  final DartType typeArg;
  final List<int> entries;

  ConstantList(this.typeArg, this.entries);

  @override
  ConstantTag get tag => ConstantTag.kList;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeNodeReference(typeArg);
    sink.writeUInt30(entries.length);
    entries.forEach(sink.writeUInt30);
  }

  ConstantList.readFromBinary(BinarySource source)
      : typeArg = source.readNodeReference() as DartType,
        entries =
            new List<int>.generate(source.readUInt(), (_) => source.readUInt());

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
  final Reference _classReference;
  final int _typeArgumentsConstantIndex;
  final Map<Reference, int> _fieldValues;

  ConstantInstance(Class class_, int typeArgumentsConstantIndex,
      Map<Reference, int> fieldValues)
      : this.byReference(
            class_.reference, typeArgumentsConstantIndex, fieldValues);

  ConstantInstance.byReference(this._classReference,
      this._typeArgumentsConstantIndex, this._fieldValues);

  @override
  ConstantTag get tag => ConstantTag.kInstance;

  Class get classNode => _classReference.asClass;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeCanonicalNameReference(getCanonicalNameOfClass(classNode));
    sink.writeUInt30(_typeArgumentsConstantIndex);
    sink.writeUInt30(_fieldValues.length);
    _fieldValues.forEach((Reference fieldRef, int valueIndex) {
      sink.writeCanonicalNameReference(
          getCanonicalNameOfMember(fieldRef.asField));
      sink.writeUInt30(valueIndex);
    });
  }

  ConstantInstance.readFromBinary(BinarySource source)
      : _classReference = source.readCanonicalNameReference().getReference(),
        _typeArgumentsConstantIndex = source.readUInt(),
        _fieldValues = new Map<Reference, int>() {
    final fieldValuesLen = source.readUInt();
    for (int i = 0; i < fieldValuesLen; i++) {
      final fieldRef = source.readCanonicalNameReference().getReference();
      final valueIndex = source.readUInt();
      _fieldValues[fieldRef] = valueIndex;
    }
  }

  @override
  String toString() =>
      'Instance $classNode type-args CP#$_typeArgumentsConstantIndex'
      ' ${_fieldValues.map<String, int>((Reference fieldRef, int valueIndex) =>
              new MapEntry(fieldRef.asField.name.name, valueIndex))}';

  @override
  int get hashCode =>
      (classNode.hashCode * 31 + _typeArgumentsConstantIndex) * 31 +
      mapHashCode(_fieldValues);

  @override
  bool operator ==(other) =>
      other is ConstantInstance &&
      this.classNode == other.classNode &&
      this._typeArgumentsConstantIndex == other._typeArgumentsConstantIndex &&
      mapEquals(this._fieldValues, other._fieldValues);
}

class ConstantSymbol extends ConstantPoolEntry {
  final String value;

  ConstantSymbol(this.value);
  ConstantSymbol.fromLiteral(SymbolLiteral literal) : this(literal.value);

  @override
  ConstantTag get tag => ConstantTag.kSymbol;

  @override
  void writeValueToBinary(BinarySink sink) {
    sink.writeStringReference(value);
  }

  ConstantSymbol.readFromBinary(BinarySource source)
      : value = source.readStringReference();

  @override
  String toString() => 'Symbol \'$value\'';

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(other) =>
      other is ConstantSymbol && this.value == other.value;
}

class ConstantPool {
  final List<ConstantPoolEntry> entries = <ConstantPoolEntry>[];
  final Map<ConstantPoolEntry, int> _canonicalizationCache =
      <ConstantPoolEntry, int>{};

  ConstantPool();

  int add(ConstantPoolEntry entry) {
    return _canonicalizationCache.putIfAbsent(entry, () {
      int index = entries.length;
      entries.add(entry);
      return index;
    });
  }

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(entries.length);
    entries.forEach((e) {
      e.writeToBinary(sink);
    });
  }

  ConstantPool.readFromBinary(BinarySource source) {
    int len = source.readUInt();
    for (int i = 0; i < len; i++) {
      entries.add(new ConstantPoolEntry.readFromBinary(source));
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
