// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=macros

import 'json_key.dart';
import 'json_serializable.dart';

@JsonSerializable()
class HasFromJson {
  HasFromJson.fromJson() {}
  //          ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
  // [cfe] unspecified
}

@JsonSerializable()
class HasToson {
  void toJson() {}
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
  // [cfe] unspecified
}

class Unserializable {}

class ExtendsUnserializable extends Unserializable {
//                                  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [cfe] unspecified
// [cfe] unspecified
  @FromJson()
  external ExtendsUnserializable.fromJson(Map<String, Object?> json);

  @ToJson()
  external Map<String, Object?> toJson();
}

class InvalidSerializationMembers {
  @FromJson()
  external InvalidSerializationMembers.fromJson();
  //                                   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
  // [cfe] unspecified

  @ToJson()
  external void toJson();
  //            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
  // [cfe] unspecified
}

@JsonSerializable()
class FunctionTypeField {
  void Function() x;
//^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [cfe] unspecified
}

typedef VoidFunc = void Function();

@JsonSerializable()
class TypeDefToFunctionTypeField {
  VoidFunc x;
//^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [cfe] unspecified
// [cfe] unspecified
}

enum Things {
  x,
}

@JsonSerializable()
class EnumField {
  Things x;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [cfe] unspecified
// [cfe] unspecified
}

@JsonSerializable()
class DuplicateJsonKey {
  @JsonKey()
  @JsonKey()
//^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [cfe] unspecified
// [cfe] unspecified
  int? x;
}
