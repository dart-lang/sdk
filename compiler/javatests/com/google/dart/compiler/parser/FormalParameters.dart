// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FormalParameterSyntax {
  a([x = 42]) { }
  b([int x = 42]) { }
  c(x, [y = 42]) { }
  d(x, [int y = 42]) { }
}
