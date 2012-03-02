
class _CloseEventImpl extends _EventImpl implements CloseEvent native "*CloseEvent" {

  final int code;

  final String reason;

  final bool wasClean;
}
