// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N type_init_formals`

class Good {
  String name;
  Good(this.name);
}

class Bad {
  String name;
  Bad(String this.name); //LINT [7:6]
}
