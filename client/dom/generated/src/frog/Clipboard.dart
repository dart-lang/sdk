
class Clipboard native "*Clipboard" {

  String dropEffect;

  String effectAllowed;

  FileList files;

  DataTransferItemList items;

  List types;

  void clearData([String type = null]) native;

  void getData(String type) native;

  bool setData(String type, String data) native;

  void setDragImage(HTMLImageElement image, int x, int y) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
