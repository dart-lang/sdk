// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BoxBad {
  var _contents;
  get contents => _contents; //LINT [7:8]
}

class BoxGood {
  final contents = [];
}

class Bad {
  var _x;
  get x { //LINT
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