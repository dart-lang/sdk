// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Parser for MIME multipart types of data as described in RFC 2046
 * section 5.1.1. The data to parse is supplied through the [:update:]
 * method. As the data is parsed the following callbacks are called:
 *
 *   [:partStart;
 *   [:headerReceived;
 *   [:headersComplete;
 *   [:partDataReceived;
 *   [:partEnd;
 *   [:error:]
 */

class _MimeMultipartParser {
  const int _START = 0;
  const int _FIRST_BOUNDARY_ENDING = 111;
  const int _FIRST_BOUNDARY_END = 112;
  const int _BOUNDARY_ENDING = 1;
  const int _BOUNDARY_END = 2;
  const int _HEADER_START = 3;
  const int _HEADER_FIELD = 4;
  const int _HEADER_VALUE_START = 5;
  const int _HEADER_VALUE = 6;
  const int _HEADER_VALUE_FOLDING_OR_ENDING = 7;
  const int _HEADER_VALUE_FOLD_OR_END = 8;
  const int _HEADER_ENDING = 9;
  const int _CONTENT = 10;
  const int _LAST_BOUNDARY_DASH2 = 11;
  const int _LAST_BOUNDARY_ENDING = 12;
  const int _LAST_BOUNDARY_END = 13;
  const int _DONE = 14;
  const int _FAILURE = 15;

  // Construct a new MIME multipart parser with the boundary
  // [boundary]. The boundary should be as specified in the content
  // type parameter, that is without the -- prefix.
  _MimeMultipartParser(String boundary) {
    List<int> charCodes = boundary.charCodes;
    _boundary = new List<int>(4 + charCodes.length);
    // Set-up the matching boundary preceding it with CRLF and two
    // dashes.
    _boundary[0] = _CharCode.CR;
    _boundary[1] = _CharCode.LF;
    _boundary[2] = _CharCode.DASH;
    _boundary[3] = _CharCode.DASH;
    _boundary.setRange(4, charCodes.length, charCodes);
    _state = _START;
    _headerField = new StringBuffer();
    _headerValue = new StringBuffer();
  }

  int update(List<int> buffer, int offset, int count) {
    // Current index in the data buffer. If index is negative then it
    // is the index into the artificial prefix of the boundary string.
    int index;
    // Number of boundary bytes to artificially place before the supplied data.
    int boundaryPrefix = 0;
    // Position where content starts. Will be null if no known content
    // start exists. Will be negative of the content starts in the
    // boundary prefix. Will be zero or position if the content starts
    // in the current buffer.
    int contentStartIndex;

    // Function to report content data for the current part. The data
    // reported is from the current content start index up til the
    // current index. As the data can be artificially prefixed with a
    // prefix of the boundary both the content start index and index
    // can be negative.
    void reportData() {
      if (partDataReceived == null) return;

      if (contentStartIndex < 0) {
        var contentLength = boundaryPrefix + index - _boundaryIndex;
        if (contentLength <= boundaryPrefix) {
          partDataReceived(
              _boundary.getRange(0, contentLength));
        } else {
          partDataReceived(
              _boundary.getRange(0, boundaryPrefix));
          partDataReceived(
              buffer.getRange(0, contentLength - boundaryPrefix));
        }
      } else {
        var contentLength = index - contentStartIndex - _boundaryIndex;
        partDataReceived(
            buffer.getRange(contentStartIndex, contentLength));
      }
    }

    // Prepare for processing the buffer.
    index = offset;
    int lastIndex = offset + count;
    if (_state == _CONTENT && _boundaryIndex == 0) {
      contentStartIndex = 0;
    } else {
      contentStartIndex = null;
    }
    // The data to parse might be "artificially" prefixed with a
    // partial match of the boundary.
    boundaryPrefix = _boundaryIndex;

    while ((index < lastIndex) && _state != _FAILURE && _state != _DONE) {
      int byte;
      if (index < 0) {
        byte = _boundary[boundaryPrefix + index];
      } else {
        byte = buffer[index];
      }
      switch (_state) {
        case _START:
          if (_toLowerCase(byte) == _toLowerCase(_boundary[_boundaryIndex])) {
            _boundaryIndex++;
            if (_boundaryIndex == _boundary.length) {
              _state = _FIRST_BOUNDARY_ENDING;
              _boundaryIndex = 0;
            }
          } else {
            // Restart matching of the boundary.
            index = index - _boundaryIndex;
            _boundaryIndex = 0;
          }
          break;

        case _FIRST_BOUNDARY_ENDING:
          if (byte == _CharCode.CR) {
            _state = _FIRST_BOUNDARY_END;
          } else {
            _expectWS(byte);
          }
          break;

        case _FIRST_BOUNDARY_END:
          _expect(byte, _CharCode.LF);
          _state = _HEADER_START;
          break;

        case _BOUNDARY_ENDING:
          if (byte == _CharCode.CR) {
            _state = _BOUNDARY_END;
          } else if (byte == _CharCode.DASH) {
            _state = _LAST_BOUNDARY_DASH2;
          } else {
            _expectWS(byte);
          }
          break;

        case _BOUNDARY_END:
          _expect(byte, _CharCode.LF);
          if (partEnd != null) {
            partEnd(false);
          }
          _state = _HEADER_START;
          break;

        case _HEADER_START:
          if (byte == _CharCode.CR) {
            _state = _HEADER_ENDING;
            } else {
              // Start of new header field.
              _headerField.addCharCode(_toLowerCase(byte));
              _state = _HEADER_FIELD;
            }
            break;

          case _HEADER_FIELD:
            if (byte == _CharCode.COLON) {
              _state = _HEADER_VALUE_START;
            } else {
              if (!_isTokenChar(byte)) {
                throw new MimeParserException("Invalid header field name");
              }
              _headerField.addCharCode(_toLowerCase(byte));
            }
            break;

          case _HEADER_VALUE_START:
            if (byte == _CharCode.CR) {
              _state = _HEADER_VALUE_FOLDING_OR_ENDING;
            } else if (byte != _CharCode.SP && byte != _CharCode.HT) {
              // Start of new header value.
              _headerValue.addCharCode(byte);
              _state = _HEADER_VALUE;
            }
            break;

          case _HEADER_VALUE:
            if (byte == _CharCode.CR) {
              _state = _HEADER_VALUE_FOLDING_OR_ENDING;
            } else {
              _headerValue.addCharCode(byte);
            }
            break;

          case _HEADER_VALUE_FOLDING_OR_ENDING:
            _expect(byte, _CharCode.LF);
            _state = _HEADER_VALUE_FOLD_OR_END;
            break;

          case _HEADER_VALUE_FOLD_OR_END:
            if (byte == _CharCode.SP || byte == _CharCode.HT) {
              _state = _HEADER_VALUE_START;
            } else {
              String headerField = _headerField.toString();
              String headerValue =_headerValue.toString();
              if (headerReceived != null) {
                headerReceived(headerField, headerValue);
              }
              _headerField.clear();
              _headerValue.clear();
              if (byte == _CharCode.CR) {
                _state = _HEADER_ENDING;
              } else {
                // Start of new header field.
                _headerField.addCharCode(_toLowerCase(byte));
                _state = _HEADER_FIELD;
              }
            }
            break;

          case _HEADER_ENDING:
            _expect(byte, _CharCode.LF);
            if (headersComplete != null) headersComplete();
            _state = _CONTENT;
            contentStartIndex = index + 1;
            break;

          case _CONTENT:
            if (_toLowerCase(byte) == _toLowerCase(_boundary[_boundaryIndex])) {
              _boundaryIndex++;
              if (_boundaryIndex == _boundary.length) {
                if (contentStartIndex != null) {
                  index++;
                  reportData();
                  index--;
                }
                _boundaryIndex = 0;
                _state = _BOUNDARY_ENDING;
              }
            } else {
              // Restart matching of the boundary.
              index = index - _boundaryIndex;
              if (contentStartIndex == null) contentStartIndex = index;
              _boundaryIndex = 0;
            }
            break;

        case _LAST_BOUNDARY_DASH2:
          _expect(byte, _CharCode.DASH);
          _state = _LAST_BOUNDARY_ENDING;
          break;

        case _LAST_BOUNDARY_ENDING:
          if (byte == _CharCode.CR) {
            _state = _LAST_BOUNDARY_END;
          } else {
            _expectWS(byte);
          }
          break;

        case _LAST_BOUNDARY_END:
          _expect(byte, _CharCode.LF);
          if (partEnd != null) {
            partEnd(true);
          }
          _state = _DONE;
          break;

        default:
          // Should be unreachable.
          assert(false);
          break;
      }

      // Move to the next byte.
      index++;
    }

    // Report any known content.
    if (_state == _CONTENT && contentStartIndex != null) {
      reportData();
    }
    return index - offset;
  }

  bool _isTokenChar(int byte) {
    return byte > 31 && byte < 128 && _Const.SEPARATORS.indexOf(byte) == -1;
  }

  int _toLowerCase(int byte) {
    final int aCode = "A".charCodeAt(0);
    final int zCode = "Z".charCodeAt(0);
    final int delta = "a".charCodeAt(0) - aCode;
    return (aCode <= byte && byte <= zCode) ? byte + delta : byte;
  }

  void _expect(int val1, int val2) {
    if (val1 != val2) {
      throw new MimeParserException("Failed to parse multipart mime 1");
    }
  }

  void _expectWS(int byte) {
    if (byte != _CharCode.SP && byte != _CharCode.HT) {
      throw new MimeParserException("Failed to parse multipart mime 2");
    }
  }

  List<int> _boundary;
  int _state;
  int _boundaryIndex = 0;

  StringBuffer _headerField;
  StringBuffer _headerValue;

  Function partStart;
  Function headerReceived;
  Function headersComplete;
  Function partDataReceived;
  Function partEnd;
}


class MimeParserException implements Exception {
  const MimeParserException([String this.message = ""]);
  String toString() => "MimeParserException: $message";
  final String message;
}
