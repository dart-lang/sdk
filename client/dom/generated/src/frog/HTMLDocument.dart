
class HTMLDocumentJs extends DocumentJs implements HTMLDocument native "*HTMLDocument" {

  ElementJs get activeElement() native "return this.activeElement;";

  String get alinkColor() native "return this.alinkColor;";

  void set alinkColor(String value) native "this.alinkColor = value;";

  HTMLAllCollectionJs get all() native "return this.all;";

  void set all(HTMLAllCollectionJs value) native "this.all = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  String get compatMode() native "return this.compatMode;";

  String get designMode() native "return this.designMode;";

  void set designMode(String value) native "this.designMode = value;";

  String get dir() native "return this.dir;";

  void set dir(String value) native "this.dir = value;";

  HTMLCollectionJs get embeds() native "return this.embeds;";

  String get fgColor() native "return this.fgColor;";

  void set fgColor(String value) native "this.fgColor = value;";

  String get linkColor() native "return this.linkColor;";

  void set linkColor(String value) native "this.linkColor = value;";

  HTMLCollectionJs get plugins() native "return this.plugins;";

  HTMLCollectionJs get scripts() native "return this.scripts;";

  String get vlinkColor() native "return this.vlinkColor;";

  void set vlinkColor(String value) native "this.vlinkColor = value;";

  void captureEvents() native;

  void clear() native;

  void close() native;

  bool hasFocus() native;

  void open() native;

  void releaseEvents() native;

  void write(String text) native;

  void writeln(String text) native;
}
