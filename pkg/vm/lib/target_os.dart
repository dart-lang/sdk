// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum TargetOS {
  android('android', '/'),
  fuchsia('fuchsia', '/'),
  iOS('ios', '/'),
  linux('linux', '/'),
  macOS('macos', '/'),
  windows('windows', '\\');

  final String name;
  final String pathSeparator;

  const TargetOS(this.name, this.pathSeparator);

  static final Iterable<String> names = values.map((v) => v.name);

  static TargetOS? fromString(String s) {
    for (final os in values) {
      if (os.name == s) return os;
    }
    return null;
  }

  @override
  String toString() => name;
}
