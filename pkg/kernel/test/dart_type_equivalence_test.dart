// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/src/dart_type_equivalence.dart';
import 'package:kernel/testing/type_parser_environment.dart';

run() {
  // Simple types.
  areEqual("int", "int");
  notEqual("int", "String");

  // Simple types with nullabilities.
  areEqual("int?", "int?");
  notEqual("int", "int?");
  notEqual("int?", "String?");

  areEqual("int?", "int?", ignoreAllNullabilities: true);
  areEqual("int", "int?", ignoreAllNullabilities: true);
  notEqual("int?", "String?", ignoreAllNullabilities: true);

  areEqual("int?", "int?", ignoreTopLevelNullability: true);
  areEqual("int", "int?", ignoreTopLevelNullability: true);
  notEqual("int?", "String?", ignoreTopLevelNullability: true);

  // 1-level deep types.
  areEqual("List<int?>?", "List<int?>?");
  notEqual("List<int?>?", "List<int?>");
  notEqual("List<int?>?", "List<int>?");
  notEqual("List<int?>?", "List<int>");

  areEqual("List<int?>?", "List<int?>?", ignoreAllNullabilities: true);
  areEqual("List<int?>?", "List<int?>", ignoreAllNullabilities: true);
  areEqual("List<int?>?", "List<int>?", ignoreAllNullabilities: true);
  areEqual("List<int?>?", "List<int>", ignoreAllNullabilities: true);

  areEqual("List<int?>?", "List<int?>?", ignoreTopLevelNullability: true);
  areEqual("List<int?>?", "List<int?>", ignoreTopLevelNullability: true);
  notEqual("List<int?>?", "List<int>?", ignoreTopLevelNullability: true);
  notEqual("List<int?>?", "List<int>", ignoreTopLevelNullability: true);

  // Top types.
  areEqual("dynamic", "dynamic");
  notEqual("dynamic", "Object?");
  notEqual("dynamic", "Object*");
  notEqual("dynamic", "void");
  areEqual("Object?", "Object?");
  notEqual("Object?", "Object*");
  notEqual("Object?", "void");
  areEqual("Object*", "Object*");
  notEqual("Object*", "void");
  areEqual("void", "void");
  notEqual("FutureOr<dynamic>", "void");
  notEqual("FutureOr<FutureOr<Object?>>", "Object*");
  notEqual("FutureOr<FutureOr<FutureOr<Object*>?>>?", "dynamic");
  notEqual("FutureOr<Object?>", "FutureOr<Object?>?");
  notEqual("FutureOr<FutureOr<Object?>>", "FutureOr<FutureOr<Object?>?>?");
  notEqual("FutureOr<FutureOr<Object?>>", "FutureOr<FutureOr<dynamic>?>?");

  areEqual("dynamic", "Object?", equateTopTypes: true);
  areEqual("dynamic", "Object*", equateTopTypes: true);
  areEqual("dynamic", "void", equateTopTypes: true);
  areEqual("Object?", "Object*", equateTopTypes: true);
  areEqual("Object?", "void", equateTopTypes: true);
  areEqual("Object*", "void", equateTopTypes: true);
  areEqual("FutureOr<dynamic>", "void", equateTopTypes: true);
  areEqual("FutureOr<FutureOr<Object?>>", "Object*", equateTopTypes: true);
  areEqual("FutureOr<FutureOr<FutureOr<Object*>?>>?", "dynamic",
      equateTopTypes: true);
  areEqual("FutureOr<Object?>", "FutureOr<Object?>?", equateTopTypes: true);
  areEqual("FutureOr<FutureOr<Object?>>", "FutureOr<FutureOr<Object?>?>?",
      equateTopTypes: true);
  areEqual("FutureOr<FutureOr<Object?>>", "FutureOr<FutureOr<dynamic>?>?",
      equateTopTypes: true);

  areEqual("Object?", "Object*", ignoreAllNullabilities: true);
  areEqual("FutureOr<Object?>", "FutureOr<Object?>?",
      ignoreAllNullabilities: true);
  areEqual("FutureOr<FutureOr<Object?>>", "FutureOr<FutureOr<Object?>?>?",
      ignoreAllNullabilities: true);
  notEqual("FutureOr<FutureOr<Object?>>", "FutureOr<FutureOr<dynamic>?>?",
      ignoreAllNullabilities: true);

  areEqual("FutureOr<Object?>", "FutureOr<Object?>?",
      ignoreTopLevelNullability: true);
  notEqual("FutureOr<FutureOr<Object?>>", "FutureOr<FutureOr<Object?>?>?",
      ignoreTopLevelNullability: true);
  notEqual("FutureOr<FutureOr<Object?>>", "FutureOr<FutureOr<dynamic>?>?",
      ignoreTopLevelNullability: true);

  // Generic function types.
  notEqual("<T extends dynamic>() ->? int", "<T extends Object?>() -> int?");
  notEqual("<T extends dynamic>() ->? int", "<T extends Object?>() -> int?",
      equateTopTypes: true);
  notEqual("<T extends dynamic>() ->? int", "<T extends Object?>() -> int?",
      ignoreAllNullabilities: true);
  notEqual("<T extends dynamic>() ->? int", "<T extends Object?>() -> int?",
      ignoreTopLevelNullability: true);
  notEqual("<T extends dynamic>() ->? int", "<T extends Object?>() -> int?",
      equateTopTypes: true, ignoreTopLevelNullability: true);
  areEqual("<T extends dynamic>() ->? int", "<T extends Object?>() -> int?",
      equateTopTypes: true, ignoreAllNullabilities: true);

  notEqual("<T extends dynamic>() -> T?", "<S extends Object?>() -> S?");
  areEqual("<T extends dynamic>() -> T?", "<S extends Object?>() -> S?",
      equateTopTypes: true);

  notEqual("<T extends dynamic>() -> T", "<S extends FutureOr<void>>() -> S?");
  notEqual("<T extends dynamic>() -> T", "<S extends FutureOr<void>>() -> S?",
      equateTopTypes: true);
  notEqual("<T extends dynamic>() -> T", "<S extends FutureOr<void>>() -> S?",
      ignoreAllNullabilities: true);
  areEqual("<T extends dynamic>() -> T", "<S extends FutureOr<void>>() -> S?",
      equateTopTypes: true, ignoreAllNullabilities: true);

  areEqual("<T>(<S>() -> void) -> void", "<X>(<Y>() -> void) -> void");

  notEqual("<T>(<S extends void>() -> void) -> void",
      "<X>(<Y extends Object?>() -> void) -> void");
  notEqual("<T>(<S extends void>() -> void) -> void",
      "<X>(<Y extends Object?>() -> void) -> void",
      ignoreAllNullabilities: true);

  // Free type variables.
  areEqual("T", "T", typeParameters: "T");
  notEqual("T?", "T", typeParameters: "T");

  notEqual("T", "S",
      typeParameters: "T, S",
      equateTopTypes: true,
      ignoreAllNullabilities: true);

  notEqual("T & int?", "T & int", typeParameters: "T");
  notEqual("T & int?", "T & int",
      typeParameters: "T", ignoreTopLevelNullability: true);
  areEqual("T & int?", "T & int",
      typeParameters: "T", ignoreAllNullabilities: true);

  // Check that normalization is out of the scope of the equivalence, even with
  // the most permissive flags.
  notEqual("Never?", "Null",
      equateTopTypes: true, ignoreAllNullabilities: true);
  notEqual("FutureOr<Never>", "Future<Never>",
      equateTopTypes: true, ignoreAllNullabilities: true);
  notEqual("FutureOr<Object>", "Object",
      equateTopTypes: true, ignoreAllNullabilities: true);

  // Typedef types.
  areEqual("Typedef<int>", "Typedef<int>");
  notEqual("Typedef<String>", "Typedef<num>");
  notEqual("Typedef<num?>?", "Typedef<num>");
  notEqual("Typedef<num?>?", "Typedef<num>", ignoreTopLevelNullability: true);
  areEqual("Typedef<num?>?", "Typedef<num>", ignoreAllNullabilities: true);
  notEqual("Typedef<Object?>?", "Typedef<dynamic>");
  notEqual("Typedef<Object?>?", "Typedef<dynamic>",
      ignoreTopLevelNullability: true);
  notEqual("Typedef<Object?>?", "Typedef<dynamic>",
      ignoreAllNullabilities: true);
  notEqual("Typedef<Object?>?", "Typedef<dynamic>", equateTopTypes: true);
  areEqual("Typedef<Object?>?", "Typedef<dynamic>",
      equateTopTypes: true, ignoreTopLevelNullability: true);
}

