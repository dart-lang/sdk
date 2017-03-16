// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * The object containing the certificates to trust when making
 * a secure client connection, and the certificate chain and
 * private key to serve from a secure server.
 *
 * The [SecureSocket]  and [SecureServer] classes take a SecurityContext
 * as an argument to their connect and bind methods.
 *
 * Certificates and keys can be added to a SecurityContext from either PEM
 * or PKCS12 containers.
 *
 * iOS note: Some methods to add, remove, and inspect certificates are not yet
 * implemented. However, the platform's built-in trusted certificates can
 * be used, by way of [SecurityContext.defaultContext].
 */
abstract class SecurityContext {
  external factory SecurityContext();

  /**
   * Secure networking classes with an optional `context` parameter
   * use the [defaultContext] object if the parameter is omitted.
   * This object can also be accessed, and modified, directly.
   * Each isolate has a different [defaultContext] object.
   * The [defaultContext] object uses a list of well-known trusted
   * certificate authorities as its trusted roots. On Linux and Windows, this
   * list is taken from Mozilla, who maintains it as part of Firefox. On,
   * MacOS, iOS, and Android, this list comes from the trusted certificates
   * stores built in to the platforms.
   */
  external static SecurityContext get defaultContext;

  /**
   * Sets the private key for a server certificate or client certificate.
   *
   * A secure connection using this SecurityContext will use this key with
   * the server or client certificate to sign and decrypt messages.
   * [file] is the path to a PEM or PKCS12 file containing an encrypted
   * private key, encrypted with [password]. Assuming it is well-formatted, all
   * other contents of [file] are ignored. An unencrypted file can be used,
   * but this is not usual.
   *
   * NB: This function calls [ReadFileAsBytesSync], and will block on file IO.
   * Prefer using [usePrivateKeyBytes].
   *
   * iOS note: Only PKCS12 data is supported. It should contain both the private
   * key and the certificate chain. On iOS one call to [usePrivateKey] with this
   * data is used instead of two calls to [useCertificateChain] and
   * [usePrivateKey].
   */
  void usePrivateKey(String file, {String password});

  /**
   * Sets the private key for a server certificate or client certificate.
   *
   * Like [usePrivateKey], but takes the contents of the file as a list
   * of bytes.
   */
  void usePrivateKeyBytes(List<int> keyBytes, {String password});

  /**
   * Sets the set of trusted X509 certificates used by [SecureSocket]
   * client connections, when connecting to a secure server.
   *
   * [file] is the path to a PEM or PKCS12 file containing X509 certificates,
   * usually root certificates from certificate authorities. For PKCS12 files,
   * [password] is the password for the file. For PEM files, [password] is
   * ignored. Assuming it is well-formatted, all other contents of [file] are
   * ignored.
   *
   * NB: This function calls [ReadFileAsBytesSync], and will block on file IO.
   * Prefer using [setTrustedCertificatesBytes].
   *
   * iOS note: On iOS, this call takes only the bytes for a single DER
   * encoded X509 certificate. It may be called multiple times to add
   * multiple trusted certificates to the context. A DER encoded certificate
   * can be obtained from a PEM encoded certificate by using the openssl tool:
   *
   *   $ openssl x509 -outform der -in cert.pem -out cert.der
   */
  void setTrustedCertificates(String file, {String password});

  /**
   * Sets the set of trusted X509 certificates used by [SecureSocket]
   * client connections, when connecting to a secure server.
   *
   * Like [setTrustedCertificates] but takes the contents of the file.
   */
  void setTrustedCertificatesBytes(List<int> certBytes, {String password});

  /**
   * Sets the chain of X509 certificates served by [SecureServer]
   * when making secure connections, including the server certificate.
   *
   * [file] is a PEM or PKCS12 file containing X509 certificates, starting with
   * the root authority and intermediate authorities forming the signed
   * chain to the server certificate, and ending with the server certificate.
   * The private key for the server certificate is set by [usePrivateKey]. For
   * PKCS12 files, [password] is the password for the file. For PEM files,
   * [password] is ignored. Assuming it is well-formatted, all
   * other contents of [file] are ignored.
   *
   * NB: This function calls [ReadFileAsBytesSync], and will block on file IO.
   * Prefer using [useCertificateChainBytes].
   *
   * iOS note: As noted above, [usePrivateKey] does the job of both
   * that call and this one. On iOS, this call is a no-op.
   */
  void useCertificateChain(String file, {String password});

  /**
   * Sets the chain of X509 certificates served by [SecureServer]
   * when making secure connections, including the server certificate.
   *
   * Like [useCertificateChain] but takes the contents of the file.
   */
  void useCertificateChainBytes(List<int> chainBytes, {String password});

