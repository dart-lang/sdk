
class _PeerConnectionJs extends _DOMTypeJs implements PeerConnection native "*PeerConnection" {

  static final int ACTIVE = 2;

  static final int CLOSED = 3;

  static final int NEGOTIATING = 1;

  static final int NEW = 0;

  final _MediaStreamListJs localStreams;

  EventListener onaddstream;

  EventListener onconnecting;

  EventListener onmessage;

  EventListener onopen;

  EventListener onremovestream;

  final int readyState;

  final _MediaStreamListJs remoteStreams;

  void addEventListener(String type, EventListener listener, bool useCapture) native;

  void addStream(_MediaStreamJs stream) native;

  void close() native;

  bool dispatchEvent(_EventJs event) native;

  void processSignalingMessage(String message) native;

  void removeEventListener(String type, EventListener listener, bool useCapture) native;

  void removeStream(_MediaStreamJs stream) native;

  void send(String text) native;
}
