// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "io.dart";

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
 * A server that delivers content, such as web pages, using the HTTP protocol.
 *
 * The HttpServer is a [Stream] that provides [HttpRequest] objects. Each
 * HttpRequest has an associated [HttpResponse] object.
 * The server responds to a request by writing to that HttpResponse object.
 * The following example shows how to bind an HttpServer to an IPv6
 * [InternetAddress] on port 80 (the standard port for HTTP servers)
 * and how to listen for requests.
 * Port 80 is the default HTTP port. However, on most systems accessing
 * this requires super-user privileges. For local testing consider
 * using a non-reserved port (1024 and above).
 *
 *     import 'dart:io';
 *
 *     main() {
 *       HttpServer
 *           .bind(InternetAddress.ANY_IP_V6, 80)
 *           .then((server) {
 *             server.listen((HttpRequest request) {
 *               request.response.write('Hello, world!');
 *               request.response.close();
 *             });
 *           });
 *     }
 *
 * Incomplete requests, in which all or part of the header is missing, are
 * ignored, and no exceptions or HttpRequest objects are generated for them.
 * Likewise, when writing to an HttpResponse, any [Socket] exceptions are
 * ignored and any future writes are ignored.
 *
 * The HttpRequest exposes the request headers and provides the request body,
 * if it exists, as a Stream of data. If the body is unread, it is drained
 * when the server writes to the HttpResponse or closes it.
 *
 * ## Bind with a secure HTTPS connection
 *
 * Use [bindSecure] to create an HTTPS server.
 *
 * The server presents a certificate to the client. The certificate
 * chain and the private key are set in the [SecurityContext]
 * object that is passed to [bindSecure].
 *
 *     import 'dart:io';
 *     import "dart:isolate";
 *
 *     main() {
 *       SecurityContext context = new SecurityContext();
 *       var chain =
 *           Platform.script.resolve('certificates/server_chain.pem')
 *           .toFilePath();
 *       var key =
 *           Platform.script.resolve('certificates/server_key.pem')
 *           .toFilePath();
 *       context.useCertificateChain(chain);
 *       context.usePrivateKey(key, password: 'dartdart');
 *
 *       HttpServer
 *           .bindSecure(InternetAddress.ANY_IP_V6,
 *                       443,
 *                       context)
 *           .then((server) {
 *             server.listen((HttpRequest request) {
 *               request.response.write('Hello, world!');
 *               request.response.close();
 *             });
 *           });
 *     }
 *
 *  The certificates and keys are PEM files, which can be created and
 *  managed with the tools in OpenSSL.
 *
 * ## Connect to a server socket
 *
 * You can use the [listenOn] constructor to attach an HTTP server to
 * a [ServerSocket].
 *
 *     import 'dart:io';
 *
 *     main() {
 *       ServerSocket.bind(InternetAddress.ANY_IP_V6, 80)
 *         .then((serverSocket) {
 *           HttpServer httpserver = new HttpServer.listenOn(serverSocket);
 *           serverSocket.listen((Socket socket) {
 *             socket.write('Hello, client.');
 *           });
 *         });
 *     }
 *
 * ## Other resources
 *
 * * HttpServer is a Stream. Refer to the [Stream] class for information
 * about the streaming qualities of an HttpServer.
 * Pausing the subscription of the stream, pauses at the OS level.
 *
 * * The [shelf](https://pub.dartlang.org/packages/shelf)
 * package on pub.dartlang.org contains a set of high-level classes that,
 * together with this class, makes it easy to provide content through HTTP
 * servers.
 */
abstract class HttpServer implements Stream<HttpRequest> {
  /**
   * Get and set the default value of the `Server` header for all responses
   * generated by this [HttpServer].
   *
   * If [serverHeader] is `null`, no `Server` header will be added to each
   * response.
   *
   * The default value is `null`.
   */
  String serverHeader;

  /**
   * Default set of headers added to all response objects.
   *
   * By default the following headers are in this set:
   *
   *     Content-Type: text/plain; charset=utf-8
   *     X-Frame-Options: SAMEORIGIN
   *     X-Content-Type-Options: nosniff
   *     X-XSS-Protection: 1; mode=block
   *
   * If the `Server` header is added here and the `serverHeader` is set as
   * well then the value of `serverHeader` takes precedence.
   */
  HttpHeaders get defaultResponseHeaders;

  /**
   * Whether the [HttpServer] should compress the content, if possible.
   *
   * The content can only be compressed when the response is using
   * chunked Transfer-Encoding and the incoming request has `gzip`
   * as an accepted encoding in the Accept-Encoding header.
   *
   * The default value is `false` (compression disabled).
   * To enable, set `autoCompress` to `true`.
   */
  bool autoCompress;

  /**
   * Get or set the timeout used for idle keep-alive connections. If no further
   * request is seen within [idleTimeout] after the previous request was
   * completed, the connection is dropped.
   *
   * Default is 120 seconds.
   *
   * Note that it may take up to `2 * idleTimeout` before a idle connection is
   * aborted.
   *
   * To disable, set [idleTimeout] to `null`.
   */
  Duration idleTimeout;

  /**
   * Starts listening for HTTP requests on the specified [address] and
   * [port].
   *
   * The [address] can either be a [String] or an
   * [InternetAddress]. If [address] is a [String], [bind] will
   * perform a [InternetAddress.lookup] and use the first value in the
   * list. To listen on the loopback adapter, which will allow only
   * incoming connections from the local host, use the value
   * [InternetAddress.LOOPBACK_IP_V4] or
   * [InternetAddress.LOOPBACK_IP_V6]. To allow for incoming
   * connection from the network use either one of the values
   * [InternetAddress.ANY_IP_V4] or [InternetAddress.ANY_IP_V6] to
   * bind to all interfaces or the IP address of a specific interface.
   *
   * If an IP version 6 (IPv6) address is used, both IP version 6
   * (IPv6) and version 4 (IPv4) connections will be accepted. To
   * restrict this to version 6 (IPv6) only, use [v6Only] to set
   * version 6 only. However, if the address is
   * [InternetAddress.LOOPBACK_IP_V6], only IP version 6 (IPv6) connections
   * will be accepted.
   *
   * If [port] has the value [:0:] an ephemeral port will be chosen by
   * the system. The actual port used can be retrieved using the
   * [port] getter.
   *
   * The optional argument [backlog] can be used to specify the listen
   * backlog for the underlying OS listen setup. If [backlog] has the
   * value of [:0:] (the default) a reasonable value will be chosen by
   * the system.
   *
   * The optional argument [shared] specifies whether additional HttpServer
   * objects can bind to the same combination of `address`, `port` and `v6Only`.
   * If `shared` is `true` and more `HttpServer`s from this isolate or other
   * isolates are bound to the port, then the incoming connections will be
   * distributed among all the bound `HttpServer`s. Connections can be
   * distributed over multiple isolates this way.
   */
  static Future<HttpServer> bind(address, int port,
          {int backlog: 0, bool v6Only: false, bool shared: false}) =>
      _HttpServer.bind(address, port, backlog, v6Only, shared);

  /**
   * The [address] can either be a [String] or an
   * [InternetAddress]. If [address] is a [String], [bind] will
   * perform a [InternetAddress.lookup] and use the first value in the
   * list. To listen on the loopback adapter, which will allow only
   * incoming connections from the local host, use the value
   * [InternetAddress.LOOPBACK_IP_V4] or
   * [InternetAddress.LOOPBACK_IP_V6]. To allow for incoming
   * connection from the network use either one of the values
   * [InternetAddress.ANY_IP_V4] or [InternetAddress.ANY_IP_V6] to
   * bind to all interfaces or the IP address of a specific interface.
   *
   * If an IP version 6 (IPv6) address is used, both IP version 6
   * (IPv6) and version 4 (IPv4) connections will be accepted. To
   * restrict this to version 6 (IPv6) only, use [v6Only] to set
   * version 6 only.
   *
   * If [port] has the value [:0:] an ephemeral port will be chosen by
   * the system. The actual port used can be retrieved using the
   * [port] getter.
   *
   * The optional argument [backlog] can be used to specify the listen
   * backlog for the underlying OS listen setup. If [backlog] has the
   * value of [:0:] (the default) a reasonable value will be chosen by
   * the system.
   *
   * If [requestClientCertificate] is true, the server will
   * request clients to authenticate with a client certificate.
   * The server will advertise the names of trusted issuers of client
   * certificates, getting them from a [SecurityContext], where they have been
   * set using [SecurityContext.setClientAuthorities].
   *
   * The optional argument [shared] specifies whether additional HttpServer
   * objects can bind to the same combination of `address`, `port` and `v6Only`.
   * If `shared` is `true` and more `HttpServer`s from this isolate or other
   * isolates are bound to the port, then the incoming connections will be
   * distributed among all the bound `HttpServer`s. Connections can be
   * distributed over multiple isolates this way.
   */

  static Future<HttpServer> bindSecure(
          address, int port, SecurityContext context,
          {int backlog: 0,
          bool v6Only: false,
          bool requestClientCertificate: false,
          bool shared: false}) =>
      _HttpServer.bindSecure(address, port, context, backlog, v6Only,
          requestClientCertificate, shared);

  /**
   * Attaches the HTTP server to an existing [ServerSocket]. When the
   * [HttpServer] is closed, the [HttpServer] will just detach itself,
   * closing current connections but not closing [serverSocket].
   */
  factory HttpServer.listenOn(ServerSocket serverSocket) =>
      new _HttpServer.listenOn(serverSocket);

  /**
   * Permanently stops this [HttpServer] from listening for new
   * connections.  This closes the [Stream] of [HttpRequest]s with a
   * done event. The returned future completes when the server is
   * stopped. For a server started using [bind] or [bindSecure] this
   * means that the port listened on no longer in use.
   *
   * If [force] is `true`, active connections will be closed immediately.
   */
  Future close({bool force: false});

  /**
   * Returns the port that the server is listening on. This can be
   * used to get the actual port used when a value of 0 for [:port:] is
   * specified in the [bind] or [bindSecure] call.
   */
  int get port;

  /**
   * Returns the address that the server is listening on. This can be
   * used to get the actual address used, when the address is fetched by
   * a lookup from a hostname.
   */
  InternetAddress get address;

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
 * Headers for HTTP requests and responses.
 *
 * In some situations, headers are immutable:
 *
 * * HttpRequest and HttpClientResponse always have immutable headers.
 *
 * * HttpResponse and HttpClientRequest have immutable headers
 *   from the moment the body is written to.
 *
 * In these situations, the mutating methods throw exceptions.
 *
 * For all operations on HTTP headers the header name is
 * case-insensitive.
 *
 * To set the value of a header use the `set()` method:
 *
 *     request.headers.set(HttpHeaders.CACHE_CONTROL,
 *                         'max-age=3600, must-revalidate');
 *
 * To retrieve the value of a header use the `value()` method:
 *
 *     print(request.headers.value(HttpHeaders.USER_AGENT));
 *
 * An HttpHeaders object holds a list of values for each name
 * as the standard allows. In most cases a name holds only a single value,
 * The most common mode of operation is to use `set()` for setting a value,
 * and `value()` for retrieving a value.
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

  static const GENERAL_HEADERS = const [
    CACHE_CONTROL,
    CONNECTION,
    DATE,
    PRAGMA,
    TRAILER,
    TRANSFER_ENCODING,
    UPGRADE,
    VIA,
    WARNING
  ];

  static const ENTITY_HEADERS = const [
    ALLOW,
    CONTENT_ENCODING,
    CONTENT_LANGUAGE,
    CONTENT_LENGTH,
    CONTENT_LOCATION,
    CONTENT_MD5,
    CONTENT_RANGE,
    CONTENT_TYPE,
    EXPIRES,
    LAST_MODIFIED
  ];

  static const RESPONSE_HEADERS = const [
    ACCEPT_RANGES,
    AGE,
    ETAG,
    LOCATION,
    PROXY_AUTHENTICATE,
    RETRY_AFTER,
    SERVER,
    VARY,
    WWW_AUTHENTICATE
  ];

  static const REQUEST_HEADERS = const [
    ACCEPT,
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
    USER_AGENT
  ];

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

  /**
   * Gets and sets the chunked transfer encoding header value.
   */
  bool chunkedTransferEncoding;

  /**
   * Returns the list of values for the header named [name]. If there
   * is no header with the provided name, [:null:] will be returned.
   */
  List<String> operator [](String name);

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
   * Remove all headers. Some headers have system supplied values and
   * for these the system supplied values will still be added to the
   * collection of values for the header.
   */
  void clear();
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
 * To parse the header values use the [:parse:] static method.
 *
 *     HttpRequest request = ...;
 *     List<String> values = request.headers[HttpHeaders.ACCEPT];
 *     values.forEach((value) {
 *       HeaderValue v = HeaderValue.parse(value);
 *       // Use v.value and v.parameters
 *     });
 *
 * An instance of [HeaderValue] is immutable.
 */
abstract class HeaderValue {
  /**
   * Creates a new header value object setting the value and parameters.
   */
  factory HeaderValue([String value = "", Map<String, String> parameters]) {
    return new _HeaderValue(value, parameters);
  }

  /**
   * Creates a new header value object from parsing a header value
   * string with both value and optional parameters.
   */
  static HeaderValue parse(String value,
      {String parameterSeparator: ";",
      String valueSeparator: null,
      bool preserveBackslash: false}) {
    return _HeaderValue.parse(value,
        parameterSeparator: parameterSeparator,
        valueSeparator: valueSeparator,
        preserveBackslash: preserveBackslash);
  }

  /**
   * Gets the header value.
   */
  String get value;

  /**
   * Gets the map of parameters.
   *
   * This map cannot be modified. invoking any operation which would
   * modify the map will throw [UnsupportedError].
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
   * Content type for plain text using UTF-8 encoding.
   *
   *     text/plain; charset=utf-8
   */
  static final TEXT = new ContentType("text", "plain", charset: "utf-8");

  /**
   *  Content type for HTML using UTF-8 encoding.
   *
   *     text/html; charset=utf-8
   */
  static final HTML = new ContentType("text", "html", charset: "utf-8");

  /**
   *  Content type for JSON using UTF-8 encoding.
   *
   *     application/json; charset=utf-8
   */
  static final JSON = new ContentType("application", "json", charset: "utf-8");

  /**
   *  Content type for binary data.
   *
   *     application/octet-stream
   */
  static final BINARY = new ContentType("application", "octet-stream");

  /**
   * Creates a new content type object setting the primary type and
   * sub type. The charset and additional parameters can also be set
   * using [charset] and [parameters]. If charset is passed and
   * [parameters] contains charset as well the passed [charset] will
   * override the value in parameters. Keys passed in parameters will be
   * converted to lower case. The `charset` entry, whether passed as `charset`
   * or in `parameters`, will have its value converted to lower-case.
   */
  factory ContentType(String primaryType, String subType,
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
  static ContentType parse(String value) {
    return _ContentType.parse(value);
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
   * Creates a new cookie optionally setting the name and value.
   *
   * By default the value of `httpOnly` will be set to `true`.
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
   * Returns the formatted string representation of the cookie. The
   * string representation can be used for for setting the Cookie or
   * 'set-cookie' headers
   */
  String toString();
}

/**
 * A server-side object
 * that contains the content of and information about an HTTP request.
 *
 * __Note__: Check out the
 * [http_server](http://pub.dartlang.org/packages/http_server)
 * package, which makes working with the low-level
 * dart:io HTTP server subsystem easier.
 *
 * `HttpRequest` objects are generated by an [HttpServer],
 * which listens for HTTP requests on a specific host and port.
 * For each request received, the HttpServer, which is a [Stream],
 * generates an `HttpRequest` object and adds it to the stream.
 *
 * An `HttpRequest` object delivers the body content of the request
 * as a stream of byte lists.
 * The object also contains information about the request,
 * such as the method, URI, and headers.
 *
 * In the following code, an HttpServer listens
 * for HTTP requests. When the server receives a request,
 * it uses the HttpRequest object's `method` property to dispatch requests.
 *
 *     final HOST = InternetAddress.LOOPBACK_IP_V4;
 *     final PORT = 80;
 *
 *     HttpServer.bind(HOST, PORT).then((_server) {
 *       _server.listen((HttpRequest request) {
 *         switch (request.method) {
 *           case 'GET':
 *             handleGetRequest(request);
 *             break;
 *           case 'POST':
 *             ...
 *         }
 *       },
 *       onError: handleError);    // listen() failed.
 *     }).catchError(handleError);
 *
 * An HttpRequest object provides access to the associated [HttpResponse]
 * object through the response property.
 * The server writes its response to the body of the HttpResponse object.
 * For example, here's a function that responds to a request:
 *
 *     void handleGetRequest(HttpRequest req) {
 *       HttpResponse res = req.response;
 *       res.write('Received request ${req.method}: ${req.uri.path}');
 *       res.close();
 *     }
 */
abstract class HttpRequest implements Stream<List<int>> {
  /**
   * The content length of the request body.
   *
   * If the size of the request body is not known in advance,
   * this value is -1.
   */
  int get contentLength;

  /**
   * The method, such as 'GET' or 'POST', for the request.
   */
  String get method;

  /**
   * The URI for the request.
   *
   * This provides access to the
   * path and query string for the request.
   */
  Uri get uri;

  /**
   * The requested URI for the request.
   *
   * The returned URI is reconstructed by using http-header fields, to access
   * otherwise lost information, e.g. host and scheme.
   *
   * To reconstruct the scheme, first 'X-Forwarded-Proto' is checked, and then
   * falling back to server type.
   *
   * To reconstruct the host, first 'X-Forwarded-Host' is checked, then 'Host'
   * and finally calling back to server.
   */
  Uri get requestedUri;

  /**
   * The request headers.
   *
   * The returned [HttpHeaders] are immutable.
   */
  HttpHeaders get headers;

  /**
   * The cookies in the request, from the Cookie headers.
   */
  List<Cookie> get cookies;

  /**
   * The persistent connection state signaled by the client.
   */
  bool get persistentConnection;

  /**
   * The client certificate of the client making the request.
   *
   * This value is null if the connection is not a secure TLS or SSL connection,
   * or if the server does not request a client certificate, or if the client
   * does not provide one.
   */
  X509Certificate get certificate;

  /**
   * The session for the given request.
   *
   * If the session is
   * being initialized by this call, [:isNew:] is true for the returned
   * session.
   * See [HttpServer.sessionTimeout] on how to change default timeout.
   */
  HttpSession get session;

  /**
   * The HTTP protocol version used in the request,
   * either "1.0" or "1.1".
   */
  String get protocolVersion;

  /**
   * Information about the client connection.
   *
   * Returns [:null:] if the socket is not available.
   */
  HttpConnectionInfo get connectionInfo;

  /**
   * The [HttpResponse] object, used for sending back the response to the
   * client.
   *
   * If the [contentLength] of the body isn't 0, and the body isn't being read,
   * any write calls on the [HttpResponse] automatically drain the request
   * body.
   */
  HttpResponse get response;
}

/**
 * An HTTP response, which returns the headers and data
 * from the server to the client in response to an HTTP request.
 *
 * Every HttpRequest object provides access to the associated [HttpResponse]
 * object through the `response` property.
 * The server sends its response to the client by writing to the
 * HttpResponse object.
 *
 * ## Writing the response
 *
 * This class implements [IOSink].
 * After the header has been set up, the methods
 * from IOSink, such as `writeln()`, can be used to write
 * the body of the HTTP response.
 * Use the `close()` method to close the response and send it to the client.
 *
 *     server.listen((HttpRequest request) {
 *       request.response.write('Hello, world!');
 *       request.response.close();
 *     });
 *
 * When one of the IOSink methods is used for the
 * first time, the request header is sent. Calling any methods that
 * change the header after it is sent throws an exception.
 *
 * ## Setting the headers
 *
 * The HttpResponse object has a number of properties for setting up
 * the HTTP headers of the response.
 * When writing string data through the IOSink, the encoding used
 * is determined from the "charset" parameter of the
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
 * An exception is thrown if you use the `write()` method
 * while an unsupported content-type is set.
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
   *
   * The status code must be set before the body is written
   * to. Setting the status code after writing to the response body or
   * closing the response will throw a `StateError`.
   */
  int statusCode;

  /**
   * Gets and sets the reason phrase. If no reason phrase is explicitly
   * set a default reason phrase is provided.
   *
   * The reason phrase must be set before the body is written
   * to. Setting the reason phrase after writing to the response body
   * or closing the response will throw a `StateError`.
   */
  String reasonPhrase;

  /**
   * Gets and sets the persistent connection state. The initial value
   * of this property is the persistent connection state from the
   * request.
   */
  bool persistentConnection;

  /**
   * Set and get the [deadline] for the response. The deadline is timed from the
   * time it's set. Setting a new deadline will override any previous deadline.
   * When a deadline is exceeded, the response will be closed and any further
   * data ignored.
   *
   * To disable a deadline, set the [deadline] to `null`.
   *
   * The [deadline] is `null` by default.
   */
  Duration deadline;

  /**
   * Get or set if the [HttpResponse] should buffer output.
   *
   * Default value is `true`.
   *
   * __Note__: Disabling buffering of the output can result in very poor
   * performance, when writing many small chunks.
   */
  bool bufferOutput;

  /**
   * Returns the response headers.
   *
   * The response headers can be modified until the response body is
   * written to or closed. After that they become immutable.
   */
  HttpHeaders get headers;

  /**
   * Cookies to set in the client (in the 'set-cookie' header).
   */
  List<Cookie> get cookies;

  /**
   * Respond with a redirect to [location].
   *
   * The URI in [location] should be absolute, but there are no checks
   * to enforce that.
   *
   * By default the HTTP status code `HttpStatus.MOVED_TEMPORARILY`
   * (`302`) is used for the redirect, but an alternative one can be
   * specified using the [status] argument.
   *
   * This method will also call `close`, and the returned future is
   * the future returned by `close`.
   */
  Future redirect(Uri location, {int status: HttpStatus.MOVED_TEMPORARILY});

  /**
   * Detaches the underlying socket from the HTTP server. When the
   * socket is detached the HTTP server will no longer perform any
   * operations on it.
   *
   * This is normally used when a HTTP upgrade request is received
   * and the communication should continue with a different protocol.
   *
   * If [writeHeaders] is `true`, the status line and [headers] will be written
   * to the socket before it's detached. If `false`, the socket is detached
   * immediately, without any data written to the socket. Default is `true`.
   */
  Future<Socket> detachSocket({bool writeHeaders: true});

  /**
   * Gets information about the client connection. Returns [:null:] if the
   * socket is not available.
   */
  HttpConnectionInfo get connectionInfo;
}

/**
 * A client that receives content, such as web pages, from
 * a server using the HTTP protocol.
 *
 * HttpClient contains a number of methods to send an [HttpClientRequest]
 * to an Http server and receive an [HttpClientResponse] back.
 * For example, you can use the [get], [getUrl], [post], and [postUrl] methods
 * for GET and POST requests, respectively.
 *
 * ## Making a simple GET request: an example
 *
 * A `getUrl` request is a two-step process, triggered by two [Future]s.
 * When the first future completes with a [HttpClientRequest], the underlying
 * network connection has been established, but no data has been sent.
 * In the callback function for the first future, the HTTP headers and body
 * can be set on the request. Either the first write to the request object
 * or a call to [close] sends the request to the server.
 *
 * When the HTTP response is received from the server,
 * the second future, which is returned by close,
 * completes with an [HttpClientResponse] object.
 * This object provides access to the headers and body of the response.
 * The body is available as a stream implemented by HttpClientResponse.
 * If a body is present, it must be read. Otherwise, it leads to resource
 * leaks. Consider using [HttpClientResponse.drain] if the body is unused.
 *
 *     HttpClient client = new HttpClient();
 *     client.getUrl(Uri.parse("http://www.example.com/"))
 *         .then((HttpClientRequest request) {
 *           // Optionally set up headers...
 *           // Optionally write to the request object...
 *           // Then call close.
 *           ...
 *           return request.close();
 *         })
 *         .then((HttpClientResponse response) {
 *           // Process the response.
 *           ...
 *         });
 *
 * The future for [HttpClientRequest] is created by methods such as
 * [getUrl] and [open].
 *
 * ## HTTPS connections
 *
 * An HttpClient can make HTTPS requests, connecting to a server using
 * the TLS (SSL) secure networking protocol. Calling [getUrl] with an
 * https: scheme will work automatically, if the server's certificate is
 * signed by a root CA (certificate authority) on the default list of
 * well-known trusted CAs, compiled by Mozilla.
 *
 * To add a custom trusted certificate authority, or to send a client
 * certificate to servers that request one, pass a [SecurityContext] object
 * as the optional `context` argument to the `HttpClient` constructor.
 * The desired security options can be set on the [SecurityContext] object.
 *
 * ## Headers
 *
 * All HttpClient requests set the following header by default:
 *
 *     Accept-Encoding: gzip
 *
 * This allows the HTTP server to use gzip compression for the body if
 * possible. If this behavior is not desired set the
 * `Accept-Encoding` header to something else.
 * To turn off gzip compression of the response, clear this header:
 *
 *      request.headers.removeAll(HttpHeaders.ACCEPT_ENCODING)
 *
 * ## Closing the HttpClient
 *
 * The HttpClient supports persistent connections and caches network
 * connections to reuse them for multiple requests whenever
 * possible. This means that network connections can be kept open for
 * some time after a request has completed. Use HttpClient.close
 * to force the HttpClient object to shut down and to close the idle
 * network connections.
 *
 * ## Turning proxies on and off
 *
 * By default the HttpClient uses the proxy configuration available
 * from the environment, see [findProxyFromEnvironment]. To turn off
 * the use of proxies set the [findProxy] property to
 * [:null:].
 *
 *     HttpClient client = new HttpClient();
 *     client.findProxy = null;
 */
abstract class HttpClient {
  static const int DEFAULT_HTTP_PORT = 80;
  static const int DEFAULT_HTTPS_PORT = 443;

  /**
   * Get and set the idle timeout of non-active persistent (keep-alive)
   * connections. The default value is 15 seconds.
   */
  Duration idleTimeout;

  /**
   * Get and set the maximum number of live connections, to a single host.
   *
   * Increasing this number may lower performance and take up unwanted
   * system resources.
   *
   * To disable, set to `null`.
   *
   * Default is `null`.
   */
  int maxConnectionsPerHost;

  /**
   * Get and set whether the body of a response will be automatically
   * uncompressed.
   *
   * The body of an HTTP response can be compressed. In most
   * situations providing the un-compressed body is most
   * convenient. Therefore the default behavior is to un-compress the
   * body. However in some situations (e.g. implementing a transparent
   * proxy) keeping the uncompressed stream is required.
   *
   * NOTE: Headers in from the response is never modified. This means
   * that when automatic un-compression is turned on the value of the
   * header `Content-Length` will reflect the length of the original
   * compressed body. Likewise the header `Content-Encoding` will also
   * have the original value indicating compression.
   *
   * NOTE: Automatic un-compression is only performed if the
   * `Content-Encoding` header value is `gzip`.
   *
   * This value affects all responses produced by this client after the
   * value is changed.
   *
   * To disable, set to `false`.
   *
   * Default is `true`.
   */
  bool autoUncompress;

  /**
   * Set and get the default value of the `User-Agent` header for all requests
   * generated by this [HttpClient]. The default value is
   * `Dart/<version> (dart:io)`.
   *
   * If the userAgent is set to `null`, no default `User-Agent` header will be
   * added to each request.
   */
  String userAgent;

  factory HttpClient({SecurityContext context}) => new _HttpClient(context);

  /**
   * Opens a HTTP connection.
   *
   * The HTTP method to use is specified in [method], the server is
   * specified using [host] and [port], and the path (including
   * a possible query) is specified using [path].
   * The path may also contain a URI fragment, which will be ignored.
   *
   * The `Host` header for the request will be set to the value
   * [host]:[port]. This can be overridden through the
   * [HttpClientRequest] interface before the request is sent.  NOTE
   * if [host] is an IP address this will still be set in the `Host`
   * header.
   *
   * For additional information on the sequence of events during an
   * HTTP transaction, and the objects returned by the futures, see
   * the overall documentation for the class [HttpClient].
   */
  Future<HttpClientRequest> open(
      String method, String host, int port, String path);

  /**
   * Opens a HTTP connection.
   *
   * The HTTP method is specified in [method] and the URL to use in
   * [url].
   *
   * The `Host` header for the request will be set to the value
   * [Uri.host]:[Uri.port] from [url]. This can be overridden through the
   * [HttpClientRequest] interface before the request is sent.  NOTE
   * if [Uri.host] is an IP address this will still be set in the `Host`
   * header.
   *
   * For additional information on the sequence of events during an
   * HTTP transaction, and the objects returned by the futures, see
   * the overall documentation for the class [HttpClient].
   */
  Future<HttpClientRequest> openUrl(String method, Uri url);

  /**
   * Opens a HTTP connection using the GET method.
   *
   * The server is specified using [host] and [port], and the path
   * (including a possible query) is specified using
   * [path].
   *
   * See [open] for details.
   */
  Future<HttpClientRequest> get(String host, int port, String path);

  /**
   * Opens a HTTP connection using the GET method.
   *
   * The URL to use is specified in [url].
   *
   * See [openUrl] for details.
   */
  Future<HttpClientRequest> getUrl(Uri url);

  /**
   * Opens a HTTP connection using the POST method.
   *
   * The server is specified using [host] and [port], and the path
   * (including a possible query) is specified using
   * [path].
   *
   * See [open] for details.
   */
  Future<HttpClientRequest> post(String host, int port, String path);

  /**
   * Opens a HTTP connection using the POST method.
   *
   * The URL to use is specified in [url].
   *
   * See [openUrl] for details.
   */
  Future<HttpClientRequest> postUrl(Uri url);

  /**
   * Opens a HTTP connection using the PUT method.
   *
   * The server is specified using [host] and [port], and the path
   * (including a possible query) is specified using [path].
   *
   * See [open] for details.
   */
  Future<HttpClientRequest> put(String host, int port, String path);

  /**
   * Opens a HTTP connection using the PUT method.
   *
   * The URL to use is specified in [url].
   *
   * See [openUrl] for details.
   */
  Future<HttpClientRequest> putUrl(Uri url);

  /**
   * Opens a HTTP connection using the DELETE method.
   *
   * The server is specified using [host] and [port], and the path
   * (including s possible query) is specified using [path].
   *
   * See [open] for details.
   */
  Future<HttpClientRequest> delete(String host, int port, String path);

  /**
   * Opens a HTTP connection using the DELETE method.
   *
   * The URL to use is specified in [url].
   *
   * See [openUrl] for details.
   */
  Future<HttpClientRequest> deleteUrl(Uri url);

  /**
   * Opens a HTTP connection using the PATCH method.
   *
   * The server is specified using [host] and [port], and the path
   * (including a possible query) is specified using [path].
   *
   * See [open] for details.
   */
  Future<HttpClientRequest> patch(String host, int port, String path);

  /**
   * Opens a HTTP connection using the PATCH method.
   *
   * The URL to use is specified in [url].
   *
   * See [openUrl] for details.
   */
  Future<HttpClientRequest> patchUrl(Uri url);

  /**
   * Opens a HTTP connection using the HEAD method.
   *
   * The server is specified using [host] and [port], and the path
   * (including a possible query) is specified using [path].
   *
   * See [open] for details.
   */
  Future<HttpClientRequest> head(String host, int port, String path);

  /**
   * Opens a HTTP connection using the HEAD method.
   *
   * The URL to use is specified in [url].
   *
   * See [openUrl] for details.
   */
  Future<HttpClientRequest> headUrl(Uri url);

  /**
   * Sets the function to be called when a site is requesting
   * authentication. The URL requested and the security realm from the
   * server are passed in the arguments [url] and [realm].
   *
   * The function returns a [Future] which should complete when the
   * authentication has been resolved. If credentials cannot be
   * provided the [Future] should complete with [:false:]. If
   * credentials are available the function should add these using
   * [addCredentials] before completing the [Future] with the value
   * [:true:].
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
   *     "DIRECT"
   *
   * for using a direct connection or
   *
   *     "PROXY host:port"
   *
   * for using the proxy server [:host:] on port [:port:].
   *
   * A configuration can contain several configuration elements
   * separated by semicolons, e.g.
   *
   *     "PROXY host:port; PROXY host2:port2; DIRECT"
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
   * provided the [Future] should complete with [:false:]. If
   * credentials are available the function should add these using
   * [addProxyCredentials] before completing the [Future] with the value
   * [:true:].
   *
   * If the [Future] completes with [:true:] the request will be retried
   * using the updated credentials. Otherwise response processing will
   * continue normally.
   */
  set authenticateProxy(
      Future<bool> f(String host, int port, String scheme, String realm));

  /**
   * Add credentials to be used for authorizing HTTP proxies.
   */
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials);

  /**
   * Sets a callback that will decide whether to accept a secure connection
   * with a server certificate that cannot be authenticated by any of our
   * trusted root certificates.
   *
   * When an secure HTTP request if made, using this HttpClient, and the
   * server returns a server certificate that cannot be authenticated, the
   * callback is called asynchronously with the [X509Certificate] object and
   * the server's hostname and port.  If the value of [badCertificateCallback]
   * is [:null:], the bad certificate is rejected, as if the callback
   * returned [:false:]
   *
   * If the callback returns true, the secure connection is accepted and the
   * [:Future<HttpClientRequest>:] that was returned from the call making the
   * request completes with a valid HttpRequest object. If the callback returns
   * false, the [:Future<HttpClientRequest>:] completes with an exception.
   *
   * If a bad certificate is received on a connection attempt, the library calls
   * the function that was the value of badCertificateCallback at the time
   * the request is made, even if the value of badCertificateCallback
   * has changed since then.
   */
  set badCertificateCallback(
      bool callback(X509Certificate cert, String host, int port));

  /**
   * Shut down the HTTP client. If [force] is `false` (the default)
   * the [HttpClient] will be kept alive until all active
   * connections are done. If [force] is `true` any active
   * connections will be closed to immediately release all
   * resources. These closed connections will receive an error
   * event to indicate that the client was shut down. In both cases
   * trying to establish a new connection after calling [close]
   * will throw an exception.
   */
  void close({bool force: false});
}

/**
 * HTTP request for a client connection.
 *
 * To set up a request, set the headers using the headers property
 * provided in this class and write the data to the body of the request.
 * HttpClientRequest is an [IOSink]. Use the methods from IOSink,
 * such as writeCharCode(), to write the body of the HTTP
 * request. When one of the IOSink methods is used for the first
 * time, the request header is sent. Calling any methods that
 * change the header after it is sent throws an exception.
 *
 * When writing string data through the [IOSink] the
 * encoding used is determined from the "charset" parameter of
 * the "Content-Type" header.
 *
 *     HttpClientRequest request = ...
 *     request.headers.contentType
 *         = new ContentType("application", "json", charset: "utf-8");
 *     request.write(...);  // Strings written will be UTF-8 encoded.
 *
 * If no charset is provided the default of ISO-8859-1 (Latin 1) is
 * be used.
 *
 *     HttpClientRequest request = ...
 *     request.headers.add(HttpHeaders.CONTENT_TYPE, "text/plain");
 *     request.write(...);  // Strings written will be ISO-8859-1 encoded.
 *
 * An exception is thrown if you use an unsupported encoding and the
 * `write()` method being used takes a string parameter.
 */
abstract class HttpClientRequest implements IOSink {
  /**
   * Gets and sets the requested persistent connection state.
   *
   * The default value is [:true:].
   */
  bool persistentConnection;

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
   * [:HttpStatus.SEE_OTHER:] (303) automatic redirect will also happen
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
   * when [followRedirects] is `true`. If this number is exceeded
   * an error event will be added with a [RedirectException].
   *
   * The default value is 5.
   */
  int maxRedirects;

  /**
   * The method of the request.
   */
  String get method;

  /**
   * The uri of the request.
   */
  Uri get uri;

  /**
   * Gets and sets the content length of the request. If the size of
   * the request is not known in advance set content length to -1,
   * which is also the default.
   */
  int contentLength;

  /**
   * Get or set if the [HttpClientRequest] should buffer output.
   *
   * Default value is `true`.
   *
   * __Note__: Disabling buffering of the output can result in very poor
   * performance, when writing many small chunks.
   */
  bool bufferOutput;

  /**
   * Returns the client request headers.
   *
   * The client request headers can be modified until the client
   * request body is written to or closed. After that they become
   * immutable.
   */
  HttpHeaders get headers;

  /**
   * Cookies to present to the server (in the 'cookie' header).
   */
  List<Cookie> get cookies;

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
   * Get information about the client connection. Returns [:null:] if the socket
   * is not available.
   */
  HttpConnectionInfo get connectionInfo;
}

/**
 * HTTP response for a client connection.
 *
 * The body of a [HttpClientResponse] object is a
 * [Stream] of data from the server. Listen to the body to handle
 * the data and be notified when the entire body is received.
 *
 *     new HttpClient().get('localhost', 80, '/file.txt')
 *          .then((HttpClientRequest request) => request.close())
 *          .then((HttpClientResponse response) {
 *            response.transform(UTF8.decoder).listen((contents) {
 *              // handle data
 *            });
 *          });
 */
abstract class HttpClientResponse implements Stream<List<int>> {
  /**
   * Returns the status code.
   *
   * The status code must be set before the body is written
   * to. Setting the status code after writing to the body will throw
   * a `StateError`.
   */
  int get statusCode;

  /**
   * Returns the reason phrase associated with the status code.
   *
   * The reason phrase must be set before the body is written
   * to. Setting the reason phrase after writing to the body will throw
   * a `StateError`.
   */
  String get reasonPhrase;

  /**
   * Returns the content length of the response body. Returns -1 if the size of
   * the response body is not known in advance.
   *
   * If the content length needs to be set, it must be set before the
   * body is written to. Setting the reason phrase after writing to
   * the body will throw a `StateError`.
   */
  int get contentLength;

  /**
   * Gets the persistent connection state returned by the server.
   *
   * if the persistent connection state needs to be set, it must be
   * set before the body is written to. Setting the reason phrase
   * after writing to the body will throw a `StateError`.
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
   * If [followLoops] is set to [:true:], redirect will follow the redirect,
   * even if the URL was already visited. The default value is [:false:].
   *
   * The method will ignore [HttpClientRequest.maxRedirects]
   * and will always perform the redirect.
   */
  Future<HttpClientResponse> redirect(
      [String method, Uri url, bool followLoops]);

  /**
   * Returns the client response headers.
   *
   * The client response headers are immutable.
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
   * Gets information about the client connection. Returns [:null:] if the socket
   * is not available.
   */
  HttpConnectionInfo get connectionInfo;
}

abstract class HttpClientCredentials {}

/**
 * Represents credentials for basic authentication.
 */
abstract class HttpClientBasicCredentials extends HttpClientCredentials {
  factory HttpClientBasicCredentials(String username, String password) =>
      new _HttpClientBasicCredentials(username, password);
}

/**
 * Represents credentials for digest authentication. Digest
 * authentication is only supported for servers using the MD5
 * algorithm and quality of protection (qop) of either "none" or
 * "auth".
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
  InternetAddress get remoteAddress;
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

class HttpException implements IOException {
  final String message;
  final Uri uri;

  const HttpException(this.message, {this.uri});

  String toString() {
    var b = new StringBuffer()..write('HttpException: ')..write(message);
    if (uri != null) {
      b.write(', uri = $uri');
    }
    return b.toString();
  }
}

class RedirectException implements HttpException {
  final String message;
  final List<RedirectInfo> redirects;

  const RedirectException(this.message, this.redirects);

  String toString() => "RedirectException: $message";

  Uri get uri => redirects.last.location;
}
