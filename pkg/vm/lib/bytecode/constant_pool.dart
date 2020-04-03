// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.constant_pool;

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

type ConstantType extends ConstantPoolEntry {
  Byte tag = 14;
  PackedObject type;
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

type ConstantEmptyTypeArguments extends ConstantPoolEntry {
  Byte tag = 24;
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

// Occupies 3 entries in the constant pool.
type ConstantInstantiatedInterfaceCall extends ConstantPoolEntry {
  Byte tag = 30;
  PackedObject target;
  PackedObject argDesc;
  PackedObject staticReceiverType;
}

// Occupies 2 entries in the constant pool
type ConstantDynamicCall extends ConstantPoolEntry {
  Byte tag = 31;
  PackedObject selectorName;
  PackedObject argDesc;
}

// Occupies 2 entries in the constant pool.
type ConstantDirectCallViaDynamicForwarder extends ConstantPoolEntry {
  Byte tag = 32;
  PackedObject target;
  PackedObject argDesc;
}

*/

enum ConstantTag {
  kInvalid,
  kUnused1,
  kUnused2,
  kUnused3,
  kUnused4,
  kUnused5,
  kUnused6,
  kUnused6a,
  kUnused7,
  kStaticField,
  kInstanceField,
  kClass,
  kTypeArgumentsField,
  kUnused8,
  kType,
  kUnused9,
  kUnused10,
  kUnused11,
  kUnused12,
  kClosureFunction,
  kEndClosureFunctionScope,
  kNativeEntry,
  kSubtypeTestCache,
  kUnused13,
  kEmptyTypeArguments,
  kUnused14,
  kUnused15,
  kObjectRef,
  kDirectCall,
  kInterfaceCall,
  kInstantiatedInterfaceCall,
  kDynamicCall,
  kDirectCallViaDynamicForwarder,
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
      case ConstantTag.kStaticField:
        return new ConstantStaticField.read(reader);
      case ConstantTag.kInstanceField:
        return new ConstantInstanceField.read(reader);
      case ConstantTag.kClass:
        return new ConstantClass.read(reader);
      case ConstantTag.kTypeArgumentsField:
        return new ConstantTypeArgumentsField.read(reader);
      case ConstantTag.kType:
        return new ConstantType.read(reader);
      case ConstantTag.kClosureFunction:
        return new ConstantClosureFunction.read(reader);
      case ConstantTag.kEndClosureFunctionScope:
        return new ConstantEndClosureFunctionScope.read(reader);
      case ConstantTag.kNativeEntry:
        return new ConstantNativeEntry.read(reader);
      case ConstantTag.kSubtypeTestCache:
        return new ConstantSubtypeTestCache.read(reader);
      case ConstantTag.kEmptyTypeArguments:
        return new ConstantEmptyTypeArguments.read(reader);
      case ConstantTag.kObjectRef:
        return new ConstantObjectRef.read(reader);
      case ConstantTag.kDirectCall:
        return new ConstantDirectCall.read(reader);
      case ConstantTag.kInterfaceCall:
        return new ConstantInterfaceCall.read(reader);
      case ConstantTag.kInstantiatedInterfaceCall:
        return new ConstantInstantiatedInterfaceCall.read(reader);
      case ConstantTag.kDynamicCall:
        return new ConstantDynamicCall.read(reader);
      case ConstantTag.kDirectCallViaDynamicForwarder:
        return new ConstantDirectCallViaDynamicForwarder.read(reader);
      // Make analyzer happy.
      case ConstantTag.kUnused1:
      case ConstantTag.kUnused2:
      case ConstantTag.kUnused3:
      case ConstantTag.kUnused4:
      case ConstantTag.kUnused5:
      case ConstantTag.kUnused6:
      case ConstantTag.kUnused6a:
      case ConstantTag.kUnused7:
      case ConstantTag.kUnused8:
      case ConstantTag.kUnused9:
      case ConstantTag.kUnused10:
      case ConstantTag.kUnused11:
      case ConstantTag.kUnused12:
      case ConstantTag.kUnused13:
      case ConstantTag.kUnused14:
      case ConstantTag.kUnused15:
        break;
    }
    throw 'Unexpected constant tag $tag';
  }
}

enum InvocationKind {
  method, // x.foo(...) or foo(...)
  getter, // x.foo
  setter // x.foo = ...
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

class ConstantDirectCallViaDynamicForwarder extends ConstantPoolEntry {
  final ObjectHandle target;
  final ObjectHandle argDesc;

  ConstantDirectCallViaDynamicForwarder(this.target, this.argDesc);

  // Reserve 1 extra slot for arguments descriptor, following target slot.
  int get numReservedEntries => 1;

  @override
  ConstantTag get tag => ConstantTag.kDirectCallViaDynamicForwarder;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(target);
    writer.writePackedObject(argDesc);
  }

  ConstantDirectCallViaDynamicForwarder.read(BufferedReader reader)
      : target = reader.readPackedObject(),
        argDesc = reader.readPackedObject();

  @override
  String toString() => "DirectCallViaDynamicForwarder '$target', $argDesc";

  @override
  int get hashCode => _combineHashes(target.hashCode, argDesc.hashCode);

  @override
  bool operator ==(other) =>
      other is ConstantDirectCallViaDynamicForwarder &&
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

class ConstantInstantiatedInterfaceCall extends ConstantPoolEntry {
  final ObjectHandle target;
  final ObjectHandle argDesc;
  final ObjectHandle staticReceiverType;

