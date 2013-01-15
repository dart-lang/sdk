// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_mangling_test;

import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

main() {
  test("Self referencing arrays serialize correctly", () {
    var messageBox = new MessageBox();
    var stream = messageBox.stream;
    var sink = messageBox.sink;
    var nested = [];
    nested.add(nested);
    Expect.identical(nested, nested[0]);
    stream.listen(expectAsync1((data) {
      Expect.isFalse(identical(nested, data));
      Expect.isTrue(data is List);
      Expect.equals(1, data.length);
      Expect.identical(data, data[0]);
      stream.close();
    }));
    sink.add(nested);
  });

  test("Self referencing arrays serialize correctly 2", () {
    var messageBox = new MessageBox();
    var stream = messageBox.stream;
    var sink = messageBox.sink;
    var nested = [0, 1];
    nested.add(nested);
    nested.add(3);
    nested.add(4);
    Expect.identical(nested, nested[2]);
    stream.listen(expectAsync1((data) {
      Expect.isFalse(identical(nested, data));
      Expect.isTrue(data is List);
      Expect.equals(5, data.length);
      Expect.identical(data, data[2]);
      Expect.equals(0, data[0]);
      Expect.equals(1, data[1]);
      Expect.equals(3, data[3]);
      Expect.equals(4, data[4]);
      stream.close();
    }));
    sink.add(nested);
  });

  test("Self referencing arrays serialize correctly 3", () {
    var messageBox = new MessageBox();
    var stream = messageBox.stream;
    var sink = messageBox.sink;
    var nested = [[[[[0, 1]]]]];
    nested.add(nested);
    nested[0][0][0][0].add(nested);
    nested.add(3);
    nested.add(4);
    Expect.identical(nested, nested[0][0][0][0][2]);
    stream.listen(expectAsync1((data) {
      Expect.isFalse(identical(nested, data));
      Expect.isTrue(data is List);
      Expect.equals(4, data.length);
      Expect.equals(1, data[0].length);
      Expect.equals(1, data[0][0].length);
      Expect.equals(1, data[0][0][0].length);
      Expect.equals(3, data[0][0][0][0].length);
      Expect.identical(data, data[0][0][0][0][2]);
      Expect.identical(data, data[1]);
      Expect.equals(3, data[2]);
      Expect.equals(4, data[3]);
      stream.close();
    }));
    sink.add(nested);
  });

  test("Self referencing maps serialize correctly", () {
    var messageBox = new MessageBox();
    var stream = messageBox.stream;
    var sink = messageBox.sink;
    var nested = {};
    nested["foo"] = nested;
    Expect.identical(nested, nested["foo"]);
    stream.listen(expectAsync1((data) {
      Expect.isFalse(identical(nested, data));
      Expect.isTrue(data is Map);
      Expect.equals(1, data.length);
      Expect.identical(data, data["foo"]);
      stream.close();
    }));
    sink.add(nested);
  });

  test("Sending of IsolateSinks", () {
    // TODO(floitsch): add test.
  });

  test("Sending of IsolateSinks in complicated structures", () {
    // TODO(floitsch): add test.
  });
}