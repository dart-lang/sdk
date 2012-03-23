// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * HTTP status codes.
 */
interface HttpStatus {
  static final int CONTINUE = 100;
  static final int SWITCHING_PROTOCOLS = 101;
  static final int OK = 200;
  static final int CREATED = 201;
  static final int ACCEPTED = 202;
  static final int NON_AUTHORITATIVE_INFORMATION = 203;
  static final int NO_CONTENT = 204;
  static final int RESET_CONTENT = 205;
  static final int PARTIAL_CONTENT = 206;
  static final int MULTIPLE_CHOICES = 300;
  static final int MOVED_PERMANENTLY = 301;
  static final int FOUND = 302;
  static final int MOVED_TEMPORARILY = 302; // Common alias for FOUND.
  static final int SEE_OTHER = 303;
  static final int NOT_MODIFIED = 304;
  static final int USE_PROXY = 305;
  static final int TEMPORARY_REDIRECT = 307;
  static final int BAD_REQUEST = 400;
  static final int UNAUTHORIZED = 401;
  static final int PAYMENT_REQUIRED = 402;
  static final int FORBIDDEN = 403;
  static final int NOT_FOUND = 404;
  static final int METHOD_NOT_ALLOWED = 405;
  static final int NOT_ACCEPTABLE = 406;
  static final int PROXY_AUTHENTICATION_REQUIRED = 407;
  static final int REQUEST_TIMEOUT = 408;
  static final int CONFLICT = 409;
  static final int GONE = 410;
  static final int LENGTH_REQUIRED = 411;
  static final int PRECONDITION_FAILED = 412;
  static final int REQUEST_ENTITY_TOO_LARGE = 413;
  static final int REQUEST_URI_TOO_LONG = 414;
  static final int UNSUPPORTED_MEDIA_TYPE = 415;
  static final int REQUESTED_RANGE_NOT_SATISFIABLE = 416;
  static final int EXPECTATION_FAILED = 417;
  static final int INTERNAL_SERVER_ERROR = 500;
  static final int NOT_IMPLEMENTED = 501;
  static final int BAD_GATEWAY = 502;
  static final int SERVICE_UNAVAILABLE = 503;
  static final int GATEWAY_TIMEOUT = 504;
  static final int HTTP_VERSION_NOT_SUPPORTED = 505;
  // Client generated status code.
  static final int NETWORK_CONNECT_TIMEOUT_ERROR = 599;
}


/**
 * HTTP server.
 */
interface HttpServer default _HttpServer {
  HttpServer();

  /**
   * Start listening for HTTP requests on the specified [host] and
   * [port]. For each HTTP request the handler set through [onRequest]
   * will be invoked. If a [port] of 0 is specified the server will
   * choose an ephemeral port. The optional argument [backlog] can be
   * used to specify the listen backlog for the underlying OS listen
   * setup.
   */
  void listen(String host, int port, [int backlog]);

  /**
   * Stop server listening.
   */
  void close();

  /**
   * Returns the port that the server is listening on. This can be
   * used to get the actual port used when a value of 0 for [port] is
   * specified in the [listen] call.
   */
  int get port();

  /**
   * Sets the handler that gets called when a new HTTP request is received.
   */
  void set onRequest(void callback(HttpRequest, HttpResponse));

  /**
   * Sets the error handler that is called when a connection error occurs.
   */
  void set onError(void callback(Exception e));
}


/**
 * Http request delivered to the HTTP server callback.
 */
interface HttpRequest default _HttpRequest {
  /**
   * Returns the content length of the request body. If the size of
   * the request body is not known in advance this -1.
   */
  int get contentLength();

  /**
   * Returns the keep alive state of the connection.
   */
  bool get keepAlive();

  /**
   * Returns the method for the request.
   */
  String get method();

  /**
   * Returns the URI for the request.
   */
  String get uri();

  /**
   * Returns the path part of the URI.
   */
  String get path();

  /**
   * Returns the query string.
   */
  String get queryString();

  /**
   * Returns the parsed query string.
   */
  Map<String, String> get queryParameters();

  /**
   * Returns the request headers.
   */
  Map<String, String> get headers();

  /**
   * Returns the input stream for the request. This is used to read
   * the request data.
   */
  InputStream get inputStream();
}


/**
 * HTTP response to be send back to the client.
 */
interface HttpResponse default _HttpResponse {
  /**
   * Gets and sets the content length of the response. If the size of
   * the response is not known in advance set the content length to
   * -1 - which is also the default if not set.
   */
  int contentLength;

  /**
   * Gets and sets the keep alive state of the connection. If the
   * associated request have a keep alive state of false setting keep
   * alive to true will have no effect.
   */
  bool keepAlive;

  /**
   * Gets and sets the status code. Any integer value is accepted, but
   * for the official HTTP status codes use the fields from
   * [HttpStatus].
   */
  int statusCode;

  /**
   * Gets and sets the reason phrase. If no reason phrase is explicitly
   * set a default reason phrase is provided.
   */
  String reasonPhrase;

  /**
   * Gets and sets the expiry date. The value of this property will
   * reflect the "Expires" header
   */
  Date expires;

  /**
   * Sets a header on the response. NOTE: If the same header name is
   * set more than once only the last value will be part of the
   * response.
   */
  void setHeader(String name, String value);

