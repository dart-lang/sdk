// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import "package:expect/expect.dart";

// ignore: IMPORT_INTERNAL_LIBRARY
import "dart:_http" show TestingClass$_HttpHeaders, TestingClass$_SHA1;

typedef _HttpHeaders = TestingClass$_HttpHeaders;
typedef _SHA1 = TestingClass$_SHA1;

const String _webSocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

// TestSocket provides a placeholder Socket implementation. Its only purpose is
// to generate a Socket object to be returned by WebSocketHttpClientResponse.
class TestSocket implements Socket {
  final Stream<Uint8List> data;
  TestSocket(this.data);

  Encoding encoding = utf8;

  void add(List<int> data) => throw "";
  void addError(Object error, [StackTrace? stackTrace]) => throw "";
  Future addStream(Stream<List<int>> stream) async {}
  InternetAddress get address => throw "";
  Future<bool> any(bool Function(Uint8List element) test) => throw "";
  Stream<Uint8List> asBroadcastStream(
          {void Function(StreamSubscription<Uint8List> subscription)? onListen,
          void Function(StreamSubscription<Uint8List> subscription)?
              onCancel}) =>
      throw "";
  Stream<E> asyncExpand<E>(Stream<E>? Function(Uint8List event) convert) =>
      throw "";
  Stream<E> asyncMap<E>(FutureOr<E> Function(Uint8List event) convert) =>
      throw "";
  Stream<R> cast<R>() async* {
    throw "";
  }

  Future close() async => throw "";
  Future<bool> contains(Object? needle) => throw "";
  void destroy() {}
  Stream<Uint8List> distinct(
          [bool Function(Uint8List previous, Uint8List next)? equals]) =>
      throw "";
  Future get done => throw "";
  Future<E> drain<E>([E? futureValue]) => throw "";
  Future<Uint8List> elementAt(int index) => throw "";
  Future<bool> every(bool Function(Uint8List element) test) => throw "";
  Stream<S> expand<S>(Iterable<S> Function(Uint8List element) convert) =>
      throw "";
  Future<Uint8List> get first => throw "";
  Future<Uint8List> firstWhere(bool Function(Uint8List element) test,
          {Uint8List Function()? orElse}) =>
      throw "";
  Future flush() => throw "";
  Future<S> fold<S>(
          S initialValue, S Function(S previous, Uint8List element) combine) =>
      throw "";
  Future<void> forEach(void Function(Uint8List element) action) => throw "";
  Uint8List getRawOption(RawSocketOption option) => throw "";
  Stream<Uint8List> handleError(Function onError,
          {bool Function(dynamic error)? test}) =>
      throw "";
  bool get isBroadcast => throw "";
  Future<bool> get isEmpty => throw "";
  Future<String> join([String separator = ""]) => throw "";
  Future<Uint8List> get last => throw "";
  Future<Uint8List> lastWhere(bool Function(Uint8List element) test,
          {Uint8List Function()? orElse}) =>
      throw "";
  Future<int> get length => throw "";
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      data.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  Stream<S> map<S>(S Function(Uint8List event) convert) => throw "";
  Future pipe(StreamConsumer<Uint8List> streamConsumer) => throw "";
  int get port => throw "";
  Future<Uint8List> reduce(
          Uint8List Function(Uint8List previous, Uint8List element) combine) =>
      throw "";
  InternetAddress get remoteAddress => throw "";
  int get remotePort => throw "";
  bool setOption(SocketOption option, bool enabled) => throw "";
  void setRawOption(RawSocketOption option) => throw "";
  Future<Uint8List> get single => throw "";
  Future<Uint8List> singleWhere(bool Function(Uint8List element) test,
          {Uint8List Function()? orElse}) =>
      throw "";
  Stream<Uint8List> skip(int count) => throw "";
  Stream<Uint8List> skipWhile(bool Function(Uint8List element) test) =>
      throw "";
  Stream<Uint8List> take(int count) => throw "";
  Stream<Uint8List> takeWhile(bool Function(Uint8List element) test) =>
      throw "";
  Stream<Uint8List> timeout(Duration timeLimit,
          {void Function(EventSink<Uint8List> sink)? onTimeout}) =>
      throw "";
  Future<List<Uint8List>> toList() => throw "";
  Future<Set<Uint8List>> toSet() => throw "";
  Stream<S> transform<S>(StreamTransformer<Uint8List, S> streamTransformer) =>
      throw "";
  Stream<Uint8List> where(bool Function(Uint8List event) test) => throw "";
  void write(Object? object) => throw "";
  void writeAll(Iterable objects, [String separator = ""]) => throw "";
  void writeCharCode(int charCode) => throw "";
  void writeln([Object? object = ""]) => throw "";
}

