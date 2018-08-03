// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "internal_patch.dart";

class ClassID {
  static int getID(Object value) native "ClassID_getID";

  // VM injects class id constants into this class.
}
