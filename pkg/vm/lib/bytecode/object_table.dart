// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.object_table;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/core_types.dart' show CoreTypes;

import 'bytecode_serialization.dart'
    show
        BufferedWriter,
        BufferedReader,
        BytecodeObject,
        ObjectReader,
        ObjectWriter,
        StringWriter;

/*

Bytecode object table is encoded in the following way
(using notation from pkg/kernel/binary.md):

type ObjectTable {
  UInt numEntries;
  UInt contentsSize;

  //  Occupies contentsSize bytes.
  ObjectContents objects[numEntries]

  UInt objectOffsets[numEntries]
}

// Either reference to an object in object table, or object contents
// written inline.
PackedObject = ObjectReference | ObjectContents

type ObjectReference {
  // Bit 0 (reference bit): 1
  // Bits 1+: index in object table
  UInt reference(<index>1)
}

type ObjectContents {
  // Bit 0 (reference bit): 0
  // Bits 1-4: object kind
  // Bits 5+ object flags
  UInt header(<flags><kind>0)
}

// Reference to a string in string table.
type PackedString {
  // Bit 0: set for two byte string
  // Bits 1+: index in string table
  UInt indexAndKind(<index><kind>)
}

// Invalid object table entry (at index 0).
type InvalidObject extends ObjectContents {
  kind = 0;
}

type Library extends ObjectContents {
  kind = 1;
  PackedString importUri;
}

type Class extends ObjectContents {
  kind = 2;
  PackedObject library;
  // Empty name is used for artificial class containing top-level
  // members of a library.
  PackedObject name;
}

type Member extends ObjectContents {
  kind = 3;
  flags = (isField, isConstructor);
  PackedObject class;
  PackedObject name;
}

type Closure extends ObjectContents {
  kind = 4;
  PackedObject enclosingMember;
  UInt closureIndex;
}

type SimpleType extends ObjectContents {
  kind = 5;
  flags = (isDynamic, isVoid);
  PackedObject class;
}

type TypeParameter extends ObjectContents {
  kind = 6;
  // Class, Member or Closure declaring this type parameter.
  // Invalid if declared by function type.
  PackedObject parent;
  UInt indexInParent;
}

type GenericType extends ObjectContents {
  kind = 7;
  PackedObject class;
  List<PackedObject> typeArgs;
}

type FunctionType extends ObjectContents {
  kind = 8;
  flags = (hasOptionalPositionalParams, hasOptionalNamedParams, hasTypeParams)

  if hasTypeParams
    UInt numTypeParameters
    PackedObject[numTypeParameters] typeParameterNames
    PackedObject[numTypeParameters] typeParameterBounds

  UInt numParameters

  if hasOptionalPositionalParams || hasOptionalNamedParams
    UInt numRequiredParameters

   Type[] positionalParameters
   NameAndType[] namedParameters
   PackedObject returnType
}

type NameAndType {
  PackedObject name;
  PackedObject type;
}

type Name extends ObjectContents {
  kind = 9;

  // Invalid for public names
  PackedObject library;

  // Getters are prefixed with 'get:'.
  // Setters are prefixed with 'set:'.
  PackedString string;
}

*/

enum ObjectKind {
  kInvalid,
  kLibrary,
  kClass,
  kMember,
  kClosure,
  kSimpleType,
  kTypeParameter,
  kGenericType,
  kFunctionType,
  kName,
}

String objectKindToString(ObjectKind kind) =>
    kind.toString().substring('ObjectKind.k'.length);

/// Represents object (library, class, member, closure, type or name) in the
/// object table.
abstract class ObjectHandle extends BytecodeObject {
  static const int referenceBit = 1 << 0;
  static const int indexShift = 1;
  static const int inlineObject = -1;

  static const int kindShift = 1;
  static const int kindMask = 0x0F;

  static const int flagBit0 = 1 << 5;
  static const int flagBit1 = 1 << 6;
  static const int flagBit2 = 1 << 7;
  static const int flagsMask = flagBit0 | flagBit1 | flagBit2;

  static int _makeReference(int index) => (index << indexShift) | referenceBit;

  static int _getIndexFromReference(int reference) {
    assert((reference & referenceBit) != 0);
    return reference >> indexShift;
  }

