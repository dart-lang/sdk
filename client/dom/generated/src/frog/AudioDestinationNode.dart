
class AudioDestinationNodeJS extends AudioNodeJS implements AudioDestinationNode native "*AudioDestinationNode" {

  int get numberOfChannels() native "return this.numberOfChannels;";
}
