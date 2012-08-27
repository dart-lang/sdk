// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class ObjectImplementation {
  /* patch */ static String toStringImpl(Object object)
      native "Object_toString";

  /* patch */ static void noSuchMethodImpl(Object object,
                                           String functionName,
                                           List args)
      native "Object_noSuchMethod";
}
