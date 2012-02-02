
class _HTMLQuoteElementJs extends _HTMLElementJs implements HTMLQuoteElement native "*HTMLQuoteElement" {

  String get cite() native "return this.cite;";

  void set cite(String value) native "this.cite = value;";
}
