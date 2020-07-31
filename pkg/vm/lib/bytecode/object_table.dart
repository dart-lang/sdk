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
        BytecodeSizeStatistics,
        ForwardReference,
        NamedEntryStatistics,
        doubleToIntBits,
        intBitsToDouble,
        ObjectReader,
        ObjectWriter,
        StringWriter;
import 'generics.dart'
    show getInstantiatorTypeArguments, hasInstantiatorTypeArguments;
import 'declarations.dart' show SourceFile, TypeParametersDeclaration;
import 'recursive_types_validator.dart' show RecursiveTypesValidator;

/*

Bytecode object table is encoded in the following way
(using notation from pkg/kernel/binary.md):

type ObjectTable {
  UInt numEntries

  // Total size of ‘objects’ in bytes.
  UInt objectsSize

  ObjectContents[numEntries] objects

  // Offsets relative to ‘objects’.
  UInt[numEntries] objectOffsets
}


// Either reference to an object in object table, or object contents
// written inline (determined by bit 0).
PackedObject = ObjectReference | ObjectContents

type ObjectReference {
  // Bit 0 (reference bit): 1
  // Bits 1+: index in object table
  UInt reference
}

type ObjectContents {
  // Bit 0 (reference bit): 0
  // Bits 1-4: object kind
  // Bits 5+ object flags
  UInt header
}

// Invalid/null object (always present at index 0).
type InvalidObject extends ObjectContents {
  kind = 0;
}

type Library extends ObjectContents {
  kind = 1;
  PackedObject importUri;
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

type Name extends ObjectContents {
  kind = 9;

  // Invalid for public names
  PackedObject library;

  // Getters are prefixed with 'get:'.
  // Setters are prefixed with 'set:'.
  PackedString string;
}

// Type arguments vector.
type TypeArguments extends ObjectContents {
  kind = 10;
  List<PackedObject> args;
}

abstract type ConstObject extends ObjectContents {
  kind = 12;
  flags = constantTag (4 bits)
}

type ConstInstance extends ConstObject {
  kind = 12
  constantTag (flags) = 1
  PackedObject type;
  List<Pair<PackedObject, PackedObject>> fieldValues;
}

type ConstInt extends ConstValue {
  kind = 12
  constantTag (flags) = 2
  SLEB128 value;
}

type ConstDouble extends ConstValue {
  kind = 12
  constantTag (flags) = 3
  // double bits are reinterpreted as 64-bit int
  SLEB128 value;
}

type ConstList extends ConstObject {
  kind = 12
  constantTag (flags) = 4
  PackedObject elemType;
  List<PackedObject> entries;
}

type ConstTearOff extends ConstObject {
  kind = 12
  constantTag (flags) = 5
  PackedObject target;
}

type ConstBool extends ConstValue {
  kind = 12
  constantTag = 6
  Byte isTrue;
}

type ConstSymbol extends ConstObject {
  kind = 12
  constantTag (flags) = 7
  PackedObject name;
}

type ConstTearOffInstantiation extends ConstObject {
  kind = 12
  constantTag (flags) = 8
  PackedObject tearOff;
  PackedObject typeArguments;
}

type ArgDesc extends ObjectContents {
  kind = 13;
  flags = (hasNamedArgs, hasTypeArgs)

  UInt numArguments

 if hasTypeArgs
   UInt numTypeArguments

 if hasNamedArgs
   List<PackedObject> argNames;
}

type Script extends ObjectContents {
  kind = 14
  flags = (hasSourceFile)
  PackedObject uri
  if hasSourceFile
    UInt sourceFileOffset
}

abstract type Type extends ObjectContents {
  kind = 15
  flags = typeTag (4 bits)
}

type DynamicType extends Type {
  kind = 15
  typeTag (flags) = 1
}

type VoidType extends Type {
  kind = 15
  typeTag (flags) = 2
}

type NeverType extends Type {
  kind = 15
  typeTag (flags) = 9
}

// SimpleType can be used only for types without instantiator type arguments.
type SimpleType extends Type {
  kind = 15
  typeTag (flags) = 3
  PackedObject class
}

type TypeParameter extends Type {
  kind = 15
  typeTag (flags) = 4
  // Class, Member or Closure declaring this type parameter.
  // Null (Invalid) if declared by function type.
  PackedObject parent
  UInt indexInParent
}

// Non-recursive finalized generic type.
type GenericType extends Type {
  kind = 15
  typeTag (flags) = 5
  PackedObject class
  // Flattened type arguments vector.
  PackedObject typeArgs
}

// Recursive finalized generic type.
type RecursiveGenericType extends Type {
  kind = 15
  typeTag (flags) = 6
  // This id is used to reference recursive types using RecursiveTypeRef.
  // Type should be declared using RecursiveGenericType before it can be referenced.
  // The root type should have zero recursiveId.
  UInt recursiveId
  PackedObject class
  // Flattened type arguments vector.
  PackedObject typeArgs
}

type RecursiveTypeRef extends Type {
  kind = 15
  typeTag (flags) = 7
  UInt recursiveId
}

type FunctionType extends Type {
  kind = 15
  typeTag (flags) = 8

  UInt functionTypeFlags(hasOptionalPositionalParams,
                         hasOptionalNamedParams,
                         hasTypeParams)

  if hasTypeParams
    TypeParametersDeclaration typeParameters

  UInt numParameters

  if hasOptionalPositionalParams || hasOptionalNamedParams
    UInt numRequiredParameters

  Type[] positionalParameters
  NameAndType[] namedParameters
  PackedObject returnType
}

type TypeParametersDeclaration {
   UInt numTypeParameters
   PackedObject[numTypeParameters] typeParameterNames
   PackedObject[numTypeParameters] typeParameterBounds
}

type NameAndType {
  PackedObject name;
  PackedObject type;
}

*/

enum ObjectKind {
  kInvalid,
  kLibrary,
  kClass,
  kMember,
  kClosure,
  kUnused1,
  kUnused2,
  kUnused3,
  kUnused4,
  kName,
  kTypeArguments,
  kUnused5,
  kConstObject,
  kArgDesc,
  kScript,
  kType,
}

enum ConstTag {
  kInvalid,
  kInstance,
  kInt,
  kDouble,
  kList,
  kTearOff,
  kBool,
  kSymbol,
  kTearOffInstantiation,
  kString,
}

