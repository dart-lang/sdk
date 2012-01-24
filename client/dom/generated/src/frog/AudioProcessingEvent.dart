
class AudioProcessingEventJs extends EventJs implements AudioProcessingEvent native "*AudioProcessingEvent" {

  AudioBufferJs get inputBuffer() native "return this.inputBuffer;";

  AudioBufferJs get outputBuffer() native "return this.outputBuffer;";
}
