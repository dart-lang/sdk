// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:expect/expect.dart';

// This test implements a new special interface that can be used to
// send data more efficiently between two converters.

abstract class MyChunkedIntSink extends ChunkedConversionSink<int> {
  MyChunkedIntSink();
  factory MyChunkedIntSink.from(sink) = IntAdapterSink;
  factory MyChunkedIntSink.withCallback(callback) {
    var sink = new ChunkedConversionSink.withCallback(callback);
    return new MyChunkedIntSink.from(sink);
  }

  add(int i);
  close();

  // The special method.
  void specialI(int i);
}

class IntAdapterSink extends MyChunkedIntSink {
  final _sink;
  IntAdapterSink(this._sink);
  add(o) => _sink.add(o);
  close() => _sink.close();
  void specialI(int o) => add(o);
}

abstract class MyChunkedBoolSink extends ChunkedConversionSink<bool> {
  MyChunkedBoolSink();
  factory MyChunkedBoolSink.from(sink) = BoolAdapterSink;
  factory MyChunkedBoolSink.withCallback(callback) {
    var sink = new ChunkedConversionSink.withCallback(callback);
    return new MyChunkedBoolSink.from(sink);
  }

  add(bool b);
  close();

  specialB(bool b);
}

class BoolAdapterSink extends MyChunkedBoolSink {
  final _sink;
  BoolAdapterSink(this._sink);
  add(o) => _sink.add(o);
  close() => _sink.close();
  specialB(o) => add(o);
}

class IntBoolConverter1 extends Converter<int, bool> {
  bool convert(int input) => input > 0;

  startChunkedConversion(sink) {
    if (sink is! MyChunkedBoolSink) sink = new MyChunkedBoolSink.from(sink);
    return new IntBoolConverter1Sink(sink);
  }
}

class BoolIntConverter1 extends Converter<bool, int> {
  int convert(bool input) => input ? 1 : 0;

  startChunkedConversion(sink) {
    if (sink is! MyChunkedIntSink) sink = new MyChunkedIntSink.from(sink);
    return new BoolIntConverter1Sink(sink);
  }
}

int specialICounter = 0;
int specialBCounter = 0;

class IntBoolConverter1Sink extends MyChunkedIntSink {
  var outSink;
  IntBoolConverter1Sink(this.outSink);

  add(int i) {
    outSink.specialB(i > 0);
  }

  void specialI(int i) {
    specialICounter++;
    add(i);
  }

  close() => outSink.close();
}

class BoolIntConverter1Sink extends MyChunkedBoolSink {
  var outSink;
  BoolIntConverter1Sink(this.outSink);

  add(bool b) {
    outSink.specialI(b ? 1 : 0);
  }

  specialB(bool b) {
    specialBCounter++;
    add(b);
  }

  close() => outSink.close();
}

class IdentityConverter<T> extends Converter<T, T> {
  T convert(T x) => x;

  startChunkedConversion(sink) {
    return new IdentitySink<T>(sink);
  }
}

class IdentitySink<T> extends ChunkedConversionSink<T> {
  final _sink;
  IdentitySink(this._sink);
  void add(T o) => _sink.add(o);
  close() => _sink.close();
}