enum TypeTag {
  kInvalid,
  kDynamic,
  kVoid,
  kSimpleType,
  kTypeParameter,
  kGenericType,
  kRecursiveGenericType,
  kRecursiveTypeRef,
  kFunctionType,
  kNever,
}

/// Name of artificial class containing top-level members of a library.
const String topLevelClassName = '';

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
  static const int flagBit3 = 1 << 8;
  static const int flagBit4 = 1 << 9;
  static const int flagBit5 = 1 << 10;
  static const int flagsMask =
      flagBit0 | flagBit1 | flagBit2 | flagBit3 | flagBit4 | flagBit5;

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
  bool get shouldBeIncludedIntoIndexTable =>
      _useCount >= ObjectTable.indexTableUseCountThreshold && isCacheable;

  factory ObjectHandle._empty(ObjectKind kind, int flags) {
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
      case ObjectKind.kName:
        return ((flags & _NameHandle.flagIsPublic) != 0)
            ? new _PublicNameHandle._empty()
            : _PrivateNameHandle._empty();
      case ObjectKind.kTypeArguments:
        return new _TypeArgumentsHandle._empty();
      case ObjectKind.kConstObject:
        return new _ConstObjectHandle._empty();
      case ObjectKind.kArgDesc:
        return new _ArgDescHandle._empty();
      case ObjectKind.kScript:
        return new _ScriptHandle._empty();
      case ObjectKind.kType:
        Nullability nullability = Nullability
            .values[(flags & _TypeHandle.nullabilityMask) ~/ flagBit4];
        switch (TypeTag.values[(flags & _TypeHandle.tagMask) ~/ flagBit0]) {
          case TypeTag.kInvalid:
            break;
          case TypeTag.kDynamic:
            return new _DynamicTypeHandle();
          case TypeTag.kVoid:
            return new _VoidTypeHandle();
          case TypeTag.kNever:
            return new _NeverTypeHandle(nullability);
          case TypeTag.kSimpleType:
            return new _SimpleTypeHandle._empty(nullability);
          case TypeTag.kTypeParameter:
            return new _TypeParameterHandle._empty(nullability);
          case TypeTag.kGenericType:
            return new _GenericTypeHandle._empty(nullability);
          case TypeTag.kRecursiveGenericType:
            return new _RecursiveGenericTypeHandle._empty(nullability);
          case TypeTag.kRecursiveTypeRef:
            return new _RecursiveTypeRefHandle._empty(nullability);
          case TypeTag.kFunctionType:
            return new _FunctionTypeHandle._empty(nullability);
        }
        throw 'Unexpected type tag $flags';
      case ObjectKind.kUnused1:
      case ObjectKind.kUnused2:
      case ObjectKind.kUnused3:
      case ObjectKind.kUnused4:
      case ObjectKind.kUnused5:
        break;
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
    final int flags = _getFlagsFromHeader(header);
    final obj = new ObjectHandle._empty(kind, flags);
    obj.flags = flags;
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
  _ConstObjectHandle uri;

  _LibraryHandle._empty();

  _LibraryHandle(this.uri);

  @override
  ObjectKind get kind => ObjectKind.kLibrary;

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(uri);
  }

  @override
  void readContents(BufferedReader reader) {
    uri = reader.readPackedObject();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    uri._useCount += numCopies;
  }

  @override
  int get hashCode => uri.hashCode + 11;

  @override
  bool operator ==(other) => other is _LibraryHandle && this.uri == other.uri;

  @override
  String toString() => uri.value;
}

class _ClassHandle extends ObjectHandle {
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
      name.name == topLevelClassName ? '$library' : '$library::${name.name}';
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
      '$parent::${name.name}' +
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

abstract class _TypeHandle extends ObjectHandle {
  static const int tagMask = ObjectHandle.flagBit0 |
      ObjectHandle.flagBit1 |
      ObjectHandle.flagBit2 |
      ObjectHandle.flagBit3;
  static const int nullabilityMask =
      ObjectHandle.flagBit4 | ObjectHandle.flagBit5;

  final TypeTag tag;
  Nullability nullability;

  _TypeHandle(this.tag, this.nullability);

  @override
  ObjectKind get kind => ObjectKind.kType;

  @override
  int get flags =>
      (tag.index * ObjectHandle.flagBit0) |
      (nullability.index * ObjectHandle.flagBit4);

  @override
  set flags(int value) {
    if (value != flags) {
      throw 'Unable to set flags for _TypeHandle (they are occupied by type tag and nnbd)';
    }
  }
}

class _DynamicTypeHandle extends _TypeHandle {
  _DynamicTypeHandle() : super(TypeTag.kDynamic, Nullability.nullable);

  @override
  void writeContents(BufferedWriter writer) {}

  @override
  void readContents(BufferedReader reader) {}

  @override
  int get hashCode => 2029;

  @override
  bool operator ==(other) => other is _DynamicTypeHandle;

  @override
  String toString() => 'dynamic';
}

class _VoidTypeHandle extends _TypeHandle {
  _VoidTypeHandle() : super(TypeTag.kVoid, Nullability.nullable);

  @override
  void writeContents(BufferedWriter writer) {}

  @override
  void readContents(BufferedReader reader) {}

  @override
  int get hashCode => 2039;

  @override
  bool operator ==(other) => other is _VoidTypeHandle;

  @override
  String toString() => 'void';
}

class _NeverTypeHandle extends _TypeHandle {
  _NeverTypeHandle(Nullability nullability)
      : super(TypeTag.kNever, nullability);

  @override
  void writeContents(BufferedWriter writer) {}

  @override
  void readContents(BufferedReader reader) {}

  @override
  int get hashCode => _combineHashes(2049, nullability.index);

  @override
  bool operator ==(other) =>
      other is _NeverTypeHandle && this.nullability == other.nullability;

  @override
  // TODO(regis): Print nullability.
  String toString() => 'Never';
}

class _SimpleTypeHandle extends _TypeHandle {
  _ClassHandle class_;

  _SimpleTypeHandle._empty(Nullability nullability)
      : super(TypeTag.kSimpleType, nullability);

  _SimpleTypeHandle(this.class_, Nullability nullability)
      : super(TypeTag.kSimpleType, nullability);

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
  int get hashCode => _combineHashes(class_.hashCode, nullability.index);

  @override
  bool operator ==(other) =>
      other is _SimpleTypeHandle &&
      this.class_ == other.class_ &&
      this.nullability == other.nullability;

  @override
  // TODO(regis): Print nullability.
  String toString() => '$class_';
}

class _TypeParameterHandle extends _TypeHandle {
  ObjectHandle parent;
  int indexInParent;

