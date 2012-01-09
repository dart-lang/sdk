
class ErrorEvent extends Event native "*ErrorEvent" {

  String filename;

  int lineno;

  String message;
}
