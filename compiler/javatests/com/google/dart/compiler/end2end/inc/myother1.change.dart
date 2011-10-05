// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Other1 {
  // The existence of this final triggers b/5078969.
  static final Function FN = () { return 42; };

  Other1() { }
}