  _TypeParameterHandle._empty(Nullability nullability)
      : super(TypeTag.kTypeParameter, nullability);

  _TypeParameterHandle(this.parent, this.indexInParent, Nullability nullability)
      : super(TypeTag.kTypeParameter, nullability) {
    assert(parent is _ClassHandle ||
        parent is _MemberHandle ||
        parent is _ClosureHandle ||
        parent == null);
    assert(indexInParent >= 0);
  }

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
  int get hashCode => _combineHashes(
      parent.hashCode, _combineHashes(indexInParent, nullability.index));

  @override
  bool operator ==(other) =>
      other is _TypeParameterHandle &&
      this.parent == other.parent &&
      this.indexInParent == other.indexInParent &&
      this.nullability == other.nullability;

  @override
  // TODO(regis): Print nullability.
  String toString() => '$parent::TypeParam/$indexInParent';
}

class _GenericTypeHandle extends _TypeHandle {
  _ClassHandle class_;
  _TypeArgumentsHandle typeArgs;

  _GenericTypeHandle._empty(Nullability nullability)
      : super(TypeTag.kGenericType, nullability);

  _GenericTypeHandle(this.class_, this.typeArgs, Nullability nullability)
      : super(TypeTag.kGenericType, nullability);

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(class_);
    writer.writePackedObject(typeArgs);
  }

  @override
  void readContents(BufferedReader reader) {
    class_ = reader.readPackedObject();
    typeArgs = reader.readPackedObject();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    class_._useCount += numCopies;
    if (typeArgs != null) {
      typeArgs._useCount += numCopies;
    }
  }

  @override
  int get hashCode => _combineHashes(
      class_.hashCode, _combineHashes(typeArgs.hashCode, nullability.index));

  @override
  bool operator ==(other) =>
      other is _GenericTypeHandle &&
      this.class_ == other.class_ &&
      this.typeArgs == other.typeArgs &&
      this.nullability == other.nullability;

  @override
  // TODO(regis): Print nullability.
  String toString() => '$class_ $typeArgs';
}

class _RecursiveGenericTypeHandle extends _TypeHandle {
  int id;
  _ClassHandle class_;
  _TypeArgumentsHandle typeArgs;

  _RecursiveGenericTypeHandle._empty(Nullability nullability)
      : super(TypeTag.kRecursiveGenericType, nullability);

  _RecursiveGenericTypeHandle(
      this.id, this.class_, this.typeArgs, Nullability nullability)
      : super(TypeTag.kRecursiveGenericType, nullability);

  @override
  bool get isCacheable => (id == 0);

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedUInt30(id);
    writer.writePackedObject(class_);
    writer.writePackedObject(typeArgs);
  }

  @override
  void readContents(BufferedReader reader) {
    id = reader.readPackedUInt30();
    class_ = reader.readPackedObject();
    typeArgs = reader.readPackedObject();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    class_._useCount += numCopies;
    if (typeArgs != null) {
      typeArgs._useCount += numCopies;
    }
  }

  @override
  int get hashCode => _combineHashes(
      class_.hashCode, _combineHashes(typeArgs.hashCode, nullability.index));

  @override
  bool operator ==(other) =>
      other is _RecursiveGenericTypeHandle &&
      this.class_ == other.class_ &&
      this.typeArgs == other.typeArgs &&
      this.nullability == other.nullability;

  @override
  // TODO(regis): Print nullability.
  String toString() => '(recursive #$id) $class_ $typeArgs';
}

class _RecursiveTypeRefHandle extends _TypeHandle {
  int id;

  _RecursiveTypeRefHandle._empty(Nullability nullability)
      : super(TypeTag.kRecursiveTypeRef, nullability);

  _RecursiveTypeRefHandle(this.id)
      : super(TypeTag.kRecursiveTypeRef, Nullability.legacy);

  @override
  bool get isCacheable => false;

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedUInt30(id);
  }

  @override
  void readContents(BufferedReader reader) {
    id = reader.readPackedUInt30();
  }

  @override
  int get hashCode => id;

  @override
  bool operator ==(other) =>
      other is _RecursiveTypeRefHandle && this.id == other.id;

  @override
  String toString() => 'recursive-ref #$id';
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
  // TODO(regis): Print nullability.
  String toString() => '$type ${name.name}';
}

class _FunctionTypeHandle extends _TypeHandle {
  static const int flagHasOptionalPositionalParams = 1 << 0;
  static const int flagHasOptionalNamedParams = 1 << 1;
  static const int flagHasTypeParams = 1 << 2;

  int functionTypeFlags = 0;
  List<NameAndType> typeParams;
  int numRequiredParams;
  List<_TypeHandle> positionalParams;
  List<NameAndType> namedParams;
  _TypeHandle returnType;

  _FunctionTypeHandle._empty(Nullability nullability)
      : super(TypeTag.kFunctionType, nullability);

