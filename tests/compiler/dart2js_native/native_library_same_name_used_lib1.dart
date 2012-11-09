// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'I' is the name of an interface and the name of the native class.

library native_library_same_name_used_lib1;

import 'native_library_same_name_used_lib2.dart';

interface I {
  I read();
  write(I x);
}

makeI() native { new Impl(); }  // Hint Impl is created by makeI.
