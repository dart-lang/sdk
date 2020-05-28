// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  passMapToNull();
}

/*member: _passMapToNull:[passMapToNull]*/
_passMapToNull(f) {
  f({});
}

/*member: passMapToNull:[]*/
@pragma('dart2js:noInline')
passMapToNull() {
  _passMapToNull(null);
}