  _FunctionTypeHandle(
      this.typeParams,
      this.numRequiredParams,
      this.positionalParams,
      this.namedParams,
      this.returnType,
      Nullability nullability)
      : super(TypeTag.kFunctionType, nullability) {
    assert(numRequiredParams <= positionalParams.length + namedParams.length);
    if (numRequiredParams < positionalParams.length) {
      assert(namedParams.isEmpty);
      functionTypeFlags |= flagHasOptionalPositionalParams;
    }
    if (namedParams.isNotEmpty) {
      assert(numRequiredParams == positionalParams.length);
      functionTypeFlags |= flagHasOptionalNamedParams;
    }
    if (typeParams.isNotEmpty) {
      functionTypeFlags |= flagHasTypeParams;
    }
  }

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedUInt30(functionTypeFlags);
    if ((functionTypeFlags & flagHasTypeParams) != 0) {
      new TypeParametersDeclaration(typeParams).write(writer);
    }
    writer.writePackedUInt30(positionalParams.length + namedParams.length);
    if (functionTypeFlags &
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
    functionTypeFlags = reader.readPackedUInt30();
    if ((functionTypeFlags & flagHasTypeParams) != 0) {
      typeParams = new TypeParametersDeclaration.read(reader).typeParams;
    } else {
      typeParams = const <NameAndType>[];
    }
    final int numParams = reader.readPackedUInt30();
    numRequiredParams = numParams;
    if ((functionTypeFlags &
            (flagHasOptionalPositionalParams | flagHasOptionalNamedParams)) !=
        0) {
      numRequiredParams = reader.readPackedUInt30();
    }
    final bool hasNamedParams =
        (functionTypeFlags & flagHasOptionalNamedParams) != 0;
    positionalParams = new List<_TypeHandle>.generate(
        hasNamedParams ? numRequiredParams : numParams,
        (_) => reader.readPackedObject());
    if (hasNamedParams) {
      namedParams = new List<NameAndType>.generate(
          numParams - numRequiredParams,
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
  bool get isCacheable {
    for (var param in positionalParams) {
      if (!param.isCacheable) {
        return false;
      }
    }
    for (var param in namedParams) {
      if (!param.type.isCacheable) {
        return false;
      }
    }
    if (!returnType.isCacheable) {
      return false;
    }
    return true;
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
  // TODO(regis): Print nullability.
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

abstract class _NameHandle extends ObjectHandle {
  static const int flagIsPublic = ObjectHandle.flagBit0;

  String get name;

  @override
  ObjectKind get kind => ObjectKind.kName;

  @override
  void indexStrings(StringWriter strings) {
    strings.put(name);
  }

  @override
  String toString() => "'$name'";
}

class _PublicNameHandle extends _NameHandle {
  String name;

  _PublicNameHandle._empty();

  _PublicNameHandle(this.name);

  @override
  int get flags => _NameHandle.flagIsPublic;

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedStringReference(name);
  }

  @override
  void readContents(BufferedReader reader) {
    name = reader.readPackedStringReference();
  }

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(other) =>
      other is _PublicNameHandle && this.name == other.name;

  @override
  String toString() => "'$name'";
}

class _PrivateNameHandle extends _NameHandle {
  _LibraryHandle library;
  String name;

  _PrivateNameHandle._empty();

  _PrivateNameHandle(this.library, this.name) {
    assert(library != null);
  }

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
    library._useCount += numCopies;
  }

  @override
  int get hashCode => _combineHashes(name.hashCode, library.hashCode);

  @override
  bool operator ==(other) =>
      other is _PrivateNameHandle &&
      this.name == other.name &&
      this.library == other.library;

  @override
  String toString() => "'$name'";
}

class _TypeArgumentsHandle extends ObjectHandle {
  List<_TypeHandle> args;

  _TypeArgumentsHandle._empty();

  _TypeArgumentsHandle(this.args);

  @override
  ObjectKind get kind => ObjectKind.kTypeArguments;

  @override
  bool get isCacheable {
    for (var arg in args) {
      if (!arg.isCacheable) {
        return false;
      }
    }
    return true;
  }

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedList(args);
  }

  @override
  void readContents(BufferedReader reader) {
    args = reader.readPackedList<_TypeHandle>();
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    args.forEach((t) {
      t._useCount += numCopies;
    });
  }

  @override
  int get hashCode => listHashCode(args);

  @override
  bool operator ==(other) =>
      other is _TypeArgumentsHandle && listEquals(this.args, other.args);

  @override
  String toString() => '< ${args.join(', ')} >';
}

class _ConstObjectHandle extends ObjectHandle {
  ConstTag tag;
  dynamic value;
  ObjectHandle type;
  int _hashCode = 0;

  _ConstObjectHandle._empty();

  _ConstObjectHandle(this.tag, this.value, [this.type]);

  @override
  ObjectKind get kind => ObjectKind.kConstObject;

  @override
  int get flags => tag.index * ObjectHandle.flagBit0;

  @override
  set flags(int value) {
    tag = ConstTag.values[value ~/ ObjectHandle.flagBit0];
    assert(tag != ConstTag.kInvalid);
  }

  bool get isCacheable => (tag != ConstTag.kInt) && (tag != ConstTag.kBool);

  @override
  void writeContents(BufferedWriter writer) {
    switch (tag) {
      case ConstTag.kInt:
        writer.writeSLEB128(value as int);
        break;
      case ConstTag.kDouble:
        writer.writeSLEB128(doubleToIntBits(value as double));
        break;
      case ConstTag.kBool:
        writer.writeByte((value as bool) ? 1 : 0);
        break;
      case ConstTag.kInstance:
        {
          final fieldValues = value as Map<ObjectHandle, ObjectHandle>;
          writer.writePackedObject(type);
          writer.writePackedUInt30(fieldValues.length);
          fieldValues.forEach((ObjectHandle field, ObjectHandle value) {
            writer.writePackedObject(field);
            writer.writePackedObject(value);
          });
        }
        break;
      case ConstTag.kList:
        {
          final elems = value as List<ObjectHandle>;
          writer.writePackedObject(type);
          writer.writePackedList(elems);
        }
        break;
      case ConstTag.kTearOff:
        {
          final target = value as ObjectHandle;
          writer.writePackedObject(target);
        }
        break;
      case ConstTag.kSymbol:
        {
          final name = value as ObjectHandle;
          writer.writePackedObject(name);
        }
        break;
      case ConstTag.kTearOffInstantiation:
        {
          final tearOff = value as ObjectHandle;
          writer.writePackedObject(tearOff);
          writer.writePackedObject(type as _TypeArgumentsHandle);
        }
        break;
      case ConstTag.kString:
        writer.writePackedStringReference(value as String);
        break;
      default:
        throw 'Unexpected constant tag: $tag';
    }
  }

  @override
  void readContents(BufferedReader reader) {
    switch (tag) {
      case ConstTag.kInt:
        value = reader.readSLEB128();
        break;
      case ConstTag.kDouble:
        value = intBitsToDouble(reader.readSLEB128());
        break;
      case ConstTag.kBool:
        value = reader.readByte() != 0;
        break;
      case ConstTag.kInstance:
        type = reader.readPackedObject();
        value = Map<ObjectHandle, ObjectHandle>.fromEntries(
            new List<MapEntry<ObjectHandle, ObjectHandle>>.generate(
                reader.readPackedUInt30(),
                (_) => new MapEntry<ObjectHandle, ObjectHandle>(
                    reader.readPackedObject(), reader.readPackedObject())));
        break;
      case ConstTag.kList:
        type = reader.readPackedObject();
        value = reader.readPackedList<ObjectHandle>();
        break;
      case ConstTag.kTearOff:
        value = reader.readPackedObject();
        break;
      case ConstTag.kSymbol:
        value = reader.readPackedObject();
        break;
      case ConstTag.kTearOffInstantiation:
        value = reader.readPackedObject();
        type = reader.readPackedObject();
        break;
      case ConstTag.kString:
        value = reader.readPackedStringReference();
        break;
      default:
        throw 'Unexpected constant tag: $tag';
    }
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    switch (tag) {
      case ConstTag.kInt:
      case ConstTag.kDouble:
      case ConstTag.kBool:
      case ConstTag.kString:
        break;
      case ConstTag.kInstance:
        {
          type._useCount += numCopies;
          final fieldValues = value as Map<ObjectHandle, ObjectHandle>;
          fieldValues.forEach((ObjectHandle field, ObjectHandle value) {
            field._useCount += numCopies;
            value?._useCount += numCopies;
          });
        }
        break;
      case ConstTag.kList:
        {
          final elems = value as List<ObjectHandle>;
          for (var elem in elems) {
            elem?._useCount += numCopies;
          }
          type._useCount += numCopies;
        }
        break;
      case ConstTag.kTearOff:
        {
          final target = value as ObjectHandle;
          target._useCount += numCopies;
        }
        break;
      case ConstTag.kSymbol:
        {
          final name = value as ObjectHandle;
          name._useCount += numCopies;
        }
        break;
      case ConstTag.kTearOffInstantiation:
        {
          final tearOff = value as ObjectHandle;
          tearOff._useCount += numCopies;
          if (type != null) {
            type._useCount += numCopies;
          }
        }
        break;
      default:
        throw 'Unexpected constant tag: $tag';
    }
  }

  @override
  int get hashCode {
    if (_hashCode != 0) {
      return _hashCode;
    }
    switch (tag) {
      case ConstTag.kInt:
      case ConstTag.kDouble:
      case ConstTag.kBool:
      case ConstTag.kTearOff:
      case ConstTag.kSymbol:
      case ConstTag.kString:
        return _hashCode = value.hashCode;
      case ConstTag.kInstance:
        {
          final fieldValues = value as Map<ObjectHandle, ObjectHandle>;
          return _hashCode =
              _combineHashes(type.hashCode, mapHashCode(fieldValues));
        }
        break;
      case ConstTag.kList:
        {
          final elems = value as List<ObjectHandle>;
          return _hashCode = _combineHashes(type.hashCode, listHashCode(elems));
        }
        break;
      case ConstTag.kTearOffInstantiation:
        return _hashCode = _combineHashes(value.hashCode, type.hashCode);
      default:
        throw 'Unexpected constant tag: $tag';
    }
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is _ConstObjectHandle && this.tag == other.tag) {
      switch (tag) {
        case ConstTag.kInt:
        case ConstTag.kBool:
        case ConstTag.kTearOff:
        case ConstTag.kSymbol:
        case ConstTag.kString:
          return this.value == other.value;
        case ConstTag.kDouble:
          return this.value.compareTo(other.value) == 0;
        case ConstTag.kInstance:
          return this.type == other.type && mapEquals(this.value, other.value);
        case ConstTag.kList:
          return this.type == other.type && listEquals(this.value, other.value);
        case ConstTag.kTearOffInstantiation:
          return this.type == other.type && this.value == other.value;
        default:
          throw 'Unexpected constant tag: $tag';
      }
    }
    return false;
  }

  @override
  String toString() {
    switch (tag) {
      case ConstTag.kInt:
      case ConstTag.kDouble:
      case ConstTag.kBool:
      case ConstTag.kSymbol:
        return 'const $value';
      case ConstTag.kInstance:
        return 'const $type $value';
      case ConstTag.kList:
        return 'const <$type> $value';
      case ConstTag.kTearOff:
        return 'const tear-off $value';
      case ConstTag.kTearOffInstantiation:
        return 'const $type $value';
      case ConstTag.kString:
        return "'$value'";
      default:
        throw 'Unexpected constant tag: $tag';
    }
  }
}

class _ArgDescHandle extends ObjectHandle {
  static const int flagHasNamedArgs = ObjectHandle.flagBit0;
  static const int flagHasTypeArgs = ObjectHandle.flagBit1;

