
class _MouseEventImpl extends _UIEventImpl implements MouseEvent native "*MouseEvent" {

  final bool altKey;

  final int button;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final _ClipboardImpl dataTransfer;

  final _NodeImpl fromElement;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  _EventTargetImpl get relatedTarget() => _FixHtmlDocumentReference(_relatedTarget);

  _EventTargetImpl get _relatedTarget() native "return this.relatedTarget;";

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final _NodeImpl toElement;

  final int x;

  final int y;

  void _initMouseEvent(String type, bool canBubble, bool cancelable, _WindowImpl view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, _EventTargetImpl relatedTarget) native "this.initMouseEvent(type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget);";
}
