
class MediaElementAudioSourceNodeJS extends AudioSourceNodeJS implements MediaElementAudioSourceNode native "*MediaElementAudioSourceNode" {

  HTMLMediaElementJS get mediaElement() native "return this.mediaElement;";
}
