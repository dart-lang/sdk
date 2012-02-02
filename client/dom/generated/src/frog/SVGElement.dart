
class _SVGElementJs extends _ElementJs implements SVGElement native "*SVGElement" {

  String get id() native "return this.id;";

  void set id(String value) native "this.id = value;";

  _SVGSVGElementJs get ownerSVGElement() native "return this.ownerSVGElement;";

  _SVGElementJs get viewportElement() native "return this.viewportElement;";

  String get xmlbase() native "return this.xmlbase;";

  void set xmlbase(String value) native "this.xmlbase = value;";
}
