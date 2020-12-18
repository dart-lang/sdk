// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'utils.dart';

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
const primitiveSizesInBytes = [1, 2, 4, 8, 1, 2, 4, 8, intptrSize, 4, 8];

abstract class CType {
  String get cType;
  String get dartCType;
  String get dartType;
  String get dartStructFieldAnnotation;

  /// Has a known [size] that is the same for all architectures.
  bool get hasSize;

  /// Get a size in bytes that is the same on all architectures.
  int get size;

  String toString() => dartCType;

  const CType();
}

class FundamentalType extends CType {
  final PrimitiveType primitive;

  const FundamentalType(this.primitive);

  bool get isFloatingPoint =>
      primitive == PrimitiveType.float || primitive == PrimitiveType.double_;
  bool get isInteger => !isFloatingPoint;
  bool get isUnsigned =>
      primitive == PrimitiveType.uint8 ||
      primitive == PrimitiveType.uint16 ||
      primitive == PrimitiveType.uint32 ||
      primitive == PrimitiveType.uint64;
  bool get isSigned => !isUnsigned;

  String get name => primitiveNames[primitive.index];

  String get cType => "${name}${isInteger ? "_t" : ""}";
  String get dartCType => name.upperCaseFirst();
  String get dartType => isInteger ? "int" : "double";
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

  String get cStructField => "${type.cType} $name;";

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

class StructType extends CType {
  final List<Member> members;

  /// To disambiguate same size structs.
  final String suffix;

  /// To override names.
  final String overrideName;

  StructType(List<CType> memberTypes)
      : this.members = generateMemberNames(memberTypes),
        this.suffix = "",
        this.overrideName = "";
  StructType.disambiguate(List<CType> memberTypes, this.suffix)
      : this.members = generateMemberNames(memberTypes),
        this.overrideName = "";
  StructType.override(List<CType> memberTypes, this.overrideName)
      : this.members = generateMemberNames(memberTypes),
        this.suffix = "";

  List<CType> get memberTypes => members.map((a) => a.type).toList();

  String get cType => name;
  String get dartCType => name;
  String get dartType => name;
  String get dartStructFieldAnnotation => "";

  bool get hasSize =>
      !memberTypes.map((e) => e.hasSize).contains(false) && !hasPadding;
  int get size => memberTypes.fold(0, (int acc, e) => acc + e.size);

  /// Rough approximation, to not redo all ABI logic here.
  bool get hasPadding =>
      members.length < 2 ? false : members[0].type.size < members[1].type.size;

  bool get hasNestedStructs =>
      members.map((e) => e.type is StructType).contains(true);

  /// All members have the same type.
  bool get isHomogeneous => memberTypes.toSet().length == 1;

  /// All members have a floating point type.
  bool get isOnlyFloatingPoint => !memberTypes.map((e) {
        if (e is FundamentalType) {
          return e.isFloatingPoint;
        }
        if (e is StructType) {
          return e.isOnlyFloatingPoint;
        }
      }).contains(false);

  /// All members have a integer type.
  bool get isOnlyInteger => !memberTypes.map((e) {
        if (e is FundamentalType) {
          return e.isInteger;
        }
        if (e is StructType) {
          return e.isOnlyInteger;
        }
      }).contains(false);

  bool get isMixed => !isOnlyInteger && !isOnlyFloatingPoint;

  String get name {
    String result = "Struct";
    if (overrideName != "") {
      return result + overrideName;
    }
    if (hasSize) {
      result += "${size}Byte" + (size != 1 ? "s" : "");
    }
    if (hasNestedStructs) {
      result += "Nested";
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
    } else {
      result += "Mixed";
    }
    result += suffix;
    return result;
  }
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
    if (arguments.containsStructs && returnValue is FundamentalType) {
      result = "Pass";
    } else if (returnValue is StructType &&
        argumentTypes.contains(returnValue)) {
      result = "ReturnStructArgument";
    } else if (returnValue is StructType) {
      if (arguments.length == (returnValue as StructType).members.length) {
        return "Return${returnValue.dartCType}";
      }
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
  bool get containsStructs => map((m) => m.type is StructType).contains(true);
}
