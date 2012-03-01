
class _PeerConnectionImpl implements PeerConnection native "*PeerConnection" {

  static final int ACTIVE = 2;

  static final int CLOSED = 3;

  static final int NEGOTIATING = 1;

  static final int NEW = 0;

  final _MediaStreamListImpl localStreams;

  EventListener onaddstream;

  EventListener onconnecting;

  EventListener onmessage;

  EventListener onopen;

  EventListener onremovestream;

  EventListener onstatechange;

  final int readyState;

  final _MediaStreamListImpl remoteStreams;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void addStream(_MediaStreamImpl stream) native;

  void close() native;

  bool dispatchEvent(_EventImpl event) native;

  void processSignalingMessage(String message) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void removeStream(_MediaStreamImpl stream) native;

  void send(String text) native;
}
