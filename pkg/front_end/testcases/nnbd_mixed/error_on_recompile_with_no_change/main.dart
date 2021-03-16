// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'object_lib.dart';
import 'main_lib1.dart';

class AdaptorElement extends RenderObject {
  Adaptor get renderObject => super.renderObject;
  void foo() {
    print(renderObject.constraints.axis);
  }
}

main() {}
