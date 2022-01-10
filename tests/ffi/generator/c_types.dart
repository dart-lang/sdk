// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'utils.dart';

const bool_ = FundamentalType(PrimitiveType.bool_);
const int8 = FundamentalType(PrimitiveType.int8);
const int16 = FundamentalType(PrimitiveType.int16);
const int32 = FundamentalType(PrimitiveType.int32);
const int64 = FundamentalType(PrimitiveType.int64);
const uint8 = FundamentalType(PrimitiveType.uint8);
const uint16 = FundamentalType(PrimitiveType.uint16);
const uint32 = FundamentalType(PrimitiveType.uint32);
const uint64 = FundamentalType(PrimitiveType.uint64);
const intptr = FundamentalType(PrimitiveType.intptr);
const float = FundamentalType(PrimitiveType.float);
const double_ = FundamentalType(PrimitiveType.double_);

enum PrimitiveType {
  bool_,
  int8,
  int16,
  int32,
  int64,
  uint8,
  uint16,
  uint32,
  uint64,
  intptr,
  float,
  double_,
}

const primitiveNames = [
  "bool",
  "int8",
  "int16",
  "int32",
  "int64",
  "uint8",
  "uint16",
  "uint32",
  "uint64",
  "intptr",
  "float",
  "double",
];

const intptrSize = -1;
const primitiveSizesInBytes = [1, 1, 2, 4, 8, 1, 2, 4, 8, intptrSize, 4, 8];

abstract class CType {
  String get cType;
  String get dartCType;
  String get dartType;
  String get dartStructFieldAnnotation;

  /// Has a known [size] that is the same for all architectures.
  bool get hasSize;

  /// Get a size in bytes that is the same on all architectures.
  int get size;

  /// All members have a floating point type.
  bool get isOnlyFloatingPoint;

  /// All members have a integer type.
  bool get isOnlyInteger;

  /// All members have a bool type.
  bool get isOnlyBool;

  String toString() => dartCType;

  const CType();
}

class FundamentalType extends CType {
  final PrimitiveType primitive;

  const FundamentalType(this.primitive);

  bool get isBool => primitive == PrimitiveType.bool_;
  bool get isFloatingPoint =>
      primitive == PrimitiveType.float || primitive == PrimitiveType.double_;
  bool get isInteger => !isFloatingPoint && !isBool;
  bool get isOnlyFloatingPoint => isFloatingPoint;
  bool get isOnlyInteger => isInteger;
  bool get isOnlyBool => isBool;
  bool get isUnsigned =>
      primitive == PrimitiveType.bool_ ||
      primitive == PrimitiveType.uint8 ||
      primitive == PrimitiveType.uint16 ||
      primitive == PrimitiveType.uint32 ||
      primitive == PrimitiveType.uint64;
  bool get isSigned => !isUnsigned;

  String get name => primitiveNames[primitive.index];

  String get cType => "${name}${isInteger ? "_t" : ""}";
  String get dartCType => name.upperCaseFirst();
  String get dartType {
    if (isInteger) return 'int';
    if (isOnlyFloatingPoint) return 'double';
    if (isBool) return 'bool';
    throw 'Unknown type $primitive';
  }

  String get dartStructFieldAnnotation => "@${dartCType}()";
  bool get hasSize => primitive != PrimitiveType.intptr;
  int get size {
    if (!hasSize) {
      throw "Size unknown.";
    }
    return primitiveSizesInBytes[primitive.index];
  }
}

class PointerType extends CType {
  final CType pointerTo;

  PointerType(this.pointerTo);

  String get cType => "${pointerTo.cType}*";
  String get dartCType => "Pointer<${pointerTo.dartCType}>";
  String get dartType => "Pointer<${pointerTo.dartType}>";
  String get dartStructFieldAnnotation => "";
  bool get hasSize => false;
  int get size => throw "Size unknown";

  bool get isOnlyFloatingPoint => false;
  bool get isOnlyInteger => true;
  bool get isOnlyBool => false;
}

/// Used to give [StructType] fields and [FunctionType] arguments names.
class Member {
  final CType type;
  final String name;

  Member(this.type, this.name);

  String dartStructField(bool nnbd) {
    final modifier = nnbd ? "external" : "";
    return "${type.dartStructFieldAnnotation} $modifier ${type.dartType} $name;";
  }

  String get cStructField {
    String postFix = "";
    if (type is FixedLengthArrayType) {
      final dimensions = (type as FixedLengthArrayType).dimensions;
      postFix = "[${dimensions.join("][")}]";
    }
    return "${type.cType} $name$postFix;";
  }

  String toString() => "$type $name";
}

