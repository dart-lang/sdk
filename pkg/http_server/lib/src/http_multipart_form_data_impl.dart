// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of http_server;


class _HttpMultipartFormData extends Stream implements HttpMultipartFormData {
  final ContentType contentType;
  final HeaderValue contentDisposition;
  final HeaderValue contentTransferEncoding;

  final MimeMultipart _mimeMultipart;

  bool _isText = false;

  Stream _stream;

  _HttpMultipartFormData(ContentType this.contentType,
                         HeaderValue this.contentDisposition,
                         HeaderValue this.contentTransferEncoding,
                         MimeMultipart this._mimeMultipart,
                         Encoding defaultEncoding) {
    _stream = _mimeMultipart;
    if (contentTransferEncoding != null) {
      // TODO(ajohnsen): Support BASE64, etc.
      throw new HttpException("Unsupported contentTransferEncoding: "
                              "${contentTransferEncoding.value}");
    }

    if (contentType == null ||
        contentType.primaryType == 'text' ||
        contentType.mimeType == 'application/json') {
      _isText = true;
      Encoding encoding;
      if (contentType != null && contentType.charset != null) {
        encoding = Encoding.getByName(contentType.charset);
      }
      if (encoding == null) encoding = defaultEncoding;
      _stream = _stream.transform(encoding.decoder);
    }
  }

  bool get isText => _isText;
  bool get isBinary => !_isText;

  static HttpMultipartFormData parse(MimeMultipart multipart,
                                     Encoding defaultEncoding) {
    var type;
    var encoding;
    var disposition;
    var remaining = new Map<String, String>();
    for (String key in multipart.headers.keys) {
      switch (key) {
        case 'content-type':
          type = ContentType.parse(multipart.headers[key]);
          break;

        case 'content-transfer-encoding':
          encoding = HeaderValue.parse(multipart.headers[key]);
          break;

        case 'content-disposition':
          disposition = HeaderValue.parse(multipart.headers[key],
                                          preserveBackslash: true);
          break;

        default:
          remaining[key] = multipart.headers[key];
          break;
      }
    }
    if (disposition == null) {
      throw new HttpException(
          "Mime Multipart doesn't contain a Content-Disposition header value");
    }
    return new _HttpMultipartFormData(
        type, disposition, encoding, multipart, defaultEncoding);
  }

  StreamSubscription listen(void onData(data),
                            {void onDone(),
                             Function onError,
                             bool cancelOnError}) {
    return _stream.listen(onData,
                          onDone: onDone,
                          onError: onError,
                          cancelOnError: cancelOnError);
  }

  String value(String name) {
    return _mimeMultipart.headers[name];
  }
}
