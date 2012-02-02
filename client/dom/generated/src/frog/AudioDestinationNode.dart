
class _AudioDestinationNodeJs extends _AudioNodeJs implements AudioDestinationNode native "*AudioDestinationNode" {

  int get numberOfChannels() native "return this.numberOfChannels;";
}
