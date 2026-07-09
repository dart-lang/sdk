// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension AmbiguousExtension1 on String {
  static void ambiguousStaticMethod1() {}
}

extension AmbiguousExtension2 on String {
  static void unambiguousStaticMethod1() {}
}

extension UnambiguousExtension1 on String {
  static void ambiguousStaticMethod2() {}
}
