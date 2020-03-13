// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_getters_setters`

import 'package:meta/meta.dart';

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

class Box5 {
  var _contents;
  @protected
  get contents => _contents; //OK (protected)
  set contents(value) {
    _contents = value;
  }
}

class Box6 {
  var _contents;
  @Deprecated('blah')
  get contents => _contents; //OK (deprecated)
  set contents(value) {
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
