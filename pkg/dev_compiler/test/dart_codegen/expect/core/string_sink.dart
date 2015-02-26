part of dart.core;
 abstract class StringSink {void write(Object obj);
 void writeAll(Iterable objects, [String separator = ""]);
 void writeln([Object obj = ""]);
 void writeCharCode(int charCode);
}
