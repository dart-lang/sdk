
class _MouseEventJs extends _UIEventJs implements MouseEvent native "*MouseEvent" {

  final bool altKey;

  final int button;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final _ClipboardJs dataTransfer;

  final _NodeJs fromElement;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  final _EventTargetJs relatedTarget;

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final _NodeJs toElement;

  final int webkitMovementX;

  final int webkitMovementY;

  final int x;

  final int y;

  void initMouseEvent(String type, bool canBubble, bool cancelable, _DOMWindowJs view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, _EventTargetJs relatedTarget) native;
}
