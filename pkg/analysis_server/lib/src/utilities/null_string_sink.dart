// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A string sink that ignores everything written to it.
 */
class NullStringSink implements StringSink {
  void write(Object obj) {}
  void writeAll(Iterable objects, [String separator = ""]) {}
  void writeCharCode(int charCode) {}
  void writeln([Object obj = ""]) {}
}
