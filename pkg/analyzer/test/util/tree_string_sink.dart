// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Wrapper around a [StringSink] for writing tree structures.
class TreeStringSink {
  final StringSink _sink;
  String _indent = '';

  TreeStringSink({
    required StringSink sink,
    required String indent,
  })  : _sink = sink,
        _indent = indent;

  void withIndent(void Function() f) {
    final indent = _indent;
    _indent = '$indent  ';
    f();
    _indent = indent;
  }

  void write(Object object) {
    _sink.write(object);
  }

  void writeElements<T extends Object>(
    String name,
    List<T> elements,
    void Function(T) f,
  ) {
    if (elements.isNotEmpty) {
      writelnWithIndent(name);
      withIndent(() {
        for (var element in elements) {
          f(element);
        }
      });
    }
  }

  void writeIf(bool flag, Object object) {
    if (flag) {
      write(object);
    }
  }

  void writeIndent() {
    _sink.write(_indent);
  }

  void writeIndentedLine(void Function() f) {
    writeIndent();
    f();
    writeln();
  }

  void writeln([Object? object = '']) {
    _sink.writeln(object);
  }

  void writelnWithIndent(Object object) {
    _sink.write(_indent);
    _sink.writeln(object);
  }

  void writeWithIndent(Object object) {
    _sink.write(_indent);
    _sink.write(object);
  }
}
