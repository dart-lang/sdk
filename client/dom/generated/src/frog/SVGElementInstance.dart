
class SVGElementInstance native "*SVGElementInstance" {

  SVGElementInstanceList childNodes;

  SVGElement correspondingElement;

  SVGUseElement correspondingUseElement;

  SVGElementInstance firstChild;

  SVGElementInstance lastChild;

  SVGElementInstance nextSibling;

  SVGElementInstance parentNode;

  SVGElementInstance previousSibling;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
