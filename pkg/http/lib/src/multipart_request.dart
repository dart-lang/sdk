// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multipart_request;

import 'dart:io';
import 'dart:math';
import 'dart:uri';
import 'dart:utf';

import 'base_request.dart';
import 'multipart_file.dart';
import 'utils.dart';

/// A `multipart/form-data` request. Such a request has both string [fields],
/// which function as normal form fields, and (potentially streamed) binary
/// [files].
///
/// This request automatically sets the Content-Type header to
/// `multipart/form-data` and the Content-Transfer-Encoding header to `binary`.
/// These values will override any values set by the user.
///
///     var uri = new Uri.fromString("http://pub.dartlang.org/packages/create");
///     var request = new http.MultipartRequest("POST", url);
///     request.fields['user'] = 'nweiz@google.com';
///     request.files.add(new http.MultipartFile.fromFile(
///         'package',
///         new File('build/package.tar.gz'),
///         contentType: new ContentType('application', 'x-tar'));
///     request.send().then((response) {
///       if (response.statusCode == 200) print("Uploaded!");
///     });
class MultipartRequest extends BaseRequest {
  /// The total length of the multipart boundaries used when building the
  /// request body. According to http://tools.ietf.org/html/rfc1341.html, this
  /// can't be longer than 70.
  static final int _BOUNDARY_LENGTH = 70;

  static final Random _random = new Random();

  /// The total length of the request body, in bytes. This is calculated from
  /// [fields] and [files] and cannot be set manually.
  int get contentLength {
    var length = 0;

    fields.forEach((name, value) {
      length += "--".length + _BOUNDARY_LENGTH + "\r\n".length +
          _headerForField(name, value).length +
          encodeUtf8(value).length + "\r\n".length;
    });

    for (var file in files) {
      length += "--".length + _BOUNDARY_LENGTH + "\r\n".length +
          _headerForFile(file).length +
          file.length + "\r\n".length;
    }

    return length + "--".length + _BOUNDARY_LENGTH + "--\r\n".length;
  }

  set contentLength(int value) {
    throw new UnsupportedError("Cannot set the contentLength property of "
        "multipart requests.");
  }

  /// The form fields to send for this request.
  final Map<String, String> fields;

  /// The files to upload for this request.
  final List<MultipartFile> files;

  /// Creates a new [MultipartRequest].
  MultipartRequest(String method, Uri url)
    : super(method, url),
      fields = <String>{},
      files = <MultipartFile>[];

  /// Freezes all mutable fields and returns an [InputStream] that will emit the
  /// request body.
  InputStream finalize() {
    // TODO(nweiz): freeze fields and files
    var boundary = _boundaryString(_BOUNDARY_LENGTH);
    headers['content-type'] = 'multipart/form-data, boundary="$boundary"';
    headers['content-transfer-encoding'] = 'binary';
    super.finalize();

    var stream = new ListInputStream();

    void writeAscii(String string) {
      assert(isPlainAscii(string));
      stream.write(string.charCodes);
    }

    void writeUtf8(String string) => stream.write(encodeUtf8(string));
    void writeLine() => stream.write([13, 10]); // \r\n

    fields.forEach((name, value) {
      writeAscii('--$boundary\r\n');
      writeAscii(_headerForField(name, value));
      writeUtf8(value);
      writeLine();
    });

    forEachFuture(files, (file) {
      writeAscii('--$boundary\r\n');
      writeAscii(_headerForFile(file));
      return writeInputToInput(file.finalize(), stream)
        .transform((_) => writeLine());
    }).then((_) {
      // TODO(nweiz): pass any errors propagated through this future on to
      // the stream. See issue 3657.
      writeAscii('--$boundary--\r\n');
      stream.markEndOfStream();
    });

    return stream;
  }

  /// All character codes that are valid in multipart boundaries. From
  /// http://tools.ietf.org/html/rfc2046#section-5.1.1.
  static final List<int> _BOUNDARY_CHARACTERS = const <int>[
    39, 40, 41, 43, 95, 44, 45, 46, 47, 58, 61, 63, 48, 49, 50, 51, 52, 53, 54,
    55, 56, 57, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
    81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103,
    104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118,
    119, 120, 121, 122
  ];

  /// Returns the header string for a field. The return value is guaranteed to
  /// contain only ASCII characters.
  String _headerForField(String name, String value) {
    // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
    // field names and file names, but in practice user agents seem to just
    // URL-encode them so we do the same.
    var header = 'content-disposition: form-data; name="${encodeUri(name)}"';
    if (!isPlainAscii(value)) {
      header = '$header\r\ncontent-type: text/plain; charset=UTF-8';
    }
    return '$header\r\n\r\n';
  }

  /// Returns the header string for a file. The return value is guaranteed to
  /// contain only ASCII characters.
  String _headerForFile(MultipartFile file) {
    var header = 'content-type: ${file.contentType}\r\n'
      'content-disposition: form-data; name="${encodeUri(file.field)}"';

    if (file.filename != null) {
      header = '$header; filename="${encodeUri(file.filename)}"';
    }
    return '$header\r\n\r\n';
  }

  /// Returns a randomly-generated multipart boundary string of the given
  /// [length].
  String _boundaryString(int length) {
    var prefix = "dart-http-boundary-";
    var list = new List<int>(length - prefix.length);
    for (var i = 0; i < list.length; i++) {
      list[i] = _BOUNDARY_CHARACTERS[
          _random.nextInt(_BOUNDARY_CHARACTERS.length)];
    }
    return "$prefix${new String.fromCharCodes(list)}";
  }
}
