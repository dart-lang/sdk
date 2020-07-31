// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  /*1:main*/ test();
}

test() async {
  // TODO(johnniwinther): Investigate why kernel doesn't point to the body
  // start brace.
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*2:test*/ c = new /*4:test*/ Class();
}

class Class {
  @pragma('dart2js:noInline')
  Class() {
    /*6:Class*/ throw '>ExceptionMarker<';
  }
}
