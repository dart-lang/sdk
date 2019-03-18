// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Collects definitions provided to the compiler via the `-D` flag.
///
/// Environment variables can be used in the user code in two ways. From
/// conditional imports, and from `const String.fromEnvironment` and
/// other similar constructors.
abstract class Environment {
  /// Return the string value of the given key.
  ///
  /// Note that `bool.fromEnvironment` and `int.fromEnvironment` are also
  /// implemented in terms of `String.fromEnvironment`.
  String valueOf(String key);

  /// Returns the full environment as map.
  Map<String, String> toMap();
}
