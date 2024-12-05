// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../helper.dart';
import 'constant.dart';

class Arguments {
  final ConstArguments constArguments;
  final NonConstArguments nonConstArguments;

  const Arguments({
    ConstArguments? constArguments,
    NonConstArguments? nonConstArguments,
  })  : constArguments = constArguments ?? const ConstArguments(),
        nonConstArguments = nonConstArguments ?? const NonConstArguments();

  factory Arguments.fromJson(
    Map<String, dynamic> json,
    List<Constant> constants,
  ) {
    final constJson = json['const'] as Map<String, dynamic>?;
    final nonConstJson = json['nonConst'] as Map<String, dynamic>?;
    return Arguments(
      constArguments: constJson != null
          ? ConstArguments.fromJson(constJson, constants)
          : null,
      nonConstArguments: nonConstJson != null
          ? NonConstArguments.fromJson(nonConstJson)
          : null,
    );
  }

  Map<String, dynamic> toJson(Map<Constant, int> constants) {
    final hasConst =
        constArguments.named.isNotEmpty || constArguments.positional.isNotEmpty;
    final hasNonConst = nonConstArguments.named.isNotEmpty ||
        nonConstArguments.positional.isNotEmpty;
    return {
      if (hasConst) 'const': constArguments.toJson(constants),
      if (hasNonConst) 'nonConst': nonConstArguments.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Arguments &&
        other.constArguments == constArguments &&
        other.nonConstArguments == nonConstArguments;
  }

  @override
  int get hashCode => Object.hash(constArguments, nonConstArguments);
}

class ConstArguments {
  final Map<int, Constant> positional;
  final Map<String, Constant> named;

  const ConstArguments(
      {Map<int, Constant>? positional, Map<String, Constant>? named})
      : named = named ?? const {},
        positional = positional ?? const {};

  factory ConstArguments.fromJson(
    Map<String, dynamic> json,
    List<Constant> constants,
  ) =>
      ConstArguments(
        positional: json['positional'] != null
            ? (json['positional'] as Map<String, dynamic>).map((position,
                    constantIndex) =>
                MapEntry(int.parse(position), constants[constantIndex as int]))
            : {},
        named: json['named'] != null
            ? (json['named'] as Map<String, dynamic>).map(
                (name, constantIndex) =>
                    MapEntry(name, constants[constantIndex as int]))
            : {},
      );

  Map<String, dynamic> toJson(Map<Constant, int> constants) => {
        if (positional.isNotEmpty)
          'positional': positional.map((position, constantIndex) =>
              MapEntry(position.toString(), constants[constantIndex]!)),
        if (named.isNotEmpty)
          'named': named.map((name, constantIndex) =>
              MapEntry(name, constants[constantIndex]!)),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConstArguments &&
        deepEquals(other.positional, positional) &&
        deepEquals(other.named, named);
  }

  @override
  int get hashCode => Object.hash(deepHash(positional), deepHash(named));
}

class NonConstArguments {
  final List<int> positional;
  final List<String> named;

  const NonConstArguments({List<int>? positional, List<String>? named})
      : named = named ?? const [],
        positional = positional ?? const [];

  factory NonConstArguments.fromJson(Map<String, dynamic> json) =>
      NonConstArguments(
        positional: json['positional'] != null
            ? (json['positional'] as List).cast()
            : <int>[],
        named: json['named'] != null ? (json['named'] as List).cast() : [],
      );

  Map<String, dynamic> toJson() => {
        if (positional.isNotEmpty) 'positional': positional,
        if (named.isNotEmpty) 'named': named,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NonConstArguments &&
        deepEquals(other.positional, positional) &&
        deepEquals(other.named, named);
  }

  @override
  int get hashCode => Object.hash(deepHash(positional), deepHash(named));
}
