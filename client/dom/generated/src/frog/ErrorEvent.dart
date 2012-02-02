
class _ErrorEventJs extends _EventJs implements ErrorEvent native "*ErrorEvent" {

  String get filename() native "return this.filename;";

  int get lineno() native "return this.lineno;";

  String get message() native "return this.message;";
}
