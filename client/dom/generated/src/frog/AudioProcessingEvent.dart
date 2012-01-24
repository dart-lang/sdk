
class AudioProcessingEventJS extends EventJS implements AudioProcessingEvent native "*AudioProcessingEvent" {

  AudioBufferJS get inputBuffer() native "return this.inputBuffer;";

  AudioBufferJS get outputBuffer() native "return this.outputBuffer;";
}
