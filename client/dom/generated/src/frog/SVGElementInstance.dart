
class _SVGElementInstanceJs extends _DOMTypeJs implements SVGElementInstance native "*SVGElementInstance" {

  _SVGElementInstanceListJs get childNodes() native "return this.childNodes;";

  _SVGElementJs get correspondingElement() native "return this.correspondingElement;";

  _SVGUseElementJs get correspondingUseElement() native "return this.correspondingUseElement;";

  _SVGElementInstanceJs get firstChild() native "return this.firstChild;";

  _SVGElementInstanceJs get lastChild() native "return this.lastChild;";

  _SVGElementInstanceJs get nextSibling() native "return this.nextSibling;";

  _SVGElementInstanceJs get parentNode() native "return this.parentNode;";

  _SVGElementInstanceJs get previousSibling() native "return this.previousSibling;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
