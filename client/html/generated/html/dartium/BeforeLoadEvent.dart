
class _BeforeLoadEventImpl extends _EventImpl implements BeforeLoadEvent {
  _BeforeLoadEventImpl._wrap(ptr) : super._wrap(ptr);

  String get url() => _wrap(_ptr.url);
}
