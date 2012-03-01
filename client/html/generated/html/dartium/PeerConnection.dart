
class _PeerConnectionImpl extends _DOMTypeBase implements PeerConnection {
  _PeerConnectionImpl._wrap(ptr) : super._wrap(ptr);

  MediaStreamList get localStreams() => _wrap(_ptr.localStreams);

  EventListener get onaddstream() => _wrap(_ptr.onaddstream);

  void set onaddstream(EventListener value) { _ptr.onaddstream = _unwrap(value); }

  EventListener get onconnecting() => _wrap(_ptr.onconnecting);

  void set onconnecting(EventListener value) { _ptr.onconnecting = _unwrap(value); }

  EventListener get onmessage() => _wrap(_ptr.onmessage);

  void set onmessage(EventListener value) { _ptr.onmessage = _unwrap(value); }

  EventListener get onopen() => _wrap(_ptr.onopen);

  void set onopen(EventListener value) { _ptr.onopen = _unwrap(value); }

  EventListener get onremovestream() => _wrap(_ptr.onremovestream);

  void set onremovestream(EventListener value) { _ptr.onremovestream = _unwrap(value); }

  EventListener get onstatechange() => _wrap(_ptr.onstatechange);

  void set onstatechange(EventListener value) { _ptr.onstatechange = _unwrap(value); }

  int get readyState() => _wrap(_ptr.readyState);

  MediaStreamList get remoteStreams() => _wrap(_ptr.remoteStreams);

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  void addStream(MediaStream stream) {
    _ptr.addStream(_unwrap(stream));
    return;
  }

  void close() {
    _ptr.close();
    return;
  }

  bool dispatchEvent(Event event) {
    return _wrap(_ptr.dispatchEvent(_unwrap(event)));
  }

  void processSignalingMessage(String message) {
    _ptr.processSignalingMessage(_unwrap(message));
    return;
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  void removeStream(MediaStream stream) {
    _ptr.removeStream(_unwrap(stream));
    return;
  }

  void send(String text) {
    _ptr.send(_unwrap(text));
    return;
  }
}