main() {
  var intSink, boolSink, sink, sink2;

  // Test int->bool converter individually.
  Converter<int, bool> int2boolConverter = new IntBoolConverter1();
  Expect.listEquals(
      [true, false, true], [2, -2, 2].map(int2boolConverter.convert).toList());
  var hasExecuted = false;
  boolSink = new MyChunkedBoolSink.withCallback((value) {
    hasExecuted = true;
    Expect.listEquals([true, false, true], value);
  });
  intSink = int2boolConverter.startChunkedConversion(boolSink);
  intSink.add(3);
  intSink.specialI(-3);
  intSink.add(3);
  intSink.close();
  Expect.isTrue(hasExecuted);
  Expect.equals(1, specialICounter);
  specialICounter = 0;
  hasExecuted = false;

  // Test bool->int converter individually.
  Converter<bool, int> bool2intConverter = new BoolIntConverter1();
  Expect.listEquals(
      [1, 0, 1], [true, false, true].map(bool2intConverter.convert).toList());
  hasExecuted = false;
  intSink = new MyChunkedIntSink.withCallback((value) {
    hasExecuted = true;
    Expect.listEquals([1, 0, 1], value);
  });
  boolSink = bool2intConverter.startChunkedConversion(intSink);
  boolSink.specialB(true);
  boolSink.add(false);
  boolSink.add(true);
  boolSink.close();
  Expect.isTrue(hasExecuted);
  Expect.equals(1, specialBCounter);
  specialBCounter = 0;
  hasExecuted = false;

  // Test identity converter indidivually.
  var identityConverter = new IdentityConverter();
  hasExecuted = false;
  sink = new ChunkedConversionSink.withCallback((value) {
    hasExecuted = true;
    Expect.listEquals([1, 2, 3], value);
  });
  sink2 = identityConverter.startChunkedConversion(sink);
  [1, 2, 3].forEach(sink2.add);
  sink2.close();
  Expect.isTrue(hasExecuted);
  hasExecuted = false;

  // Test fused converters.
  Converter<int, int> fused = int2boolConverter.fuse(bool2intConverter);
  Expect.listEquals([1, 0, 1], [2, -2, 2].map(fused.convert).toList());
  hasExecuted = false;
  Sink<int> intSink2 = new MyChunkedIntSink.withCallback((value) {
    hasExecuted = true;
    Expect.listEquals([1, 0, 1], value);
  });
  intSink = fused.startChunkedConversion(intSink2);
  intSink.specialI(3);
  intSink.add(-3);
  intSink.add(3);
  intSink.close();
  Expect.isTrue(hasExecuted);
  Expect.equals(3, specialBCounter);
  specialBCounter = 0;
  Expect.equals(1, specialICounter);
  specialICounter = 0;
  hasExecuted = false;

  // With identity in front.
  Converter<int, int> fused2 = new IdentityConverter<int>().fuse(fused);
  hasExecuted = false;
  intSink2 = new MyChunkedIntSink.withCallback((value) {
    hasExecuted = true;
    Expect.listEquals([1, 0, 1], value);
  });
  sink = fused2.startChunkedConversion(intSink2);
  Expect.isFalse(sink is MyChunkedIntSink);
  sink.add(3);
  sink.add(-3);
  sink.add(3);
  sink.close();
  Expect.isTrue(hasExecuted);
  Expect.equals(3, specialBCounter);
  specialBCounter = 0;
  Expect.equals(0, specialICounter);
  specialICounter = 0;
  hasExecuted = false;

  // With identity at the end.
  fused2 = fused.fuse(new IdentityConverter());
  hasExecuted = false;
  sink = new ChunkedConversionSink<int>.withCallback((value) {
    hasExecuted = true;
    Expect.listEquals([1, 0, 1], value);
  });
  intSink = fused2.startChunkedConversion(sink);
  Expect.isTrue(intSink is MyChunkedIntSink);
  intSink.specialI(3);
  intSink.add(-3);
  intSink.specialI(3);
  intSink.close();
  Expect.isTrue(hasExecuted);
  Expect.equals(3, specialBCounter);
  specialBCounter = 0;
  Expect.equals(2, specialICounter);
  specialICounter = 0;
  hasExecuted = false;

  // With identity between the two converters.
  fused =
      int2boolConverter.fuse(new IdentityConverter()).fuse(bool2intConverter);
  Expect.listEquals([1, 0, 1], [2, -2, 2].map(fused.convert).toList());
  hasExecuted = false;
  intSink2 = new MyChunkedIntSink.withCallback((value) {
    hasExecuted = true;
    Expect.listEquals([1, 0, 1], value);
  });
  intSink = fused.startChunkedConversion(intSink2);
  intSink.specialI(3);
  intSink.add(-3);
  intSink.add(3);
  intSink.close();
  Expect.isTrue(hasExecuted);
  Expect.equals(0, specialBCounter);
  specialBCounter = 0;
  Expect.equals(1, specialICounter);
  specialICounter = 0;
  hasExecuted = false;
}
