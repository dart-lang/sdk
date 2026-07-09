// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ambiguous_lib1.dart';
import 'ambiguous_lib2.dart';

test() {
  AmbiguousExtension1.ambiguousStaticMethod1(); // Error
  AmbiguousExtension2.unambiguousStaticMethod1(); // Error
  UnambiguousExtension1.ambiguousStaticMethod2(); // Ok
  UnambiguousExtension2.ambiguousStaticMethod2(); // Ok
}
