// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum TargetArch {
  arm64('arm64'),
  ia32('ia32'),
  riscv32('riscv32'),
  riscv64('riscv64'),
  x64('x64');

  final String name;

  const TargetArch(this.name);

  static final Iterable<String> names = values.map((v) => v.name);

  static TargetArch? fromString(String s) {
    for (final arch in values) {
      if (arch.name == s) return arch;
    }
    return null;
  }

  @override
  String toString() => name;
}
