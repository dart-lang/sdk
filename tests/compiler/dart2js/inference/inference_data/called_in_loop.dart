// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  staticCalledInForLoop();
  staticCalledInForInLoop();
  staticCalledInWhileLoop();
  staticCalledInDoLoop();
  instanceCalledInForLoop();
  staticCalledIndirectlyInForLoop();
}

/*element: _staticCalledInForLoop:loop*/
_staticCalledInForLoop() {}

/*element: _staticNotCalledInForLoop:*/
_staticNotCalledInForLoop() {}

/*element: staticCalledInForLoop:*/
staticCalledInForLoop() {
  _staticNotCalledInForLoop();
  for (int i = 0; i < 10; i++) {
    _staticCalledInForLoop();
  }
  _staticNotCalledInForLoop();
}

/*element: _staticCalledInForInLoop:loop*/
_staticCalledInForInLoop() {}

/*element: _staticNotCalledInForInLoop:*/
_staticNotCalledInForInLoop() {}

/*element: staticCalledInForInLoop:*/
staticCalledInForInLoop() {
  _staticNotCalledInForInLoop();
  // ignore: unused_local_variable
  for (int i in [1, 2, 3]) {
    _staticCalledInForInLoop();
  }
  _staticNotCalledInForInLoop();
}

/*element: _staticCalledInWhileLoop:loop*/
_staticCalledInWhileLoop() {}

/*element: _staticNotCalledInWhileLoop:*/
_staticNotCalledInWhileLoop() {}

/*element: staticCalledInWhileLoop:*/
staticCalledInWhileLoop() {
  int i = 0;
  _staticNotCalledInWhileLoop();
  while (i < 10) {
    _staticCalledInWhileLoop();
    i++;
  }
  _staticNotCalledInWhileLoop();
}

/*element: _staticCalledInDoLoop:loop*/
_staticCalledInDoLoop() {}

/*element: _staticNotCalledInDoLoop:*/
_staticNotCalledInDoLoop() {}

/*element: staticCalledInDoLoop:*/
staticCalledInDoLoop() {
  int i = 0;
  _staticNotCalledInDoLoop();
  do {
    _staticCalledInDoLoop();
    i++;
  } while (i <= 10);
  _staticNotCalledInDoLoop();
}

class Class {
  /*element: Class.constructorCalledInForLoop:loop*/
  Class.constructorCalledInForLoop();

  /*element: Class.constructorNotCalledInForLoop:*/
  Class.constructorNotCalledInForLoop();

  // TODO(johnniwinther): Should we track instance calls in loops?
  /*element: Class.instanceCalledInForLoop:*/
  instanceCalledInForLoop() {}

  /*element: Class.instanceNotCalledInForLoop:*/
  instanceNotCalledInForLoop() {}
}

/*element: instanceCalledInForLoop:*/
instanceCalledInForLoop() {
  var c = new Class.constructorNotCalledInForLoop();
  c.instanceNotCalledInForLoop();
  for (int i = 0; i < 10; i++) {
    new Class.constructorCalledInForLoop();
    c.instanceCalledInForLoop();
  }
  c.instanceNotCalledInForLoop();
}

// TODO(johnniwinther): Should we track indirect calls in loops?
/*element: _staticCalledIndirectlyInForLoop:*/
_staticCalledIndirectlyInForLoop() {}

/*element: _staticCalledIndirectlyInForLoopHelper:loop*/
_staticCalledIndirectlyInForLoopHelper() => _staticCalledIndirectlyInForLoop();

/*element: staticCalledIndirectlyInForLoop:*/
staticCalledIndirectlyInForLoop() {
  for (int i = 0; i < 10; i++) {
    _staticCalledIndirectlyInForLoopHelper();
  }
}
