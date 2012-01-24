
class SVGElementJS extends ElementJS implements SVGElement native "*SVGElement" {

  String get id() native "return this.id;";

  void set id(String value) native "this.id = value;";

  SVGSVGElementJS get ownerSVGElement() native "return this.ownerSVGElement;";

  SVGElementJS get viewportElement() native "return this.viewportElement;";

  String get xmlbase() native "return this.xmlbase;";

  void set xmlbase(String value) native "this.xmlbase = value;";
}
