// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  /*1:main*/ test();
}

test() async {
  // TODO(johnniwinther): Investigate why kernel doesn't point to the body
  // start brace.
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*2:test*/ /*3:test*/ c = new /*4:test*/ Class();
}

class Class {
  @NoInline()
  /*5:Class*/ Class() {
    /*6:Class*/ throw '>ExceptionMarker<';
  }
}