  static int _makeHeader(ObjectKind kind, int flags) {
    assert((kind.index & kindMask) == kind.index);
    assert((flags & flagsMask) == flags);
    return (kind.index << kindShift) | flags;
  }

  static ObjectKind _getKindFromHeader(int header) {
    assert((header & referenceBit) == 0);
    return ObjectKind.values[(header >> kindShift) & kindMask];
  }

  static int _getFlagsFromHeader(int header) {
    assert((header & referenceBit) == 0);
    return header & flagsMask;
  }

  int _useCount = 0;
  int _reference;

  ObjectHandle();

  ObjectKind get kind;

  int get flags => 0;
  set flags(int value) {}

  bool get isCacheable => true;

  factory ObjectHandle._empty(ObjectKind kind) {
    switch (kind) {
      case ObjectKind.kInvalid:
        return new _InvalidHandle();
      case ObjectKind.kLibrary:
        return new _LibraryHandle._empty();
      case ObjectKind.kClass:
        return new _ClassHandle._empty();
      case ObjectKind.kMember:
        return new _MemberHandle._empty();
      case ObjectKind.kClosure:
        return new _ClosureHandle._empty();
      case ObjectKind.kSimpleType:
        return new _SimpleTypeHandle._empty();
      case ObjectKind.kGenericType:
        return new _GenericTypeHandle._empty();
      case ObjectKind.kTypeParameter:
        return new _TypeParameterHandle._empty();
      case ObjectKind.kFunctionType:
        return new _FunctionTypeHandle._empty();
      case ObjectKind.kName:
        return new _NameHandle._empty();
    }
    throw 'Unexpected object kind $kind';
  }

  void _write(BufferedWriter writer) {
    int header = _makeHeader(kind, flags);
    assert((header & referenceBit) == 0);
    writer.writePackedUInt30(header);
    writeContents(writer);
  }

  void writeContents(BufferedWriter writer);

  factory ObjectHandle._read(BufferedReader reader, int header) {
    assert((header & referenceBit) == 0);
    final ObjectKind kind = _getKindFromHeader(header);
    final obj = new ObjectHandle._empty(kind);
    obj.flags = _getFlagsFromHeader(header);
    obj.readContents(reader);
    return obj;
  }

  void readContents(BufferedReader reader);

  void accountUsesForObjectCopies(int numCopies) {}

  void indexStrings(StringWriter strings) {}
}

class _InvalidHandle extends ObjectHandle {
  _InvalidHandle();

  @override
  ObjectKind get kind => ObjectKind.kInvalid;

  @override
  void writeContents(BufferedWriter writer) {}

  @override
  void readContents(BufferedReader reader) {}

  @override
  String toString() => 'Invalid';
}

class _LibraryHandle extends ObjectHandle {
  String uri;

  _LibraryHandle._empty();

  _LibraryHandle(this.uri);

  @override
  ObjectKind get kind => ObjectKind.kLibrary;

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedStringReference(uri);
  }

  @override
  void readContents(BufferedReader reader) {
    uri = reader.readPackedStringReference();
  }

  @override
  void indexStrings(StringWriter strings) {
    strings.put(uri);
  }

  @override
  int get hashCode => uri.hashCode + 11;

  @override
  bool operator ==(other) => other is _LibraryHandle && this.uri == other.uri;

  @override
  String toString() => uri;
}

class _ClassHandle extends ObjectHandle {
  /// Name of artificial class containing top-level members of a library.
  static const String topLevelClassName = '';

  _LibraryHandle library;
  _NameHandle name;

  _ClassHandle._empty();

  _ClassHandle(this.library, this.name);

  @override
  ObjectKind get kind => ObjectKind.kClass;

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(library);
    writer.writePackedObject(name);
  }

  @override
  void readContents(BufferedReader reader) {
    library = reader.readPackedObject();
    name = reader.readPackedObject();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    library._useCount += numCopies;
    name._useCount += numCopies;
  }

  @override
  int get hashCode => _combineHashes(library.hashCode, name.hashCode);

  @override
  bool operator ==(other) =>
      other is _ClassHandle &&
      this.library == other.library &&
      this.name == other.name;

  @override
  String toString() =>
      name.name == topLevelClassName ? '$library' : '$library::$name';
}

