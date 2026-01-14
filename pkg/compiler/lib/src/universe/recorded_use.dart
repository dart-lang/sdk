// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains data structures that loosely represent the data
/// structures in `package:record_use`. However these data structures are
/// different in the following ways:
/// * [ConstantValue]s are used for constants, to enable serialization of
///   composite constants.
/// * No loading units are present. The loading units only get assigned in a
///   later phase in the compiler.
///
/// Please keep this library in sync with `package:record_use`.
library;

import 'package:compiler/src/constants/values.dart';
import 'package:record_use/record_use_internal.dart' as record_use;

import '../serialization/serialization.dart';

/// Dart2js version of [record_use.Identifier].
class RecordedIdentifier {
  /// Name of the class or method that is a resource identifier.
  final String name;

  /// Name of the parent, if existing.
  final String? parent;

  /// Where the class or method is defined.
  final String uri;

  RecordedIdentifier({required this.name, this.parent, required this.uri});

  factory RecordedIdentifier.readFromDataSource(DataSourceReader source) {
    String uri = source.readString();
    String name = source.readString();
    String? parent = source.readStringOrNull();
    return RecordedIdentifier(uri: uri, name: name, parent: parent);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.writeString(uri);
    sink.writeString(name);
    sink.writeStringOrNull(parent);
  }

  @override
  bool operator ==(Object other) {
    if (other is! RecordedIdentifier) return false;
    return uri == other.uri && name == other.name && parent == other.parent;
  }

  @override
  int get hashCode => Object.hash(uri, name, parent);

  record_use.Identifier toPackageRecordUseFormat() => record_use.Identifier(
    importUri: uri.toString(),
    scope: parent,
    name: name,
  );
}

enum RecordedUseKind { call, tearOff }

/// Dart2js version of [record_use.CallReference], but with the [identifier]
/// nested for easy serialization.
sealed class RecordedUse {
  static const String tag = 'record-use';

  final RecordedIdentifier identifier;

  /// Location of the resource identifier instance. This is `null` for constant
  /// resource identifiers. For other resource identifier instances this is the
  /// call site to the constructor or method.
  final record_use.Location? location;

  RecordedUseKind get kind;

  RecordedUse({required this.identifier, this.location});

  factory RecordedUse.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    RecordedUseKind kind = source.readEnum(RecordedUseKind.values);
    final identifier = RecordedIdentifier.readFromDataSource(source);
    final location = source.readValueOrNull(
      () => RecordUseLocation.readFromDataSource(source),
    );
    RecordedUse result;
    switch (kind) {
      case RecordedUseKind.call:
        result = RecordedCallWithArguments._readFromDataSource(
          identifier,
          location,
          source,
        );
        break;
      case RecordedUseKind.tearOff:
        result = RecordedTearOff._readFromDataSource(
          identifier,
          location,
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
    identifier.writeToDataSink(sink);
    sink.writeValueOrNull(location, (l) => location!.writeToDataSink);
    _writeFieldsForKind(sink);
    sink.end(tag);
  }

  void _writeFieldsForKind(DataSinkWriter sink);

  @override
  bool operator ==(Object other) {
    if (other is! RecordedUse) return false;
    return identifier == other.identifier && location == other.location;
  }

  @override
  int get hashCode => Object.hash(identifier, location);
}

/// Dart2js version of [record_use.CallWithArguments], with [ConstantValue]s
/// instead of [record_use.Constant]s.
class RecordedCallWithArguments extends RecordedUse {
  final List<ConstantValue?> positionalArguments;

  /// Constant argument values in `package:record_use` format.
  List<record_use.Constant?> get arguments =>
      positionalArguments.map(_findValue).toList();

  RecordedCallWithArguments({
    required super.identifier,
    super.location,
    required this.positionalArguments,
  });

  @override
  RecordedUseKind get kind => RecordedUseKind.call;

