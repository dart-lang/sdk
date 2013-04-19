// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * HTTP status codes.
 */
abstract class HttpStatus {
  static const int CONTINUE = 100;
  static const int SWITCHING_PROTOCOLS = 101;
  static const int OK = 200;
  static const int CREATED = 201;
  static const int ACCEPTED = 202;
  static const int NON_AUTHORITATIVE_INFORMATION = 203;
  static const int NO_CONTENT = 204;
  static const int RESET_CONTENT = 205;
  static const int PARTIAL_CONTENT = 206;
  static const int MULTIPLE_CHOICES = 300;
  static const int MOVED_PERMANENTLY = 301;
  static const int FOUND = 302;
  static const int MOVED_TEMPORARILY = 302; // Common alias for FOUND.
  static const int SEE_OTHER = 303;
  static const int NOT_MODIFIED = 304;
  static const int USE_PROXY = 305;
  static const int TEMPORARY_REDIRECT = 307;
  static const int BAD_REQUEST = 400;
  static const int UNAUTHORIZED = 401;
  static const int PAYMENT_REQUIRED = 402;
  static const int FORBIDDEN = 403;
  static const int NOT_FOUND = 404;
  static const int METHOD_NOT_ALLOWED = 405;
  static const int NOT_ACCEPTABLE = 406;
  static const int PROXY_AUTHENTICATION_REQUIRED = 407;
  static const int REQUEST_TIMEOUT = 408;
  static const int CONFLICT = 409;
  static const int GONE = 410;
  static const int LENGTH_REQUIRED = 411;
  static const int PRECONDITION_FAILED = 412;
  static const int REQUEST_ENTITY_TOO_LARGE = 413;
  static const int REQUEST_URI_TOO_LONG = 414;
  static const int UNSUPPORTED_MEDIA_TYPE = 415;
  static const int REQUESTED_RANGE_NOT_SATISFIABLE = 416;
  static const int EXPECTATION_FAILED = 417;
  static const int INTERNAL_SERVER_ERROR = 500;
  static const int NOT_IMPLEMENTED = 501;
  static const int BAD_GATEWAY = 502;
  static const int SERVICE_UNAVAILABLE = 503;
  static const int GATEWAY_TIMEOUT = 504;
  static const int HTTP_VERSION_NOT_SUPPORTED = 505;
  // Client generated status code.
  static const int NETWORK_CONNECT_TIMEOUT_ERROR = 599;
}


/**
 * HTTP server.
 */
abstract class HttpServer implements Stream<HttpRequest> {
  // TODO(ajohnsen): Document with example, once the stream API is final.
  // TODO(ajohnsen): Add HttpServer.secure.
  /**
   * Starts listening for HTTP requests on the specified [address] and
   * [port].
   *
   * The default value for [address] is 127.0.0.1, which will allow
   * only incoming connections from the local host. To allow for
   * incoming connection from the network use either the value 0.0.0.0
   * to bind to all interfaces or the IP address of a specific
   * interface.
   *
   * If [port] has the value [:0:] (the default) an ephemeral port
   * will be chosen by the system. The actual port used can be
   * retrieved using the [:port:] getter.
   *
   * The optional argument [backlog] can be used to specify the listen
   * backlog for the underlying OS listen setup. If [backlog] has the
   * value of [:0:] (the default) a reasonable value will be chosen by
   * the system.
   */
  static Future<HttpServer> bind([String address = "127.0.0.1",
                                  int port = 0,
                                  int backlog = 0])
      => _HttpServer.bind(address, port, backlog);

  /**
   * Starts listening for HTTPS requests on the specified [address] and
   * [port]. If a [port] of 0 is specified the server will choose an
   * ephemeral port. The optional argument [backlog] can be used to
   * specify the listen backlog for the underlying OS listen
   * setup.
   *
   * The certificate with Distinguished Name [certificateName] is looked
   * up in the certificate database, and is used as the server certificate.
   * if [requestClientCertificate] is true, the server will request clients
   * to authenticate with a client certificate.
   */

  static Future<HttpServer> bindSecure(String address,
                                       int port,
                                       {int backlog: 0,
                                        String certificateName,
                                        bool requestClientCertificate: false})
      => _HttpServer.bindSecure(address,
                                port,
                                backlog,
                                certificateName,
                                requestClientCertificate);

  /**
   * Attaches the HTTP server to an existing [ServerSocket]. When the
   * [HttpServer] is closed, the [HttpServer] will just detach itself,
   * closing current connections but not closing [serverSocket].
   */
  factory HttpServer.listenOn(ServerSocket serverSocket)
      => new _HttpServer.listenOn(serverSocket);

  /**
   * Permanently stops this [HttpServer] from listening for new connections.
   * This closes this [Stream] of [HttpRequest]s with a done event.
   */
  void close();

