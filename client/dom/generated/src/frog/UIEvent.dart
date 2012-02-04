
class _UIEventJs extends _EventJs implements UIEvent native "*UIEvent" {

  final int charCode;

  final int detail;

  final int keyCode;

  final int layerX;

  final int layerY;

  final int pageX;

  final int pageY;

  final _DOMWindowJs view;

  final int which;

  void initUIEvent(String type, bool canBubble, bool cancelable, _DOMWindowJs view, int detail) native;
}
