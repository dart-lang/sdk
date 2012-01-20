
class Rect native "*Rect" {

  CSSPrimitiveValue get bottom() native "return this.bottom;";

  CSSPrimitiveValue get left() native "return this.left;";

  CSSPrimitiveValue get right() native "return this.right;";

  CSSPrimitiveValue get top() native "return this.top;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