  /**
   * Returns the port that the server is listening on. This can be
   * used to get the actual port used when a value of 0 for [:port:] is
   * specified in the [bind] or [bindSecure] call.
   */
  int get port;

  /**
   * Sets the timeout, in seconds, for sessions of this [HttpServer].
   * The default timeout is 20 minutes.
   */
  set sessionTimeout(int timeout);

  /**
   * Returns an [HttpConnectionsInfo] object summarizing the number of
   * current connections handled by the server.
   */
  HttpConnectionsInfo connectionsInfo();
}


/**
 * Summary statistics about an [HttpServer]s current socket connections.
 */
class HttpConnectionsInfo {
  /**
   * Total number of socket connections.
   */
  int total = 0;

  /**
   * Number of active connections where actual request/response
   * processing is active.
   */
  int active = 0;

  /**
   * Number of idle connections held by clients as persistent connections.
   */
  int idle = 0;

  /**
   * Number of connections which are preparing to close. Note: These
   * connections are also part of the [:active:] count as they might
   * still be sending data to the client before finally closing.
   */
  int closing = 0;
}


/**
 * Access to the HTTP headers for requests and responses. In some
 * situations the headers will be immutable and the mutating methods
 * will then throw exceptions.
 *
 * For all operations on HTTP headers the header name is
 * case-insensitive.
 */
abstract class HttpHeaders {
  static const ACCEPT = "accept";
  static const ACCEPT_CHARSET = "accept-charset";
  static const ACCEPT_ENCODING = "accept-encoding";
  static const ACCEPT_LANGUAGE = "accept-language";
  static const ACCEPT_RANGES = "accept-ranges";
  static const AGE = "age";
  static const ALLOW = "allow";
  static const AUTHORIZATION = "authorization";
  static const CACHE_CONTROL = "cache-control";
  static const CONNECTION = "connection";
  static const CONTENT_ENCODING = "content-encoding";
  static const CONTENT_LANGUAGE = "content-language";
  static const CONTENT_LENGTH = "content-length";
  static const CONTENT_LOCATION = "content-location";
  static const CONTENT_MD5 = "content-md5";
  static const CONTENT_RANGE = "content-range";
  static const CONTENT_TYPE = "content-type";
  static const DATE = "date";
  static const ETAG = "etag";
  static const EXPECT = "expect";
  static const EXPIRES = "expires";
  static const FROM = "from";
  static const HOST = "host";
  static const IF_MATCH = "if-match";
  static const IF_MODIFIED_SINCE = "if-modified-since";
  static const IF_NONE_MATCH = "if-none-match";
  static const IF_RANGE = "if-range";
  static const IF_UNMODIFIED_SINCE = "if-unmodified-since";
  static const LAST_MODIFIED = "last-modified";
  static const LOCATION = "location";
  static const MAX_FORWARDS = "max-forwards";
  static const PRAGMA = "pragma";
  static const PROXY_AUTHENTICATE = "proxy-authenticate";
  static const PROXY_AUTHORIZATION = "proxy-authorization";
  static const RANGE = "range";
  static const REFERER = "referer";
  static const RETRY_AFTER = "retry-after";
  static const SERVER = "server";
  static const TE = "te";
  static const TRAILER = "trailer";
  static const TRANSFER_ENCODING = "transfer-encoding";
  static const UPGRADE = "upgrade";
  static const USER_AGENT = "user-agent";
  static const VARY = "vary";
  static const VIA = "via";
  static const WARNING = "warning";
  static const WWW_AUTHENTICATE = "www-authenticate";

  // Cookie headers from RFC 6265.
  static const COOKIE = "cookie";
  static const SET_COOKIE = "set-cookie";

  static const GENERAL_HEADERS = const [CACHE_CONTROL,
                                        CONNECTION,
                                        DATE,
                                        PRAGMA,
                                        TRAILER,
                                        TRANSFER_ENCODING,
                                        UPGRADE,
                                        VIA,
                                        WARNING];

  static const ENTITY_HEADERS = const [ALLOW,
                                       CONTENT_ENCODING,
                                       CONTENT_LANGUAGE,
                                       CONTENT_LENGTH,
                                       CONTENT_LOCATION,
                                       CONTENT_MD5,
                                       CONTENT_RANGE,
                                       CONTENT_TYPE,
                                       EXPIRES,
                                       LAST_MODIFIED];


  static const RESPONSE_HEADERS = const [ACCEPT_RANGES,
                                         AGE,
                                         ETAG,
                                         LOCATION,
                                         PROXY_AUTHENTICATE,
                                         RETRY_AFTER,
                                         SERVER,
                                         VARY,
                                         WWW_AUTHENTICATE];

