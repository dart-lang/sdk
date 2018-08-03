// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library GetterSetterInLib3;

var _f = 33;

set bar(a) {
  _f = a;
}

get bar => _f;
