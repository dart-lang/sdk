// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

var x = () => "x";

class C<T> {
  var v = (x) => x is T;

  final y = () => "y";

  static final z = () => "z";
}

main() {
  if (!new C<String>().v("")) throw "C<String>.v false on String";
  if (new C<String>().v(0)) throw "C<String>.v true on int";
  if (new C<String>().v(null)) throw "C<String>.v true on null";
  if (new C<int>().v("")) throw "C<int>.v true on String";
  if (!new C<int>().v(0)) throw "C<int>.v false on int";
  if (new C<int>().v(null)) throw "C<int>.v true on null";
  if ("x" != x()) throw "x";
  if ("y" != new C<String>().y()) throw "y";
  if ("z" != C.z()) throw "z";
}
