
class _MediaElementAudioSourceNodeJs extends _AudioSourceNodeJs implements MediaElementAudioSourceNode native "*MediaElementAudioSourceNode" {

  _HTMLMediaElementJs get mediaElement() native "return this.mediaElement;";
}
