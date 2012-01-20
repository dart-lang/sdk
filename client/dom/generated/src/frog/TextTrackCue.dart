
class TextTrackCue native "*TextTrackCue" {

  String get alignment() native "return this.alignment;";

  void set alignment(String value) native "this.alignment = value;";

  String get direction() native "return this.direction;";

  void set direction(String value) native "this.direction = value;";

  num get endTime() native "return this.endTime;";

  void set endTime(num value) native "this.endTime = value;";

  String get id() native "return this.id;";

  void set id(String value) native "this.id = value;";

  int get linePosition() native "return this.linePosition;";

  void set linePosition(int value) native "this.linePosition = value;";

  EventListener get onenter() native "return this.onenter;";

  void set onenter(EventListener value) native "this.onenter = value;";

  EventListener get onexit() native "return this.onexit;";

  void set onexit(EventListener value) native "this.onexit = value;";

  bool get pauseOnExit() native "return this.pauseOnExit;";

  void set pauseOnExit(bool value) native "this.pauseOnExit = value;";

  int get size() native "return this.size;";

  void set size(int value) native "this.size = value;";

  bool get snapToLines() native "return this.snapToLines;";

  void set snapToLines(bool value) native "this.snapToLines = value;";

  num get startTime() native "return this.startTime;";

  void set startTime(num value) native "this.startTime = value;";

  String get text() native "return this.text;";

  void set text(String value) native "this.text = value;";

  int get textPosition() native "return this.textPosition;";

  void set textPosition(int value) native "this.textPosition = value;";

  TextTrack get track() native "return this.track;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  DocumentFragment getCueAsHTML() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