// WebSocketHttpClientRequest provides a minimal HttpClientRequest
// implementation to pass the WebSocket connection setup process.
class WebSocketHttpClientRequest implements HttpClientRequest {
  final String method;
  final Uri uri;
  final bool setAcceptHeader;
  final WebSocketHttpClientResponse response;
  final headers = _HttpHeaders("1.2");

  WebSocketHttpClientRequest(
      this.method, this.uri, this.setAcceptHeader, this.response);

  bool bufferOutput = false;
  int contentLength = 0;
  Encoding encoding = Utf8Codec();
  bool followRedirects = false;
  int maxRedirects = 0;
  bool persistentConnection = false;

  void abort([Object? exception, StackTrace? stackTrace]) => throw "";
  void add(List<int> data) => throw "";
  void addError(Object error, [StackTrace? stackTrace]) => throw "";
  Future addStream(Stream<List<int>> stream) => throw "";
  Future<HttpClientResponse> close() async {
    // Compute the hash for the the Sec-WebSocket-Accept header.
    if (setAcceptHeader) {
      final nonce = headers.value("Sec-WebSocket-Key");
      final sha1 = _SHA1();
      sha1.add("$nonce$_webSocketGUID".codeUnits);
      final accept = sha1.close();
      final acceptEncoded = base64Encode(accept);
      response.headers.set("Sec-WebSocket-Accept", acceptEncoded);
    }
    print(response.headers.toString());
    return response;
  }

  HttpConnectionInfo? get connectionInfo => throw "";
  List<Cookie> get cookies => throw "";
  Future<HttpClientResponse> get done => throw "";
  Future flush() => throw "";
  // HttpHeaders get headers => throw "";
  void write(Object? object) => throw "";
  void writeAll(Iterable objects, [String separator = ""]) => throw "";
  void writeCharCode(int charCode) => throw "";
  void writeln([Object? object = ""]) => throw "";
}

// WebSocketHttpClientRequest provides a minimal HttpClientResponse
// implementation to pass the WebSocket connection setup process.
class WebSocketHttpClientResponse implements HttpClientResponse {
  final Stream<Uint8List> data;
  final HttpHeaders headers;
  int statusCode = HttpStatus.switchingProtocols;
  WebSocketHttpClientResponse(this.data, this.headers);

