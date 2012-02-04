
class _CharacterDataJs extends _NodeJs implements CharacterData native "*CharacterData" {

  String data;

  final int length;

  void appendData(String data) native;

  void deleteData(int offset, int length) native;

  void insertData(int offset, String data) native;

  void replaceData(int offset, int length, String data) native;

  String substringData(int offset, int length) native;
}