  static RecordedCallWithArguments _readFromDataSource(
    RecordedIdentifier identifier,
    record_use.Location? location,
    DataSourceReader source,
  ) {
    final positionalArguments = source.readList(
      () => source.readValueOrNull(source.readConstant),
    );
    return RecordedCallWithArguments(
      identifier: identifier,
      location: location,
      positionalArguments: positionalArguments,
    );
  }

  @override
  void _writeFieldsForKind(DataSinkWriter sink) {
    sink.writeList(
      positionalArguments,
      (c) => sink.writeValueOrNull(c, sink.writeConstant),
    );
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
  RecordedTearOff({required super.identifier, super.location});

  @override
  RecordedUseKind get kind => RecordedUseKind.tearOff;

  static RecordedTearOff _readFromDataSource(
    RecordedIdentifier identifier,
    record_use.Location? location,
    DataSourceReader source,
  ) {
    // No specific fields to read.
    return RecordedTearOff(identifier: identifier, location: location);
  }

  @override
  void _writeFieldsForKind(DataSinkWriter sink) {
    // No specific fields to write.
  }
}

record_use.Constant? _findValue(ConstantValue? constant) {
  return switch (constant) {
    null => null, // not const.
    NullConstantValue() => record_use.NullConstant(),
    BoolConstantValue() => record_use.BoolConstant(constant.boolValue),
    IntConstantValue() => record_use.IntConstant(constant.intValue.toInt()),
    StringConstantValue() => record_use.StringConstant(constant.stringValue),
    MapConstantValue() => _findMapValue(constant),
    ListConstantValue() => _findListValue(constant),
    ConstructedConstantValue() => _findInstanceValue(constant),
    // TODO(https://github.com/dart-lang/native/issues/2899): Handle
    // unsupported const types so that the values don't show up as non-const.
    Object() => null,
  };
}

record_use.MapConstant? _findMapValue(MapConstantValue constant) {
  final result = <String, record_use.Constant>{};
  for (var index = 0; index < constant.keys.length; index++) {
    var keyConstantValue = constant.keys[index];
    if (keyConstantValue is! StringConstantValue) {
      // TODO(https://github.com/dart-lang/native/issues/2715): Support non
      // string keys in maps.
      return null;
    }
    final value = _findValue(constant.values[index]);
    if (value == null) {
      // TODO(https://github.com/dart-lang/native/issues/2899): Handle
      // unsupported values.
      return null;
    }
    result[keyConstantValue.stringValue] = value;
  }
  return record_use.MapConstant(result);
}

record_use.ListConstant? _findListValue(ListConstantValue constant) {
  final result = <record_use.Constant>[];
  for (final constantValue in constant.entries) {
    final constant = _findValue(constantValue);
    if (constant == null) {
      // TODO(https://github.com/dart-lang/native/issues/2899): Handle
      // unsupported values.
      return null;
    }
    result.add(constant);
  }
  return record_use.ListConstant(result);
}

record_use.InstanceConstant? _findInstanceValue(
  ConstructedConstantValue constant,
) {
  final fieldValues = <String, record_use.Constant>{};
  for (final entry in constant.fields.entries) {
    final name = entry.key.name;
    final value = _findValue(entry.value);
    if (name == null || value == null) {
      // TODO(https://github.com/dart-lang/native/issues/2899): Handle
      // unsupported fields.
      return null;
    }
    fieldValues[name] = value;
  }
  return record_use.InstanceConstant(fields: fieldValues);
}

extension RecordUseLocation on record_use.Location {
  static record_use.Location readFromDataSource(DataSourceReader source) {
    final uri = source.readUri();
    //TODO(mosum): Use a verbose flag for line and column info
    // final line = source.readIntOrNull();
    // final column = source.readIntOrNull();
    return record_use.Location(uri: uri.toFilePath());
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.writeUri(Uri.file(uri));
    //TODO(mosum): Use a verbose flag for line and column info
    // sink.writeIntOrNull(line);
    // sink.writeIntOrNull(column);
  }
}
