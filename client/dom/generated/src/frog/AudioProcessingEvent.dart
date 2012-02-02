
class _AudioProcessingEventJs extends _EventJs implements AudioProcessingEvent native "*AudioProcessingEvent" {

  _AudioBufferJs get inputBuffer() native "return this.inputBuffer;";

  _AudioBufferJs get outputBuffer() native "return this.outputBuffer;";
}
