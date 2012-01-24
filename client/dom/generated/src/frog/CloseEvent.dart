
class CloseEventJS extends EventJS implements CloseEvent native "*CloseEvent" {

  int get code() native "return this.code;";

  String get reason() native "return this.reason;";

  bool get wasClean() native "return this.wasClean;";
}
