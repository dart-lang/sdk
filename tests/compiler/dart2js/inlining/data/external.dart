// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@JS()
library lib;

import 'package:js/js.dart';

/*member: main:[]*/
main() {
  externalFunction();
}

/*member: externalFunction:[]*/
@pragma('dart2js:noInline')
externalFunction() {
  _externalFunction();
}

/*member: _externalFunction:[]*/
@JS('externalFunction')
external _externalFunction();
