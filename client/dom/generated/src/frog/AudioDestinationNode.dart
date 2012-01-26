
class AudioDestinationNodeJs extends AudioNodeJs implements AudioDestinationNode native "*AudioDestinationNode" {

  int get numberOfChannels() native "return this.numberOfChannels;";
}