  static const REQUEST_HEADERS = const [ACCEPT,
                                        ACCEPT_CHARSET,
                                        ACCEPT_ENCODING,
                                        ACCEPT_LANGUAGE,
                                        AUTHORIZATION,
                                        EXPECT,
                                        FROM,
                                        HOST,
                                        IF_MATCH,
                                        IF_MODIFIED_SINCE,
                                        IF_NONE_MATCH,
                                        IF_RANGE,
                                        IF_UNMODIFIED_SINCE,
                                        MAX_FORWARDS,
                                        PROXY_AUTHORIZATION,
                                        RANGE,
                                        REFERER,
                                        TE,
                                        USER_AGENT];

  /**
   * Returns the list of values for the header named [name]. If there
   * is no header with the provided name, [:null:] will be returned.
   */
  List<String> operator[](String name);

  /**
   * Convenience method for the value for a single valued header. If
   * there is no header with the provided name, [:null:] will be
   * returned. If the header has more than one value an exception is
   * thrown.
   */
  String value(String name);

  /**
   * Adds a header value. The header named [name] will have the value
   * [value] added to its list of values. Some headers are single
   * valued, and for these adding a value will replace the previous
   * value. If the value is of type DateTime a HTTP date format will be
   * applied. If the value is a [:List:] each element of the list will
   * be added separately. For all other types the default [:toString:]
   * method will be used.
   */
  void add(String name, Object value);

  /**
   * Sets a header. The header named [name] will have all its values
   * cleared before the value [value] is added as its value.
   */
  void set(String name, Object value);

  /**
   * Removes a specific value for a header name. Some headers have
   * system supplied values and for these the system supplied values
   * will still be added to the collection of values for the header.
   */
  void remove(String name, Object value);

  /**
   * Removes all values for the specified header name. Some headers
   * have system supplied values and for these the system supplied
   * values will still be added to the collection of values for the
   * header.
   */
  void removeAll(String name);

  /**
   * Enumerates the headers, applying the function [f] to each
   * header. The header name passed in [:name:] will be all lower
   * case.
   */
  void forEach(void f(String name, List<String> values));

  /**
   * Disables folding for the header named [name] when sending the HTTP
   * header. By default, multiple header values are folded into a
   * single header line by separating the values with commas. The
   * 'set-cookie' header has folding disabled by default.
   */
  void noFolding(String name);

  /**
   * Gets and sets the date. The value of this property will
   * reflect the 'date' header.
   */
  DateTime date;

  /**
   * Gets and sets the expiry date. The value of this property will
   * reflect the 'expires' header.
   */
  DateTime expires;

  /**
   * Gets and sets the "if-modified-since" date. The value of this property will
   * reflect the "if-modified-since" header.
   */
  DateTime ifModifiedSince;

  /**
   * Gets and sets the host part of the 'host' header for the
   * connection.
   */
  String host;

  /**
   * Gets and sets the port part of the 'host' header for the
   * connection.
   */
  int port;

  /**
   * Gets and sets the content type. Note that the content type in the
   * header will only be updated if this field is set
   * directly. Mutating the returned current value will have no
   * effect.
   */
  ContentType contentType;

  /**
   * Gets and sets the content length header value.
   */
  int contentLength;

  /**
   * Gets and sets the persistent connection header value.
   */
  bool persistentConnection;
}


/**
 * Representation of a header value in the form:
 *
 *   [:value; parameter1=value1; parameter2=value2:]
 *
 * [HeaderValue] can be used to conveniently build and parse header
 * values on this form.
 *
 * To build an [:accepts:] header with the value
 *
 *     text/plain; q=0.3, text/html
 *
 * use code like this:
 *
 *     HttpClientRequest request = ...;
 *     var v = new HeaderValue("text/plain", {"q": "0.3"});
 *     request.headers.add(HttpHeaders.ACCEPT, v);
 *     request.headers.add(HttpHeaders.ACCEPT, "text/html");
 *
 * To parse the header values use the [:fromString:] constructor.
 *
 *     HttpRequest request = ...;
 *     List<String> values = request.headers[HttpHeaders.ACCEPT];
 *     values.forEach((value) {
 *       HeaderValue v = new HeaderValue.fromString(value);
 *       // Use v.value and v.parameters
 *     });
 *
 * An instance of [HeaderValue] is immutable.
 */
abstract class HeaderValue {
  /**
   * Creates a new header value object setting the value part.
   */
  factory HeaderValue([String value = "", Map<String, String> parameters]) {
    return new _HeaderValue(value, parameters);
  }

  /**
   * Creates a new header value object from parsing a header value
   * string with both value and optional parameters.
   */
  factory HeaderValue.fromString(String value,
                                 {String parameterSeparator: ";"}) {
    return new _HeaderValue.fromString(
        value, parameterSeparator: parameterSeparator);
  }

  /**
   * Gets the header value.
   */
  String get value;

  /**
   * Gets the map of parameters.
   */
  Map<String, String> get parameters;

  /**
   * Returns the formatted string representation in the form:
   *
   *     value; parameter1=value1; parameter2=value2
   */
  String toString();
}

abstract class HttpSession implements Map {
  /**
   * Gets the id for the current session.
   */
  String get id;

