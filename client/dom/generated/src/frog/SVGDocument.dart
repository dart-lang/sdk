
class SVGDocumentJs extends DocumentJs implements SVGDocument native "*SVGDocument" {

  SVGSVGElementJs get rootElement() native "return this.rootElement;";

  EventJs createEvent(String eventType) native;
}