  int _flags = 0;
  int numArguments;
  int numTypeArguments;
  List<_PublicNameHandle> argNames;

  _ArgDescHandle._empty();

  _ArgDescHandle(this.numArguments, this.numTypeArguments, this.argNames) {
    if (argNames.isNotEmpty) {
      _flags |= flagHasNamedArgs;
    }
    if (numTypeArguments > 0) {
      _flags |= flagHasTypeArgs;
    }
  }

  @override
  ObjectKind get kind => ObjectKind.kArgDesc;

  @override
  int get flags => _flags;

  @override
  set flags(int value) {
    _flags = value;
  }

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedUInt30(numArguments);
    if ((_flags & flagHasTypeArgs) != 0) {
      writer.writePackedUInt30(numTypeArguments);
    }
    if ((_flags & flagHasNamedArgs) != 0) {
      writer.writePackedList(argNames);
    }
  }

  @override
  void readContents(BufferedReader reader) {
    numArguments = reader.readPackedUInt30();
    numTypeArguments =
        ((_flags & flagHasTypeArgs) != 0) ? reader.readPackedUInt30() : 0;
    argNames = ((_flags & flagHasNamedArgs) != 0)
        ? reader.readPackedList<_PublicNameHandle>()
        : null;
  }

  @override
  void accountUsesForObjectCopies(int numCopies) {
    if (argNames != null) {
      for (var name in argNames) {
        name._useCount += numCopies;
      }
    }
  }

  @override
  int get hashCode => _combineHashes(
      numArguments, _combineHashes(numTypeArguments, listHashCode(argNames)));

  @override
  bool operator ==(other) =>
      other is _ArgDescHandle &&
      this.numArguments == other.numArguments &&
      this.numTypeArguments == other.numTypeArguments &&
      listEquals(this.argNames, other.argNames);

  @override
  String toString() =>
      'ArgDesc num-args $numArguments, num-type-args $numTypeArguments, names $argNames';
}

class _ScriptHandle extends ObjectHandle {
  static const int flagHasSourceFile = ObjectHandle.flagBit0;

  int _flags = 0;
  ObjectHandle uri;
  SourceFile _source;
  ForwardReference<SourceFile> _sourceForwardReference;

  _ScriptHandle._empty();

  _ScriptHandle(this.uri, this._source) {
    if (_source != null) {
      _flags |= flagHasSourceFile;
    }
  }

  @override
  ObjectKind get kind => ObjectKind.kScript;

  // Include scripts into index table if there are more than 1 reference
  // in order to make sure there are no duplicated script objects within the
  // same bytecode component.
  @override
  bool get shouldBeIncludedIntoIndexTable => _useCount > 1;