class _MemberHandle extends ObjectHandle {
  static const int flagIsField = ObjectHandle.flagBit0;
  static const int flagIsConstructor = ObjectHandle.flagBit1;

  int _flags = 0;
  _ClassHandle parent;
  _NameHandle name;

  _MemberHandle._empty();
  _MemberHandle(this.parent, this.name, bool isField, bool isConstructor) {
    if (isField) {
      _flags |= flagIsField;
    }
    if (isConstructor) {
      _flags |= flagIsConstructor;
    }
  }

  @override
  ObjectKind get kind => ObjectKind.kMember;

  @override
  int get flags => _flags;

  @override
  set flags(int value) {
    _flags = value;
  }

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(parent);
    writer.writePackedObject(name);
  }

  @override
  void readContents(BufferedReader reader) {
    parent = reader.readPackedObject();
    name = reader.readPackedObject();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    parent._useCount += numCopies;
    name._useCount += numCopies;
  }

  @override
  int get hashCode => _combineHashes(parent.hashCode, name.hashCode);

  @override
  bool operator ==(other) =>
      other is _MemberHandle &&
      this.parent == other.parent &&
      this.name == other.name &&
      this.flags == other.flags;

  @override
  String toString() =>
      '$parent::$name' +
      (flags & flagIsField != 0 ? ' (field)' : '') +
      (flags & flagIsConstructor != 0 ? ' (constructor)' : '');
}

class _ClosureHandle extends ObjectHandle {
  _MemberHandle enclosingMember;
  int closureIndex;

  _ClosureHandle._empty();

  _ClosureHandle(this.enclosingMember, this.closureIndex) {
    assert(closureIndex >= 0);
  }

  @override
  ObjectKind get kind => ObjectKind.kClosure;

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(enclosingMember);
    writer.writePackedUInt30(closureIndex);
  }

  @override
  void readContents(BufferedReader reader) {
    enclosingMember = reader.readPackedObject();
    closureIndex = reader.readPackedUInt30();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    enclosingMember._useCount += numCopies;
  }

  @override
  int get hashCode => _combineHashes(enclosingMember.hashCode, closureIndex);

  @override
  bool operator ==(other) =>
      other is _ClosureHandle &&
      this.enclosingMember == other.enclosingMember &&
      this.closureIndex == other.closureIndex;

  @override
  String toString() => '$enclosingMember::Closure/$closureIndex';
}

abstract class _TypeHandle extends ObjectHandle {}

class _SimpleTypeHandle extends _TypeHandle {
  static const int flagIsDynamic = ObjectHandle.flagBit0;
  static const int flagIsVoid = ObjectHandle.flagBit1;

  _ClassHandle class_;
  int _flags = 0;

  _SimpleTypeHandle._empty();

  _SimpleTypeHandle(this.class_);

  _SimpleTypeHandle._dynamic() : _flags = flagIsDynamic;

  _SimpleTypeHandle._void() : _flags = flagIsVoid;

  @override
  ObjectKind get kind => ObjectKind.kSimpleType;

  @override
  int get flags => _flags;

  @override
  set flags(int value) {
    _flags = value;
  }

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(class_);
  }

  @override
  void readContents(BufferedReader reader) {
    class_ = reader.readPackedObject();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    if (class_ != null) {
      class_._useCount += numCopies;
    }
  }

  @override
  int get hashCode => class_.hashCode + _flags + 11;

  @override
  bool operator ==(other) =>
      other is _SimpleTypeHandle &&
      this.class_ == other.class_ &&
      this._flags == other._flags;

  @override
  String toString() {
    if ((_flags & flagIsDynamic) != 0) return 'dynamic';
    if ((_flags & flagIsVoid) != 0) return 'void';
    return '$class_';
  }
}

class _TypeParameterHandle extends _TypeHandle {
  ObjectHandle parent;
  int indexInParent;

  _TypeParameterHandle._empty();

  _TypeParameterHandle(this.parent, this.indexInParent) {
    assert(parent is _ClassHandle ||
        parent is _MemberHandle ||
        parent is _ClosureHandle ||
        parent == null);
    assert(indexInParent >= 0);
  }

