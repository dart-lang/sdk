
class MediaList native "MediaList" {

  int length;

  String mediaText;

  String operator[](int index) native;

  void appendMedium(String newMedium) native;

  void deleteMedium(String oldMedium) native;

  String item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
