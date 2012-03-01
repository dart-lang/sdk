
class _ErrorEventImpl extends _EventImpl implements ErrorEvent native "*ErrorEvent" {

  final String filename;

  final int lineno;

  final String message;
}