  /**
   * Destroys the session. This will terminate the session and any further
   * connections with this id will be given a new id and session.
   */
  void destroy();

  /**
   * Sets a callback that will be called when the session is timed out.
   */
  void set onTimeout(void callback());

  /**
   * Is true if the session has not been sent to the client yet.
   */
  bool get isNew;
}


/**
 * Representation of a content type. An instance of [ContentType] is
 * immutable.
 */
abstract class ContentType implements HeaderValue {
  /**
   * Creates a new content type object setting the primary type and
   * sub type. The charset and additional parameters can also be set
   * using [charset] and [parameters]. If charset is passed and
   * [parameters] contains charset as well the passed [charset] will
   * override the value in parameters. Keys and values passed in
   * parameters will be converted to lower case.
   */
  factory ContentType(String primaryType,
                      String subType,
                      {String charset, Map<String, String> parameters}) {
    return new _ContentType(primaryType, subType, charset, parameters);
  }

  /**
   * Creates a new content type object from parsing a Content-Type
   * header value. As primary type, sub type and parameter names and
   * values are not case sensitive all these values will be converted
   * to lower case. Parsing this string
   *
   *     text/html; charset=utf-8
   *
   * will create a content type object with primary type [:text:], sub
   * type [:html:] and parameter [:charset:] with value [:utf-8:].
   */
  factory ContentType.fromString(String value) {
    return new _ContentType.fromString(value);
  }

  /**
   * Gets the mime-type, without any parameters.
   */
  String get mimeType;

  /**
   * Gets the primary type.
   */
  String get primaryType;

  /**
   * Gets the sub type.
   */
  String get subType;

  /**
   * Gets the character set.
   */
  String get charset;
}


/**
 * Representation of a cookie. For cookies received by the server as
 * Cookie header values only [:name:] and [:value:] fields will be
 * set. When building a cookie for the 'set-cookie' header in the server
 * and when receiving cookies in the client as 'set-cookie' headers all
 * fields can be used.
 */
abstract class Cookie {
  /**
   * Creates a new cookie optionally setting the name and value.
   */
  factory Cookie([String name, String value]) => new _Cookie(name, value);

  /**
   * Creates a new cookie by parsing a header value from a 'set-cookie'
   * header.
   */
  factory Cookie.fromSetCookieValue(String value) {
    return new _Cookie.fromSetCookieValue(value);
  }

  /**
   * Gets and sets the name.
   */
  String name;

  /**
   * Gets and sets the value.
   */
  String value;

  /**
   * Gets and sets the expiry date.
   */
  DateTime expires;

  /**
   * Gets and sets the max age. A value of [:0:] means delete cookie
   * now.
   */
  int maxAge;

  /**
   * Gets and sets the domain.
   */
  String domain;

  /**
   * Gets and sets the path.
   */
  String path;

  /**
   * Gets and sets whether this cookie is secure.
   */
  bool secure;

  /**
   * Gets and sets whether this cookie is HTTP only.
   */
  bool httpOnly;

  /**
   * Returns the formatted string representation of the cookie. The
   * string representation can be used for for setting the Cookie or
   * 'set-cookie' headers
   */
  String toString();
}


/**
 * Http request delivered to the HTTP server callback. The [HttpRequest] is a
 * [Stream] of the body content of the request. Listen to the body to handle the
 * data and be notified once the entire body is received.
 */
abstract class HttpRequest implements Stream<List<int>> {
  /**
   * Returns the content length of the request body. If the size of
   * the request body is not known in advance this -1.
   */
  int get contentLength;

  /**
   * Returns the method for the request.
   */
  String get method;

  /**
   * Returns the URI for the request.
   */
  Uri get uri;

  /**
   * Returns the parsed query string.
   */
  Map<String, String> get queryParameters;

  /**
   * Returns the request headers.
   */
  HttpHeaders get headers;

  /**
   * Returns the cookies in the request (from the Cookie headers).
   */
  List<Cookie> get cookies;

  /**
   * Returns the persistent connection state signaled by the client.
   */
  bool get persistentConnection;

  /**
   * Returns the client certificate of the client making the request.
   * Returns null if the connection is not a secure TLS or SSL connection,
   * or if the server does not request a client certificate, or if the client
   * does not provide one.
   */
  X509Certificate get certificate;

  /**
   * Gets the session for the given request. If the session is
   * being initialized by this call, [:isNew:] will be true for the returned
   * session.
   * See [HttpServer.sessionTimeout] on how to change default timeout.
   */
  HttpSession get session;

  /**
   * Returns the HTTP protocol version used in the request. This will
   * be "1.0" or "1.1".
   */
  String get protocolVersion;

  /**
   * Gets information about the client connection. Returns [null] if the socket
   * is not available.
   */
  HttpConnectionInfo get connectionInfo;