  @override
  int get flags => _flags;

  @override
  set flags(int value) {
    _flags = value;
  }

  SourceFile get source {
    // Unwrap forward reference on the first access.
    if (_sourceForwardReference != null) {
      _source = _sourceForwardReference.get();
      _sourceForwardReference = null;
    }
    return _source;
  }

  set source(SourceFile sourceFile) {
    _source = sourceFile;
    if (_source != null) {
      _flags |= flagHasSourceFile;
    } else {
      _flags &= ~flagHasSourceFile;
    }
  }

  @override
  void writeContents(BufferedWriter writer) {
    writer.writePackedObject(uri);
    if ((_flags & flagHasSourceFile) != 0) {
      writer.writeLinkOffset(source);
    }
  }

  @override
  void readContents(BufferedReader reader) {
    uri = reader.readPackedObject();
    if ((_flags & flagHasSourceFile) != 0) {
      // Script handles in the object table may be read before source files,
      // so use forwarding reference here.
      _sourceForwardReference =
          reader.readLinkOffsetAsForwardReference<SourceFile>();
    }
  }

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(other) => other is _ScriptHandle && this.uri == other.uri;

  @override
  String toString() => "$uri${source != null ? '($source)' : ''}";
}

class ObjectTable implements ObjectWriter, ObjectReader {
  /// Object is added to an index table if it is used more than this
  /// number of times.
  static const int indexTableUseCountThreshold = 3;

  final List<ObjectHandle> _objects = new List<ObjectHandle>();
  final Map<ObjectHandle, ObjectHandle> _canonicalizationCache =
      <ObjectHandle, ObjectHandle>{};
  final Map<Node, ObjectHandle> _nodeCache = <Node, ObjectHandle>{};
  final Map<String, _PublicNameHandle> _publicNames =
      <String, _PublicNameHandle>{};
  List<ObjectHandle> _indexTable;
  _TypeHandle _dynamicType;
  _TypeHandle _voidType;
  _NodeVisitor _nodeVisitor;

  ObjectTable(CoreTypes coreTypes) {
    _dynamicType = getOrAddObject(new _DynamicTypeHandle());
    _voidType = getOrAddObject(new _VoidTypeHandle());
    _nodeVisitor = new _NodeVisitor(this, coreTypes);
  }

  ObjectHandle getHandle(Node node) {
    if (node == null) {
      return null;
    }
    ObjectHandle handle = _nodeCache[node];
    if (handle == null) {
      handle = node.accept(_nodeVisitor);
      if (handle != null && handle.isCacheable) {
        _nodeCache[node] = handle;
      }
    } else {
      ++handle._useCount;
    }
    return handle;
  }

  List<ObjectHandle> getHandles(List<Node> nodes) {
    final handles = new List<ObjectHandle>(nodes.length);
    for (int i = 0; i < nodes.length; ++i) {
      handles[i] = getHandle(nodes[i]);
    }
    return handles;
  }

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

  ObjectHandle getPublicNameHandle(String name) {
    assert(name != null);
    _PublicNameHandle handle = _publicNames[name];
    if (handle == null) {
      handle = getOrAddObject(new _PublicNameHandle(name));
      _publicNames[name] = handle;
    }
    return handle;
  }

  ObjectHandle getNameHandle(Library library, String name) {
    if (library == null) {
      return getPublicNameHandle(name);
    }
    assert(name != null);
    final libraryHandle = library != null ? getHandle(library) : null;
    return getOrAddObject(new _PrivateNameHandle(libraryHandle, name));
  }

  List<_PublicNameHandle> getPublicNameHandles(List<String> names) {
    if (names.isEmpty) {
      return const <_PublicNameHandle>[];
    }
    final handles = new List<_PublicNameHandle>(names.length);
    for (int i = 0; i < names.length; ++i) {
      handles[i] = getPublicNameHandle(names[i]);
    }
    return handles;
  }

  ObjectHandle getConstStringHandle(String value) =>
      getOrAddObject(new _ConstObjectHandle(ConstTag.kString, value));

  List<ObjectHandle> getConstStringHandles(List<String> values) {
    if (values.isEmpty) {
      return const <ObjectHandle>[];
    }
    final handles = new List<ObjectHandle>(values.length);
    for (int i = 0; i < values.length; ++i) {
      handles[i] = getConstStringHandle(values[i]);
    }
    return handles;
  }

  ObjectHandle getSelectorNameHandle(Name name,
      {bool isGetter: false, bool isSetter: false}) {
    return getNameHandle(
        name.library, mangleSelectorName(name.name, isGetter, isSetter));
  }

  ObjectHandle getTopLevelClassHandle(Library library) {
    final libraryHandle = getHandle(library);
    final name = getPublicNameHandle(topLevelClassName);
    return getOrAddObject(new _ClassHandle(libraryHandle, name));
  }

  ObjectHandle getMemberHandle(Member member,
      {bool isGetter: false, bool isSetter: false}) {
    final parent = member.parent;
    ObjectHandle classHandle;
    if (parent is Class) {
      classHandle = getHandle(parent);
    } else if (parent is Library) {
      classHandle = getTopLevelClassHandle(parent);
    } else {
      throw "Unexpected Member's parent ${parent.runtimeType} $parent";
    }
    final nameHandle = getNameHandle(
        member.name.library, mangleMemberName(member, isGetter, isSetter));
    bool isField = member is Field && !isGetter && !isSetter;
    bool isConstructor =
        member is Constructor || (member is Procedure && member.isFactory);
    return getOrAddObject(
        new _MemberHandle(classHandle, nameHandle, isField, isConstructor));
  }

  ObjectHandle getTypeArgumentsHandle(List<DartType> typeArgs) {
    if (typeArgs == null) {
      return null;
    }
    final handles = new List<_TypeHandle>(typeArgs.length);
    for (int i = 0; i < typeArgs.length; ++i) {
      handles[i] = getHandle(typeArgs[i]) as _TypeHandle;
    }
    return getOrAddObject(new _TypeArgumentsHandle(handles));
  }

  ObjectHandle getArgDescHandle(int numArguments,
      [int numTypeArguments = 0, List<String> argNames = const <String>[]]) {
    return getOrAddObject(new _ArgDescHandle(
        numArguments, numTypeArguments, getPublicNameHandles(argNames)));
  }

