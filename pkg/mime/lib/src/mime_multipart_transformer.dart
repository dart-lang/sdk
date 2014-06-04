// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library mime.multipart_transformer;

import 'dart:async';
import 'dart:typed_data';

import 'bound_multipart_stream.dart';
import 'mime_shared.dart';
import 'char_code.dart';


Uint8List _getBoundary(String boundary) {
  var charCodes = boundary.codeUnits;

  var boundaryList = new Uint8List(4 + charCodes.length);
  // Set-up the matching boundary preceding it with CRLF and two
  // dashes.
  boundaryList[0] = CharCode.CR;
  boundaryList[1] = CharCode.LF;
  boundaryList[2] = CharCode.DASH;
  boundaryList[3] = CharCode.DASH;
  boundaryList.setRange(4, 4 + charCodes.length, charCodes);
  return boundaryList;
}

/**
 * Parser for MIME multipart types of data as described in RFC 2046
 * section 5.1.1. The data is transformed into [MimeMultipart] objects, each
 * of them streaming the multipart data.
 */
class MimeMultipartTransformer
    implements StreamTransformer<List<int>, MimeMultipart> {

  final List<int> _boundary;

  /**
   * Construct a new MIME multipart parser with the boundary
   * [boundary]. The boundary should be as specified in the content
   * type parameter, that is without the -- prefix.
   */
  MimeMultipartTransformer(String boundary)
      : _boundary = _getBoundary(boundary);

  Stream<MimeMultipart> bind(Stream<List<int>> stream) {
    return new BoundMultipartStream(_boundary, stream).stream;
  }
}