  /**
   * Gets the [HttpResponse] object, used for sending back the response to the
   * client.
   */
  HttpResponse get response;
}


/**
 * HTTP response to be send back to the client.
 *
 * This object has a number of properties for setting up the HTTP
 * header of the response. When the header has been set up the methods
 * from the [IOSink] can be used to write the actual body of the HTTP
 * response. When one of the [IOSink] methods is used for the
 * first time the request header is send. Calling any methods that
 * will change the header after it is sent will throw an exception.
 *
 * When writing string data through the [IOSink] the encoding used
 * will be determined from the "charset" parameter of the
 * "Content-Type" header.
 *
 *     HttpResponse response = ...
 *     response.headers.contentType
 *         = new ContentType("application", "json", charset: "utf-8");
 *     response.write(...);  // Strings written will be UTF-8 encoded.
 *
 * If no charset is provided the default of ISO-8859-1 (Latin 1) will
 * be used.
 *
 *     HttpResponse response = ...
 *     response.headers.add(HttpHeaders.CONTENT_TYPE, "text/plain");
 *     response.write(...);  // Strings written will be ISO-8859-1 encoded.
 *
 * If an unsupported encoding is used an exception will be thrown if
 * using one of the write methods taking a string.
 */
abstract class HttpResponse implements IOSink {
  // TODO(ajohnsen): Add documentation of how to pipe a file to the response.
  /**
   * Gets and sets the content length of the response. If the size of
   * the response is not known in advance set the content length to
   * -1 - which is also the default if not set.
   */
  int contentLength;

  /**
   * Gets and sets the status code. Any integer value is accepted. For
   * the official HTTP status codes use the fields from
   * [HttpStatus]. If no status code is explicitly set the default
   * value [HttpStatus.OK] is used.
   */
  int statusCode;

  /**
   * Gets and sets the reason phrase. If no reason phrase is explicitly
   * set a default reason phrase is provided.
   */
  String reasonPhrase;

  /**
   * Gets and sets the persistent connection state. The initial value
   * of this property is the persistent connection state from the
   * request.
   */
  bool persistentConnection;

  /**
   * Returns the response headers.
   */
  HttpHeaders get headers;

  /**
   * Cookies to set in the client (in the 'set-cookie' header).
   */
  List<Cookie> get cookies;

  /**
   * Detaches the underlying socket from the HTTP server. When the
   * socket is detached the HTTP server will no longer perform any
   * operations on it.
   *
   * This is normally used when a HTTP upgrade request is received
   * and the communication should continue with a different protocol.
   */
  Future<Socket> detachSocket();

  /**
   * Gets information about the client connection. Returns [null] if the socket
   * is not available.
   */
  HttpConnectionInfo get connectionInfo;
}


/**
 * The [HttpClient] class implements the client side of the HTTP
 * protocol. It contains a number of methods to send a HTTP request
 * to a HTTP server and receive a HTTP response back.
 *
 * This is a two-step process, triggered by two futures. When the
 * first future completes with a [HttpClientRequest] the underlying
 * network connection has been established, but no data has yet been
 * sent. The HTTP headers and body can be set on the request, and
 * [:close:] is called to sent it to the server.
 *
 * The second future, which is returned by [:close:], completes with
 * an [HttpClientResponse] object when the response is received from
 * the server. This object contains the headers and body of the
 * response.

 * The future for [HttpClientRequest] is created by methods such as
 * [getUrl] and [open].
 *
 * When the HTTP response is ready a [HttpClientResponse] object is
 * provided which provides access to the headers and body of the response.
 *
 *     HttpClient client = new HttpClient();
 *     client.getUrl(new Uri.fromString("http://www.example.com/"))
 *         .then((HttpClientRequest request) {
 *           // Prepare the request then call close on it to send it.
 *           return request.close();
 *         })
 *         .then((HttpClientResponse response) {
 *          // Process the response.
 *         });
 *
 * All [HttpClient] requests set the following header by default:
 *
 *     Accept-Encoding: gzip
 *
 * This allows the HTTP server to use gzip compression for the body if
 * possible. If this behavior is not desired set the
 * "Accept-Encoding" header to something else.
 *
 * The [HttpClient] supports persistent connections and caches network
 * connections to reuse then for multiple requests whenever
 * possible. This means that network connections can be kept open for
 * some time after a request have completed. Use [:HttpClient.close:]
 * to force shut down the [HttpClient] object and close the idle
 * network connections.
 *
 * By default the HttpClient uses the proxy configuration available
 * from the environment, see [findProxyFromEnvironment]. To turn off
 * the use of proxies all together set the [findProxy] property to
 * [:null:].
 *
 *     HttpClient client = new HttpClient();
 *     client.findProxy = null;
 */
abstract class HttpClient {
  static const int DEFAULT_HTTP_PORT = 80;
  static const int DEFAULT_HTTPS_PORT = 443;

  factory HttpClient() => new _HttpClient();

