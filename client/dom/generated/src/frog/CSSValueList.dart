
class _CSSValueListJs extends _CSSValueJs implements CSSValueList native "*CSSValueList" {

  int get length() native "return this.length;";

  _CSSValueJs item(int index) native;
}
