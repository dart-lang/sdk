// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/constants/values.dart';
import 'package:record_use/record_use_internal.dart' as record_use;

import '../serialization/serialization.dart';

class RecordedUse {
  static const String tag = 'record-use';

  /// Name of the class or method that is a resource identifier.
  final String name;

  /// Name of the parent, if existing.
  final String? parent;

  /// Where the class or method is defined.
  final String uri;

  /// Location of the resource identifier instance. This is `null` for constant
  /// resource identifiers. For other resource identifier instances this is the
  /// call site to the constructor or method.
  final record_use.Location? location;

  /// True if some argument is missing from [positionalArguments] because it is not
  /// a constant.
  final bool nonconstant;

  final List<ConstantValue?> positionalArguments;

  /// Constant argument values in `package:record_use` format.
  List<record_use.Constant?> get arguments => _argumentsFromConstantValues();

  RecordedUse(
    this.name,
    this.parent,
    this.uri,
    this.location,
    this.nonconstant,
    this.positionalArguments,
  );

  factory RecordedUse.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    String name = source.readString();
    String? parent = source.readStringOrNull();
    String uri = source.readString();

    bool hasLocation = source.readBool();
    record_use.Location? location = hasLocation
        ? RecordUseLocation.readFromDataSource(source)
        : null;

    bool nonconstant = source.readBool();

    final positionalArguments = source.readList(
      () => source.readValueOrNull(source.readConstant),
    );
    source.end(tag);
    return RecordedUse(
      name,
      parent,
      uri,
      location,
      nonconstant,
      positionalArguments,
    );
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeString(name);
    sink.writeStringOrNull(parent);
    sink.writeString(uri);

    if (location == null) {
      sink.writeBool(false);
    } else {
      sink.writeBool(true);
      location!.writeToDataSink(sink);
    }

    sink.writeBool(nonconstant);

    sink.writeList(
      positionalArguments,
      (c) => sink.writeValueOrNull(c, sink.writeConstant),
    );
    sink.end(tag);
  }

  @override
  bool operator ==(Object other) {
    if (other is! RecordedUse) return false;
    if (name != other.name) return false;
    if (uri != other.uri) return false;
    if (location != other.location) return false;
    if (positionalArguments.length != other.positionalArguments.length) {
      return false;
    }
    for (var i = 0; i < positionalArguments.length; i++) {
      if (positionalArguments[i] != other.positionalArguments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(name, uri, location, Object.hashAll(positionalArguments));

  @override
  String toString() {
    return 'RecordedUse($name @ $uri, $location, $positionalArguments)';
  }

  List<record_use.Constant?> _argumentsFromConstantValues() =>
      positionalArguments.map(_findValue).toList();

  record_use.Constant? _findValue(ConstantValue? constant) {
    return switch (constant) {
      null => null, // not const.
      NullConstantValue() => record_use.NullConstant(),
      BoolConstantValue() => record_use.BoolConstant(constant.boolValue),
      IntConstantValue() => record_use.IntConstant(constant.intValue.toInt()),
      StringConstantValue() => record_use.StringConstant(constant.stringValue),
      MapConstantValue() => _findMapValue(constant),
      ListConstantValue() => _findListValue(constant),
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
