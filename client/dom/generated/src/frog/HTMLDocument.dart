
class HTMLDocument extends Document native "*HTMLDocument" {

  Element activeElement;

  String alinkColor;

  HTMLAllCollection all;

  String bgColor;

  String compatMode;

  String designMode;

  String dir;

  HTMLCollection embeds;

  String fgColor;

  int height;

  String linkColor;

  HTMLCollection plugins;

  HTMLCollection scripts;

  String vlinkColor;

  int width;

  void captureEvents() native;

  void clear() native;

  void close() native;

  bool hasFocus() native;

  void open() native;

  void releaseEvents() native;

  void write(String text) native;

  void writeln(String text) native;
}
