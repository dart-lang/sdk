// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library mime.bound_multipart_stream;

import 'dart:async';
import 'dart:convert';

import 'mime_shared.dart';
import 'char_code.dart';

// Bytes for '()<>@,;:\\"/[]?={} \t'.
const _SEPARATORS = const [40, 41, 60, 62, 64, 44, 59, 58, 92, 34, 47, 91, 93,
                           63, 61, 123, 125, 32, 9];

bool _isTokenChar(int byte) {
  return byte > 31 && byte < 128 && _SEPARATORS.indexOf(byte) == -1;
}

int _toLowerCase(int byte) {
  const delta = CharCode.LOWER_A - CharCode.UPPER_A;
  return (CharCode.UPPER_A <= byte && byte <= CharCode.UPPER_Z) ?
      byte + delta : byte;
}

void _expectByteValue(int val1, int val2) {
  if (val1 != val2) {
    throw new MimeMultipartException("Failed to parse multipart mime 1");
  }
}

void _expectWhitespace(int byte) {
  if (byte != CharCode.SP && byte != CharCode.HT) {
    throw new MimeMultipartException("Failed to parse multipart mime 2");
  }
}

class _MimeMultipart extends MimeMultipart {
  final Map<String, String> headers;
  final Stream<List<int>> _stream;

  _MimeMultipart(this.headers, this._stream);

  StreamSubscription<List<int>> listen(void onData(List<int> data),
                                       {void onDone(),
                                        Function onError,
                                        bool cancelOnError}) {
    return _stream.listen(onData,
                          onDone: onDone,
                          onError: onError,
                          cancelOnError: cancelOnError);
  }
}

class BoundMultipartStream {
   static const int _START = 0;
   static const int _FIRST_BOUNDARY_ENDING = 111;
   static const int _FIRST_BOUNDARY_END = 112;
   static const int _BOUNDARY_ENDING = 1;
   static const int _BOUNDARY_END = 2;
   static const int _HEADER_START = 3;
   static const int _HEADER_FIELD = 4;
   static const int _HEADER_VALUE_START = 5;
   static const int _HEADER_VALUE = 6;
   static const int _HEADER_VALUE_FOLDING_OR_ENDING = 7;
   static const int _HEADER_VALUE_FOLD_OR_END = 8;
   static const int _HEADER_ENDING = 9;
   static const int _CONTENT = 10;
   static const int _LAST_BOUNDARY_DASH2 = 11;
   static const int _LAST_BOUNDARY_ENDING = 12;
   static const int _LAST_BOUNDARY_END = 13;
   static const int _DONE = 14;
   static const int _FAIL = 15;

   final List<int> _boundary;
   final List<int> _headerField = [];
   final List<int> _headerValue = [];

   StreamController _controller;

   Stream<MimeMultipart> get stream => _controller.stream;

   StreamSubscription _subscription;

   StreamController _multipartController;
   Map<String, String> _headers;

   int _state = _START;
   int _boundaryIndex = 2;

   // Current index in the data buffer. If index is negative then it
   // is the index into the artificial prefix of the boundary string.
   int _index;
   List<int> _buffer;

   BoundMultipartStream(this._boundary, Stream<List<int>> stream) {
     _controller = new StreamController(
         sync: true,
         onPause: _pauseStream,
         onResume:_resumeStream,
         onCancel: () {
           _subscription.cancel();
         },
         onListen: () {
           _subscription = stream.listen(
               (data) {
                 assert(_buffer == null);
                 _pauseStream();
                 _buffer = data;
                 _index = 0;
                 _parse();
               },
               onDone: () {
                 if (_state != _DONE) {
                   _controller.addError(
                       new MimeMultipartException("Bad multipart ending"));
                 }
                 _controller.close();
               },
               onError: _controller.addError);
         });
   }

   void _resumeStream() {
     _subscription.resume();
   }

   void _pauseStream() {
     _subscription.pause();
   }


   void _parse() {
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
       if (contentStartIndex < 0) {
         var contentLength = boundaryPrefix + _index - _boundaryIndex;
         if (contentLength <= boundaryPrefix) {
           _multipartController.add(
               _boundary.sublist(0, contentLength));
         } else {
           _multipartController.add(
               _boundary.sublist(0, boundaryPrefix));
           _multipartController.add(
               _buffer.sublist(0, contentLength - boundaryPrefix));
         }
       } else {
         var contentEndIndex = _index - _boundaryIndex;
         _multipartController.add(
             _buffer.sublist(contentStartIndex, contentEndIndex));
       }
     }

     if (_state == _CONTENT && _boundaryIndex == 0) {
       contentStartIndex = 0;
     } else {
       contentStartIndex = null;
     }
     // The data to parse might be "artificially" prefixed with a
     // partial match of the boundary.
     boundaryPrefix = _boundaryIndex;

