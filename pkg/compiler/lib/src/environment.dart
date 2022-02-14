// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Collects definitions provided to the compiler via the `-D` flag.
///
/// Environment variables can be used in the user code in two ways. From
/// conditional imports, and from `const String.fromEnvironment` and
/// other similar constructors.
class Environment {
  /// An immutable map of environment variables.
  final Map<String, String> definitions;

  Environment(Map<String, String> definitions)
      : this.definitions = Map.unmodifiable(definitions);
}
