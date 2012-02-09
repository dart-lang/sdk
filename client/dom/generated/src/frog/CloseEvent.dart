
class _CloseEventJs extends _EventJs implements CloseEvent native "*CloseEvent" {

  final int code;

  final String reason;

  final bool wasClean;
}
