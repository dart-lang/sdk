part of dart.core;

class StringBuffer implements StringSink {
  StringBuffer([Object content = ""]) : _contents = '$content';
  int get length => DDC$RT.cast(_contents.length, dynamic, int, "CastGeneral",
      """line 23, column 21 of dart:core/string_buffer.dart: """,
      _contents.length is int, true);
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
  void write(Object obj) {
    _writeString('$obj');
  }
  void writeCharCode(int charCode) {
    _writeString(new String.fromCharCode(charCode));
  }
  void writeAll(Iterable objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }
  void writeln([Object obj = ""]) {
    write(obj);
    write("\n");
  }
  void clear() {
    _contents = "";
  }
  String toString() => ((__x40) => DDC$RT.cast(__x40, dynamic, String,
      "CastGeneral", """line 73, column 24 of dart:core/string_buffer.dart: """,
      __x40 is String, true))(Primitives.flattenString(_contents));
}
