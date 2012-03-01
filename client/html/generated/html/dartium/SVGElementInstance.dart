
class _SVGElementInstanceImpl extends _EventTargetImpl implements SVGElementInstance {
  _SVGElementInstanceImpl._wrap(ptr) : super._wrap(ptr);

  SVGElementInstanceList get childNodes() => _wrap(_ptr.childNodes);

  SVGElement get correspondingElement() => _wrap(_ptr.correspondingElement);

  SVGUseElement get correspondingUseElement() => _wrap(_ptr.correspondingUseElement);

  SVGElementInstance get firstChild() => _wrap(_ptr.firstChild);

  SVGElementInstance get lastChild() => _wrap(_ptr.lastChild);

  SVGElementInstance get nextSibling() => _wrap(_ptr.nextSibling);

  SVGElementInstance get parentNode() => _wrap(_ptr.parentNode);

  SVGElementInstance get previousSibling() => _wrap(_ptr.previousSibling);

  _SVGElementInstanceEventsImpl get on() {
    if (_on == null) _on = new _SVGElementInstanceEventsImpl(this);
    return _on;
  }

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  bool _dispatchEvent(Event event) {
    return _wrap(_ptr.dispatchEvent(_unwrap(event)));
  }

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }
}

class _SVGElementInstanceEventsImpl extends _EventsImpl implements SVGElementInstanceEvents {
  _SVGElementInstanceEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get beforeCopy() => _get('beforecopy');

  EventListenerList get beforeCut() => _get('beforecut');

  EventListenerList get beforePaste() => _get('beforepaste');

  EventListenerList get blur() => _get('blur');

  EventListenerList get change() => _get('change');

  EventListenerList get click() => _get('click');

  EventListenerList get contextMenu() => _get('contextmenu');

  EventListenerList get copy() => _get('copy');

  EventListenerList get cut() => _get('cut');

  EventListenerList get doubleClick() => _get('dblclick');

  EventListenerList get drag() => _get('drag');

  EventListenerList get dragEnd() => _get('dragend');

  EventListenerList get dragEnter() => _get('dragenter');

  EventListenerList get dragLeave() => _get('dragleave');

  EventListenerList get dragOver() => _get('dragover');

  EventListenerList get dragStart() => _get('dragstart');

  EventListenerList get drop() => _get('drop');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get input() => _get('input');

  EventListenerList get keyDown() => _get('keydown');

  EventListenerList get keyPress() => _get('keypress');

  EventListenerList get keyUp() => _get('keyup');

  EventListenerList get load() => _get('load');

  EventListenerList get mouseDown() => _get('mousedown');

  EventListenerList get mouseMove() => _get('mousemove');

  EventListenerList get mouseOut() => _get('mouseout');

  EventListenerList get mouseOver() => _get('mouseover');

  EventListenerList get mouseUp() => _get('mouseup');

  EventListenerList get mouseWheel() => _get('mousewheel');

  EventListenerList get paste() => _get('paste');

  EventListenerList get reset() => _get('reset');

  EventListenerList get resize() => _get('resize');

  EventListenerList get scroll() => _get('scroll');

  EventListenerList get search() => _get('search');

  EventListenerList get select() => _get('select');

  EventListenerList get selectStart() => _get('selectstart');

  EventListenerList get submit() => _get('submit');

  EventListenerList get unload() => _get('unload');
}
