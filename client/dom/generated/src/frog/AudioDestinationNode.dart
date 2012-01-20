
class AudioDestinationNode extends AudioNode native "*AudioDestinationNode" {

  int get numberOfChannels() native "return this.numberOfChannels;";
}
