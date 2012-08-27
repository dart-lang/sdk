// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface OverflowEvent extends Event default OverflowEventWrappingImplementation {

  OverflowEvent(int orient, bool horizontalOverflow, bool verticalOverflow);

  static const int BOTH = 2;

  static const int HORIZONTAL = 0;

  static const int VERTICAL = 1;

  bool get horizontalOverflow();

  int get orient();

  bool get verticalOverflow();
}
