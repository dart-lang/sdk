// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enum values used for identifying different kinds of serialized data.
///
/// This is used to for debugging data inconsistencies between serialization
/// and deserialization.
enum DataKind {
  bool,
  uint30,
  string,
  enumValue,
  uri,
  libraryNode,
  classNode,
  extensionTypeDeclarationNode,
  typedefNode,
  memberNode,
  treeNode,
  typeParameterNode,
  dartType,
  dartTypeNode,
  sourceSpan,
  constant,
  import,
  double,
  int,
}

/// Enum used for identifying the enclosing entity of a member in serialization.
enum MemberContextKind { library, cls }

/// Enum used for identifying [Local] subclasses in serialization.
enum LocalKind {
  jLocal,
  thisLocal,
  boxLocal,
  anonymousClosureLocal,
  typeVariableLocal,
}

/// Class used for encoding tags in [ObjectDataSink] and [ObjectDataSource].
class Tag {
  final String value;

  Tag(this.value);

  @override
  int get hashCode => value.hashCode * 13;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Tag) return false;
    return value == other.value;
  }

  @override
  String toString() => 'Tag($value)';
}

/// Enum used for identifying [DartType] subclasses in serialization.
enum DartTypeKind {
  none,
  legacyType,
  nullableType,
  neverType,
  voidType,
  typeVariable,
  functionTypeVariable,
  functionType,
  interfaceType,
  recordType,
  dynamicType,
  erasedType,
  anyType,
  futureOr,
}

/// Enum used for identifying [ir.DartType] subclasses in serialization.
enum DartTypeNodeKind {
  none,
  voidType,
  typeParameterType,
  functionType,
  functionTypeVariable,
  interfaceType,
  recordType,
  extensionType,
  typedef,
  dynamicType,
  invalidType,
  thisInterfaceType,
  exactInterfaceType,
  neverType,
  futureOrType,
  nullType,
}

const String functionTypeNodeTag = 'function-type-node';
