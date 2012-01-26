
class CharacterDataJs extends NodeJs implements CharacterData native "*CharacterData" {

  String get data() native "return this.data;";

  void set data(String value) native "this.data = value;";

  int get length() native "return this.length;";

  void appendData(String data) native;

  void deleteData(int offset, int length) native;

  void insertData(int offset, String data) native;

  void replaceData(int offset, int length, String data) native;

  String substringData(int offset, int length) native;
}
