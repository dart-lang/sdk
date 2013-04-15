// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class _HttpBodyHandlerTransformer
    extends StreamEventTransformer<HttpRequest, HttpRequestBody> {
  void handleData(HttpRequest request, EventSink<HttpRequestBody> sink) {
    HttpBodyHandler.processRequest(request)
        .then(sink.add, onError: sink.addError);
  }
}

class _HttpBodyHandler implements HttpBodyHandler {
  Stream<HttpRequestBody> bind(Stream<HttpRequest> stream) {
    return new _HttpBodyHandlerTransformer().bind(stream);
  }

  static Future<HttpRequestBody> processRequest(HttpRequest request) {
    return process(request, request.headers)
        .then((body) => new _HttpRequestBody(request, body),
              onError: (error) {
                // Try to send BAD_REQUEST response.
                request.response.statusCode = HttpStatus.BAD_REQUEST;
                request.response.close();
                request.response.done.catchError((_) {});
                throw error;
              });
  }

  static Future<HttpClientResponseBody> processResponse(
      HttpClientResponse response) {
    return process(response, response.headers)
        .then((body) => new _HttpClientResponseBody(response, body));
  }

  static Future<HttpBody> process(Stream<List<int>> stream,
                                  HttpHeaders headers) {
    return stream.fold(
        new _BufferList(),
        (buffer, data) {
          // TODO(ajohnsen): Add limit for POST data.
          buffer.add(data);
          return buffer;
        })
        .then((list) {
          dynamic content = list.readBytes();
          String type = "binary";
          ContentType contentType = headers.contentType;
          if (contentType == null) {
            return new _HttpBody(null, type, content);
          }
          String asText(Encoding defaultEncoding) {
            var encoding;
            var charset = contentType.charset;
            if (charset != null) encoding = Encoding.fromName(charset);
            if (encoding == null) encoding = defaultEncoding;
            return _decodeString(content, encoding);
          }
          switch (contentType.primaryType) {
            case "text":
              type = "text";
              content = asText(Encoding.ASCII);
              break;

            case "application":
              switch (contentType.subType) {
                case "json":
                  content = JSON.parse(asText(Encoding.UTF_8));
                  type = "json";
                  break;

                default:
                  break;
              }
              break;

            default:
              break;
          }
          return new _HttpBody(contentType.mimeType, type, content);
        });
  }
}

class _HttpBody implements HttpBody {
  final String mimeType;
  final String type;
  final dynamic body;

  _HttpBody(String this.mimeType,
            String this.type,
            dynamic this.body);
}

class _HttpRequestBody extends _HttpBody implements HttpRequestBody {
  final String method;
  final Uri uri;
  final HttpHeaders headers;
  final HttpResponse response;

  _HttpRequestBody(HttpRequest request, HttpBody body)
      : super(body.mimeType, body.type, body.body),
        method = request.method,
        uri = request.uri,
        headers = request.headers,
        response = request.response;
}

class _HttpClientResponseBody
    extends _HttpBody implements HttpClientResponseBody {
  final int statusCode;
  final String reasonPhrase;
  final HttpHeaders headers;

  _HttpClientResponseBody(HttpClientResponse response, HttpBody body)
      : super(body.mimeType, body.type, body.body),
        statusCode = response.statusCode,
        reasonPhrase = response.reasonPhrase,
        headers = response.headers;
}
