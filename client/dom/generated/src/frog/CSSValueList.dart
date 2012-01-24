
class CSSValueListJs extends CSSValueJs implements CSSValueList native "*CSSValueList" {

  int get length() native "return this.length;";

  CSSValueJs item(int index) native;
}