areEqual(String type1, String type2,
    {String typeParameters = '',
    bool equateTopTypes = false,
    bool ignoreAllNullabilities = false,
    bool ignoreTopLevelNullability = false}) {
  Env env =
      new Env("typedef Typedef<T> () -> T;\n", isNonNullableByDefault: true)
        ..extendWithTypeParameters(typeParameters);
  DartType t1 = env.parseType(type1);
  DartType t2 = env.parseType(type2);

  List<String> flagNamesForDebug = [
    if (equateTopTypes) "equateTopTypes",
    if (ignoreAllNullabilities) "ignoreAllNullabilities",
    if (ignoreTopLevelNullability) "ignoreTopLevelNullability",
  ];

  print("areEqual(${type1}, ${type2}"
      "${flagNamesForDebug.map((f) => ", $f").join()})");
  Expect.isTrue(
      new DartTypeEquivalence(env.coreTypes,
              equateTopTypes: equateTopTypes,
              ignoreAllNullabilities: ignoreAllNullabilities,
              ignoreTopLevelNullability: ignoreTopLevelNullability)
          .areEqual(t1, t2),
      "Expected '${type1}' and '${type2}' to be equal "
      "with flags ${flagNamesForDebug.map((f) => "'$f'").join(", ")}.");

  print("areEqual(${type2}, ${type1}"
      "${flagNamesForDebug.map((f) => ", $f").join()})");
  Expect.isTrue(
      new DartTypeEquivalence(env.coreTypes,
              equateTopTypes: equateTopTypes,
              ignoreAllNullabilities: ignoreAllNullabilities,
              ignoreTopLevelNullability: ignoreTopLevelNullability)
          .areEqual(t2, t1),
      "Expected '${type2}' and '${type1}' to be equal "
      "with flags ${flagNamesForDebug.map((f) => "'$f'").join(", ")}.");
}

