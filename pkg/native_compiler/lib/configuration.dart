// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum TargetCPU {
  arm64;

  static final String defaultName = arm64.name;
  static final List<String> allowedNames = [for (final v in values) v.name];
  static TargetCPU fromName(String name) => values.byName(name);
}
