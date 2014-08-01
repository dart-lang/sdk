// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import 'dart:profiler';
import 'package:expect/expect.dart';

testGauge1() {
  var gauge = new Gauge('test', 'alpha bravo', 0.0, 100.0);
  Expect.equals(0.0, gauge.min);
  Expect.equals(0.0, gauge.value);
  Expect.equals(100.0, gauge.max);
  Expect.equals('test', gauge.name);
  Expect.equals('alpha bravo', gauge.description);
  gauge.value = 44.0;
  Expect.equals(44.0, gauge.value);
  // Test setting below min.
  gauge.value = -1.0;
  Expect.equals(0.0, gauge.value);
  // Test setting above max.
  gauge.value = 101.0;
  Expect.equals(100.0, gauge.value);
}

testGauge2() {
  var gauge = new Gauge('test', 'alpha bravo', 1.0, 2.0);
  Expect.equals(1.0, gauge.min);
  Expect.equals(2.0, gauge.max);
  Expect.equals(gauge.min, gauge.value);
  Expect.equals('test', gauge.name);
  Expect.equals('alpha bravo', gauge.description);

  Expect.throws(() {
    // min > max.
    gauge = new Gauge('test', 'alpha bravo', 2.0, 1.0);
  });

  Expect.throws(() {
    // min == max.
    gauge = new Gauge('test', 'alpha bravo', 1.0, 1.0);
  });

  Expect.throws(() {
    // min is null
    gauge = new Gauge('test', 'alpha bravo', null, 1.0);
  });

  Expect.throws(() {
    // min is not a double
    gauge = new Gauge('test', 'alpha bravo', 'string', 1.0);
  });

  Expect.throws(() {
    // max is null
    gauge = new Gauge('test', 'alpha bravo', 1.0, null);
  });
}

testCounter() {
  var counter = new Counter('test', 'alpha bravo');
  Expect.equals(0.0, counter.value);
  Expect.equals('test', counter.name);
  Expect.equals('alpha bravo', counter.description);
  counter.value = 1.0;
  Expect.equals(1.0, counter.value);
}

class CustomCounter extends Counter {
  CustomCounter(name, description) : super(name, description);
  // User provided getter.
  double get value => 77.0;
}

testCustomCounter() {
  var counter = new CustomCounter('test', 'alpha bravo');
  Expect.equals(77.0, counter.value);
  Expect.equals('test', counter.name);
  Expect.equals('alpha bravo', counter.description);
  // Should have no effect.
  counter.value = 1.0;
  Expect.equals(77.0, counter.value);
}

testMetricNameCollision() {
  var counter = new Counter('a.b.c', 'alpha bravo charlie');
  var counter2 = new Counter('a.b.c', 'alpha bravo charlie collider');
  Metrics.register(counter);
  Expect.throws(() {
    Metrics.register(counter2);
  });
  Metrics.deregister(counter);
  Metrics.register(counter);
  var counter3 = new Counter('a.b.c.d', '');
  Metrics.register(counter3);
}

testBadName() {
  Expect.throws(() {
    var counter = new Counter('a.b/c', 'description');
  });
}

main() {
  testGauge1();
  testGauge2();
  testCounter();
  testCustomCounter();
  testMetricNameCollision();
  testBadName();
}
