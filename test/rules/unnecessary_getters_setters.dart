// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Box {
  var _contents;
  get contents => _contents; //LINT [7:8]
  set contents(value) //LINT
  {
    _contents = value;
  }
}

class Box2 {
  var _contents;
  get contents //LINT
  {
    return _contents;
  }
  set contents(value) //LINT
  {
    _contents = value;
  }
}

class Box3 {
  var _contents;
  get contents //LINT
  {
    return _contents;
  }
  set contents(value) => _contents = value; //LINT
}

class Box4 {
  var _contents;
  get contents {
    return _contents;
  }
  set contents(int value) // OK -- notice the type
  {
    _contents = value;
  }
}

class LowerCase {
  var _contents;
  get contents => _contents;
  set contents(value) {
    _contents = value.toLowerCase();
  }
}
