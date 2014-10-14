// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.source.unknown;

import 'dart:async';

import '../package.dart';
import '../pubspec.dart';
import '../source.dart';

/// A [Null Object] that represents a source not recognized by pub.
///
/// It provides some default behavior so that pub can work with sources it
/// doesn't recognize.
///
/// [null object]: http://en.wikipedia.org/wiki/Null_Object_pattern
class UnknownSource extends Source {
  final String name;

  UnknownSource(this.name);

  /// Two unknown sources are the same if their names are the same.
  bool operator ==(other) => other is UnknownSource && other.name == name;

  int get hashCode => name.hashCode;

  Future<Pubspec> doDescribe(PackageId id) =>
      throw new UnsupportedError(
          "Cannot describe a package from unknown source '$name'.");

  Future get(PackageId id, String symlink) =>
      throw new UnsupportedError("Cannot get an unknown source '$name'.");

  /// Returns the directory where this package can be found locally.
  Future<String> getDirectory(PackageId id) =>
      throw new UnsupportedError(
          "Cannot find a package from an unknown source '$name'.");

  bool descriptionsEqual(description1, description2) =>
      description1 == description2;

  /// Unknown sources do no validation.
  dynamic parseDescription(String containingPath, description,
      {bool fromLockFile: false}) =>
      description;
}
