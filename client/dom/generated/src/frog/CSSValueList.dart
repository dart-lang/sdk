
class CSSValueList extends CSSValue native "*CSSValueList" {

  int get length() native "return this.length;";

  CSSValue item(int index) native;
}
