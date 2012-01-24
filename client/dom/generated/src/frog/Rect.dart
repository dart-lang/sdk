
class RectJS implements Rect native "*Rect" {

  CSSPrimitiveValueJS get bottom() native "return this.bottom;";

  CSSPrimitiveValueJS get left() native "return this.left;";

  CSSPrimitiveValueJS get right() native "return this.right;";

  CSSPrimitiveValueJS get top() native "return this.top;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
