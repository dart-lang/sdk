
class OfflineAudioCompletionEventJs extends EventJs implements OfflineAudioCompletionEvent native "*OfflineAudioCompletionEvent" {

  AudioBufferJs get renderedBuffer() native "return this.renderedBuffer;";
}