List<Member> generateMemberNames(List<CType> memberTypes) {
  int index = 0;
  List<Member> result = [];
  for (final type in memberTypes) {
    result.add(Member(type, "a$index"));
    index++;
  }
  return result;
}

abstract class CompositeType extends CType {
  final List<Member> members;

  /// To disambiguate same size structs.
  final String suffix;

  /// To override names.
  final String overrideName;

  CompositeType(List<CType> memberTypes)
      : this.members = generateMemberNames(memberTypes),
        this.suffix = "",
        this.overrideName = "";
  CompositeType.disambiguate(List<CType> memberTypes, this.suffix)
      : this.members = generateMemberNames(memberTypes),
        this.overrideName = "";
  CompositeType.override(List<CType> memberTypes, this.overrideName)
      : this.members = generateMemberNames(memberTypes),
        this.suffix = "";

  List<CType> get memberTypes => members.map((a) => a.type).toList();

  String get name;

  String get cType => name;
  String get dartCType => name;
  String get dartType => name;
  String get dartStructFieldAnnotation => "";
  String get cKeyword;
  String get dartSuperClass;

  bool get isOnlyFloatingPoint =>
      memberTypes.every((e) => e.isOnlyFloatingPoint);
  bool get isOnlyInteger => memberTypes.every((e) => e.isOnlyInteger);
  bool get isOnlyBool => memberTypes.every((e) => e.isOnlyBool);

  bool get isMixed => !isOnlyInteger && !isOnlyFloatingPoint && !isOnlyBool;

  bool get hasNestedStructs =>
      members.map((e) => e.type is StructType).contains(true);

  bool get hasInlineArrays =>
      members.map((e) => e.type is FixedLengthArrayType).contains(true);

  bool get hasMultiDimensionalInlineArrays => members
      .map((e) => e.type)
      .whereType<FixedLengthArrayType>()
      .where((e) => e.isMulti)
      .isNotEmpty;
}

class StructType extends CompositeType {
  final int? packing;

  StructType(List<CType> memberTypes, {int? this.packing}) : super(memberTypes);
  StructType.disambiguate(List<CType> memberTypes, String suffix,
      {int? this.packing})
      : super.disambiguate(memberTypes, suffix);
  StructType.override(List<CType> memberTypes, String overrideName,
      {int? this.packing})
      : super.override(memberTypes, overrideName);

  String get cKeyword => "struct";
  String get dartSuperClass => "Struct";

  bool get hasSize => memberTypes.every((e) => e.hasSize) && !hasPadding;
  int get size => memberTypes.fold(0, (int acc, e) => acc + e.size);

  bool get hasPacking => packing != null;

  bool get hasPadding {
    if (members.length < 2) {
      return false;
    }
    if (packing == 1) {
      return false;
    }

    /// Rough approximation, to not redo all ABI logic here.
    return members[0].type.size < members[1].type.size;
  }

  /// All members have the same type.
  bool get isHomogeneous => memberTypes.toSet().length == 1;

  String get name {
    String result = dartSuperClass;
    if (overrideName != "") {
      return result + overrideName;
    }
    if (hasSize) {
      result += "${size}Byte" + (size != 1 ? "s" : "");
    }
    if (hasPacking) {
      result += "Packed";
      if (packing! > 1) {
        result += "$packing";
      }
    }
    if (hasNestedStructs) {
      result += "Nested";
    }
    if (hasInlineArrays) {
      result += "InlineArray";
      if (hasMultiDimensionalInlineArrays) {
        result += "MultiDimensional";
      }
    }
    if (members.length == 0) {
      // No suffix.
    } else if (hasPadding) {
      result += "Alignment${memberTypes[1].dartCType}";
    } else if (isHomogeneous && members.length > 1 && !hasNestedStructs) {
      result += "Homogeneous${memberTypes.first.dartCType}";
    } else if (isOnlyFloatingPoint) {
      result += "Float";
    } else if (isOnlyInteger) {
      result += "Int";
    } else if (isOnlyBool) {
      result += "Bool";
    } else {
      result += "Mixed";
    }
    result += suffix;
    return result;
  }
}

class UnionType extends CompositeType {
  UnionType(List<CType> memberTypes) : super(memberTypes);

  String get cKeyword => "union";
  String get dartSuperClass => "Union";

  bool get hasSize => memberTypes.every((e) => e.hasSize);
  int get size => memberTypes.fold(0, (int acc, e) => math.max(acc, e.size));

