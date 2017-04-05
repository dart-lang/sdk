// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Unittest for the [LocationCollector].

import 'package:compiler/src/io/code_output.dart';
import 'package:compiler/src/io/location_provider.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' show Location;

import 'output_collector.dart';

test(List events, Map<int, List<int>> expectedPositions) {
  BufferedOutputSink sink = new BufferedOutputSink();
  LocationProvider locationProvider = new LocationCollector();
  CodeOutput output = new StreamCodeOutput(sink, [locationProvider]);
  for (var event in events) {
    if (event is String) {
      output.add(event);
    } else if (event is CodeBuffer) {
      output.addBuffer(event);
    }
  }
  output.close();

  expectedPositions.forEach((int offset, List<int> expectedPosition) {
    if (expectedPosition == null) {
      Expect.throws(
          () => locationProvider.getLocation(offset),
          (e) => true,
          'Expected out-of-bounds offset: $offset\n'
          'text:"""${sink.text}"""\n'
          'locationProvider:$locationProvider');
    } else {
      Location location = locationProvider.getLocation(offset);
      int line = location.line - 1;
      int column = location.column - 1;
      Expect.equals(
          expectedPosition[0],
          line,
          'Unexpected result: $offset -> $expectedPosition = [$line,$column]\n'
          'text:"""${sink.text}"""\n'
          'locationProvider:$locationProvider');
      Expect.equals(
          expectedPosition[1],
          column,
          'Unexpected result: $offset -> $expectedPosition = [$line,$column]\n'
          'text:"""${sink.text}"""\n'
          'locationProvider:$locationProvider');
    }
  });
}

main() {
  test([
    ""
  ], {
    0: [0, 0],
    1: null
  });

  test([
    " "
  ], {
    0: [0, 0],
    1: [0, 1],
    2: null
  });

  test([
    "\n "
  ], {
    0: [0, 0],
    1: [1, 0],
    2: [1, 1],
    3: null
  });

  Map positions = {
    0: [0, 0],
    1: [0, 1],
    2: [1, 0],
    3: [1, 1],
    4: [2, 0],
    5: [2, 1],
    6: null
  };

  test(["a\nb\nc"], positions);

  test(["a", "\nb\nc"], positions);

  test(["a", "\n", "b\nc"], positions);

  CodeBuffer buffer1 = new CodeBuffer();
  buffer1.add("a\nb\nc");
  test([buffer1], positions);

  CodeBuffer buffer2 = new CodeBuffer();
  buffer2.add("\nb\nc");
  test(["a", buffer2], positions);

  CodeBuffer buffer3 = new CodeBuffer();
  buffer3.add("a");
  test([buffer3, buffer2], positions);

  CodeBuffer buffer4 = new CodeBuffer();
  buffer4.addBuffer(buffer3);
  test([buffer4, buffer2], positions);
}
