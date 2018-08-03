// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An implementation of this defines the variables that are available for use
/// inside a status file section header.
abstract class Environment {
  /// Validates that the variable with [name] exists and can be compared
  /// against [value].
  ///
  /// If any errors are found, adds them to [errors].
  void validate(String name, String value, List<String> errors);

  /// Looks up the value of the variable with [name].
  String lookUp(String name);
}
