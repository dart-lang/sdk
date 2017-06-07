// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@patch
class SecureSocket {
  @patch
  factory SecureSocket._(RawSecureSocket rawSocket) =>
      new _SecureSocket(rawSocket);
}

@patch
class _SecureFilter {
  @patch
  factory _SecureFilter() => new _SecureFilterImpl();
}

@patch
class X509Certificate {
  @patch
  factory X509Certificate._() => new _X509CertificateImpl();
}

class _SecureSocket extends _Socket implements SecureSocket {
  _SecureSocket(RawSecureSocket raw) : super(raw);

  void set onBadCertificate(bool callback(X509Certificate certificate)) {
    if (_raw == null) {
      throw new StateError("onBadCertificate called on destroyed SecureSocket");
    }
    _raw.onBadCertificate = callback;
  }

  void renegotiate(
      {bool useSessionCache: true,
      bool requestClientCertificate: false,
      bool requireClientCertificate: false}) {
    _raw.renegotiate(
        useSessionCache: useSessionCache,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate);
  }

  X509Certificate get peerCertificate {
    if (_raw == null) {
      throw new StateError("peerCertificate called on destroyed SecureSocket");
    }
    return _raw.peerCertificate;
  }

  String get selectedProtocol {
    if (_raw == null) {
      throw new StateError("selectedProtocol called on destroyed SecureSocket");
    }
    return _raw.selectedProtocol;
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
class _SecureFilterImpl extends NativeFieldWrapperClass1
    implements _SecureFilter {
  // Performance is improved if a full buffer of plaintext fits
  // in the encrypted buffer, when encrypted.
  static final int SIZE = 8 * 1024;
  static final int ENCRYPTED_SIZE = 10 * 1024;

  _SecureFilterImpl() {
    buffers = new List<_ExternalBuffer>(_RawSecureSocket.NUM_BUFFERS);
    for (int i = 0; i < _RawSecureSocket.NUM_BUFFERS; ++i) {
      buffers[i] = new _ExternalBuffer(
          _RawSecureSocket._isBufferEncrypted(i) ? ENCRYPTED_SIZE : SIZE);
    }
  }

  void connect(
      String hostName,
      SecurityContext context,
      bool is_server,
      bool requestClientCertificate,
      bool requireClientCertificate,
      Uint8List protocols) native "SecureSocket_Connect";

  void destroy() {
    buffers = null;
    _destroy();
  }

  void _destroy() native "SecureSocket_Destroy";

  void handshake() native "SecureSocket_Handshake";

  String selectedProtocol() native "SecureSocket_GetSelectedProtocol";

  void renegotiate(bool useSessionCache, bool requestClientCertificate,
      bool requireClientCertificate) native "SecureSocket_Renegotiate";

  void init() native "SecureSocket_Init";

  X509Certificate get peerCertificate native "SecureSocket_PeerCertificate";

  void registerBadCertificateCallback(Function callback)
      native "SecureSocket_RegisterBadCertificateCallback";

  void registerHandshakeCompleteCallback(Function handshakeCompleteHandler)
      native "SecureSocket_RegisterHandshakeCompleteCallback";

  // This is a security issue, as it exposes a raw pointer to Dart code.
  int _pointer() native "SecureSocket_FilterPointer";

  List<_ExternalBuffer> buffers;
}

@patch
class SecurityContext {
  @patch
  factory SecurityContext() {
    return new _SecurityContext();
  }

  @patch
  static SecurityContext get defaultContext {
    return _SecurityContext.defaultContext;
  }
}

class _SecurityContext extends NativeFieldWrapperClass1
    implements SecurityContext {
  _SecurityContext() {
    _createNativeContext();
  }

  void _createNativeContext() native "SecurityContext_Allocate";

  static final SecurityContext defaultContext = new _SecurityContext()
    .._trustBuiltinRoots();

  void usePrivateKey(String file, {String password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    usePrivateKeyBytes(bytes, password: password);
  }

  void usePrivateKeyBytes(List<int> keyBytes, {String password})
      native "SecurityContext_UsePrivateKeyBytes";

  void setTrustedCertificates(String file, {String password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    setTrustedCertificatesBytes(bytes, password: password);
  }

  void setTrustedCertificatesBytes(List<int> certBytes, {String password})
      native "SecurityContext_SetTrustedCertificatesBytes";

  void useCertificateChain(String file, {String password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    useCertificateChainBytes(bytes, password: password);
  }

  void useCertificateChainBytes(List<int> chainBytes, {String password})
      native "SecurityContext_UseCertificateChainBytes";

  void setClientAuthorities(String file, {String password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    setClientAuthoritiesBytes(bytes, password: password);
  }

  void setClientAuthoritiesBytes(List<int> authCertBytes, {String password})
      native "SecurityContext_SetClientAuthoritiesBytes";

  void setAlpnProtocols(List<String> protocols, bool isServer) {
    Uint8List encodedProtocols =
        SecurityContext._protocolsToLengthEncoding(protocols);
    _setAlpnProtocols(encodedProtocols, isServer);
  }

  void _setAlpnProtocols(Uint8List protocols, bool isServer)
      native "SecurityContext_SetAlpnProtocols";
  void _trustBuiltinRoots() native "SecurityContext_TrustBuiltinRoots";
}

/**
 * _X509CertificateImpl wraps an X509 certificate object held by the BoringSSL
 * library. It exposes the fields of the certificate object.
 */
class _X509CertificateImpl extends NativeFieldWrapperClass1
    implements X509Certificate {
  // The native field must be set manually on a new object, in native code.
  // This is done by WrappedX509 in secure_socket.cc.
  _X509CertificateImpl();

  String get subject native "X509_Subject";
  String get issuer native "X509_Issuer";
  DateTime get startValidity {
    return new DateTime.fromMillisecondsSinceEpoch(_startValidity(),
        isUtc: true);
  }

  DateTime get endValidity {
    return new DateTime.fromMillisecondsSinceEpoch(_endValidity(), isUtc: true);
  }

  int _startValidity() native "X509_StartValidity";
  int _endValidity() native "X509_EndValidity";
}
