
class _UIEventImpl extends _EventImpl implements UIEvent native "*UIEvent" {

  final int charCode;

  final int detail;

  final int keyCode;

  final int layerX;

  final int layerY;

  final int pageX;

  final int pageY;

  final _WindowImpl view;

  final int which;

  void initUIEvent(String type, bool canBubble, bool cancelable, _WindowImpl view, int detail) native;
}
