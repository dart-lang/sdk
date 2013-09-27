// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  Completer done = new Completer();
  List events = [];

  // runGuarded calls run, captures the synchronous error (if any) and
  // gives that one to handleUncaughtError.

  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked;
  Map zoneValues = new Map();
  var foo = const Symbol("foo");
  var bar = const Symbol("bar");
  zoneValues[foo] = 499;
  zoneValues[bar] = [];
  forked = Zone.current.fork(zoneValues: zoneValues);

  Expect.identical(Zone.ROOT, Zone.current);
  Expect.isNull(Zone.current[foo]);
  Expect.isNull(Zone.current[bar]);

  forked.run(() {
    Expect.equals(499, Zone.current[foo]);
    Expect.listEquals([], Zone.current[bar]);
    Zone.current[bar].add(42);
  });
  Expect.identical(Zone.ROOT, Zone.current);
  Expect.isNull(Zone.current[foo]);
  Expect.isNull(Zone.current[bar]);

  forked.run(() {
    Expect.equals(499, Zone.current[foo]);
    Expect.listEquals([42], Zone.current[bar]);
  });

  zoneValues = new Map();
  var gee = const Symbol("gee");
  zoneValues[gee] = 99;
  zoneValues[foo] = -499;
  Zone forkedChild = forked.fork(zoneValues: zoneValues);

  forkedChild.run(() {
    Expect.equals(-499, Zone.current[foo]);
    Expect.listEquals([42], Zone.current[bar]);
    Expect.equals(99, Zone.current[gee]);
  });
}