  @override
  ObjectKind get kind => ObjectKind.kTypeParameter;

  @override
  bool get isCacheable => (parent != null);

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(parent);
    writer.writePackedUInt30(indexInParent);
  }

  @override
  void readContents(BufferedReader reader) {
    parent = reader.readPackedObject();
    indexInParent = reader.readPackedUInt30();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    if (parent != null) {
      parent._useCount += numCopies;
    }
  }

  @override
  int get hashCode => _combineHashes(parent.hashCode, indexInParent);

  @override
  bool operator ==(other) =>
      other is _TypeParameterHandle &&
      this.parent == other.parent &&
      this.indexInParent == other.indexInParent;

  @override
  String toString() => '$parent::TypeParam/$indexInParent';
}

class _GenericTypeHandle extends _TypeHandle {
  _ClassHandle class_;
  List<_TypeHandle> typeArgs;

  _GenericTypeHandle._empty();

  _GenericTypeHandle(this.class_, this.typeArgs);

  @override
  ObjectKind get kind => ObjectKind.kGenericType;

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(class_);
    writer.writePackedList(typeArgs);
  }

  @override
  void readContents(BufferedReader reader) {
    class_ = reader.readPackedObject();
    typeArgs = reader.readPackedList<_TypeHandle>();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    class_._useCount += numCopies;
    typeArgs.forEach((t) {
      t._useCount += numCopies;
    });
  }

  @override
  int get hashCode => _combineHashes(class_.hashCode, listHashCode(typeArgs));

  @override
  bool operator ==(other) =>
      other is _GenericTypeHandle &&
      this.class_ == other.class_ &&
      listEquals(this.typeArgs, other.typeArgs);

  @override
  String toString() => '$class_ < ${typeArgs.join(', ')} >';
}

class NameAndType {
  _NameHandle name;
  _TypeHandle type;

  NameAndType(this.name, this.type);

  @override
  int get hashCode => _combineHashes(name.hashCode, type.hashCode);

  @override
  bool operator ==(other) =>
      other is NameAndType &&
      this.name == other.name &&
      this.type == other.type;

  @override
  String toString() => '$type $name';
}

class _FunctionTypeHandle extends _TypeHandle {
  static const int flagHasOptionalPositionalParams = ObjectHandle.flagBit0;
  static const int flagHasOptionalNamedParams = ObjectHandle.flagBit1;
  static const int flagHasTypeParams = ObjectHandle.flagBit2;

  int _flags = 0;
  List<NameAndType> typeParams;
  int numRequiredParams;
  List<_TypeHandle> positionalParams;
  List<NameAndType> namedParams;
  _TypeHandle returnType;

  _FunctionTypeHandle._empty();

  _FunctionTypeHandle(this.typeParams, this.numRequiredParams,
      this.positionalParams, this.namedParams, this.returnType) {
    assert(numRequiredParams <= positionalParams.length + namedParams.length);
    if (numRequiredParams < positionalParams.length) {
      assert(namedParams.isEmpty);
      _flags |= flagHasOptionalPositionalParams;
    }
    if (namedParams.isNotEmpty) {
      assert(numRequiredParams == positionalParams.length);
      _flags |= flagHasOptionalNamedParams;
    }
    if (typeParams.isNotEmpty) {
      _flags |= flagHasTypeParams;
    }
  }

  @override
  int get flags => _flags;

  @override
  set flags(int value) {
    _flags = value;
  }

  ObjectKind get kind => ObjectKind.kFunctionType;

  @override
  void writeContents(BufferedWriter writer) {
    if ((_flags & flagHasTypeParams) != 0) {
      writer.writePackedUInt30(typeParams.length);
      for (var tp in typeParams) {
        writer.writePackedObject(tp.name);
      }
      for (var tp in typeParams) {
        writer.writePackedObject(tp.type);
      }
    }
    writer.writePackedUInt30(positionalParams.length + namedParams.length);
    if (_flags &
            (flagHasOptionalPositionalParams | flagHasOptionalNamedParams) !=
        0) {
      writer.writePackedUInt30(numRequiredParams);
    }
    for (var param in positionalParams) {
      writer.writePackedObject(param);
    }
    for (var param in namedParams) {
      writer.writePackedObject(param.name);
      writer.writePackedObject(param.type);
    }
    writer.writePackedObject(returnType);
  }

