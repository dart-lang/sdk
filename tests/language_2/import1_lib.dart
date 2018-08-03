// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library import1_lib;

int libfunc(a, b) => a + b;

var show = 'show';
var hide = 'hide';

var ugly = 'ugly';

class Q {
  var _s;
  Q(s) : _s = s;
  toString() => "LQQK: '$_s'";
}
