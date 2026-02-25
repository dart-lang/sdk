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
// ignore: implementation_imports
import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:record_use/record_use_internal.dart' as record_use;

import '../common/elements.dart' show JElementEnvironment;
import '../serialization/serialization.dart';

enum RecordedUseKind {
  constInstance,
  staticCallTearOff,
  staticCallWithArguments,
}

/// Dart2js version of `record_use.Reference`, with [sourceInformation].
///
/// Has no loading unit yet as these are assigned only all the way at the end of
/// the compilation.
sealed class RecordedUse {
  static const String tag = 'record-use';

  final SourceInformation sourceInformation;

  RecordedUseKind get kind;

  RecordedUse({required this.sourceInformation});

  factory RecordedUse.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    RecordedUseKind kind = source.readEnum(RecordedUseKind.values);
    final sourceInformation = SourceInformation.readFromDataSource(source);
    RecordedUse result;
    switch (kind) {
      case RecordedUseKind.staticCallWithArguments:
        result = RecordedCallWithArguments._readFromDataSource(
          sourceInformation,
          source,
        );
        break;
      case RecordedUseKind.staticCallTearOff:
        result = RecordedTearOff._readFromDataSource(sourceInformation, source);
        break;
      case RecordedUseKind.constInstance:
        result = RecordedConstInstance._readFromDataSource(
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
    SourceInformation.writeToDataSink(sink, sourceInformation);
    _writeFieldsForKind(sink);
    sink.end(tag);
  }

  void _writeFieldsForKind(DataSinkWriter sink);
}

/// Dart2js version of [record_use.CallReference], with the [function]
/// it belongs to.
sealed class RecordedStaticCall extends RecordedUse {
  final FunctionEntity function;

  /// Whether the call has a receiver in the recorded use format.
  ///
  /// This is true for calls to extension instance methods and extension type
  /// instance methods. It is false for all other static calls, including
  /// class static methods, static extension methods, and static extension type
  /// methods.
  final bool definitionHasReceiver;

  /// The constant value of the receiver, if it is a constant.
  ///
  /// If [definitionHasReceiver] is true, but [constantReceiver] is null, then the
  /// receiver is not a constant.
  final ConstantValue? constantReceiver;

  record_use.MaybeConstant? receiverInRecordUseFormat(
    JElementEnvironment elementEnvironment,
  ) {
    if (!definitionHasReceiver) return null;
    return _findValueOrNonConst(constantReceiver, elementEnvironment);
  }

  RecordedStaticCall({
    required this.function,
    required this.definitionHasReceiver,
    required this.constantReceiver,
    required super.sourceInformation,
  });

  @override
  bool operator ==(Object other) {
    if (other is! RecordedStaticCall) return false;
    return function == other.function &&
        definitionHasReceiver == other.definitionHasReceiver &&
        constantReceiver == other.constantReceiver &&
        sourceInformation == other.sourceInformation;
  }

  @override
  int get hashCode => Object.hash(
    function,
    definitionHasReceiver,
    constantReceiver,
    sourceInformation,
  );
}

/// Dart2js version of [record_use.CallWithArguments], with [ConstantValue]s
/// instead of [record_use.Constant]s.
class RecordedCallWithArguments extends RecordedStaticCall {
  final List<ConstantValue?> positionalArguments;
  final Map<String, ConstantValue?> namedArguments;

  /// Constant positional argument values in `package:record_use` format.
  List<record_use.MaybeConstant> positionalArgumentsInRecordUseFormat(
    JElementEnvironment elementEnvironment,
  ) => positionalArguments
      .map((v) => _findValueOrNonConst(v, elementEnvironment))
      .toList();

  /// Constant named argument values in `package:record_use` format.
  Map<String, record_use.MaybeConstant> namedArgumentsInRecordUseFormat(
    JElementEnvironment elementEnvironment,
  ) => namedArguments.map(
    (k, v) => MapEntry(k, _findValueOrNonConst(v, elementEnvironment)),
  );