  /**
   * Opens a HTTP connection. The returned [HttpClientRequest] is used to
   * fill in the content of the request before sending it. The 'host' header for
   * the request will be set to the value [host]:[port]. This can be overridden
   * through the [HttpClientRequest] interface before the request is sent.
   * NOTE if [host] is an IP address this will still be set in the 'host'
   * header.
   */
  Future<HttpClientRequest> open(String method,
                                 String host,
                                 int port,
                                 String path);

  /**
   * Opens a HTTP connection. The returned [HttpClientRequest] is used to
   * fill in the content of the request before sending it. The 'hosth header for
   * the request will be set to the value [host]:[port]. This can be overridden
   * through the [HttpClientRequest] interface before the request is sent.
   * NOTE if [host] is an IP address this will still be set in the 'host'
   * header.
   */
  Future<HttpClientRequest> openUrl(String method, Uri url);

  /**
   * Opens a HTTP connection using the GET method. See [open] for
   * details. Using this method to open a HTTP connection will set the
   * content length to 0.
   */
  Future<HttpClientRequest> get(String host, int port, String path);

  /**
   * Opens a HTTP connection using the GET method. See [openUrl] for
   * details. Using this method to open a HTTP connection will set the
   * content length to 0.
   */
  Future<HttpClientRequest> getUrl(Uri url);

  /**
   * Opens a HTTP connection using the POST method. See [open] for details.
   */
  Future<HttpClientRequest> post(String host, int port, String path);

  /**
   * Opens a HTTP connection using the POST method. See [openUrl] for details.
   */
  Future<HttpClientRequest> postUrl(Uri url);

  /**
   * Sets the function to be called when a site is requesting
   * authentication. The URL requested and the security realm from the
   * server are passed in the arguments [url] and [realm].
   *
   * The function returns a [Future] which should complete when the
   * authentication has been resolved. If credentials cannot be
   * provided the [Future] should complete with [false]. If
   * credentials are available the function should add these using
   * [addCredentials] before completing the [Future] with the value
   * [true].
   *
   * If the [Future] completes with true the request will be retried
   * using the updated credentials. Otherwise response processing will
   * continue normally.
   */
  set authenticate(Future<bool> f(Uri url, String scheme, String realm));

  /**
   * Add credentials to be used for authorizing HTTP requests.
   */
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials);

  /**
   * Sets the function used to resolve the proxy server to be used for
   * opening a HTTP connection to the specified [url]. If this
   * function is not set, direct connections will always be used.
   *
   * The string returned by [f] must be in the format used by browser
   * PAC (proxy auto-config) scripts. That is either
   *
   *   "DIRECT"
   *
   * for using a direct connection or
   *
   *   "PROXY host:port"
   *
   * for using the proxy server [:host:] on port [:port:].
   *
   * A configuration can contain several configuration elements
   * separated by semicolons, e.g.
   *
   *   "PROXY host:port; PROXY host2:port2; DIRECT"
   *
   * The static function [findProxyFromEnvironment] on this class can
   * be used to implement proxy server resolving based on environment
   * variables.
   */
  set findProxy(String f(Uri url));

  /**
   * Function for resolving the proxy server to be used for a HTTP
   * connection from the proxy configuration specified through
   * environment variables.
   *
   * The following environment variables are taken into account:
   *
   *     http_proxy
   *     https_proxy
   *     no_proxy
   *     HTTP_PROXY
   *     HTTPS_PROXY
   *     NO_PROXY
   *
   * [:http_proxy:] and [:HTTP_PROXY:] specify the proxy server to use for
   * http:// urls. Use the format [:hostname:port:]. If no port is used a
   * default of 1080 will be used. If both are set the lower case one takes
   * precedence.
   *
   * [:https_proxy:] and [:HTTPS_PROXY:] specify the proxy server to use for
   * https:// urls. Use the format [:hostname:port:]. If no port is used a
   * default of 1080 will be used. If both are set the lower case one takes
   * precedence.
   *
   * [:no_proxy:] and [:NO_PROXY:] specify a comma separated list of
   * postfixes of hostnames for which not to use the proxy
   * server. E.g. the value "localhost,127.0.0.1" will make requests
   * to both "localhost" and "127.0.0.1" not use a proxy. If both are set
   * the lower case one takes precedence.
   *
   * To activate this way of resolving proxies assign this function to
   * the [findProxy] property on the [HttpClient].
   *
   *     HttpClient client = new HttpClient();
   *     client.findProxy = HttpClient.findProxyFromEnvironment;
   *
   * If you don't want to use the system environment you can use a
   * different one by wrapping the function.
   *
   *     HttpClient client = new HttpClient();
   *     client.findProxy = (url) {
   *       return HttpClient.findProxyFromEnvironment(
   *           url, {"http_proxy": ..., "no_proxy": ...});
   *     }
   *
   * If a proxy requires authentication it is possible to configure
   * the username and password as well. Use the format
   * [:username:password@hostname:port:] to include the username and
   * password. Alternatively the API [addProxyCredentials] can be used
   * to set credentials for proxies which require authentication.
   */
  static String findProxyFromEnvironment(Uri url,
                                         {Map<String, String> environment}) {
    return _HttpClient._findProxyFromEnvironment(url, environment);
  }

  /**
   * Sets the function to be called when a proxy is requesting
   * authentication. Information on the proxy in use and the security
   * realm for the authentication are passed in the arguments [host],
   * [port] and [realm].
   *
   * The function returns a [Future] which should complete when the
   * authentication has been resolved. If credentials cannot be
   * provided the [Future] should complete with [false]. If
   * credentials are available the function should add these using
   * [addProxyCredentials] before completing the [Future] with the value
   * [true].
   *
   * If the [Future] completes with [true] the request will be retried
   * using the updated credentials. Otherwise response processing will
   * continue normally.
   */
  set authenticateProxy(
      Future<bool> f(String host, int port, String scheme, String realm));

  /**
   * Add credentials to be used for authorizing HTTP proxies.
   */
  void addProxyCredentials(String host,
                           int port,
                           String realm,
                           HttpClientCredentials credentials);

  /**
   * Shutdown the HTTP client. If [force] is [:false:] (the default)
   * the [:HttpClient:] will be kept alive until all active
   * connections are done. If [force] is [:true:] any active
   * connections will be closed to immediately release all
   * resources. These closed connections will receive an [:onError:]
   * callback to indicate that the client was shutdown. In both cases
   * trying to establish a new connection after calling [shutdown]
   * will throw an exception.
   */
  void close({bool force: false});
}


