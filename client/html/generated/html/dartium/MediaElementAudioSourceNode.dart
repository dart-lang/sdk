
class _MediaElementAudioSourceNodeImpl extends _AudioSourceNodeImpl implements MediaElementAudioSourceNode {
  _MediaElementAudioSourceNodeImpl._wrap(ptr) : super._wrap(ptr);

  MediaElement get mediaElement() => _wrap(_ptr.mediaElement);
}
