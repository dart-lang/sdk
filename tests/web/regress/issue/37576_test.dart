// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js/js.dart';

@JS('jsFun')
external set jsFun(Function fun);

void main() {
  jsFun = allowInterop(dartFun);
}

void dartFun() {}