  RecordedCallWithArguments({
    required super.function,
    required super.definitionHasReceiver,
    required super.constantReceiver,
    required super.sourceInformation,
    required this.positionalArguments,
    required this.namedArguments,
  });

  @override
  RecordedUseKind get kind => RecordedUseKind.staticCallWithArguments;

  static RecordedCallWithArguments _readFromDataSource(
    SourceInformation sourceInformation,
    DataSourceReader source,
  ) {
    final function = source.readMember() as FunctionEntity;
    final definitionHasReceiver = source.readBool();
    final constantReceiver = source.readConstantOrNull();
    final positionalArguments = source.readList(source.readConstantOrNull);
    final namedArguments = source.readStringMap(source.readConstantOrNull);
    return RecordedCallWithArguments(
      function: function,
      definitionHasReceiver: definitionHasReceiver,
      constantReceiver: constantReceiver,
      sourceInformation: sourceInformation,
      positionalArguments: positionalArguments,
      namedArguments: namedArguments,
    );
  }

  @override
  void _writeFieldsForKind(DataSinkWriter sink) {
    sink.writeMember(function);
    sink.writeBool(definitionHasReceiver);
    sink.writeConstantOrNull(constantReceiver);
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

/// Dart2js version of [record_use.CallTearoff].
class RecordedTearOff extends RecordedStaticCall {
  RecordedTearOff({
    required super.function,
    required super.definitionHasReceiver,
    required super.constantReceiver,
    required super.sourceInformation,
  });

  @override
  RecordedUseKind get kind => RecordedUseKind.staticCallTearOff;

  static RecordedTearOff _readFromDataSource(
    SourceInformation sourceInformation,
    DataSourceReader source,
  ) {
    final function = source.readMember() as FunctionEntity;
    final definitionHasReceiver = source.readBool();
    final constantReceiver = source.readConstantOrNull();
    return RecordedTearOff(
      function: function,
      definitionHasReceiver: definitionHasReceiver,
      constantReceiver: constantReceiver,
      sourceInformation: sourceInformation,
    );
  }

  @override
  void _writeFieldsForKind(DataSinkWriter sink) {
    sink.writeMember(function);
    sink.writeBool(definitionHasReceiver);
    sink.writeConstantOrNull(constantReceiver);
  }
}

/// Dart2js version of [record_use.InstanceReference], with a [ConstantValue]
/// instead of [record_use.Constant].
class RecordedConstInstance extends RecordedUse {
  final ConstructedConstantValue constant;

  RecordedConstInstance({
    required this.constant,
    required super.sourceInformation,
  });

  ClassEntity get constantClass => constant.type.element;

  @override
  RecordedUseKind get kind => RecordedUseKind.constInstance;

  static RecordedConstInstance _readFromDataSource(
    SourceInformation sourceInformation,
    DataSourceReader source,
  ) {
    final constant = source.readConstant() as ConstructedConstantValue;
    return RecordedConstInstance(
      constant: constant,
      sourceInformation: sourceInformation,
    );
  }

  @override
  void _writeFieldsForKind(DataSinkWriter sink) {
    sink.writeConstant(constant);
  }

  @override
  bool operator ==(Object other) {
    if (other is! RecordedConstInstance) return false;
    return constant == other.constant &&
        sourceInformation == other.sourceInformation;
  }

  @override
  int get hashCode => Object.hash(constant, sourceInformation);
}

record_use.MaybeConstant _findValueOrNonConst(
  ConstantValue? constant,
  JElementEnvironment elementEnvironment,
) {
  if (constant == null) return const record_use.NonConstant();
  return _findValue(constant, elementEnvironment);
}

record_use.Constant _findValue(
  ConstantValue constant,
  JElementEnvironment elementEnvironment,
) {
  return switch (constant) {
    NullConstantValue() => record_use.NullConstant(),
    BoolConstantValue() => record_use.BoolConstant(constant.boolValue),
    IntConstantValue() => record_use.IntConstant(constant.intValue.toInt()),
    StringConstantValue() => record_use.StringConstant(constant.stringValue),
    MapConstantValue() => _findMapValue(constant, elementEnvironment),
    ListConstantValue() => _findListValue(constant, elementEnvironment),
    RecordConstantValue() => findRecordConstant(constant, elementEnvironment),
    ConstructedConstantValue() => findInstanceValue(
      constant,
      elementEnvironment,
    ),
    DoubleConstantValue() => record_use.UnsupportedConstant(
      'Double literals are not supported for recording.',
    ),
    SetConstantValue() => record_use.UnsupportedConstant(
      'Set literals are not supported for recording.',
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

record_use.RecordConstant findRecordConstant(
  RecordConstantValue constant,
  JElementEnvironment elementEnvironment,
) {
  final positional = <record_use.Constant>[];
  for (var i = 0; i < constant.shape.positionalFieldCount; i++) {
    positional.add(_findValue(constant.values[i], elementEnvironment));
  }
  final named = <String, record_use.Constant>{};
  for (var i = 0; i < constant.shape.fieldNames.length; i++) {
    final name = constant.shape.fieldNames[i];
    final value = constant.values[constant.shape.positionalFieldCount + i];
    named[name] = _findValue(value, elementEnvironment);
  }
  return record_use.RecordConstant(positional: positional, named: named);
}

record_use.MapConstant _findMapValue(
  MapConstantValue constant,
  JElementEnvironment elementEnvironment,
) {
  final List<MapEntry<record_use.Constant, record_use.Constant>> result = [];
  for (var index = 0; index < constant.keys.length; index++) {
    final keyConstantValue = constant.keys[index];
    final keyValue = _findValue(keyConstantValue, elementEnvironment);
    final value = _findValue(constant.values[index], elementEnvironment);

    result.add(MapEntry(keyValue, value));
  }
  return record_use.MapConstant(result);
}

record_use.ListConstant _findListValue(
  ListConstantValue constant,
  JElementEnvironment elementEnvironment,
) {
  final result = <record_use.Constant>[];
  for (final constantValue in constant.entries) {
    result.add(_findValue(constantValue, elementEnvironment));
  }
  return record_use.ListConstant(result);
}

record_use.Constant findInstanceValue(
  ConstructedConstantValue constant,
  JElementEnvironment elementEnvironment,
) {
  final cls = constant.type.element;

  if (elementEnvironment.isEnumClass(cls)) {
    int? index;
    String? name;
    final fields = <String, record_use.Constant>{};

    constant.fields.forEach((field, value) {
      final fieldName = field.name;
      if (fieldName == null) return;
      if (fieldName == enumIndexFieldName) {
        index = (value as IntConstantValue).intValue.toInt();
      } else if (fieldName == enumNameFieldName) {
        name = (value as StringConstantValue).stringValue;
      } else {
        fields[fieldName] = _findValue(value, elementEnvironment);
      }
    });

    final libraryUri = cls.library.canonicalUri.toString();
    final definition = record_use.Definition(libraryUri, [
      record_use.Name(cls.name, kind: record_use.DefinitionKind.enumKind),
    ]);

    return record_use.EnumConstant(
      definition: definition,
      index: index!,
      name: name!,
      fields: fields,
    );
  }

  final fieldValues = <String, record_use.Constant>{};
  constant.fields.forEach((field, value) {
    final name = field.name;
    if (name == null) return;
    fieldValues[name] = _findValue(value, elementEnvironment);
  });

  final libraryUri = cls.library.canonicalUri.toString();
  final definition = record_use.Definition(libraryUri, [
    record_use.Name(cls.name, kind: record_use.DefinitionKind.classKind),
  ]);
  return record_use.InstanceConstant(
    definition: definition,
    fields: fieldValues,
  );
}
