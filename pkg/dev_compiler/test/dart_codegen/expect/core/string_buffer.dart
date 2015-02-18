part of dart.core;

class StringBuffer implements StringSink {
  external StringBuffer([Object content = ""]);
  external int get length;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
  external void write(Object obj);
  external void writeCharCode(int charCode);
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
  external void clear();
  external String toString();
}
