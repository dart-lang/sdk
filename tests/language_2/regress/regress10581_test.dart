// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://code.google.com/p/dart/issues/detail?id=10581.

import 'package:expect/expect.dart';

abstract class AxesObject {
  Update();
}

String result = '';

class Point2DObject extends AxesObject {
  Update() {
    result += 'P';
  }
}

class BestFitObject extends AxesObject {
  Update() {
    result += 'B';
  }
}

class Foo {
  AddAxesObject(type) {
    AxesObject a = null;
    switch (type) {
      case 100:
        a = new Point2DObject();
        break;
      case 200:
        a = new BestFitObject();
        break;
    }
    if (a != null) {
      a.Update();
    }
  }

  AddAxesObject2(type) {
    AxesObject a = null;
    if (type == 100) {
      a = new Point2DObject();
    } else if (type == 200) {
      a = new BestFitObject();
    }
    if (a != null) {
      a.Update();
    }
  }
}

main() {
  var f = new Foo();
  f.AddAxesObject(100);
  f.AddAxesObject(200);
  f.AddAxesObject2(100);
  f.AddAxesObject2(200);
  Expect.equals('PBPB', result);
}