  @override
  void readContents(BufferedReader reader) {
    if ((_flags & flagHasTypeParams) != 0) {
      final int numTypeParams = reader.readPackedUInt30();
      List<_NameHandle> names = new List<_NameHandle>.generate(
          numTypeParams, (_) => reader.readPackedObject());
      List<_TypeHandle> bounds = new List<_TypeHandle>.generate(
          numTypeParams, (_) => reader.readPackedObject());
      typeParams = new List<NameAndType>.generate(
          numTypeParams, (int i) => new NameAndType(names[i], bounds[i]));
    } else {
      typeParams = const <NameAndType>[];
    }
    final int numParams = reader.readPackedUInt30();
    numRequiredParams = numParams;
    if ((_flags &
            (flagHasOptionalPositionalParams | flagHasOptionalNamedParams)) !=
        0) {
      numRequiredParams = reader.readPackedUInt30();
    }
    final bool hasNamedParams = (_flags & flagHasOptionalNamedParams) != 0;
    positionalParams = new List<_TypeHandle>.generate(
        hasNamedParams ? numRequiredParams : numParams,
        (_) => reader.readPackedObject());
    if (hasNamedParams) {
      namedParams = new List<NameAndType>.generate(
          reader.readPackedUInt30(),
          (_) => new NameAndType(
              reader.readPackedObject(), reader.readPackedObject()));
    } else {
      namedParams = const <NameAndType>[];
    }
    returnType = reader.readPackedObject();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    positionalParams.forEach((p) {
      p._useCount += numCopies;
    });
    namedParams.forEach((p) {
      p.name._useCount += numCopies;
      p.type._useCount += numCopies;
    });
  }

  @override
  int get hashCode {
    int hash = listHashCode(typeParams);
    hash = _combineHashes(hash, numRequiredParams);
    hash = _combineHashes(hash, listHashCode(positionalParams));
    hash = _combineHashes(hash, listHashCode(namedParams));
    hash = _combineHashes(hash, returnType.hashCode);
    return hash;
  }

  @override
  bool operator ==(other) =>
      other is _FunctionTypeHandle &&
      listEquals(this.typeParams, other.typeParams) &&
      this.numRequiredParams == other.numRequiredParams &&
      listEquals(this.positionalParams, other.positionalParams) &&
      listEquals(this.namedParams, other.namedParams) &&
      this.returnType == other.returnType;

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('FunctionType');
    if (typeParams.isNotEmpty) {
      sb.write(' <${typeParams.join(', ')}>');
    }
    sb.write(' (');
    sb.write(positionalParams.sublist(0, numRequiredParams).join(', '));
    if (numRequiredParams != positionalParams.length) {
      if (numRequiredParams > 0) {
        sb.write(', ');
      }
      sb.write('[ ${positionalParams.sublist(numRequiredParams).join(', ')} ]');
    }
    if (namedParams.isNotEmpty) {
      if (numRequiredParams > 0) {
        sb.write(', ');
      }
      sb.write('{ ${namedParams.join(', ')} }');
    }
    sb.write(') -> ');
    sb.write(returnType);
    return sb.toString();
  }
}

class _NameHandle extends ObjectHandle {
  _LibraryHandle library;
  String name;

  _NameHandle._empty();

  _NameHandle(this.library, this.name);

  @override
  ObjectKind get kind => ObjectKind.kName;

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(library);
    writer.writePackedStringReference(name);
  }

  @override
  void readContents(BufferedReader reader) {
    library = reader.readPackedObject();
    name = reader.readPackedStringReference();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    if (library != null) {
      library._useCount += numCopies;
    }
  }

  @override
  void indexStrings(StringWriter strings) {
    strings.put(name);
  }

  @override
  int get hashCode => _combineHashes(name.hashCode, library.hashCode);

  @override
  bool operator ==(other) =>
      other is _NameHandle &&
      this.name == other.name &&
      this.library == other.library;

  @override
  String toString() => name.isEmpty ? "''" : name;
}

class ObjectTable implements ObjectWriter, ObjectReader {
  /// Object is added to an index table if it is used more than this
  /// number of times.
  static const int indexTableUseCountThreshold = 3;

