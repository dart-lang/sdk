// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:compiler/src/helpers/helpers.dart';

class CollectingOutput implements StatsOutput {
  final StringBuffer sb = new StringBuffer();

  void println(String text) {
    sb.write('$text\n');
  }

  String toString() => sb.toString();
}

void main() {
  testRecordElement();
  testRecordFrequency();
  testRecordCounter();
}

void testRecordElement() {
  test((Stats stats) {
    stats.recordElement('foo', 'a', data: 'first-a-data');
    stats.recordElement('foo', 'a', data: 'second-a-data');
    stats.recordElement('foo', 'b');
    stats.recordElement('bar', 'a', data: 'third-a-data');
    stats.recordElement('bar', 'c');
  }, r'''
foo: 2
 value=a data=second-a-data
 b
bar: 2
 value=a data=third-a-data
 c
''');
}

void testRecordFrequency() {
  test((Stats stats) {
    stats.recordFrequency('foo', 'a', 'first-a-data');
    stats.recordFrequency('foo', 'a', 'second-a-data');
    stats.recordFrequency('bar', 'b', 'first-b-data');
    stats.recordFrequency('foo', 'c');
    stats.recordFrequency('bar', 'b');
  }, r'''
foo:
 a: 2
  first-a-data
  second-a-data
 c: 1
bar:
 b: 2
  first-b-data
''');
}

void testRecordCounter() {
  test((Stats stats) {
    stats.recordCounter('foo', 'a');
    stats.recordCounter('foo', 'a');
    stats.recordCounter('foo', 'b');
    stats.recordCounter('bar', 'c', 'first-c-data');
    stats.recordCounter('bar', 'c', 'second-c-data');
    stats.recordCounter('bar', 'd');
    stats.recordCounter('bar', 'd');
    stats.recordCounter('baz');
    stats.recordCounter('baz');
  }, r'''
foo: 3
 count=2 example=a
 count=1 example=b
bar: 4
 count=2 examples=2
  c:
   first-c-data
   second-c-data
  d
baz: 2
''');
}

void test(f(Stats stats), expectedDump) {
  CollectingOutput output = new CollectingOutput();
  Stats stats = new ActiveStats(new ConsolePrinter(output: output));
  f(stats);
  stats.dumpStats();
  print(output.toString());
  Expect.equals(expectedDump, output.toString());
}
