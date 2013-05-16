// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;


/**
 * [HttpBodyHandler] is a helper class for parsing and collecting HTTP message
 * data in an easy-to-use [HttpBody] object. The content body is parsed,
 * depending on the 'Content-Type' header field.
 *
 * To use with the [HttpServer] for request messages, [HttpBodyHandler] can be
 * used as either a [StreamTransformer] or as a per-request handler (see
 * [processRequest]).
 *
 *     HttpServer server = ...
 *     server.transform(new HttpBodyHandler())
 *         .listen((HttpRequestBody body) {
 *           ...
 *         });
 *
 * To use with the [HttpClient] for response messages, [HttpBodyHandler] can be
 * used as a per-request handler (see [processResponse]).
 *
 *     HttpClient client = ...
 *     client.get(...)
 *         .then((HttpClientRequest response) => response.close())
 *         .then(HttpBodyHandler.processResponse)
 *         .then((HttpClientResponseBody body) {
 *           ...
 *         });
 *
 * The following mime-types will be handled specially:
 *   - text/\*
 *   - application/json
 *
 * All other mime-types will be returned as [List<int>].
 */
class HttpBodyHandler
    implements StreamTransformer<HttpRequest, HttpRequestBody> {
  var _transformer;

  /**
   * Create a new [HttpBodyHandler] to be used with a [Stream]<[HttpRequest]>,
   * e.g. a [HttpServer].
   *
   * If the page was served using different encoding than UTF-8, set
   * [defaultEncoding] accordingly. This is required for parsing
   * 'application/x-www-form-urlencoded' content correctly.
   */
  HttpBodyHandler({Encoding defaultEncoding: Encoding.UTF_8})
      : _transformer = new _HttpBodyHandlerTransformer(defaultEncoding);

  /**
   * Process and parse an incoming [HttpRequest]. The returned [HttpRequestBody]
   * contains a [response] field for accessing the [HttpResponse].
   *
   * See [HttpBodyHandler] constructor for more info on [defaultEncoding].
   */
  static Future<HttpRequestBody> processRequest(
      HttpRequest request,
      {Encoding defaultEncoding: Encoding.UTF_8}) {
    return _HttpBodyHandler.processRequest(request, defaultEncoding);
  }

  /**
   * Process and parse an incoming [HttpClientResponse].
   *
   * See [HttpBodyHandler] constructor for more info on [defaultEncoding].
   */
  static Future<HttpClientResponseBody> processResponse(
      HttpClientResponse response,
      {Encoding defaultEncoding: Encoding.UTF_8}) {
    return _HttpBodyHandler.processResponse(response, defaultEncoding);
  }

  Stream<HttpRequestBody> bind(Stream<HttpRequest> stream) {
    return _transformer.bind(stream);
  }
}


/**
 * A HTTP content body produced by [HttpBodyHandler] for either [HttpRequest]
 * or [HttpClientResponse].
 */
abstract class HttpBody {
  /**
   * The content type e.g. application/json, application/octet-stream,
   * application/x-www-form-urlencoded, text/plain.
   */
  ContentType get contentType;

  /**
   * A high-level type value, that reflects how the body was parsed, e.g.
   * "text", "binary" and "json".
   */
  String get type;

  /**
   * The actual body. The type depends on [type].
   */
  dynamic get body;
}


/**
 * The [HttpBody] of a [HttpClientResponse] will be of type
 * [HttpClientResponseBody]. It contains the [HttpClientResponse] object
 * for access to the headers.
 */
abstract class HttpClientResponseBody extends HttpBody {
  /**
   * Returns the status code.
   */
  int get statusCode;

  /**
   * Returns the reason phrase associated with the status code.
   */
  String get reasonPhrase;

  /**
   * Returns the response headers.
   */
  HttpHeaders get headers;

  /**
   * The [HttpClientResponse] of the HTTP body.
   */
  HttpClientResponse get response;
}


/**
 * The [HttpBody] of a [HttpRequest] will be of type [HttpRequestBody]. It
 * contains the fields used to read all request header information and
 * responding to the client.
 */
abstract class HttpRequestBody extends HttpBody {
  /**
   * Returns the method for the request.
   */
  String get method;

  /**
   * Returns the URI for the request.
   */
  Uri get uri;

  /**
   * Returns the request headers.
   */
  HttpHeaders get headers;

  /**
   * The [HttpResponse] used for responding to the client.
   */
  HttpResponse get response;
}


/**
 * A [HttpBodyFileUpload] object wraps a file upload, presenting a way for
 * extracting filename, contentType and the data of the uploaded file.
 */
abstract class HttpBodyFileUpload {
  /**
   * The filename of the uploaded file.
   */
  String filename;

  /**
   * The [ContentType] of the uploaded file. For 'text/\*' and
   * 'application/json' the [data] field will a String.
   */
  ContentType contentType;

  /**
   * The content of the file. Either a [String] or a [List<int>].
   */
  dynamic content;
}