/**
 * HTTP request for a client connection.
 *
 * This object has a number of properties for setting up the HTTP
 * header of the request. When the header has been set up the methods
 * from the [IOSink] can be used to write the actual body of the HTTP
 * request. When one of the [IOSink] methods is used for the first
 * time the request header is send. Calling any methods that will
 * change the header after it is sent will throw an exception.
 *
 * When writing string data through the [IOSink] the
 * encoding used will be determined from the "charset" parameter of
 * the "Content-Type" header.
 *
 *     HttpClientRequest request = ...
 *     request.headers.contentType
 *         = new ContentType("application", "json", charset: "utf-8");
 *     request.write(...);  // Strings written will be UTF-8 encoded.
 *
 * If no charset is provided the default of ISO-8859-1 (Latin 1) will
 * be used.
 *
 *     HttpClientRequest request = ...
 *     request.headers.add(HttpHeaders.CONTENT_TYPE, "text/plain");
 *     request.write(...);  // Strings written will be ISO-8859-1 encoded.
 *
 * If an unsupported encoding is used an exception will be thrown if
 * using one of the write methods taking a string.
 */
abstract class HttpClientRequest implements IOSink {
  /**
   * Gets and sets the content length of the request. If the size of
   * the request is not known in advance set content length to -1,
   * which is also the default.
   */
  int contentLength;

  /**
   * Returns the request headers.
   */
  HttpHeaders get headers;

  /**
   * Cookies to present to the server (in the 'cookie' header).
   */
  List<Cookie> get cookies;

  /**
   * Gets and sets the requested persistent connection state.
   * The default value is [:true:].
   */
  bool persistentConnection;

  /**
   * A [HttpClientResponse] future that will complete once the response is
   * available. If an error occurs before the response is available, this
   * future will complete with an error.
   */
  Future<HttpClientResponse> get done;

  /**
   * Close the request for input. Returns the value of [done].
   */
  Future<HttpClientResponse> close();

  /**
   * Set this property to [:true:] if this request should
   * automatically follow redirects. The default is [:true:].
   *
   * Automatic redirect will only happen for "GET" and "HEAD" requests
   * and only for the status codes [:HttpHeaders.MOVED_PERMANENTLY:]
   * (301), [:HttpStatus.FOUND:] (302),
   * [:HttpStatus.MOVED_TEMPORARILY:] (302, alias for
   * [:HttpStatus.FOUND:]), [:HttpStatus.SEE_OTHER:] (303) and
   * [:HttpStatus.TEMPORARY_REDIRECT:] (307). For
   * [:HttpStatus.SEE_OTHER:] (303) autmatic redirect will also happen
   * for "POST" requests with the method changed to "GET" when
   * following the redirect.
   *
   * All headers added to the request will be added to the redirection
   * request(s). However, any body send with the request will not be
   * part of the redirection request(s).
   */
  bool followRedirects;

  /**
   * Set this property to the maximum number of redirects to follow
   * when [followRedirects] is [:true:]. If this number is exceeded the
   * [onError] callback will be called with a [RedirectLimitExceeded]
   * exception. The default value is 5.
   */
  int maxRedirects;

  /**
   * Get information about the client connection. Returns [null] if the socket
   * is not available.
   */
  HttpConnectionInfo get connectionInfo;
}


