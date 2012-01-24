
class HTMLModElementJS extends HTMLElementJS implements HTMLModElement native "*HTMLModElement" {

  String get cite() native "return this.cite;";

  void set cite(String value) native "this.cite = value;";

  String get dateTime() native "return this.dateTime;";

  void set dateTime(String value) native "this.dateTime = value;";
}
