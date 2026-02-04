// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:record_use/record_use_internal.dart';

import '../serialization/serialization.dart';

class ResourceIdentifier {
  static const String tag = 'resource-identifier';

  /// Name of the class or method that is a resource identifier.
  final String name;

  /// Name of the parent, if existing.
  final String? parent;

  /// Where the class or method is defined.
  final String uri;

  /// Location of the resource identifier instance. This is `null` for constant
  /// resource identifiers. For other resource identifier instances this is the
  /// call site to the constructor or method.
  final Location? location;

  /// True if some argument is missing from [_argumentsString] because it is not
  /// a constant.
  final bool nonconstant;

  /// JSON encoded map from class field names or function parameter positions to
  /// primitive values for arguments that are constant.
  // TODO(sra): Consider holding as a map with ConstantValue values.
  String _argumentsString;

  /// JSON encoded map from class field names or function parameter positions to
  /// primitive values for arguments that are constant.
  List<Constant?> get arguments => _argumentsFromJson();

  ResourceIdentifier(
    this.name,
    this.parent,
    this.uri,
    this.location,
    this.nonconstant,
    this._argumentsString,
  );

  factory ResourceIdentifier.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    String name = source.readString();
    String? parent = source.readStringOrNull();
    String uri = source.readString();

    bool hasLocation = source.readBool();
    Location? location = hasLocation
        ? ResourceIdentifierLocation.readFromDataSource(source)
        : null;

    bool nonconstant = source.readBool();
    String arguments = source.readString();
    source.end(tag);
    return ResourceIdentifier(
      name,
      parent,
      uri,
      location,
      nonconstant,
      arguments,
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
    sink.writeString(_argumentsString);
    sink.end(tag);
  }

  @override
  bool operator ==(Object other) =>
      other is ResourceIdentifier &&
      name == other.name &&
      uri == other.uri &&
      location == other.location &&
      _argumentsString == other._argumentsString;

  @override
  int get hashCode => Object.hash(name, uri, location, _argumentsString);

  @override
  String toString() {
    return 'ResourceIdentifier($name @ $uri, $location, $_argumentsString)';
  }

  List<Constant?> _argumentsFromJson() {
    final json = jsonDecode(_argumentsString) as List<Object?>;
    final constants = <Constant>[];
    final arguments = <Constant?>[];
    for (final constantJsonObj in json) {
      final constantJson = constantJsonObj as Map<String, Object?>?;
      final Constant? constant;
      if (constantJson != null) {
        constant = Constant.fromJson(constantJson, constants);
        constants.add(constant);
      } else {
        constant = null;
      }
      arguments.add(constant);
    }
    return arguments;
  }
}

extension ResourceIdentifierLocation on Location {
  static Location readFromDataSource(DataSourceReader source) {
    final uri = source.readUri();
    //TODO(mosum): Use a verbose flag for line and column info
    // final line = source.readIntOrNull();
    // final column = source.readIntOrNull();
    return Location(uri: uri.toFilePath());
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.writeUri(Uri.file(uri));
    //TODO(mosum): Use a verbose flag for line and column info
    // sink.writeIntOrNull(line);
    // sink.writeIntOrNull(column);
  }
}