  ObjectHandle getArgDescHandleByArguments(Arguments args,
      {bool hasReceiver: false, bool isFactory: false}) {
    List<_PublicNameHandle> argNames = const <_PublicNameHandle>[];
    final namedArguments = args.named;
    if (namedArguments.isNotEmpty) {
      argNames = new List<_PublicNameHandle>(namedArguments.length);
      for (int i = 0; i < namedArguments.length; ++i) {
        argNames[i] = getPublicNameHandle(namedArguments[i].name);
      }
    }
    final int numArguments = args.positional.length +
        args.named.length +
        (hasReceiver ? 1 : 0) +
        // VM expects that type arguments vector passed to a factory
        // constructor is counted in numArguments, and not counted in
        // numTypeArgs.
        // TODO(alexmarkov): Clean this up.
        (isFactory ? 1 : 0);
    final int numTypeArguments = isFactory ? 0 : args.types.length;
    return getOrAddObject(
        new _ArgDescHandle(numArguments, numTypeArguments, argNames));
  }

  ObjectHandle getScriptHandle(Uri uri, SourceFile source) {
    ObjectHandle uriHandle = getPublicNameHandle(uri.toString());
    _ScriptHandle handle = getOrAddObject(new _ScriptHandle(uriHandle, source));
    if (handle.source == null && source != null) {
      handle.source = source;
    }
    return handle;
  }

  List<NameAndType> getTypeParameterHandles(List<TypeParameter> typeParams) {
    if (typeParams.isEmpty) {
      return const <NameAndType>[];
    }
    final namesAndBounds = new List<NameAndType>();
    for (TypeParameter tp in typeParams) {
      namesAndBounds.add(
          new NameAndType(getPublicNameHandle(tp.name), getHandle(tp.bound)));
    }
    return namesAndBounds;
  }

  void declareClosure(
      FunctionNode function, Member enclosingMember, int closureIndex) {
    final handle = getOrAddObject(
        new _ClosureHandle(getHandle(enclosingMember), closureIndex));
    _nodeCache[function] = handle;
  }

  ObjectHandle getOrAddObject(ObjectHandle obj) {
    assert(obj._useCount == 0);
    ObjectHandle canonical = _canonicalizationCache[obj];
    if (canonical == null) {
      assert(_indexTable == null);
      _objects.add(obj);
      _canonicalizationCache[obj] = obj;
      canonical = obj;
    }
    ++canonical._useCount;
    return canonical;
  }