  ConstantInstantiatedInterfaceCall(
      this.target, this.argDesc, this.staticReceiverType);

  // Reserve 2 extra slots (3 slots total).
  int get numReservedEntries => 2;

  @override
  ConstantTag get tag => ConstantTag.kInstantiatedInterfaceCall;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(target);
    writer.writePackedObject(argDesc);
    writer.writePackedObject(staticReceiverType);
  }

  ConstantInstantiatedInterfaceCall.read(BufferedReader reader)
      : target = reader.readPackedObject(),
        argDesc = reader.readPackedObject(),
        staticReceiverType = reader.readPackedObject();

  @override
  String toString() =>
      "InstantiatedInterfaceCall '$target', $argDesc, receiver $staticReceiverType";

  @override
  int get hashCode => _combineHashes(
      _combineHashes(target.hashCode, argDesc.hashCode),
      staticReceiverType.hashCode);

  @override
  bool operator ==(other) =>
      other is ConstantInstantiatedInterfaceCall &&
      this.target == other.target &&
      this.argDesc == other.argDesc &&
      this.staticReceiverType == other.staticReceiverType;
}

class ConstantDynamicCall extends ConstantPoolEntry {
  final ObjectHandle selectorName;
  final ObjectHandle argDesc;

  ConstantDynamicCall(this.selectorName, this.argDesc);

  // Reserve 1 extra slot for arguments descriptor, following selector slot.
  int get numReservedEntries => 1;

  @override
  ConstantTag get tag => ConstantTag.kDynamicCall;

  @override
  void writeValue(BufferedWriter writer) {
    writer.writePackedObject(selectorName);
    writer.writePackedObject(argDesc);
  }

  ConstantDynamicCall.read(BufferedReader reader)
      : selectorName = reader.readPackedObject(),
        argDesc = reader.readPackedObject();

  @override
  String toString() => 'DynamicCall $selectorName, $argDesc';

  @override
  int get hashCode => _combineHashes(selectorName.hashCode, argDesc.hashCode);

  @override
  bool operator ==(other) =>
      other is ConstantDynamicCall &&
      this.selectorName == other.selectorName &&
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

  int addName(String name) =>
      _add(new ConstantObjectRef(objectTable.getPublicNameHandle(name)));

  int addArgDesc(int numArguments,
          {int numTypeArgs = 0, List<String> argNames = const <String>[]}) =>
      _add(new ConstantObjectRef(
          objectTable.getArgDescHandle(numArguments, numTypeArgs, argNames)));

  int addArgDescByArguments(Arguments args,
          {bool hasReceiver: false, bool isFactory: false}) =>
      _add(new ConstantObjectRef(objectTable.getArgDescHandleByArguments(args,
          hasReceiver: hasReceiver, isFactory: isFactory)));

  int addDirectCall(
      InvocationKind invocationKind, Member target, ObjectHandle argDesc,
      [bool isDynamicForwarder = false]) {
    final targetHandle = objectTable.getMemberHandle(target,
        isGetter: invocationKind == InvocationKind.getter,
        isSetter: invocationKind == InvocationKind.setter);
    return _add(isDynamicForwarder
        ? new ConstantDirectCallViaDynamicForwarder(targetHandle, argDesc)
        : new ConstantDirectCall(targetHandle, argDesc));
  }

  int addInterfaceCall(
          InvocationKind invocationKind, Member target, ObjectHandle argDesc) =>
      _add(new ConstantInterfaceCall(
          objectTable.getMemberHandle(target,
              isGetter: invocationKind == InvocationKind.getter,
              isSetter: invocationKind == InvocationKind.setter),
          argDesc));

  int addInstantiatedInterfaceCall(InvocationKind invocationKind, Member target,
          ObjectHandle argDesc, DartType staticReceiverType) =>
      _add(new ConstantInstantiatedInterfaceCall(
          objectTable.getMemberHandle(target,
              isGetter: invocationKind == InvocationKind.getter,
              isSetter: invocationKind == InvocationKind.setter),
          argDesc,
          objectTable.getHandle(staticReceiverType)));

  int addDynamicCall(
          InvocationKind invocationKind, Name selector, ObjectHandle argDesc) =>
      _add(new ConstantDynamicCall(
          objectTable.getSelectorNameHandle(selector,
              isGetter: invocationKind == InvocationKind.getter,
              isSetter: invocationKind == InvocationKind.setter),
          argDesc));

  int addInstanceCall(InvocationKind invocationKind, Member target,
          Name targetName, ObjectHandle argDesc) =>
      (target == null)
          ? addDynamicCall(invocationKind, targetName, argDesc)
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

  int addSelectorName(Name name, InvocationKind invocationKind) =>
      _add(new ConstantObjectRef(objectTable.getSelectorNameHandle(name,
          isGetter: invocationKind == InvocationKind.getter,
          isSetter: invocationKind == InvocationKind.setter)));

  int _add(ConstantPoolEntry entry) {
    int index = _canonicalizationCache[entry];
    if (index == null) {
      index = entries.length;
      if (index >= constantPoolIndexLimit) {
        throw new ConstantPoolIndexOverflowException();
      }
      _addEntry(entry);
      _canonicalizationCache[entry] = index;
    }
    return index;
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
