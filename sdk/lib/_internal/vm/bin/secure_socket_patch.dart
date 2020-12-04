// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

@patch
class SecureSocket {
  @patch
  factory SecureSocket._(RawSecureSocket rawSocket) =>
      new _SecureSocket(rawSocket);
}

@patch
class _SecureFilter {
  @patch
  factory _SecureFilter._() => new _SecureFilterImpl._();
}

@patch
@pragma("vm:entry-point")
class X509Certificate {
  @patch
  @pragma("vm:entry-point")
  factory X509Certificate._() => new _X509CertificateImpl._();
}

class _SecureSocket extends _Socket implements SecureSocket {
  _RawSecureSocket? get _raw => super._raw as _RawSecureSocket?;

  _SecureSocket(RawSecureSocket raw) : super(raw);

  void renegotiate(
      {bool useSessionCache: true,
      bool requestClientCertificate: false,
      bool requireClientCertificate: false}) {
    _raw!.renegotiate(
        useSessionCache: useSessionCache,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate);
  }

  X509Certificate? get peerCertificate {
    if (_raw == null) {
      throw new StateError("peerCertificate called on destroyed SecureSocket");
    }
    return _raw!.peerCertificate;
  }

  String? get selectedProtocol {
    if (_raw == null) {
      throw new StateError("selectedProtocol called on destroyed SecureSocket");
    }
    return _raw!.selectedProtocol;
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
@pragma("vm:entry-point")
class _SecureFilterImpl extends NativeFieldWrapperClass1
    implements _SecureFilter {
  // Performance is improved if a full buffer of plaintext fits
  // in the encrypted buffer, when encrypted.
  // SIZE and ENCRYPTED_SIZE are referenced from C++.
  @pragma("vm:entry-point")
  static final int SIZE = 8 * 1024;
  @pragma("vm:entry-point")
  static final int ENCRYPTED_SIZE = 10 * 1024;

  _SecureFilterImpl._() {
    buffers = <_ExternalBuffer>[
      for (int i = 0; i < _RawSecureSocket.bufferCount; ++i)
        new _ExternalBuffer(
            _RawSecureSocket._isBufferEncrypted(i) ? ENCRYPTED_SIZE : SIZE),
    ];
  }

  void connect(
      String hostName,
      SecurityContext context,
      bool isServer,
      bool requestClientCertificate,
      bool requireClientCertificate,
      Uint8List protocols) native "SecureSocket_Connect";

  void destroy() {
    buffers = null;
    _destroy();
  }

  void _destroy() native "SecureSocket_Destroy";

  int _handshake(SendPort replyPort) native "SecureSocket_Handshake";

  void _markAsTrusted(int certificatePtr, bool isTrusted)
      native "SecureSocket_MarkAsTrusted";

  static X509Certificate _newX509CertificateWrapper(int certificatePtr)
      native "SecureSocket_NewX509CertificateWrapper";

  Future<bool> handshake() {
    Completer<bool> evaluatorCompleter = Completer<bool>();

    ReceivePort rpEvaluateResponse = ReceivePort();
    rpEvaluateResponse.listen((data) {
      List list = data as List;
      // incoming messages (bool isTrusted, int certificatePtr) is
      // sent by TrustEvaluator native port after system evaluates
      // the certificate chain
      if (list.length != 2) {
        throw Exception("Invalid number of arguments in evaluate response");
      }
      bool isTrusted = list[0] as bool;
      int certificatePtr = list[1] as int;
      if (!isTrusted) {
        if (badCertificateCallback != null) {
          try {
            isTrusted = badCertificateCallback!(
                _newX509CertificateWrapper(certificatePtr));
          } catch (e, st) {
            evaluatorCompleter.completeError(e, st);
            rpEvaluateResponse.close();
            return;
          }
        }
      }
      _markAsTrusted(certificatePtr, isTrusted);
      evaluatorCompleter.complete(true);
      rpEvaluateResponse.close();
    });

    const int kSslErrorWantCertificateVerify = 16; // ssl.h:558
    int handshakeResult;
    try {
      handshakeResult = _handshake(rpEvaluateResponse.sendPort);
    } catch (e, st) {
      rpEvaluateResponse.close();
      rethrow;
    }
    if (handshakeResult == kSslErrorWantCertificateVerify) {
      return evaluatorCompleter.future;
    } else {
      // Response is ready, no need for evaluate response receive port
      rpEvaluateResponse.close();
      return Future<bool>.value(false);
    }
  }

  void rehandshake() => throw new UnimplementedError();

  int processBuffer(int bufferIndex) => throw new UnimplementedError();

  String? selectedProtocol() native "SecureSocket_GetSelectedProtocol";

  void renegotiate(bool useSessionCache, bool requestClientCertificate,
      bool requireClientCertificate) native "SecureSocket_Renegotiate";

  void init() native "SecureSocket_Init";

  X509Certificate? get peerCertificate native "SecureSocket_PeerCertificate";

  void _registerBadCertificateCallback(Function callback)
      native "SecureSocket_RegisterBadCertificateCallback";

  Function? badCertificateCallback;

  void registerBadCertificateCallback(Function callback) {
    badCertificateCallback = callback;
    _registerBadCertificateCallback(callback);
  }

  void registerHandshakeCompleteCallback(Function handshakeCompleteHandler)
      native "SecureSocket_RegisterHandshakeCompleteCallback";

  // This is a security issue, as it exposes a raw pointer to Dart code.
  int _pointer() native "SecureSocket_FilterPointer";

  @pragma("vm:entry-point", "get")
  List<_ExternalBuffer>? buffers;
}

@patch
class SecurityContext {
  @patch
  factory SecurityContext({bool withTrustedRoots: false}) {
    return new _SecurityContext(withTrustedRoots);
  }

  @patch
  static SecurityContext get defaultContext {
    return _SecurityContext.defaultContext;
  }

  @patch
  static bool get alpnSupported => true;
}

class _SecurityContext extends NativeFieldWrapperClass1
    implements SecurityContext {
  _SecurityContext(bool withTrustedRoots) {
    _createNativeContext();
    if (withTrustedRoots) {
      _trustBuiltinRoots();
    }
  }

  void _createNativeContext() native "SecurityContext_Allocate";

  static final SecurityContext defaultContext = new _SecurityContext(true);

  void usePrivateKey(String file, {String? password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    usePrivateKeyBytes(bytes, password: password);
  }

  void usePrivateKeyBytes(List<int> keyBytes, {String? password})
      native "SecurityContext_UsePrivateKeyBytes";

  void setTrustedCertificates(String file, {String? password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    setTrustedCertificatesBytes(bytes, password: password);
  }

  void setTrustedCertificatesBytes(List<int> certBytes, {String? password})
      native "SecurityContext_SetTrustedCertificatesBytes";

  void useCertificateChain(String file, {String? password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    useCertificateChainBytes(bytes, password: password);
  }

  void useCertificateChainBytes(List<int> chainBytes, {String? password})
      native "SecurityContext_UseCertificateChainBytes";

  void setClientAuthorities(String file, {String? password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    setClientAuthoritiesBytes(bytes, password: password);
  }

  void setClientAuthoritiesBytes(List<int> authCertBytes, {String? password})
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
  // This is done by WrappedX509Certificate in security_context.cc.
  _X509CertificateImpl._();

  Uint8List get _der native "X509_Der";
  late final Uint8List der = _der;

  String get _pem native "X509_Pem";
  late final String pem = _pem;

  Uint8List get _sha1 native "X509_Sha1";
  late final Uint8List sha1 = _sha1;

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