  Future<bool> any(bool Function(List<int> element) test) => data.any(test);
  Stream<List<int>> asBroadcastStream(
      {void Function(StreamSubscription<List<int>> subscription)? onListen,
      void Function(StreamSubscription<List<int>> subscription)? onCancel}) {
    return data.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> event) convert) =>
      data.asyncExpand(convert);
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) convert) =>
      data.asyncMap(convert);
  Stream<R> cast<R>() => data.cast<R>();

  X509Certificate? get certificate => throw "";
  HttpClientResponseCompressionState get compressionState => throw "";
  HttpConnectionInfo? get connectionInfo => throw "";
  Future<bool> contains(Object? needle) => data.contains(needle);

  int get contentLength => 0;
  List<Cookie> get cookies => [];

  Future<Socket> detachSocket() async => TestSocket(data);
  Stream<List<int>> distinct(
          [bool Function(List<int> previous, List<int> next)? equals]) =>
      data.distinct(equals);

  Future<E> drain<E>([E? futureValue]) => data.drain(futureValue);
  Future<List<int>> elementAt(int index) => data.elementAt(index);
  Future<bool> every(bool Function(List<int> element) test) => data.every(test);
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) convert) =>
      data.expand(convert);
  Future<List<int>> get first => data.first;
  Future<List<int>> firstWhere(bool Function(List<int> element) test,
          {List<int> Function()? orElse}) =>
      throw "";
  Future<S> fold<S>(
          S initialValue, S Function(S previous, List<int> element) combine) =>
      data.fold(initialValue, combine);
  Future<void> forEach(void Function(List<int> element) action) =>
      data.forEach(action);
  Stream<List<int>> handleError(Function onError,
          {bool Function(dynamic error)? test}) =>
      data.handleError(onError, test: test);
  bool get isBroadcast => false;
  Future<bool> get isEmpty async => false;
  bool get isRedirect => false;
  Future<String> join([String separator = ""]) => data.join(separator);
  Future<List<int>> get last => data.last;
  Future<List<int>> lastWhere(bool Function(List<int> element) test,
          {List<int> Function()? orElse}) =>
      throw "";
  Future<int> get length => throw "";
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      data.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  Stream<S> map<S>(S Function(List<int> event) convert) => data.map(convert);
  bool get persistentConnection => throw "";
  Future pipe(StreamConsumer<List<int>> streamConsumer) => throw "";
  String get reasonPhrase => throw "";
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      throw "";
  List<RedirectInfo> get redirects => throw "";
  Future<List<int>> reduce(
          List<int> Function(List<int> previous, List<int> element) combine) =>
      throw "";
  Future<List<int>> get single => throw "";
  Future<List<int>> singleWhere(bool Function(List<int> element) test,
          {List<int> Function()? orElse}) =>
      throw "";
  Stream<List<int>> skip(int count) => data.skip(count);
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) =>
      data.skipWhile(test);

  Stream<List<int>> take(int count) => data.take(count);
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) =>
      data.takeWhile(test);
  Stream<List<int>> timeout(Duration timeLimit,
          {void Function(EventSink<List<int>> sink)? onTimeout}) =>
      throw "";
  Future<List<List<int>>> toList() => data.toList();
  Future<Set<List<int>>> toSet() => data.toSet();
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      throw "";
  Stream<List<int>> where(bool Function(List<int> event) test) =>
      data.where(test);
}

// WebSocketHttpClient1 immediately sends a fixed WebSocket upgrade response for
// any request without contacting any server. Thereby the Sec-WebSocket-Accept
// is not set to trigger and exception during the connect.
class WebSocketHttpClient1 implements HttpClient {
  String? userAgent = "WebSocketHttpClient1";

  WebSocketHttpClient1(SecurityContext? context);

  Duration idleTimeout = Duration.zero;
  Duration? connectionTimeout;
  int? maxConnectionsPerHost;
  bool autoUncompress = true;
  bool enableTimelineLogging = false;

  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      WebSocketHttpClientRequest(
          method,
          url,
          false,
          WebSocketHttpClientResponse(
              Stream.empty(),
              _HttpHeaders("1.2")
                ..set(HttpHeaders.connectionHeader, "upgrade")
                ..set(HttpHeaders.upgradeHeader, "websocket")));
  Future<HttpClientRequest> get(String host, int port, String path) => throw "";
  Future<HttpClientRequest> getUrl(Uri url) => throw "";
  Future<HttpClientRequest> post(String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> postUrl(Uri url) => throw "";
  Future<HttpClientRequest> put(String host, int port, String path) => throw "";
  Future<HttpClientRequest> putUrl(Uri url) => throw "";
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> deleteUrl(Uri url) => throw "";
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> patchUrl(Uri url) => throw "";
  Future<HttpClientRequest> head(String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> headUrl(Uri url) => throw "";
  set authenticate(Future<bool> f(Uri url, String scheme, String realm)?) {}
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {}
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
              Uri url, String? proxyHost, int? proxyPort)?
          f) {}
  set findProxy(String f(Uri url)?) {}
  set authenticateProxy(
      Future<bool> f(String host, int port, String scheme, String realm)?) {}
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}
  set badCertificateCallback(
      bool callback(X509Certificate cert, String host, int port)?) {}
  void set keyLog(Function(String line)? callback) {}
  void close({bool force = false}) {}
}

