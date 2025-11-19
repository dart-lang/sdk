// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1 {
  new ();
}

class C2 {
  var x;
  new () : x = 0;
}

class C3 {
  new () {}
}

class C4 {
  var x;
  new () : x = 0 {}
}

class C5 {
  const new ();
}

class C6 {
  var x;
  const new () : x = 0;
}

class C7 {
  const new () {}
}

class C8 {
  var x;
  const new () : x = 0 {}
}

class C9 {
  new named();
}

class C10 {
  var x;
  new named() : x = 0;
}

class C11 {
  new named() {}
}

class C12 {
  var x;
  new named() : x = 0 {}
}

class C13 {
  const new named();
}

class C14 {
  final x;
  const new named() : x = 0;
}

class C15 {
  const new named() {}
}

class C16 {
  final x;
  const new named() : x = 0 {}
}