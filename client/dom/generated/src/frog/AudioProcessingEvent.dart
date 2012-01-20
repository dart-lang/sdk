
class AudioProcessingEvent extends Event native "*AudioProcessingEvent" {

  AudioBuffer get inputBuffer() native "return this.inputBuffer;";

  AudioBuffer get outputBuffer() native "return this.outputBuffer;";
}
