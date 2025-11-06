// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

main() {
  var a = () {};
  var b = () {
    return;
  };
  var c = () {
    return null;
  };
  var d = () {
    return 0;
  };
  var e = (bool b) {
    if (b) {
      return;
    } else {
      return;
    }
  };
  var f = (bool b) {
    if (b) {
      return;
    } else {
      return null;
    }
  };
  var g = (bool b) {
    if (b) {
      return;
    } else {
      return 0;
    }
  };
  var h = (bool b) {
    if (b) {
      return null;
    } else {
      return;
    }
  };
  var i = (bool b) {
    if (b) {
      return null;
    } else {
      return null;
    }
  };
  var j = (bool b) {
    if (b) {
      return null;
    } else {
      return 0;
    }
  };
  var k = (bool b) {
    if (b) {
      return 0;
    } else {
      return;
    }
  };
  var l = (bool b) {
    if (b) {
      return 0;
    } else {
      return null;
    }
  };
  var m = (bool b) {
    if (b) {
      return 0;
    } else {
      return 0;
    }
  };
}
