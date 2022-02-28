// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N use_colored_box`

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class Color {
  Color(int value);
}

Widget containerWithoutArguments() {
  return Container(); // OK
}

Widget containerWithKey() {
  return Container( // OK
    key: Key('abc'),
  );
}

Widget containerWithColor() {
  return Container( // LINT
    color: Color(0xffffffff),
  );
}

Widget containerWithChild() {
  return Container( // OK
    child: SizedBox(),
  );
}

Widget containerWithKeyAndChild() {
  return Container( // OK
    key: Key('abc'),
    child: SizedBox(),
  );
}

Widget containerWithKeyAndColor() {
  return Container( // LINT
    key: Key('abc'),
    color: Color(0xffffffff),
  );
}

Widget containerWithColorAndChild() {
  return Container( // LINT
    color: Color(0xffffffff),
    child: SizedBox(),
  );
}

Widget containerWithKeyAndColorAndChild() {
  return Container( // LINT
    key: Key('abc'),
    color: Color(0xffffffff),
    child: SizedBox(),
  );
}

Widget containerWithAnotherArgument() {
  return Container( // OK
    width: 20,
  );
}

Widget containerWithColorAndAdditionalArgument() {
  return Container( // OK
    color: Color(0xffffffff),
    width: 20,
  );
}

Widget containerWithColorAndAdditionalArgumentAndChild() {
  return Container( // OK
    color: Color(0xffffffff),
    width: 20,
    child: SizedBox(),
  );
}
