
class _MouseEventImpl extends _UIEventImpl implements MouseEvent {
  _MouseEventImpl._wrap(ptr) : super._wrap(ptr);

  bool get altKey() => _wrap(_ptr.altKey);

  int get button() => _wrap(_ptr.button);

  int get clientX() => _wrap(_ptr.clientX);

  int get clientY() => _wrap(_ptr.clientY);

  bool get ctrlKey() => _wrap(_ptr.ctrlKey);

  Clipboard get dataTransfer() => _wrap(_ptr.dataTransfer);

  Node get fromElement() => _wrap(_ptr.fromElement);

  bool get metaKey() => _wrap(_ptr.metaKey);

  int get offsetX() => _wrap(_ptr.offsetX);

  int get offsetY() => _wrap(_ptr.offsetY);

  EventTarget get relatedTarget() => _FixHtmlDocumentReference(_wrap(_ptr.relatedTarget));

  int get screenX() => _wrap(_ptr.screenX);

  int get screenY() => _wrap(_ptr.screenY);

  bool get shiftKey() => _wrap(_ptr.shiftKey);

  Node get toElement() => _wrap(_ptr.toElement);

  int get x() => _wrap(_ptr.x);

  int get y() => _wrap(_ptr.y);

  void _initMouseEvent(String type, bool canBubble, bool cancelable, Window view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) {
    _ptr.initMouseEvent(_unwrap(type), _unwrap(canBubble), _unwrap(cancelable), _unwrap(view), _unwrap(detail), _unwrap(screenX), _unwrap(screenY), _unwrap(clientX), _unwrap(clientY), _unwrap(ctrlKey), _unwrap(altKey), _unwrap(shiftKey), _unwrap(metaKey), _unwrap(button), _unwrap(relatedTarget));
    return;
  }
}
