
class TextTrackListJS implements TextTrackList native "*TextTrackList" {

  int get length() native "return this.length;";

  EventListener get onaddtrack() native "return this.onaddtrack;";

  void set onaddtrack(EventListener value) native "this.onaddtrack = value;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJS evt) native;

  TextTrackJS item(int index) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
