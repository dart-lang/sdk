
class OfflineAudioCompletionEventJS extends EventJS implements OfflineAudioCompletionEvent native "*OfflineAudioCompletionEvent" {

  AudioBufferJS get renderedBuffer() native "return this.renderedBuffer;";
}
