// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for the evaluation order of getters and setters.

import 'package:expect/expect.dart';

var trace;

class X {
  get b {
    trace.add('get b');
    return new X();
  }

  set c(value) {
    trace.add('set c');
  }

  toString() {
    trace.add('toString');
    return 'X';
  }

  get c {
    trace.add('get c');
    return 42;
  }

  get d {
    trace.add('get d');
    return new X();
  }

  operator [](index) {
    trace.add('index');
    return 42;
  }

  operator []=(index, value) {
    trace.add('indexSet');
  }
}

main() {
  var x = new X();

  trace = [];
  x.b.c = '$x';
  Expect.listEquals(['get b', 'toString', 'set c'], trace);

  trace = [];
  x.b.c += '$x'.hashCode;
  Expect.listEquals(['get b', 'get c', 'toString', 'set c'], trace);

  trace = [];
  x.b.c++;
  Expect.listEquals(['get b', 'get c', 'set c'], trace);

  trace = [];
  x.b.d[42] = '$x';
  Expect.listEquals(['get b', 'get d', 'toString', 'indexSet'], trace);

  trace = [];
  x.b.d[42] += '$x'.hashCode;
  Expect.listEquals(['get b', 'get d', 'index', 'toString', 'indexSet'], trace);

  trace = [];
  x.b.d[42]++;
  Expect.listEquals(['get b', 'get d', 'index', 'indexSet'], trace);

  trace = [];
  ++x.b.d[42];
  Expect.listEquals(['get b', 'get d', 'index', 'indexSet'], trace);

  trace = [];
  x.b.d[x.c] *= '$x'.hashCode;
  Expect.listEquals(
      ['get b', 'get d', 'get c', 'index', 'toString', 'indexSet'], trace);

  trace = [];
  x.b.c = x.d.c = '$x';
  Expect.listEquals([
    'get b',
    'get d',
    'toString',
    'set c',
    'set c',
  ], trace);

  trace = [];
  x.b.c = x.d[42] *= '$x'.hashCode;
  Expect.listEquals(
      ['get b', 'get d', 'index', 'toString', 'indexSet', 'set c'], trace);

  trace = [];
  x.b.c = ++x.d.c;
  Expect.listEquals(['get b', 'get d', 'get c', 'set c', 'set c'], trace);
}
