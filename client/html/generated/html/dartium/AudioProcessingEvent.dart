
class _AudioProcessingEventImpl extends _EventImpl implements AudioProcessingEvent {
  _AudioProcessingEventImpl._wrap(ptr) : super._wrap(ptr);

  AudioBuffer get inputBuffer() => _wrap(_ptr.inputBuffer);

  AudioBuffer get outputBuffer() => _wrap(_ptr.outputBuffer);
}
