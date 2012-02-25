
class _ClipboardJs extends _DOMTypeJs implements Clipboard native "*Clipboard" {

  String dropEffect;

  String effectAllowed;

  final _FileListJs files;

  final _DataTransferItemListJs items;

  void clearData([String type = null]) native;

  void getData(String type) native;

  bool setData(String type, String data) native;

  void setDragImage(_HTMLImageElementJs image, int x, int y) native;
}
