
class SVGDocumentJS extends DocumentJS implements SVGDocument native "*SVGDocument" {

  SVGSVGElementJS get rootElement() native "return this.rootElement;";

  EventJS createEvent(String eventType) native;
}
