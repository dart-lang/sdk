// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=
// VMOptions=--use_compactor
// VMOptions=--use_compactor --force_evacuation

import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

// small example from [Lenguaer & Tarjan 1979]
class R {
  // All fields are marked with @pragma("vm:entry-point")
  // in order to make sure they are not removed by the tree shaker
  // even though they are never read.
  @pragma("vm:entry-point")
  var x;
  @pragma("vm:entry-point")
  var y;
  @pragma("vm:entry-point")
  var z;
}

class A {
  @pragma("vm:entry-point")
  var x;
}

class B {
  @pragma("vm:entry-point")
  var x;
  @pragma("vm:entry-point")
  var y;
  @pragma("vm:entry-point")
  var z;
}

class C {
  @pragma("vm:entry-point")
  var x;
  @pragma("vm:entry-point")
  var y;
}

class D {
  @pragma("vm:entry-point")
  var x;
}

class E {
  @pragma("vm:entry-point")
  var x;
}

class F {
  @pragma("vm:entry-point")
  var x;
}

class G {
  @pragma("vm:entry-point")
  var x;
  @pragma("vm:entry-point")
  var y;
}

class H {
  @pragma("vm:entry-point")
  var x;
  @pragma("vm:entry-point")
  var y;
}

class I {
  @pragma("vm:entry-point")
  var x;
}

class J {
  @pragma("vm:entry-point")
  var x;
}

class K {
  @pragma("vm:entry-point")
  var x;
  @pragma("vm:entry-point")
  var y;
}

class L {
  @pragma("vm:entry-point")
  var x;
}

var r;

buildGraph() {
  r = new R();
  var a = new A();
  var b = new B();
  var c = new C();
  var d = new D();
  var e = new E();
  var f = new F();
  var g = new G();
  var h = new H();
  var i = new I();
  var j = new J();
  var k = new K();
  var l = new L();

  r.x = a;
  r.y = b;
  r.z = c;
  a.x = d;
  b.x = a;
  b.y = d;
  b.z = e;
  c.x = f;
  c.y = g;
  d.x = l;
  e.x = h;
  f.x = i;
  g.x = i;
  g.y = j;
  h.x = e;
  h.y = k;
  i.x = k;
  j.x = i;
  k.x = i;
  k.y = r;
  l.x = h;
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    final graph = await isolate.fetchHeapSnapshot().done;

    node(String className) {
      return graph.objects.singleWhere((v) => v.klass.name == className);
    }

    expect(node('I').parent, equals(node('R')));
    expect(node('K').parent, equals(node('R')));
    expect(node('C').parent, equals(node('R')));
    expect(node('H').parent, equals(node('R')));
    expect(node('E').parent, equals(node('R')));
    expect(node('A').parent, equals(node('R')));
    expect(node('D').parent, equals(node('R')));
    expect(node('B').parent, equals(node('R')));

    expect(node('F').parent, equals(node('C')));
    expect(node('G').parent, equals(node('C')));
    expect(node('J').parent, equals(node('G')));
    expect(node('L').parent, equals(node('D')));

    expect(node('R'), isNotNull); // The field.
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: buildGraph);
