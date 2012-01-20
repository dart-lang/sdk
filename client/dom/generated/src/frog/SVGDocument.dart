
class SVGDocument extends Document native "*SVGDocument" {

  SVGSVGElement get rootElement() native "return this.rootElement;";

  Event createEvent(String eventType) native;
}