  void allocateIndexTable() {
    int tableSize = 1; // Reserve invalid entry.
    for (var obj in _objects.reversed) {
      assert(obj._reference == null);
      if (obj.shouldBeIncludedIntoIndexTable) {
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
    final start = writer.offset;
    if (BytecodeSizeStatistics.objectTableStats.isEmpty) {
      for (var kind in ObjectKind.values) {
        BytecodeSizeStatistics.objectTableStats
            .add(new NamedEntryStatistics(objectKindToString(kind)));
      }
    }

    BufferedWriter contentsWriter = new BufferedWriter.fromWriter(writer);
    List<int> offsets = new List<int>(_indexTable.length);

    for (int i = 0; i < _indexTable.length; ++i) {
      offsets[i] = contentsWriter.offset;
      _indexTable[i]._write(contentsWriter);

      final entryStat =
          BytecodeSizeStatistics.objectTableStats[_indexTable[i].kind.index];
      entryStat.size += (contentsWriter.offset - offsets[i]);
      ++entryStat.count;
    }

    writer.writePackedUInt30(_indexTable.length);
    writer.writePackedUInt30(contentsWriter.offset);
    writer.appendWriter(contentsWriter);
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

    BytecodeSizeStatistics.objectTableSize += (writer.offset - start);
    BytecodeSizeStatistics.objectTableEntriesCount += _indexTable.length;
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
  final CoreTypes coreTypes;
  final _typeParameters = <TypeParameter, ObjectHandle>{};
  final Map<DartType, int> _recursiveTypeIds = <DartType, int>{};
  final recursiveTypesValidator;

  _NodeVisitor(this.objectTable, this.coreTypes)
      : recursiveTypesValidator = new RecursiveTypesValidator(coreTypes);

  @override
  ObjectHandle defaultNode(Node node) =>
      throw 'Unexpected node ${node.runtimeType} $node';

  @override
  ObjectHandle visitLibrary(Library node) {
    final uri = objectTable.getConstStringHandle(node.importUri.toString());
    return objectTable.getOrAddObject(new _LibraryHandle(uri));
  }

  @override
  ObjectHandle visitClass(Class node) {
    final ObjectHandle library = objectTable.getHandle(node.enclosingLibrary);
    final name = node.name.startsWith('_')
        ? objectTable.getOrAddObject(new _PrivateNameHandle(library, node.name))
        : objectTable.getPublicNameHandle(node.name);
    return objectTable.getOrAddObject(new _ClassHandle(library, name));
  }

  @override
  ObjectHandle defaultMember(Member node) => objectTable.getMemberHandle(node);

  @override
  ObjectHandle visitDynamicType(DynamicType node) => objectTable._dynamicType;

  @override
  ObjectHandle visitVoidType(VoidType node) => objectTable._voidType;

  @override
  ObjectHandle visitNeverType(NeverType node) =>
      objectTable.getOrAddObject(new _NeverTypeHandle(node.nullability));

  @override
  ObjectHandle visitBottomType(BottomType node) =>
      // Map Bottom type to Null type until not emitted by CFE anymore.
      objectTable.getHandle(coreTypes.nullType);

  @override
  ObjectHandle visitInterfaceType(InterfaceType node) {
    final classHandle = objectTable.getHandle(node.classNode);
    if (!hasInstantiatorTypeArguments(node.classNode)) {
      return objectTable
          .getOrAddObject(new _SimpleTypeHandle(classHandle, node.nullability));
    }

    // Non-finalized types are not recursive, but finalization of
    // generic types includes flattening of type arguments and types could
    // become recursive. Consider the following example:
    //
    //  class Base<T> {}
    //  class Foo<T> extends Base<Foo<T>> {}
    //
    //  Foo<int> is not recursive, but finalized type is recursive:
    //  Foo<int>* = Foo [ Base [ Foo<int>* ], int ]
    //
    // Object table serialization/deserialization cannot handle cycles between
    // objects, so recursive types require extra care when serializing.
    // Back references to the already serialized types are represented as
    // _RecursiveTypeRefHandle objects, which are only valid in the context
    // of enclosing top-level _RecursiveGenericType.
    //
    int recursiveId = _recursiveTypeIds[node];
    if (recursiveId != null) {
      return objectTable
          .getOrAddObject(new _RecursiveTypeRefHandle(recursiveId));
    }

    recursiveTypesValidator.validateType(node);

    final isRecursive = recursiveTypesValidator.isRecursive(node);
    if (isRecursive) {
      recursiveId = _recursiveTypeIds.length;
      _recursiveTypeIds[node] = recursiveId;
    }

    List<DartType> instantiatorArgs =
        getInstantiatorTypeArguments(node.classNode, node.typeArguments);
    ObjectHandle typeArgsHandle =
        objectTable.getTypeArgumentsHandle(instantiatorArgs);

    final result = objectTable.getOrAddObject(isRecursive
        ? new _RecursiveGenericTypeHandle(
            recursiveId, classHandle, typeArgsHandle, node.nullability)
        : new _GenericTypeHandle(
            classHandle, typeArgsHandle, node.nullability));

    if (isRecursive) {
      _recursiveTypeIds.remove(node);
    }

    return result;
  }

  @override
  ObjectHandle visitFutureOrType(FutureOrType node) {
    final classNode = coreTypes.deprecatedFutureOrClass;
    final classHandle = objectTable.getHandle(classNode);
    List<DartType> instantiatorArgs =
        getInstantiatorTypeArguments(classNode, [node.typeArgument]);
    ObjectHandle typeArgsHandle =
        objectTable.getTypeArgumentsHandle(instantiatorArgs);
    final result = objectTable.getOrAddObject(
        new _GenericTypeHandle(classHandle, typeArgsHandle, node.nullability));
    return result;
  }

  @override
  ObjectHandle visitTypeParameterType(TypeParameterType node) {
    final param = node.parameter;
    final handle = _typeParameters[param];
    if (handle != null) {
      final typeParameterHandle = handle as _TypeParameterHandle;
      if (typeParameterHandle.nullability == node.nullability) {
        return handle;
      }
      return objectTable.getOrAddObject(new _TypeParameterHandle(
          typeParameterHandle.parent,
          typeParameterHandle.indexInParent,
          node.nullability));
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
    return objectTable.getOrAddObject(new _TypeParameterHandle(
        parentHandle, indexInParent, node.nullability));
  }

  @override
  ObjectHandle visitFunctionType(FunctionType node) {
    final int numEnclosingTypeParameters = _typeParameters.length;
    for (int i = 0; i < node.typeParameters.length; ++i) {
      _typeParameters[node.typeParameters[i]] = objectTable.getOrAddObject(
          new _TypeParameterHandle(
              null, numEnclosingTypeParameters + i, Nullability.legacy));
      // Nullability.legacy is a dummy value, since TypeParameter does not
      // specify nullability, only the reference to a TypeParameter does, i.e.
      // TypeParameterType.
    }

    final positionalParams = new List<_TypeHandle>();
    for (var param in node.positionalParameters) {
      positionalParams.add(objectTable.getHandle(param));
    }
    final namedParams = new List<NameAndType>();
    for (var param in node.namedParameters) {
      namedParams.add(new NameAndType(
          objectTable.getPublicNameHandle(param.name),
          objectTable.getHandle(param.type)));
    }
    final returnType = objectTable.getHandle(node.returnType);

    final result = objectTable.getOrAddObject(new _FunctionTypeHandle(
        objectTable.getTypeParameterHandles(node.typeParameters),
        node.requiredParameterCount,
        positionalParams,
        namedParams,
        returnType,
        node.nullability));

    for (int i = 0; i < node.typeParameters.length; ++i) {
      _typeParameters.remove(node.typeParameters[i]);
    }

    return result;
  }

  @override
  ObjectHandle visitTypedefType(TypedefType node) =>
      objectTable.getHandle(node.unalias);

  @override
  ObjectHandle visitNullConstant(NullConstant node) => null;

  @override
  ObjectHandle visitBoolConstant(BoolConstant node) => objectTable
      .getOrAddObject(new _ConstObjectHandle(ConstTag.kBool, node.value));

  @override
  ObjectHandle visitIntConstant(IntConstant node) => objectTable
      .getOrAddObject(new _ConstObjectHandle(ConstTag.kInt, node.value));

  @override
  ObjectHandle visitDoubleConstant(DoubleConstant node) => objectTable
      .getOrAddObject(new _ConstObjectHandle(ConstTag.kDouble, node.value));

  @override
  ObjectHandle visitStringConstant(StringConstant node) =>
      objectTable.getConstStringHandle(node.value);

  @override
  ObjectHandle visitSymbolConstant(SymbolConstant node) =>
      objectTable.getOrAddObject(new _ConstObjectHandle(
          ConstTag.kSymbol,
          objectTable.getNameHandle(
              node.libraryReference?.asLibrary, node.name)));

  @override
  ObjectHandle visitListConstant(ListConstant node) =>
      objectTable.getOrAddObject(new _ConstObjectHandle(
          ConstTag.kList,
          objectTable.getHandles(node.entries),
          objectTable.getHandle(node.typeArgument)));

  @override
  ObjectHandle visitInstanceConstant(InstanceConstant node) =>
      objectTable.getOrAddObject(new _ConstObjectHandle(
          ConstTag.kInstance,
          node.fieldValues.map<ObjectHandle, ObjectHandle>(
              (Reference fieldRef, Constant value) => new MapEntry(
                  objectTable.getHandle(fieldRef.asField),
                  objectTable.getHandle(value))),
          objectTable.getHandle(new InterfaceType(
              node.classNode, Nullability.legacy, node.typeArguments))));

  @override
  ObjectHandle visitTearOffConstant(TearOffConstant node) =>
      objectTable.getOrAddObject(new _ConstObjectHandle(
          ConstTag.kTearOff, objectTable.getHandle(node.procedure)));

  @override
  ObjectHandle visitTypeLiteralConstant(TypeLiteralConstant node) =>
      objectTable.getHandle(node.type);

  @override
  ObjectHandle visitPartialInstantiationConstant(
          PartialInstantiationConstant node) =>
      objectTable.getOrAddObject(new _ConstObjectHandle(
          ConstTag.kTearOffInstantiation,
          objectTable.getHandle(node.tearOffConstant),
          objectTable.getTypeArgumentsHandle(node.types)));
}

int _combineHashes(int hash1, int hash2) =>
    (((hash1 * 31) & 0x3fffffff) + hash2) & 0x3fffffff;