  /**
   * Returns the response headers.
   */
  Map<String, String> get headers();

  /**
   * Returns the output stream for the response. This is used to write
   * the response data. When all response data has been written close
   * the stream to indicate the end of the response.
   *
   * When this is accessed for the first time the response header is
   * send. Calling any methods that will change the header after
   * having retrieved the output stream will throw an exception.
   */
  OutputStream get outputStream();
}


/**
 * HTTP client factory.
 */
interface HttpClient default _HttpClient {
  static final int DEFAULT_HTTP_PORT = 80;

  HttpClient();

  /**
   * Opens a HTTP connection. The returned [HttpClientConnection] is
   * used to register callbacks for asynchronous events on the HTTP
   * connection. The "Host" header for the request will be set to the
   * value [host]:[port]. This can be overridden through the
   * HttpClientRequest interface before the request is sent. NOTE if
   * [host] is an IP address this will still be set in the "Host"
   * header.
   */
  HttpClientConnection open(String method, String host, int port, String path);

  /**
   * Opens a HTTP connection. The returned [HttpClientConnection] is
   * used to register callbacks for asynchronous events on the HTTP
   * connection. The "Host" header for the request will be set based
   * the host and port specified in [url]. This can be overridden
   * through the HttpClientRequest interface before the request is
   * sent. NOTE if the host is specified as an IP address this will
   * still be set in the "Host" header.
   */
  HttpClientConnection openUrl(String method, Uri url);

  /**
   * Opens a HTTP connection using the GET method. See [open] for details.
   */
  HttpClientConnection get(String host, int port, String path);

  /**
   * Opens a HTTP connection using the GET method. See [openUrl] for details.
   */
  HttpClientConnection getUrl(Uri url);

  /**
   * Opens a HTTP connection using the POST method. See [open] for details.
   */
  HttpClientConnection post(String host, int port, String path);

  /**
   * Opens a HTTP connection using the POST method. See [openUrl] for details.
   */
  HttpClientConnection postUrl(Uri url);

  /**
   * Shutdown the HTTP client releasing all resources.
   */
  void shutdown();
}


/**
 * A [HttpClientConnection] is returned by all [HttpClient] methods
 * that initiate a connection to an HTTP server. The handlers will be
 * called as the connection state progresses.
 *
 * The setting of all handlers is optional. If [onRequest] is not set
 * the request will be send without any additional headers and an
 * empty body. If [onResponse] is not set the response will be read
 * and discarded.
 */
interface HttpClientConnection {
  /**
   * Sets the handler that is called when the connection is established.
   */
  void set onRequest(void callback(HttpClientRequest request));

  /**
   * Sets callback to be called when the request has been send and
   * the response is ready for processing. The callback is called when
   * all headers of the response are received and data is ready to be
   * received.
   */
  void set onResponse(void callback(HttpClientResponse response));

  /**
   * Sets the handler that gets called if an error occurs while
   * connecting or processing the HTTP request.
   */
  void set onError(void callback(Exception e));
}


/**
 * HTTP request for a client connection.
 */
interface HttpClientRequest default _HttpClientRequest {
  /**
   * Gets and sets the content length of the request. If the size of
   * the request is not known in advance set content length to -1,
   * which is also the default.
   */
  int contentLength;

  /**
   * Gets and sets the keep alive state of the connection.
   */
  bool keepAlive;

  /**
   * Gets and sets the " host part of the "Host" header for the
   * connection. By default this will be set to the value of the host
   * used when initiating the connection.
   */
  String host;

  /**
   * Gets and sets the port part of the "Host" header for the
   * connection. By default this will be set to the value of the port
   * used when initiating the connection.
   */
  int port;

  /**
   * Sets a header on the request. NOTE: If the same header name is
   * set more than once only the last value set will be part of the
   * request.
   */
  void setHeader(String name, String value);

  /**
   * Returns the request headers.
   */
  Map<String, String> get headers();

  /**
   * Returns the output stream for the request. This is used to write
   * the request data. When all request data has been written close
   * the stream to indicate the end of the request.
   *
   * When this is accessed for the first time the request header is
   * send. Calling any methods that will change the header after
   * having retrieved the output stream will throw an exception.
   */
  OutputStream get outputStream();
}


/**
 * HTTP response for a client connection.
 */
interface HttpClientResponse default _HttpClientResponse {
  /**
   * Returns the status code.
   */
  int get statusCode();

  /**
   * Returns the reason phrase associated with the status code.
   */
  String get reasonPhrase();

  /**
   * Returns the content length of the request body. If the size of
   * the request body is not known in advance this -1.
   */
  int get contentLength();

  /**
   * Returns the keep alive state of the connection.
   */
  bool get keepAlive();

  /**
   * Returns the date value for the "Expires" header. Returns null if
   * the response has no "Expires" header. Throws a HttpException if
   * the response has an "Expires" header which is not formatted as a
   * valid HTTP date.
   */
  Date get expires();

  /**
   * Returns the response headers.
   */
  Map<String, String> get headers();

  /**
   * Returns the input stream for the response. This is used to read
   * the response data.
   */
  InputStream get inputStream();
}


class HttpException implements Exception {
  const HttpException([String this.message = ""]);
  String toString() => "HttpException: $message";
  final String message;
}
