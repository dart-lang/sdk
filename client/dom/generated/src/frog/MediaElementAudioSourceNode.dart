
class MediaElementAudioSourceNodeJs extends AudioSourceNodeJs implements MediaElementAudioSourceNode native "*MediaElementAudioSourceNode" {

  HTMLMediaElementJs get mediaElement() native "return this.mediaElement;";
}
