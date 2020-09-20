// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension TestExtension on int {
  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
}

extension UnusedExtension on int {
  bool get isReallyZero => this == 0;
}
