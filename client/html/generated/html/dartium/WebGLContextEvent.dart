
class _WebGLContextEventImpl extends _EventImpl implements WebGLContextEvent {
  _WebGLContextEventImpl._wrap(ptr) : super._wrap(ptr);

  String get statusMessage() => _wrap(_ptr.statusMessage);
}
