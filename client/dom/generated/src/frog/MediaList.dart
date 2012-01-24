
class MediaListJs extends DOMTypeJs implements MediaList native "*MediaList" {

  int get length() native "return this.length;";

  String get mediaText() native "return this.mediaText;";

  void set mediaText(String value) native "this.mediaText = value;";

  String operator[](int index) native;

  void operator[]=(int index, String value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void appendMedium(String newMedium) native;

  void deleteMedium(String oldMedium) native;

  String item(int index) native;
}
