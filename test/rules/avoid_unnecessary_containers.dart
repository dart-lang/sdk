// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_unnecessary_containers`

// ignore_for_file: prefer_expression_function_bodies

import 'package:flutter/widgets.dart';

Widget w() {
  return Container( // LINT
    child: Row(),
  );
}

Widget ww() {
  return Container( // OK
    child: Row(),
    width: 10,
    height: 10,
  );
}

Widget www() {
  return Container( // OK
  );
}