  /**
   * Sets the list of authority names that a [SecureServer] will advertise
   * as accepted when requesting a client certificate from a connecting
   * client.
   *
   * [file] is a PEM or PKCS12 file containing the accepted signing
   * authority certificates - the authority names are extracted from the
   * certificates. For PKCS12 files, [password] is the password for the file.
   * For PEM files, [password] is ignored. Assuming it is well-formatted, all
   * other contents of [file] are ignored.
   *
   * NB: This function calls [ReadFileAsBytesSync], and will block on file IO.
   * Prefer using [setClientAuthoritiesBytes].
   *
   * iOS note: This call is not supported.
   */
  void setClientAuthorities(String file, {String password});

  /**
   * Sets the list of authority names that a [SecureServer] will advertise
   * as accepted, when requesting a client certificate from a connecting
   * client.
   *
   * Like [setClientAuthority] but takes the contents of the file.
   */
  void setClientAuthoritiesBytes(List<int> authCertBytes, {String password});

  /**
   * Whether the platform supports ALPN.
   */
  external static bool get alpnSupported;

  /**
   * Sets the list of application-level protocols supported by a client
   * connection or server connection. The ALPN (application level protocol
   * negotiation) extension to TLS allows a client to send a list of
   * protocols in the TLS client hello message, and the server to pick
   * one and send the selected one back in its server hello message.
   *
   * Separate lists of protocols can be sent for client connections and
   * for server connections, using the same SecurityContext.  The [isServer]
   * boolean argument specifies whether to set the list for server connections
   * or client connections.
   */
  void setAlpnProtocols(List<String> protocols, bool isServer);

  /// Encodes a set of supported protocols for ALPN/NPN usage.
  ///
  /// The `protocols` list is expected to contain protocols in descending order
  /// of preference.
  ///
  /// See RFC 7301 (https://tools.ietf.org/html/rfc7301) for the encoding of
  /// `List<String> protocols`:
  ///     opaque ProtocolName<1..2^8-1>;
  ///
  ///     struct {
  ///         ProtocolName protocol_name_list<2..2^16-1>
  ///     } ProtocolNameList;
  ///
  /// The encoding of the opaque `ProtocolName<lower..upper>` vector is
  /// described in RFC 2246: 4.3 Vectors.
  ///
  /// Note: Even though this encoding scheme would allow a total
  /// `ProtocolNameList` length of 65535, this limit cannot be reached. Testing
  /// showed that more than ~ 2^14  bytes will fail to negotiate a protocol.
  /// We will be conservative and support only messages up to (1<<13)-1 bytes.
  static Uint8List _protocolsToLengthEncoding(List<String> protocols) {
    if (protocols == null || protocols.length == 0) {
      return new Uint8List(0);
    }
    int protocolsLength = protocols.length;

    // Calculate the number of bytes we will need if it is ASCII.
    int expectedLength = protocolsLength;
    for (int i = 0; i < protocolsLength; i++) {
      int length = protocols[i].length;
      if (length > 0 && length <= 255) {
        expectedLength += length;
      } else {
        throw new ArgumentError(
            'Length of protocol must be between 1 and 255 (was: $length).');
      }
    }

    if (expectedLength >= (1 << 13)) {
      throw new ArgumentError(
          'The maximum message length supported is 2^13-1.');
    }

    // Try encoding the `List<String> protocols` array using fast ASCII path.
    var bytes = new Uint8List(expectedLength);
    int bytesOffset = 0;
    for (int i = 0; i < protocolsLength; i++) {
      String proto = protocols[i];

      // Add length byte.
      bytes[bytesOffset++] = proto.length;
      int bits = 0;

      // Add protocol bytes.
      for (int j = 0; j < proto.length; j++) {
        var char = proto.codeUnitAt(j);
        bits |= char;
        bytes[bytesOffset++] = char & 0xff;
      }

      // Go slow case if we have encountered anything non-ascii.
      if (bits > 0x7f) {
        return _protocolsToLengthEncodingNonAsciiBailout(protocols);
      }
    }
    return bytes;
  }

  static Uint8List _protocolsToLengthEncodingNonAsciiBailout(
      List<String> protocols) {
    void addProtocol(List<int> outBytes, String protocol) {
      var protocolBytes = UTF8.encode(protocol);
      var len = protocolBytes.length;

      if (len > 255) {
        throw new ArgumentError(
            'Length of protocol must be between 1 and 255 (was: $len)');
      }
      // Add length byte.
      outBytes.add(len);

      // Add protocol bytes.
      outBytes.addAll(protocolBytes);
    }

    List<int> bytes = [];
    for (var i = 0; i < protocols.length; i++) {
      addProtocol(bytes, protocols[i]);
    }

    if (bytes.length >= (1 << 13)) {
      throw new ArgumentError(
          'The maximum message length supported is 2^13-1.');
    }

    return new Uint8List.fromList(bytes);
  }
}
