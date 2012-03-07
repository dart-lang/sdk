
class _ClipboardImpl implements Clipboard native "*Clipboard" {

  String dropEffect;

  String effectAllowed;

  final _FileListImpl files;

  final _DataTransferItemListImpl items;

  final List<String> types;

  void clearData([String type = null]) native;

  void getData(String type) native;

  bool setData(String type, String data) native;

  void setDragImage(_ImageElementImpl image, int x, int y) native;
}
