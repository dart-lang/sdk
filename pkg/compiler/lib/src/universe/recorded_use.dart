// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains data structures that loosely represent the data
/// structures in `package:record_use`. However these data structures are
/// different in the following ways:
/// * [ConstantValue] is used for constants, to enable serialization of
///   composite constants.
/// * [Entity] is used for definitions, so that it can be used in the last stage
///   of the compiler to see in which loading unit it ended up.
/// * [SourceLocation] is used for source locations instead of
///   [record_use.Location] to keep the serialization smaller.
///
/// Please keep this library in sync with `package:record_use`.
library;

import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/io/source_information.dart';
import 'package:record_use/record_use_internal.dart' as record_use;

import '../serialization/serialization.dart';

enum RecordedUseKind { call, tearOff }

/// Dart2js version of [record_use.CallReference], but with the [identifier]
/// nested for easy serialization.
sealed class RecordedUse {
  static const String tag = 'record-use';

  final FunctionEntity function;

  final SourceInformation sourceInformation;

  RecordedUseKind get kind;

  RecordedUse({required this.function, required this.sourceInformation});

  factory RecordedUse.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    RecordedUseKind kind = source.readEnum(RecordedUseKind.values);
    final function = source.readMember() as FunctionEntity;
    final sourceInformation = SourceInformation.readFromDataSource(source);
    RecordedUse result;
    switch (kind) {
      case RecordedUseKind.call:
        result = RecordedCallWithArguments._readFromDataSource(
          function,
          sourceInformation,
          source,
        );
        break;
      case RecordedUseKind.tearOff:
        result = RecordedTearOff._readFromDataSource(
          function,
          sourceInformation,
          source,
        );
        break;
    }
    source.end(tag);
    return result;
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    sink.writeMember(function);
    SourceInformation.writeToDataSink(sink, sourceInformation);
    _writeFieldsForKind(sink);
    sink.end(tag);
  }

  void _writeFieldsForKind(DataSinkWriter sink);

  @override
  bool operator ==(Object other) {
    if (other is! RecordedUse) return false;
    return function == other.function &&
        sourceInformation == other.sourceInformation;
  }

  @override
  int get hashCode => Object.hash(function, sourceInformation);
}

/// Dart2js version of [record_use.CallWithArguments], with [ConstantValue]s
/// instead of [record_use.Constant]s.
class RecordedCallWithArguments extends RecordedUse {
  final List<ConstantValue?> positionalArguments;
  final Map<String, ConstantValue?> namedArguments;

  /// Constant positional argument values in `package:record_use` format.
  List<record_use.MaybeConstant> positionalArgumentsInRecordUseFormat() =>
      positionalArguments.map(_findValueOrNonConst).toList();

  /// Constant named argument values in `package:record_use` format.
  Map<String, record_use.MaybeConstant> namedArgumentsInRecordUseFormat() =>
      namedArguments.map((k, v) => MapEntry(k, _findValueOrNonConst(v)));

  RecordedCallWithArguments({
    required super.function,
    required super.sourceInformation,
    required this.positionalArguments,
    required this.namedArguments,
  });

  @override
  RecordedUseKind get kind => RecordedUseKind.call;

  static RecordedCallWithArguments _readFromDataSource(
    FunctionEntity function,
    SourceInformation sourceInformation,
    DataSourceReader source,
  ) {
    final positionalArguments = source.readList(source.readConstantOrNull);
    final namedArguments = source.readStringMap(source.readConstantOrNull);
    return RecordedCallWithArguments(
      function: function,
      sourceInformation: sourceInformation,
      positionalArguments: positionalArguments,
      namedArguments: namedArguments,
    );
  }

  @override
  void _writeFieldsForKind(DataSinkWriter sink) {
    sink.writeList(positionalArguments, sink.writeConstantOrNull);
    sink.writeStringMap(namedArguments, sink.writeConstantOrNull);
  }

  @override
  bool operator ==(Object other) {
    if (other is! RecordedCallWithArguments) return false;
    if (positionalArguments.length != other.positionalArguments.length) {
      return false;
    }
    for (var i = 0; i < positionalArguments.length; i++) {
      if (positionalArguments[i] != other.positionalArguments[i]) return false;
    }
    return super == other;
  }

  @override
  int get hashCode =>
      Object.hash(super.hashCode, Object.hashAll(positionalArguments));
}

/// Dart2js version of [record_use.CallTearOff].
class RecordedTearOff extends RecordedUse {
  RecordedTearOff({required super.function, required super.sourceInformation});

  @override
  RecordedUseKind get kind => RecordedUseKind.tearOff;

  static RecordedTearOff _readFromDataSource(
    FunctionEntity function,
    SourceInformation sourceInformation,
    DataSourceReader source,
  ) {
    // No specific fields to read.
    return RecordedTearOff(
      function: function,
      sourceInformation: sourceInformation,
    );
  }

  @override
  void _writeFieldsForKind(DataSinkWriter sink) {
    // No specific fields to write.
  }
}

record_use.MaybeConstant _findValueOrNonConst(ConstantValue? constant) {
  return constant == null
      ? const record_use.NonConstant()
      : _findValue(constant);
}

record_use.Constant _findValue(ConstantValue constant) {
  return switch (constant) {
    NullConstantValue() => record_use.NullConstant(),
    BoolConstantValue() => record_use.BoolConstant(constant.boolValue),
    IntConstantValue() => record_use.IntConstant(constant.intValue.toInt()),
    StringConstantValue() => record_use.StringConstant(constant.stringValue),
    MapConstantValue() => _findMapValue(constant),
    ListConstantValue() => _findListValue(constant),
    ConstructedConstantValue() => _findInstanceValue(constant),
    DoubleConstantValue() => record_use.UnsupportedConstant(
      'Double literals are not supported for recording.',
    ),
    SetConstantValue() => record_use.UnsupportedConstant(
      'Set literals are not supported for recording.',
    ),
    RecordConstantValue() => record_use.UnsupportedConstant(
      'Record literals are not supported for recording.',
    ),
    InstantiationConstantValue() => record_use.UnsupportedConstant(
      'Generic instantiations are not supported for recording.',
    ),
    FunctionConstantValue() => record_use.UnsupportedConstant(
      'Function/Method tear-offs are not supported for recording.',
    ),
    TypeConstantValue() => record_use.UnsupportedConstant(
      'Type literals are not supported for recording.',
    ),
    Object() => record_use.UnsupportedConstant(
      '${constant.runtimeType} is not supported for recording.',
    ),
  };
}

record_use.MapConstant _findMapValue(MapConstantValue constant) {
  final List<MapEntry<record_use.Constant, record_use.Constant>> result = [];
  for (var index = 0; index < constant.keys.length; index++) {
    final keyConstantValue = constant.keys[index];
    final keyValue = _findValue(keyConstantValue);
    final value = _findValue(constant.values[index]);

    result.add(MapEntry(keyValue, value));
  }
  return record_use.MapConstant(result);
}

record_use.ListConstant _findListValue(ListConstantValue constant) {
  final result = <record_use.Constant>[];
  for (final constantValue in constant.entries) {
    result.add(_findValue(constantValue));
  }
  return record_use.ListConstant(result);
}

record_use.InstanceConstant _findInstanceValue(
  ConstructedConstantValue constant,
) {
  final fieldValues = <String, record_use.Constant>{};
  for (final entry in constant.fields.entries) {
    final name = entry.key.name;
    if (name == null) continue;
    fieldValues[name] = _findValue(entry.value);
  }
  return record_use.InstanceConstant(fields: fieldValues);
}
