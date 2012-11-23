// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class SecureSocket {
  /* patch */ static void setCertificateDatabase(String certificateDatabase,
                                                 [String password])
      native "SecureSocket_SetCertificateDatabase";
}


patch class _SecureFilter {
  /* patch */ factory _SecureFilter() => new _SecureFilterImpl();
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
    buffers = new List<_ExternalBuffer>(_SecureSocket.NUM_BUFFERS);
    for (int i = 0; i < _SecureSocket.NUM_BUFFERS; ++i) {
      buffers[i] = new _ExternalBuffer();
    }
  }

  void connect(String hostName,
               int port,
               bool is_server,
               String certificate_name) native "SecureSocket_Connect";

  void destroy() {
    buffers = null;
    _destroy();
  }

  void _destroy() native "SecureSocket_Destroy";

  void handshake() native "SecureSocket_Handshake";

  void init() native "SecureSocket_Init";

  int processBuffer(int bufferIndex) native "SecureSocket_ProcessBuffer";

  void registerHandshakeCompleteCallback(Function handshakeCompleteHandler)
      native "SecureSocket_RegisterHandshakeCompleteCallback";

  List<_ExternalBuffer> buffers;
}
