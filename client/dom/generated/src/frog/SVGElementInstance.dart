
class _SVGElementInstanceJs extends _EventTargetJs implements SVGElementInstance native "*SVGElementInstance" {

  final _SVGElementInstanceListJs childNodes;

  final _SVGElementJs correspondingElement;

  final _SVGUseElementJs correspondingUseElement;

  final _SVGElementInstanceJs firstChild;

  final _SVGElementInstanceJs lastChild;

  final _SVGElementInstanceJs nextSibling;

  final _SVGElementInstanceJs parentNode;

  final _SVGElementInstanceJs previousSibling;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