  final List<ObjectHandle> _objects = new List<ObjectHandle>();
  final Map<ObjectHandle, ObjectHandle> _canonicalizationCache =
      <ObjectHandle, ObjectHandle>{};
  final Map<Node, ObjectHandle> _nodeCache = <Node, ObjectHandle>{};
  List<ObjectHandle> _indexTable;
  _TypeHandle _dynamicType;
  _TypeHandle _voidType;
  CoreTypes coreTypes;
  _NodeVisitor _nodeVisitor;

  ObjectTable() {
    _dynamicType = getOrAddObject(new _SimpleTypeHandle._dynamic());
    _voidType = getOrAddObject(new _SimpleTypeHandle._void());
    _nodeVisitor = new _NodeVisitor(this);
  }

  ObjectHandle getHandle(Node node) {
    if (node == null) {
      return null;
    }
    ObjectHandle handle = _nodeCache[node];
    if (handle == null) {
      handle = node.accept(_nodeVisitor);
      _nodeCache[node] = handle;
    } else {
      ++handle._useCount;
    }
    return handle;
  }

  List<ObjectHandle> getHandles(List<Node> nodes) =>
      nodes.map((n) => getHandle(n)).toList();

  String mangleGetterName(String name) => 'get:$name';

  String mangleSetterName(String name) => 'set:$name';

  String mangleSelectorName(String name, bool isGetter, bool isSetter) {
    if (isGetter) {
      return mangleGetterName(name);
    } else if (isSetter) {
      return mangleSetterName(name);
    } else {
      return name;
    }
  }

  String mangleMemberName(Member member, bool isGetter, bool isSetter) {
    final name = member.name.name;
    if (isGetter || (member is Procedure && member.isGetter)) {
      return mangleGetterName(name);
    }
    if (isSetter || (member is Procedure && member.isSetter)) {
      return mangleSetterName(name);
    }
    return name;
  }

  ObjectHandle getNameHandle(Library library, String name) {
    final libraryHandle = library != null ? getHandle(library) : null;
    return getOrAddObject(new _NameHandle(libraryHandle, name));
  }

  ObjectHandle getSelectorNameHandle(Name name,
      {bool isGetter: false, bool isSetter: false}) {
    return getNameHandle(
        name.library, mangleSelectorName(name.name, isGetter, isSetter));
  }

  ObjectHandle getMemberHandle(Member member,
      {bool isGetter: false, bool isSetter: false}) {
    final parent = member.parent;
    ObjectHandle classHandle;
    if (parent is Class) {
      classHandle = getHandle(parent);
    } else if (parent is Library) {
      final library = getHandle(parent);
      final name = getNameHandle(null, _ClassHandle.topLevelClassName);
      classHandle = getOrAddObject(new _ClassHandle(library, name));
    } else {
      throw "Unexpected Member's parent ${parent.runtimeType} $parent";
    }
    if (member is Constructor || member is Procedure && member.isFactory) {}
    final nameHandle = getNameHandle(
        member.name.library, mangleMemberName(member, isGetter, isSetter));
    bool isField = member is Field && !isGetter && !isSetter;
    bool isConstructor =
        member is Constructor || (member is Procedure && member.isFactory);
    return getOrAddObject(
        new _MemberHandle(classHandle, nameHandle, isField, isConstructor));
  }

  void declareClosure(
      FunctionNode function, Member enclosingMember, int closureIndex) {
    final handle = getOrAddObject(
        new _ClosureHandle(getHandle(enclosingMember), closureIndex));
    _nodeCache[function] = handle;
  }

  ObjectHandle getOrAddObject(ObjectHandle obj) {
    assert(obj._useCount == 0);
    ObjectHandle canonical = _canonicalizationCache.putIfAbsent(obj, () {
      assert(_indexTable == null);
      _objects.add(obj);
      return obj;
    });
    ++canonical._useCount;
    return canonical;
  }

