// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  staticCalledInForLoop();
  staticCalledInForInLoop();
  staticCalledInWhileLoop();
  staticCalledInDoLoop();
  instanceCalledInForLoop();
  staticCalledIndirectlyInForLoop();
}

/*member: _staticCalledInForLoop:loop*/
_staticCalledInForLoop() {}

/*member: _staticNotCalledInForLoop:*/
_staticNotCalledInForLoop() {}

/*member: staticCalledInForLoop:*/
staticCalledInForLoop() {
  _staticNotCalledInForLoop();
  for (int i = 0; i < 10; i++) {
    _staticCalledInForLoop();
  }
  _staticNotCalledInForLoop();
}

/*member: _staticCalledInForInLoop:loop*/
_staticCalledInForInLoop() {}

/*member: _staticNotCalledInForInLoop:*/
_staticNotCalledInForInLoop() {}

/*member: staticCalledInForInLoop:*/
staticCalledInForInLoop() {
  _staticNotCalledInForInLoop();
  // ignore: unused_local_variable
  for (int i in [1, 2, 3]) {
    _staticCalledInForInLoop();
  }
  _staticNotCalledInForInLoop();
}

/*member: _staticCalledInWhileLoop:loop*/
_staticCalledInWhileLoop() {}

/*member: _staticNotCalledInWhileLoop:*/
_staticNotCalledInWhileLoop() {}

/*member: staticCalledInWhileLoop:*/
staticCalledInWhileLoop() {
  int i = 0;
  _staticNotCalledInWhileLoop();
  while (i < 10) {
    _staticCalledInWhileLoop();
    i++;
  }
  _staticNotCalledInWhileLoop();
}

/*member: _staticCalledInDoLoop:loop*/
_staticCalledInDoLoop() {}

/*member: _staticNotCalledInDoLoop:*/
_staticNotCalledInDoLoop() {}

/*member: staticCalledInDoLoop:*/
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
  /*member: Class.constructorCalledInForLoop:loop*/
  Class.constructorCalledInForLoop();

  /*member: Class.constructorNotCalledInForLoop:*/
  Class.constructorNotCalledInForLoop();

  // TODO(johnniwinther): Should we track instance calls in loops?
  /*member: Class.instanceCalledInForLoop:loop*/
  instanceCalledInForLoop() {}

  /*member: Class.instanceNotCalledInForLoop:*/
  instanceNotCalledInForLoop() {}
}

/*member: instanceCalledInForLoop:*/
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
/*member: _staticCalledIndirectlyInForLoop:*/
_staticCalledIndirectlyInForLoop() {}

/*member: _staticCalledIndirectlyInForLoopHelper:loop*/
_staticCalledIndirectlyInForLoopHelper() => _staticCalledIndirectlyInForLoop();

/*member: staticCalledIndirectlyInForLoop:*/
staticCalledIndirectlyInForLoop() {
  for (int i = 0; i < 10; i++) {
    _staticCalledIndirectlyInForLoopHelper();
  }
}