// WebSocketHttpClient2 immediately sends a fixed WebSocket upgrade response for
// any request without contacting any server. The response is valid and should
// result in an established connection.
class WebSocketHttpClient2 implements HttpClient {
  String? userAgent = "WebSocketHttpClient2";

  WebSocketHttpClient2(SecurityContext? context);

  Duration idleTimeout = Duration.zero;
  Duration? connectionTimeout;
  int? maxConnectionsPerHost;
  bool autoUncompress = true;
  bool enableTimelineLogging = false;

  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      WebSocketHttpClientRequest(
          method,
          url,
          true,
          WebSocketHttpClientResponse(
              Stream.empty(),
              _HttpHeaders("1.2")
                ..set(HttpHeaders.connectionHeader, "upgrade")
                ..set(HttpHeaders.upgradeHeader, "websocket")));
  Future<HttpClientRequest> get(String host, int port, String path) => throw "";
  Future<HttpClientRequest> getUrl(Uri url) => throw "";
  Future<HttpClientRequest> post(String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> postUrl(Uri url) => throw "";
  Future<HttpClientRequest> put(String host, int port, String path) => throw "";
  Future<HttpClientRequest> putUrl(Uri url) => throw "";
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> deleteUrl(Uri url) => throw "";
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> patchUrl(Uri url) => throw "";
  Future<HttpClientRequest> head(String host, int port, String path) =>
      throw "";
  Future<HttpClientRequest> headUrl(Uri url) => throw "";
  set authenticate(Future<bool> f(Uri url, String scheme, String realm)?) {}
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {}
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
              Uri url, String? proxyHost, int? proxyPort)?
          f) {}
  set findProxy(String f(Uri url)?) {}
  set authenticateProxy(
      Future<bool> f(String host, int port, String scheme, String realm)?) {}
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}
  set badCertificateCallback(
      bool callback(X509Certificate cert, String host, int port)?) {}
  void set keyLog(Function(String line)? callback) {}
  void close({bool force = false}) {}
}

HttpClient createWebSocketHttpClient1(SecurityContext? context) {
  return new WebSocketHttpClient1(context);
}

HttpClient createWebSocketHttpClient2(SecurityContext? context) {
  return new WebSocketHttpClient2(context);
}

// Override the HttpClient with one that always sends and invalid response to a
// WebSocket connect request and verify that this causes an WebSocketException.
Future<void> websocketHttpOverridesNoAcceptHeader() async {
  await HttpOverrides.runZoned(() async {
    var success = false;
    try {
      await WebSocket.connect("wss://example.com");
    } on WebSocketException catch (e) {
      Expect.equals(e.message,
          "Response did not contain a 'Sec-WebSocket-Accept' header");
      success = true;
    } catch (e, stackTrace) {
      Expect.fail("Unexpected exception: $e\n$stackTrace");
    } finally {
      Expect.isTrue(success,
          "Connecting to example websocket did not throw a WebSocketException");
    }
  }, createHttpClient: createWebSocketHttpClient1);
}

// Override the HttpClient with one that always sends a valid response to a
// WebSocket connect request and verify that a connection is established.
Future<void> websocketHttpOverridesSuccess() async {
  await HttpOverrides.runZoned(() async {
    try {
      final webSocket = await WebSocket.connect("wss://example.com");
      Expect.equals(WebSocket.open, webSocket.readyState);
      await webSocket.close();
      Expect.equals(WebSocket.closed, webSocket.readyState);
    } catch (e, stackTrace) {
      Expect.fail("Unexpected exception: $e\n$stackTrace");
    }
  }, createHttpClient: createWebSocketHttpClient2);
}

main() async {
  await websocketHttpOverridesNoAcceptHeader();
  await websocketHttpOverridesSuccess();
}