     while ((_index < _buffer.length) && _state != _FAIL && _state != _DONE) {
       if (_multipartController != null && _multipartController.isPaused) {
         return;
       }
       int byte;
       if (_index < 0) {
         byte = _boundary[boundaryPrefix + _index];
       } else {
         byte = _buffer[_index];
       }
       switch (_state) {
         case _START:
           if (byte == _boundary[_boundaryIndex]) {
             _boundaryIndex++;
             if (_boundaryIndex == _boundary.length) {
               _state = _FIRST_BOUNDARY_ENDING;
               _boundaryIndex = 0;
             }
           } else {
             // Restart matching of the boundary.
             _index = _index - _boundaryIndex;
             _boundaryIndex = 0;
           }
           break;

         case _FIRST_BOUNDARY_ENDING:
           if (byte == CharCode.CR) {
             _state = _FIRST_BOUNDARY_END;
           } else {
             _expectWhitespace(byte);
           }
           break;

         case _FIRST_BOUNDARY_END:
           _expectByteValue(byte, CharCode.LF);
           _state = _HEADER_START;
           break;

         case _BOUNDARY_ENDING:
           if (byte == CharCode.CR) {
             _state = _BOUNDARY_END;
           } else if (byte == CharCode.DASH) {
             _state = _LAST_BOUNDARY_DASH2;
           } else {
             _expectWhitespace(byte);
           }
           break;

         case _BOUNDARY_END:
           _expectByteValue(byte, CharCode.LF);
           _multipartController.close();
           _multipartController = null;
           _state = _HEADER_START;
           break;

         case _HEADER_START:
           _headers = new Map<String, String>();
           if (byte == CharCode.CR) {
             _state = _HEADER_ENDING;
           } else {
             // Start of new header field.
             _headerField.add(_toLowerCase(byte));
             _state = _HEADER_FIELD;
           }
           break;

         case _HEADER_FIELD:
           if (byte == CharCode.COLON) {
             _state = _HEADER_VALUE_START;
           } else {
             if (!_isTokenChar(byte)) {
               throw new MimeMultipartException("Invalid header field name");
             }
             _headerField.add(_toLowerCase(byte));
           }
           break;

         case _HEADER_VALUE_START:
           if (byte == CharCode.CR) {
             _state = _HEADER_VALUE_FOLDING_OR_ENDING;
           } else if (byte != CharCode.SP && byte != CharCode.HT) {
             // Start of new header value.
             _headerValue.add(byte);
             _state = _HEADER_VALUE;
           }
           break;

         case _HEADER_VALUE:
           if (byte == CharCode.CR) {
             _state = _HEADER_VALUE_FOLDING_OR_ENDING;
           } else {
             _headerValue.add(byte);
           }
           break;

         case _HEADER_VALUE_FOLDING_OR_ENDING:
           _expectByteValue(byte, CharCode.LF);
           _state = _HEADER_VALUE_FOLD_OR_END;
           break;

         case _HEADER_VALUE_FOLD_OR_END:
           if (byte == CharCode.SP || byte == CharCode.HT) {
             _state = _HEADER_VALUE_START;
           } else {
             String headerField = UTF8.decode(_headerField);
             String headerValue = UTF8.decode(_headerValue);
             _headers[headerField.toLowerCase()] = headerValue;
             _headerField.clear();
             _headerValue.clear();
             if (byte == CharCode.CR) {
               _state = _HEADER_ENDING;
             } else {
               // Start of new header field.
               _headerField.add(_toLowerCase(byte));
               _state = _HEADER_FIELD;
             }
           }
           break;

         case _HEADER_ENDING:
           _expectByteValue(byte, CharCode.LF);
           _multipartController = new StreamController(
               sync: true,
               onPause: () {
                 _pauseStream();
               },
               onResume: () {
                 _resumeStream();
                 _parse();
               });
           _controller.add(
               new _MimeMultipart(_headers, _multipartController.stream));
           _headers = null;
           _state = _CONTENT;
           contentStartIndex = _index + 1;
           break;

         case _CONTENT:
           if (byte == _boundary[_boundaryIndex]) {
             _boundaryIndex++;
             if (_boundaryIndex == _boundary.length) {
               if (contentStartIndex != null) {
                 _index++;
                 reportData();
                 _index--;
               }
               _multipartController.close();
               _boundaryIndex = 0;
               _state = _BOUNDARY_ENDING;
             }
           } else {
             // Restart matching of the boundary.
             _index = _index - _boundaryIndex;
             if (contentStartIndex == null) contentStartIndex = _index;
             _boundaryIndex = 0;
           }
           break;

         case _LAST_BOUNDARY_DASH2:
           _expectByteValue(byte, CharCode.DASH);
           _state = _LAST_BOUNDARY_ENDING;
           break;

         case _LAST_BOUNDARY_ENDING:
           if (byte == CharCode.CR) {
             _state = _LAST_BOUNDARY_END;
           } else {
             _expectWhitespace(byte);
           }
           break;

         case _LAST_BOUNDARY_END:
           _expectByteValue(byte, CharCode.LF);
           _multipartController.close();
           _multipartController = null;
           _state = _DONE;
           break;

         default:
           // Should be unreachable.
           assert(false);
           break;
       }

       // Move to the next byte.
       _index++;
     }

     // Report any known content.
     if (_state == _CONTENT && contentStartIndex != null) {
       reportData();
     }

     // Resume if at end.
     if (_index == _buffer.length) {
       _buffer = null;
       _index = null;
       _resumeStream();
     }
   }
}
