
class _SVGElementImpl extends _ElementImpl implements SVGElement native "*SVGElement" {

  // Shadowing definition.
  String get id() native "return this.id;";

  void set id(String value) native "this.id = value;";

  final _SVGSVGElementImpl ownerSVGElement;

  final _SVGElementImpl viewportElement;

  String xmlbase;
}
