// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 42997

main() {}

PropertyState();
class PropertyState<I, O> {
  void dispose() {
    for (PropertyState<Object, Object>> state in _states) ;
  }
}
