// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import '../constants/values.dart';
import '../serialization/serialization.dart';

class ResourceIdentifier {
  static const String tag = 'resource-identifier';

  /// Name of the class or method that is a resource identifier.
  final String name;

  /// When the class or method is defined.
  final Uri uri;

  /// Location of the resource identifer instance. This is `null` for constant
  /// resource identifiers. For other resource identifer instances this is the
  /// call site to the constructor or method.
  final ResourceIdentifierLocation? location;

  /// True if some argument is missing from [arguments] because it is not a
  /// constant.
  final bool nonconstant;

  /// JSON encoded map from class field names or function parameter positions to
  /// primitive values for arguments that are constant.
  // TODO(sra): Consider holding as a map with ConstantValue values.
  final String arguments;

  ResourceIdentifier(
      this.name, this.uri, this.location, this.nonconstant, this.arguments);

  factory ResourceIdentifier.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    String name = source.readString();
    Uri uri = source.readUri();

    bool hasLocation = source.readBool();
    ResourceIdentifierLocation? location = hasLocation
        ? ResourceIdentifierLocation.readFromDataSource(source)
        : null;

    bool nonconstant = source.readBool();
    String arguments = source.readString();
    source.end(tag);
    return ResourceIdentifier(name, uri, location, nonconstant, arguments);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeString(name);
    sink.writeUri(uri);

    if (location == null) {
      sink.writeBool(false);
    } else {
      sink.writeBool(true);
      location!.writeToDataSink(sink);
    }

    sink.writeBool(nonconstant);
    sink.writeString(arguments);
    sink.end(tag);
  }

  @override
  bool operator ==(Object other) =>
      other is ResourceIdentifier &&
      name == other.name &&
      uri == other.uri &&
      location == other.location &&
      arguments == other.arguments;

  @override
  int get hashCode => Object.hash(name, uri, location, arguments);

  @override
  String toString() {
    return 'ResourceIdentifier($name @ $uri, $location, $arguments)';
  }
}

class ResourceIdentifierLocation {
  final Uri uri;
  final int? line;
  final int? column;
  ResourceIdentifierLocation._(this.uri, this.line, this.column);

  factory ResourceIdentifierLocation.readFromDataSource(
      DataSourceReader source) {
    final uri = source.readUri();
    final line = source.readIntOrNull();
    final column = source.readIntOrNull();
    return ResourceIdentifierLocation._(uri, line, column);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.writeUri(uri);
    sink.writeIntOrNull(line);
    sink.writeIntOrNull(column);
  }

  @override
  bool operator ==(Object other) =>
      other is ResourceIdentifierLocation &&
      uri == other.uri &&
      line == other.line &&
      column == other.column;

  @override
  late int hashCode = Object.hash(uri, line, column);

  @override
  String toString() => 'ResourceIdentifierLocation($uri:$line:$column)';
}

class ResourceIdentifierBuilder {
  final String name;
  final Uri uri;
  bool _nonconstant = false;
  ResourceIdentifierLocation? _location;
  final Map<String, Object?> _arguments = {};

  ResourceIdentifierBuilder(this.name, this.uri);

  ResourceIdentifier finish() {
    return ResourceIdentifier(
        name, uri, _location, _nonconstant, jsonEncode(_arguments));
  }

  void add(String argumentName, ConstantValue? constant) {
    if (constant != null) {
      final value = _findValue(constant);
      if (!identical(value, _unknown)) {
        _arguments[argumentName] = value;
        return;
      }
    }
    _nonconstant = true;
  }

  void addLocation(Uri uri, int? line, int? column) {
    _location = ResourceIdentifierLocation._(uri, line, column);
  }

  Object? _findValue(ConstantValue constant) {
    if (constant is IntConstantValue) {
      final value = constant.intValue;
      return value.isValidInt ? value.toInt() : _unknown;
    }
    if (constant is StringConstantValue) return constant.stringValue;
    if (constant is BoolConstantValue) return constant.boolValue;
    if (constant is DoubleConstantValue) return constant.doubleValue;
    if (constant is NullConstantValue) return null;
    return _unknown;
  }

  static final Object _unknown = Object();
}
