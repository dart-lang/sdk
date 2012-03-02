
class _OfflineAudioCompletionEventImpl extends _EventImpl implements OfflineAudioCompletionEvent {
  _OfflineAudioCompletionEventImpl._wrap(ptr) : super._wrap(ptr);

  AudioBuffer get renderedBuffer() => _wrap(_ptr.renderedBuffer);
}
