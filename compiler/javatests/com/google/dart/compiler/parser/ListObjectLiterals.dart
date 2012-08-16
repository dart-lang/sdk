// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ListObjectLiterals {
  foo() {
    var a = [a, b, [c + 42, x], 1, 2, 3];
    var b = { 'a':1, 'b':c + 42, 'd':[0, 1, 2], 'e':{ 'foo':42, 'bar':49 }};

    var c = [a, b, ];
    var d = {'a':1, 'b':2, 'c':3};

    var e = [ ];
    var f = { };
    var g = [];
    var h = {};

    var i = const [];
    var j = const <int>[];
    var k = <int>[];
    var l = const [1,2,3];
    var m = const <int>[1,2,3];
    var n = <int>[1,2,3];

    var o = const {};
    var p = const <String, int>{};
    var q = <String, int>{};
    var r = const {'a':1, 'b':2, 'c':3};
    var s = const <int> {'a':1, 'b':2, 'c':3 };
    var t = {'a':1, 'b':2, 'c':3};
  }
}