  void allocateIndexTable() {
    int tableSize = 1; // Reserve invalid entry.
    for (var obj in _objects.reversed) {
      assert(obj._reference == null);
      if (obj._useCount >= indexTableUseCountThreshold && obj.isCacheable) {
        // This object will be included into index table.
        ++tableSize;
      } else {
        // This object will be copied and written inline. Bump use count for
        // objects referenced from this one for each copy after the first.
        obj._reference = ObjectHandle.inlineObject;
        obj.accountUsesForObjectCopies(obj._useCount - 1);
      }
    }
    _indexTable = new List<ObjectHandle>(tableSize);
    int count = 0;
    _indexTable[count++] = new _InvalidHandle()
      .._reference = ObjectHandle._makeReference(0);
    for (var obj in _objects) {
      if (obj._reference == null) {
        obj._reference = ObjectHandle._makeReference(count);
        _indexTable[count++] = obj;
      } else {
        assert(obj._reference == ObjectHandle.inlineObject);
      }
    }
    assert(count == tableSize);
  }

  @override
  void writeObject(BytecodeObject object, BufferedWriter writer) {
    ObjectHandle handle = object as ObjectHandle;
    if (handle == null) {
      writer.writePackedUInt30(ObjectHandle._makeReference(0));
      return;
    }
    if (handle._reference == ObjectHandle.inlineObject) {
      handle._write(writer);
    } else {
      assert(handle._reference >= 0);
      assert((handle._reference & ObjectHandle.referenceBit) != 0);
      writer.writePackedUInt30(handle._reference);
    }
  }

  @override
  BytecodeObject readObject(BufferedReader reader) {
    final int header = reader.readPackedUInt30();
    if ((header & ObjectHandle.referenceBit) == 0) {
      return new ObjectHandle._read(reader, header);
    } else {
      final int index = ObjectHandle._getIndexFromReference(header);
      return (index == 0) ? null : _indexTable[index];
    }
  }

  void write(BufferedWriter writer) {
    assert(writer.objectWriter == this);
    assert(_indexTable != null);

    BufferedWriter contentsWriter = new BufferedWriter.fromWriter(writer);
    List<int> offsets = new List<int>(_indexTable.length);

    for (int i = 0; i < _indexTable.length; ++i) {
      offsets[i] = contentsWriter.offset;
      _indexTable[i]._write(contentsWriter);
    }

    writer.writePackedUInt30(_indexTable.length);
    writer.writePackedUInt30(contentsWriter.offset);
    writer.writeBytes(contentsWriter.takeBytes());
    for (var offs in offsets) {
      writer.writePackedUInt30(offs);
    }

    // Index strings in objects which will be written inline
    // in constant pool entries.
    for (var obj in _objects) {
      if (obj._reference == ObjectHandle.inlineObject) {
        obj.indexStrings(writer.stringWriter);
      }
    }
  }

  ObjectTable.read(BufferedReader reader) {
    reader.objectReader = this;

    final int numEntries = reader.readPackedUInt30();
    reader.readPackedUInt30(); // Contents length

    _indexTable = new List<ObjectHandle>(numEntries);
    for (int i = 0; i < numEntries; ++i) {
      final int header = reader.readPackedUInt30();
      _indexTable[i] = new ObjectHandle._read(reader, header)
        .._reference = ObjectHandle._makeReference(i);
    }
    // Skip index table.
    for (int i = 0; i < numEntries; ++i) {
      reader.readPackedUInt30();
    }
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln('ObjectTable {');
    for (int i = 0; i < _indexTable.length; ++i) {
      final obj = _indexTable[i];
      sb.writeln('  [$i] = ${objectKindToString(obj.kind)} $obj');
    }
    sb.writeln('}');
    return sb.toString();
  }
}

class _NodeVisitor extends Visitor<ObjectHandle> {
  final ObjectTable objectTable;
  final _typeParameters = <TypeParameter, ObjectHandle>{};

  _NodeVisitor(this.objectTable);

  @override
  ObjectHandle defaultNode(Node node) =>
      throw 'Unexpected node ${node.runtimeType} $node';

  @override
  ObjectHandle visitLibrary(Library node) =>
      objectTable.getOrAddObject(new _LibraryHandle(node.importUri.toString()));

  @override
  ObjectHandle visitClass(Class node) {
    final ObjectHandle library = objectTable.getHandle(node.enclosingLibrary);
    final name = objectTable.getOrAddObject(
        new _NameHandle(node.name.startsWith('_') ? library : null, node.name));
    return objectTable.getOrAddObject(new _ClassHandle(library, name));
  }

