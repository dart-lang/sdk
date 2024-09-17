// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../helper.dart';

sealed class Constant {
  const Constant();

  Map<String, dynamic> toJson(Map<Constant, int> constants);

  static Constant fromJson(
          Map<String, dynamic> value, List<Constant> constants) =>
      switch (value['type'] as String) {
        NullConstant._type => const NullConstant(),
        BoolConstant._type => BoolConstant(value['value'] as bool),
        IntConstant._type => IntConstant(value['value'] as int),
        StringConstant._type => StringConstant(value['value'] as String),
        ListConstant._type => ListConstant((value['value'] as List<dynamic>)
            .map((value) => value as int)
            .map((value) => constants[value])
            .toList()),
        MapConstant._type => MapConstant(
            (value['value'] as Map<String, dynamic>)
                .map((key, value) => MapEntry(key, constants[value as int]))),
        InstanceConstant._type => InstanceConstant(
            fields: (value['value'] as Map<String, dynamic>)
                .map((key, value) => MapEntry(key, constants[value as int]))),
        String() =>
          throw UnimplementedError('This type is not a supported constant'),
      };
}

final class NullConstant extends Constant {
  static const _type = 'Null';

  const NullConstant() : super();

  @override
  Map<String, dynamic> toJson(Map<Constant, int> constants) =>
      _toJson(_type, null);
}

sealed class PrimitiveConstant<T extends Object> extends Constant {
  final T value;

  const PrimitiveConstant(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PrimitiveConstant<T> && other.value == value;
  }

  @override
  Map<String, dynamic> toJson(Map<Constant, int> constants) => valueToJson();

  Map<String, dynamic> valueToJson();
}

final class BoolConstant extends PrimitiveConstant<bool> {
  static const _type = 'bool';

  const BoolConstant(super.value);

  @override
  Map<String, dynamic> valueToJson() => _toJson(_type, value);
}

final class IntConstant extends PrimitiveConstant<int> {
  static const _type = 'int';

  const IntConstant(super.value);

  @override
  Map<String, dynamic> valueToJson() => _toJson(_type, value);
}

final class StringConstant extends PrimitiveConstant<String> {
  static const _type = 'String';

  const StringConstant(super.value);

  @override
  Map<String, dynamic> valueToJson() => _toJson(_type, value);
}

final class ListConstant<T extends Constant> extends Constant {
  static const _type = 'list';

  final List<T> value;

  const ListConstant(this.value);

  @override
  int get hashCode => deepHash(value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ListConstant && deepEquals(other.value, value);
  }

  @override
  Map<String, dynamic> toJson(Map<Constant, int> constants) => _toJson(
        _type,
        value.map((constant) => constants[constant]).toList(),
      );
}

final class MapConstant<T extends Constant> extends Constant {
  static const _type = 'map';

  final Map<String, T> value;

  const MapConstant(this.value);

  @override
  int get hashCode => deepHash(value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MapConstant && deepEquals(other.value, value);
  }

  @override
  Map<String, dynamic> toJson(Map<Constant, int> constants) => _toJson(
        _type,
        value.map((key, constant) => MapEntry(key, constants[constant]!)),
      );
}

final class InstanceConstant extends Constant {
  static const _type = 'Instance';

  final Map<String, Constant> fields;

  const InstanceConstant({
    required this.fields,
  });

  factory InstanceConstant.fromJson(
    Map<String, dynamic> json,
    List<Constant> constants,
  ) {
    return InstanceConstant(
      fields: json.map((key, constantIndex) =>
          MapEntry(key, constants[constantIndex as int])),
    );
  }

  @override
  Map<String, dynamic> toJson(Map<Constant, int> constants) => _toJson(
        _type,
        fields.isNotEmpty
            ? fields.map((name, constantIndex) =>
                MapEntry(name, constants[constantIndex]!))
            : null,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InstanceConstant && deepEquals(other.fields, fields);
  }

  @override
  int get hashCode => deepHash(fields);
}

Map<String, dynamic> _toJson(String type, Object? value) {
  return {
    'type': type,
    if (value != null) 'value': value,
  };
}
