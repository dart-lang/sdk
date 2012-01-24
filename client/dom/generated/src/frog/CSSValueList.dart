
class CSSValueListJS extends CSSValueJS implements CSSValueList native "*CSSValueList" {

  int get length() native "return this.length;";

  CSSValueJS item(int index) native;
}
