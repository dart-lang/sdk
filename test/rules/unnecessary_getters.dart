// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_getters`

class BoxBad {
  var _contents;
  get contents => _contents; //__LINT [9:8]
}

class BoxGood {
  final contents = [];
}

class Bad {
  var _x;
  get x //__LINT
  {
    return _x;
  }
}

class Ok {
  var _stuff;
  get stuff => _stuff;
  set stuff(stuff) {
    _stuff = stuff;
  }
}

class OkToo {
  var _x;
  get x {
    print(x);
    return _x;
  }
}

class _SuperClass {
  int _field = 0;
}

class PublicClass extends _SuperClass {
  int get field => _field; //OK
}

class Q {
  int _q; //OK
  int get q => _q;
}

q() {
  print(new Q()._q);
}
