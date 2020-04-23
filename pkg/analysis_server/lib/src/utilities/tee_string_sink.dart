// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A [StringSink] that writes into two other [StringSink]s.
class TeeStringSink implements StringSink {
  final StringSink sink1;
  final StringSink sink2;

  TeeStringSink(this.sink1, this.sink2);

  @override
  void write(Object obj) {
    sink1.write(obj);
    sink2.write(obj);
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    sink1.writeAll(objects, separator);
    sink2.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    sink1.writeCharCode(charCode);
    sink2.writeCharCode(charCode);
  }

  @override
  void writeln([Object obj = '']) {
    sink1.writeln(obj);
    sink2.writeln(obj);
  }
}
