
class _SpeechInputEventImpl extends _EventImpl implements SpeechInputEvent {
  _SpeechInputEventImpl._wrap(ptr) : super._wrap(ptr);

  SpeechInputResultList get results() => _wrap(_ptr.results);
}
