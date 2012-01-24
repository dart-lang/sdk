
class SVGElementInstanceJs extends DOMTypeJs implements SVGElementInstance native "*SVGElementInstance" {

  SVGElementInstanceListJs get childNodes() native "return this.childNodes;";

  SVGElementJs get correspondingElement() native "return this.correspondingElement;";

  SVGUseElementJs get correspondingUseElement() native "return this.correspondingUseElement;";

  SVGElementInstanceJs get firstChild() native "return this.firstChild;";

  SVGElementInstanceJs get lastChild() native "return this.lastChild;";

  SVGElementInstanceJs get nextSibling() native "return this.nextSibling;";

  SVGElementInstanceJs get parentNode() native "return this.parentNode;";

  SVGElementInstanceJs get previousSibling() native "return this.previousSibling;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJs event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
