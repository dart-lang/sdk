// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: This test relies on LF line endings in the source file.
// It requires an entry in the .gitattributes file.

library line_endings.lf;

oneLineLF(x) => x;
multiLineLF(y) {
  return y + 1;
}
a
(){
}