  @override
  ObjectHandle defaultMember(Member node) => objectTable.getMemberHandle(node);

  @override
  ObjectHandle visitDynamicType(DynamicType node) => objectTable._dynamicType;

  @override
  ObjectHandle visitVoidType(VoidType node) => objectTable._voidType;

  @override
  ObjectHandle visitBottomType(BottomType node) =>
      objectTable.getHandle(objectTable.coreTypes.nullClass.rawType);

  @override
  ObjectHandle visitInterfaceType(InterfaceType node) {
    final classHandle = objectTable.getHandle(node.classNode);
    if (node.typeArguments.isEmpty) {
      return objectTable.getOrAddObject(new _SimpleTypeHandle(classHandle));
    }
    final List<_TypeHandle> typeArgs = node.typeArguments
        .map((t) => objectTable.getHandle(t) as _TypeHandle)
        .toList();
    return objectTable
        .getOrAddObject(new _GenericTypeHandle(classHandle, typeArgs));
  }

  @override
  ObjectHandle visitTypeParameterType(TypeParameterType node) {
    final param = node.parameter;
    final handle = _typeParameters[param];
    if (handle != null) {
      return handle;
    }

    final parent = param.parent;
    if (parent == null) {
      throw 'Type parameter $param without parent, but not declared by function type';
    }

    ObjectHandle parentHandle;
    int indexInParent;
    if (parent is Class) {
      parentHandle = objectTable.getHandle(parent);
      indexInParent = parent.typeParameters.indexOf(param);
      if (indexInParent < 0) {
        throw 'Type parameter $param is not found in its parent class $parent';
      }
    } else if (parent is FunctionNode) {
      final funcParent = parent.parent;
      if (funcParent is Member) {
        parentHandle = objectTable.getHandle(funcParent);
      } else if (funcParent is FunctionExpression ||
          funcParent is FunctionDeclaration) {
        parentHandle = objectTable.getHandle(parent);
      } else {
        throw 'Unexpected parent of FunctionNode: ${funcParent.runtimeType} $funcParent';
      }
      indexInParent = parent.typeParameters.indexOf(node.parameter);
      if (indexInParent < 0) {
        throw 'Type parameter $param is not found in its parent function $parent';
      }
    } else {
      throw 'Unexpected parent of TypeParameter: ${parent.runtimeType} $parent';
    }
    return objectTable
        .getOrAddObject(new _TypeParameterHandle(parentHandle, indexInParent));
  }

  @override
  ObjectHandle visitFunctionType(FunctionType node) {
    final typeParameters = new List<_TypeParameterHandle>.generate(
        node.typeParameters.length,
        (i) => objectTable.getOrAddObject(new _TypeParameterHandle(null, i)));
    for (int i = 0; i < node.typeParameters.length; ++i) {
      _typeParameters[node.typeParameters[i]] = typeParameters[i];
    }

    final positionalParams = new List<_TypeHandle>();
    for (var param in node.positionalParameters) {
      positionalParams.add(objectTable.getHandle(param));
    }
    final namedParams = new List<NameAndType>();
    for (var param in node.namedParameters) {
      namedParams.add(new NameAndType(
          objectTable.getNameHandle(null, param.name),
          objectTable.getHandle(param.type)));
    }
    final returnType = objectTable.getHandle(node.returnType);

    for (int i = 0; i < node.typeParameters.length; ++i) {
      _typeParameters.remove(node.typeParameters[i]);
    }

    return objectTable.getOrAddObject(new _FunctionTypeHandle(
        node.typeParameters
            .map((tp) => new NameAndType(
                objectTable.getNameHandle(null, tp.name),
                objectTable.getHandle(tp.bound)))
            .toList(),
        node.requiredParameterCount,
        positionalParams,
        namedParams,
        returnType));
  }

  @override
  ObjectHandle visitTypedefType(TypedefType node) =>
      objectTable.getHandle(node.unalias);
}

int _combineHashes(int hash1, int hash2) =>
    (((hash1 * 31) & 0x3fffffff) + hash2) & 0x3fffffff;
