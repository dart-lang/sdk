
class _ErrorEventJs extends _EventJs implements ErrorEvent native "*ErrorEvent" {

  final String filename;

  final int lineno;

  final String message;
}
