
class _HTMLDocumentJs extends _DocumentJs implements HTMLDocument native "*HTMLDocument" {

  final _ElementJs activeElement;

  String alinkColor;

  _HTMLAllCollectionJs all;

  String bgColor;

  final String compatMode;

  String designMode;

  String dir;

  final _HTMLCollectionJs embeds;

  String fgColor;

  String linkColor;

  final _HTMLCollectionJs plugins;

  final _HTMLCollectionJs scripts;

  String vlinkColor;

  void captureEvents() native;

  void clear() native;

  void close() native;

  bool hasFocus() native;

  void open() native;

  void releaseEvents() native;

  void write(String text) native;

  void writeln(String text) native;
}