  String get name {
    String result = dartSuperClass;
    if (overrideName != "") {
      return result + overrideName;
    }
    if (hasSize) {
      result += "${size}Byte" + (size != 1 ? "s" : "");
    }
    if (hasNestedStructs) {
      result += "Nested";
    }
    if (hasInlineArrays) {
      result += "InlineArray";
      if (hasMultiDimensionalInlineArrays) {
        result += "MultiDimensional";
      }
    }
    if (members.length == 0) {
      // No suffix.
    } else if (isOnlyFloatingPoint) {
      result += "Float";
    } else if (isOnlyInteger) {
      result += "Int";
    } else {
      result += "Mixed";
    }
    result += suffix;
    return result;
  }
}

class FixedLengthArrayType extends CType {
  final CType elementType;
  final int length;

  FixedLengthArrayType(this.elementType, this.length);

  factory FixedLengthArrayType.multi(CType elementType, List<int> dimensions) {
    if (dimensions.length == 1) {
      return FixedLengthArrayType(elementType, dimensions.single);
    }

    final remainingDimensions = dimensions.sublist(1);
    final nestedArray =
        FixedLengthArrayType.multi(elementType, remainingDimensions);
    return FixedLengthArrayType(nestedArray, dimensions.first);
  }

  String get cType => elementType.cType;
  String get dartCType => "Array<${elementType.dartCType}>";
  String get dartType => "Array<${elementType.dartCType}>";

  String get dartStructFieldAnnotation {
    if (dimensions.length > 5) {
      return "@Array.multi([${dimensions.join(", ")}])";
    }
    return "@Array(${dimensions.join(", ")})";
  }

  List<int> get dimensions {
    final elementType = this.elementType;
    if (elementType is FixedLengthArrayType) {
      return [length, ...elementType.dimensions];
    }
    return [length];
  }

  bool get isMulti => elementType is FixedLengthArrayType;

  bool get hasSize => elementType.hasSize;
  int get size => elementType.size * length;

  bool get isOnlyFloatingPoint => elementType.isOnlyFloatingPoint;
  bool get isOnlyInteger => elementType.isOnlyInteger;
  bool get isOnlyBool => elementType.isOnlyBool;
}

class FunctionType extends CType {
  final List<Member> arguments;
  final CType returnValue;
  final String reason;

  List<CType> get argumentTypes => arguments.map((a) => a.type).toList();

  FunctionType(List<CType> argumentTypes, this.returnValue, this.reason)
      : this.arguments = generateMemberNames(argumentTypes);

  String get cType =>
      throw "Are not represented without function or variable name in C.";

  String get dartCType {
    final argumentsDartCType = argumentTypes.map((e) => e.dartCType).join(", ");
    return "${returnValue.dartCType} Function($argumentsDartCType)";
  }

  String get dartType {
    final argumentsDartType = argumentTypes.map((e) => e.dartType).join(", ");
    return "${returnValue.dartType} Function($argumentsDartType)";
  }

  String get dartStructFieldAnnotation => throw "No nested function pointers.";

  bool get hasSize => false;
  int get size => throw "Unknown size.";

  bool get isOnlyFloatingPoint => throw "Not implemented";
  bool get isOnlyInteger => throw "Not implemented";
  bool get isOnlyBool => throw "Not implemented";

  /// Group consecutive [arguments] by same type.
  ///
  /// Used for naming.
  List<List<Member>> get argumentsGrouped {
    List<List<Member>> result = [];
    for (final a in arguments) {
      if (result.isEmpty) {
        result.add([a]);
      } else if (result.last.first.type.dartCType == a.type.dartCType) {
        result.last.add(a);
      } else {
        result.add([a]);
      }
    }
    return result;
  }

  /// A suitable name based on the signature.
  String get cName {
    String result = "";
    if (arguments.containsComposites && returnValue is FundamentalType) {
      result = "Pass";
    } else if (returnValue is StructType &&
        argumentTypes.contains(returnValue)) {
      result = "ReturnStructArgument";
    } else if (returnValue is UnionType &&
        argumentTypes.contains(returnValue)) {
      result = "ReturnUnionArgument";
    } else if (returnValue is StructType) {
      if (arguments.length == (returnValue as StructType).members.length) {
        return "Return${returnValue.dartCType}";
      }
    } else if (returnValue is UnionType && arguments.length == 1) {
      return "Return${returnValue.dartCType}";
    } else {
      result = "Uncategorized";
    }

    for (final group in argumentsGrouped) {
      result += group.first.type.dartCType;
      if (group.length > 1) {
        result += "x${group.length}";
      }
    }
    return result.limitTo(50);
  }

  String get dartTestName => "test$cName";

  String get dartName => cName.lowerCaseFirst();

  /// Only valid for [TestType.structReturnArgument].
  Member get structReturnArgument =>
      arguments.firstWhere((a) => a.type == returnValue);
}

extension MemberList on List<Member> {
  bool get containsComposites =>
      map((m) => m.type is CompositeType).contains(true);
}
