
class MediaStreamList native "MediaStreamList" {

  int length;

  MediaStream item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
