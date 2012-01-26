
class RectJs extends DOMTypeJs implements Rect native "*Rect" {

  CSSPrimitiveValueJs get bottom() native "return this.bottom;";

  CSSPrimitiveValueJs get left() native "return this.left;";

  CSSPrimitiveValueJs get right() native "return this.right;";

  CSSPrimitiveValueJs get top() native "return this.top;";
}
