// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class SecureSocket {
  /* patch */ factory SecureSocket._(RawSecureSocket rawSocket) =>
      new _SecureSocket(rawSocket);

  /* patch */ static void initialize({String database,
                                      String password,
                                      bool useBuiltinRoots: true})
  native "SecureSocket_InitializeLibrary";
}


patch class _SecureFilter {
  /* patch */ factory _SecureFilter() => new _SecureFilterImpl();
}


class _SecureSocket extends _Socket implements SecureSocket {
  _SecureSocket(RawSecureSocket raw) : super(raw);

  void set onBadCertificate(bool callback(X509Certificate certificate)) {
    if (_raw == null) {
      throw new StateError("onBadCertificate called on destroyed SecureSocket");
    }
    _raw.onBadCertificate = callback;
  }

  X509Certificate get peerCertificate {
    if (_raw == null) {
     throw new StateError("peerCertificate called on destroyed SecureSocket");
    }
    return _raw.peerCertificate;
  }
}


/**
 * _SecureFilterImpl wraps a filter that encrypts and decrypts data travelling
 * over an encrypted socket.  The filter also handles the handshaking
 * and certificate verification.
 *
 * The filter exposes its input and output buffers as Dart objects that
 * are backed by an external C array of bytes, so that both Dart code and
 * native code can access the same data.
 */
class _SecureFilterImpl
    extends NativeFieldWrapperClass1
    implements _SecureFilter {
  _SecureFilterImpl() {
    buffers = new List<_ExternalBuffer>(_RawSecureSocket.NUM_BUFFERS);
    for (int i = 0; i < _RawSecureSocket.NUM_BUFFERS; ++i) {
      buffers[i] = new _ExternalBuffer();
    }
  }

  void connect(String hostName,
               Uint8List sockaddrStorage,
               int port,
               bool is_server,
               String certificateName,
               bool requestClientCertificate,
               bool requireClientCertificate,
               bool sendClientCertificate) native "SecureSocket_Connect";

  void destroy() {
    buffers = null;
    _destroy();
  }

  void _destroy() native "SecureSocket_Destroy";

  void handshake() native "SecureSocket_Handshake";

  void init() native "SecureSocket_Init";

  X509Certificate get peerCertificate native "SecureSocket_PeerCertificate";

  int processBuffer(int bufferIndex) native "SecureSocket_ProcessBuffer";

  void registerBadCertificateCallback(Function callback)
      native "SecureSocket_RegisterBadCertificateCallback";

  void registerHandshakeCompleteCallback(Function handshakeCompleteHandler)
      native "SecureSocket_RegisterHandshakeCompleteCallback";

  List<_ExternalBuffer> buffers;
}
