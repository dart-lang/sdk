// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class TlsSocket {
  /* patch */ static void setCertificateDatabase(String certificateDatabase,
                                                 [String password])
      native "TlsSocket_SetCertificateDatabase";
}


patch class _TlsFilter {
  /* patch */ factory _TlsFilter() => new _TlsFilterImpl();
}


/**
 * _TlsFilterImpl wraps a filter that encrypts and decrypts data travelling
 * over a TLS encrypted socket.  The filter also handles the handshaking
 * and certificate verification.
 *
 * The filter exposes its input and output buffers as Dart objects that
 * are backed by an external C array of bytes, so that both Dart code and
 * native code can access the same data.
 */
class _TlsFilterImpl extends NativeFieldWrapperClass1 implements _TlsFilter {
  _TlsFilterImpl() {
    buffers = new List<_TlsExternalBuffer>(_TlsSocket.NUM_BUFFERS);
    for (int i = 0; i < _TlsSocket.NUM_BUFFERS; ++i) {
      buffers[i] = new _TlsExternalBuffer();
    }
  }

  void connect(String hostName,
               int port,
               bool is_server,
               String certificate_name) native "TlsSocket_Connect";

  void destroy() {
    buffers = null;
    _destroy();
  }

  void _destroy() native "TlsSocket_Destroy";

  void handshake() native "TlsSocket_Handshake";

  void init() native "TlsSocket_Init";

  int processBuffer(int bufferIndex) native "TlsSocket_ProcessBuffer";

  void registerHandshakeCompleteCallback(Function handshakeCompleteHandler)
      native "TlsSocket_RegisterHandshakeCompleteCallback";

  List<_TlsExternalBuffer> buffers;
}
