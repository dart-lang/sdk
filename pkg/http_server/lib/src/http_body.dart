// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_server.http_body;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'http_body_impl.dart';

/**
 * [HttpBodyHandler] is a helper class for processing and collecting
 * HTTP message data in an easy-to-use [HttpBody] object. The content
 * body is parsed, depending on the `Content-Type` header field. When
 * the full body is read and parsed the body content is made
 * available. The class can be used to process both server requests
 * and client responses.
 *
 * The following content types are recognized:
 *
 *     text/ *
 *     application/json
 *     application/x-www-form-urlencoded
 *     multipart/form-data
 *
 *  For content type `text/\*` the body is decoded into a string. The
 *  'charset' parameter of the content type specifies the encoding
 *  used for decoding. If no 'charset' is present the default encoding
 *  of ISO-8859-1 is used.
 *
 *  For content type `application/json` the body is decoded into a
 *  string which is then parsed as JSON. The resulting body is a
 *  [Map].  The 'charset' parameter of the content type specifies the
 *  encoding used for decoding. If no 'charset' is present the default
 *  encoding of UTF-8 is used.
 *
 *  For content type `application/x-www-form-urlencoded` the body is a
 *  query string which is then split according to the rules for
 *  splitting a query string. The resulting body is a `Map<String,
 *  String>`.  If the same name is present several times in the query
 *  string, then the last value seen for this name will be in the
 *  resulting map. The encoding US-ASCII is always used for decoding
 *  the body.
 *
 *  For content type `multipart/form-data` the body is parsed into
 *  it's different fields. The resulting body is a `Map<String,
 *  dynamic>`, where the value is a [String] for normal fields and a
 *  [HttpBodyFileUpload] instance for file upload fields. If the same
 *  name is present several times, then the last value seen for this
 *  name will be in the resulting map.
 *
 *  When using content type `multipart/form-data` the encoding of
 *  fields with [String] values is determined by the browser sending
 *  the HTTP request with the form data. The encoding is specified
 *  either by the attribute `accept-charset` on the HTML form, or by
 *  the content type of the web page containing the form. If the HTML
 *  form has an `accept-charset` attribute the browser will use the
 *  encoding specified there. If the HTML form has no `accept-charset`
 *  attribute the browser determines the encoding from the content
 *  type of the web page containing the form. Using a content type of
 *  `text/html; charset=utf-8` for the page and setting
 *  `accept-charset` on the HTML form to `utf-8` is recommended as the
 *  default for [HttpBodyHandler] is UTF-8. It is important to get
 *  these encoding values right, as the actual `multipart/form-data`
 *  HTTP request sent by the browser does _not_ contain any
 *  information on the encoding. If something else than UTF-8 is used
 *  `defaultEncoding` needs to be set in the [HttpBodyHandler]
 *  constructor and calls to [processRequest] and [processResponse].
 *
 *  For all other content types the body will be treated as
 *  uninterpreted binary data. The resulting body will be of type
 *  `List<int>`.
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
 */
class HttpBodyHandler
    implements StreamTransformer<HttpRequest, HttpRequestBody> {
  var _transformer;

  /**
   * Create a new [HttpBodyHandler] to be used with a [Stream]<[HttpRequest]>,
   * e.g. a [HttpServer].
   *
   * If the page is served using different encoding than UTF-8, set
   * [defaultEncoding] accordingly. This is required for parsing
   * `multipart/form-data` content correctly. See the class comment
   * for more information on `multipart/form-data`.
   */
  HttpBodyHandler({Encoding defaultEncoding: UTF8})
      : _transformer = new HttpBodyHandlerTransformer(defaultEncoding);

  /**
   * Process and parse an incoming [HttpRequest]. The returned [HttpRequestBody]
   * contains a [response] field for accessing the [HttpResponse].
   *
   * See [HttpBodyHandler] constructor for more info on [defaultEncoding].
   */
  static Future<HttpRequestBody> processRequest(
      HttpRequest request,
      {Encoding defaultEncoding: UTF8}) {
    return HttpBodyHandlerImpl.processRequest(request, defaultEncoding);
  }

  /**
   * Process and parse an incoming [HttpClientResponse].
   *
   * See [HttpBodyHandler] constructor for more info on [defaultEncoding].
   */
  static Future<HttpClientResponseBody> processResponse(
      HttpClientResponse response,
      {Encoding defaultEncoding: UTF8}) {
    return HttpBodyHandlerImpl.processResponse(response, defaultEncoding);
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
   * The [HttpClientResponse] from which the [HttpClientResponseBody] was
   * created.
   */
  HttpClientResponse get response;
}


/**
 * The [HttpBody] of a [HttpRequest] will be of type [HttpRequestBody]. It
 * provides access to the request, for reading all request header information
 * and responding to the client.
 */
abstract class HttpRequestBody extends HttpBody {
  /**
   * The [HttpRequest] from which the [HttpRequestBody] was created.
   *
   * Note that the [HttpRequest] is already drained at this point, so the
   * `Stream` methods cannot be used.
   */
  HttpRequest get request;
}


/**
 * A [HttpBodyFileUpload] object wraps a file upload, presenting a way for
 * extracting filename, contentType and the data of the uploaded file.
 */
abstract class HttpBodyFileUpload {
  /**
   * The filename of the uploaded file.
   */
  String get filename;

  /**
   * The [ContentType] of the uploaded file. For 'text/\*' and
   * 'application/json' the [data] field will a String.
   */
  ContentType get contentType;

  /**
   * The content of the file. Either a [String] or a [List<int>].
   */
  dynamic get content;
}