notEqual(String type1, String type2,
    {String typeParameters = '',
    bool equateTopTypes = false,
    bool ignoreAllNullabilities = false,
    bool ignoreTopLevelNullability = false}) {
  Env env =
      new Env("typedef Typedef<T> () -> T;\n", isNonNullableByDefault: true)
        ..extendWithTypeParameters(typeParameters);
  DartType t1 = env.parseType(type1);
  DartType t2 = env.parseType(type2);

  List<String> flagNamesForDebug = [
    if (equateTopTypes) "equateTopTypes",
    if (ignoreAllNullabilities) "ignoreAllNullabilities",
    if (ignoreTopLevelNullability) "ignoreTopLevelNullability",
  ];

  print("notEqual(${type1}, ${type2}"
      "${flagNamesForDebug.map((f) => ", $f").join()})");
  Expect.isFalse(
      new DartTypeEquivalence(env.coreTypes,
              equateTopTypes: equateTopTypes,
              ignoreAllNullabilities: ignoreAllNullabilities,
              ignoreTopLevelNullability: ignoreTopLevelNullability)
          .areEqual(t1, t2),
      "Expected '${type1}' and '${type2}' to be not equal "
      "with flags ${flagNamesForDebug.map((f) => "'$f'").join(", ")}.");

  print("notEqual(${type2}, ${type1}"
      "${flagNamesForDebug.map((f) => ", $f").join()})");
  Expect.isFalse(
      new DartTypeEquivalence(env.coreTypes,
              equateTopTypes: equateTopTypes,
              ignoreAllNullabilities: ignoreAllNullabilities,
              ignoreTopLevelNullability: ignoreTopLevelNullability)
          .areEqual(t2, t1),
      "Expected '${type2}' and '${type1}' to be not equal "
      "with flags ${flagNamesForDebug.map((f) => "'$f'").join(", ")}.");
}

main() => run();