/**
 * HTTP response for a client connection. The [HttpClientResponse] is a
 * [Stream] of the body content of the response. Listen to the body to handle
 * the data and be notified once the entire body is received.
 */
abstract class HttpClientResponse implements Stream<List<int>> {
  /**
   * Returns the status code.
   */
  int get statusCode;

  /**
   * Returns the reason phrase associated with the status code.
   */
  String get reasonPhrase;

  /**
   * Returns the content length of the request body. Returns -1 if the size of
   * the request body is not known in advance.
   */
  int get contentLength;

  /**
   * Gets the persistent connection state returned by the server.
   */
  bool get persistentConnection;

  /**
   * Returns whether the status code is one of the normal redirect
   * codes [HttpStatus.MOVED_PERMANENTLY], [HttpStatus.FOUND],
   * [HttpStatus.MOVED_TEMPORARILY], [HttpStatus.SEE_OTHER] and
   * [HttpStatus.TEMPORARY_REDIRECT].
   */
  bool get isRedirect;

  /**
   * Returns the series of redirects this connection has been through. The
   * list will be empty if no redirects were followed. [redirects] will be
   * updated both in the case of an automatic and a manual redirect.
   */
  List<RedirectInfo> get redirects;

  /**
   * Redirects this connection to a new URL. The default value for
   * [method] is the method for the current request. The default value
   * for [url] is the value of the [HttpHeaders.LOCATION] header of
   * the current response. All body data must have been read from the
   * current response before calling [redirect].
   *
   * All headers added to the request will be added to the redirection
   * request. However, any body sent with the request will not be
   * part of the redirection request.
   *
   * If [followLoops] is set to [true], redirect will follow the redirect,
   * even if the URL was already visited. The default value is [false].
   *
   * [redirect] will ignore [maxRedirects] and will always perform the redirect.
   */
  Future<HttpClientResponse> redirect([String method,
                                       Uri url,
                                       bool followLoops]);


  /**
   * Returns the response headers.
   */
  HttpHeaders get headers;

  /**
   * Detach the underlying socket from the HTTP client. When the
   * socket is detached the HTTP client will no longer perform any
   * operations on it.
   *
   * This is normally used when a HTTP upgrade is negotiated and the
   * communication should continue with a different protocol.
   */
  Future<Socket> detachSocket();

  /**
   * Cookies set by the server (from the 'set-cookie' header).
   */
  List<Cookie> get cookies;

  /**
   * Returns the certificate of the HTTPS server providing the response.
   * Returns null if the connection is not a secure TLS or SSL connection.
   */
  X509Certificate get certificate;

  /**
   * Gets information about the client connection. Returns [null] if the socket
   * is not available.
   */
  HttpConnectionInfo get connectionInfo;
}


abstract class HttpClientCredentials { }


/**
 * Represents credentials for basic authentication.
 */
abstract class HttpClientBasicCredentials extends HttpClientCredentials {
  factory HttpClientBasicCredentials(String username, String password) =>
      new _HttpClientBasicCredentials(username, password);
}


/**
 * Represents credentials for digest authentication.
 */
abstract class HttpClientDigestCredentials extends HttpClientCredentials {
  factory HttpClientDigestCredentials(String username, String password) =>
      new _HttpClientDigestCredentials(username, password);
}


/**
 * Information about an [HttpRequest], [HttpResponse], [HttpClientRequest], or
 * [HttpClientResponse] connection.
 */
abstract class HttpConnectionInfo {
  String get remoteHost;
  int get remotePort;
  int get localPort;
}


/**
 * Redirect information.
 */
abstract class RedirectInfo {
  /**
   * Returns the status code used for the redirect.
   */
  int get statusCode;

  /**
   * Returns the method used for the redirect.
   */
  String get method;

  /**
   * Returns the location for the redirect.
   */
  Uri get location;
}


/**
 * When detaching a socket from either the [:HttpServer:] or the
 * [:HttpClient:] due to a HTTP connection upgrade there might be
 * unparsed data already read from the socket. This unparsed data
 * together with the detached socket is returned in an instance of
 * this class.
 */
abstract class DetachedSocket {
  Socket get socket;
  List<int> get unparsedData;
}


class HttpException implements Exception {
  const HttpException([String this.message = ""]);
  String toString() => "HttpException: $message";
  final String message;
}


class RedirectException extends HttpException {
  const RedirectException(String message,
                          List<RedirectInfo> this.redirects) : super(message);
  final List<RedirectInfo> redirects;
}


class RedirectLimitExceededException extends RedirectException {
  const RedirectLimitExceededException(List<RedirectInfo> redirects)
      : super("Redirect limit exceeded", redirects);
}


class RedirectLoopException extends RedirectException {
  const RedirectLoopException(List<RedirectInfo> redirects)
      : super("Redirect loop detected", redirects);
}
