// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * SHA-1.
 * Ripped from package:crypto.
 */
library sha1;

import 'dart:math' show pow;
import 'dart:convert';

/// Returns the base64-encoded SHA-1 hash of the utf-8 bytes of [input].
String hashOfString(String input) {
  Hash hasher = new SHA1();
  hasher.add(const Utf8Encoder().convert(input));
  return _bytesToBase64(hasher.close());
}

/**
 * Converts a list of bytes into a Base 64 encoded string.
 *
 * The list can be any list of integers in the range 0..255,
 * for example a message digest.
 *
 * If [addLineSeparator] is true, the resulting string will  be
 * broken into lines of 76 characters, separated by "\r\n".
 *
 * If [urlSafe] is true, the result is URL and filename safe.
 *
 * Based on [RFC 4648](http://tools.ietf.org/html/rfc4648)
 *
 */
String _bytesToBase64(List<int> bytes,
                            {bool urlSafe : false,
                             bool addLineSeparator : false}) {
  return _CryptoUtils.bytesToBase64(bytes,
                                    urlSafe,
                                    addLineSeparator);
}


// Constants.
const _MASK_8 = 0xff;
const _MASK_32 = 0xffffffff;
const _BITS_PER_BYTE = 8;
const _BYTES_PER_WORD = 4;

// Helper functions used by more than one hasher.

// Rotate left limiting to unsigned 32-bit values.
int _rotl32(int val, int shift) {
var mod_shift = shift & 31;
return ((val << mod_shift) & _MASK_32) |
   ((val & _MASK_32) >> (32 - mod_shift));
}

// Base class encapsulating common behavior for cryptographic hash
// functions.
abstract class _HashBase implements Hash {
  final int _chunkSizeInWords;
  final int _digestSizeInWords;
  final bool _bigEndianWords;
  final List<int> _currentChunk;
  final List<int> _h;
  int _lengthInBytes = 0;
  List<int> _pendingData;
  bool _digestCalled = false;

  _HashBase(int chunkSizeInWords,
            int digestSizeInWords,
            bool this._bigEndianWords)
      : _pendingData = [],
        _currentChunk = new List(chunkSizeInWords),
        _h = new List(digestSizeInWords),
        _chunkSizeInWords = chunkSizeInWords,
        _digestSizeInWords = digestSizeInWords;

  // Update the hasher with more data.
  void add(List<int> data) {
     if (_digestCalled) {
       throw new StateError(
           'Hash update method called after digest was retrieved');
     }
     _lengthInBytes += data.length;
     _pendingData.addAll(data);
     _iterate();
  }

  // Finish the hash computation and return the digest string.
  List<int> close() {
    if (_digestCalled) {
      return _resultAsBytes();
    }
    _digestCalled = true;
    _finalizeData();
    _iterate();
    assert(_pendingData.length == 0);
    return _resultAsBytes();
  }

  // Returns the block size of the hash in bytes.
  int get blockSize {
   return _chunkSizeInWords * _BYTES_PER_WORD;
  }

  // One round of the hash computation.
  void _updateHash(List<int> m);

  // Helper methods.
  int _add32(x, y) => (x + y) & _MASK_32;
  int _roundUp(val, n) => (val + n - 1) & -n;

  // Compute the final result as a list of bytes from the hash words.
  List<int> _resultAsBytes() {
    var result = [];
    for (var i = 0; i < _h.length; i++) {
      result.addAll(_wordToBytes(_h[i]));
    }
    return result;
  }

  // Converts a list of bytes to a chunk of 32-bit words.
  void _bytesToChunk(List<int> data, int dataIndex) {
    assert((data.length - dataIndex) >= (_chunkSizeInWords * _BYTES_PER_WORD));

    for (var wordIndex = 0; wordIndex < _chunkSizeInWords; wordIndex++) {
      var w3 = _bigEndianWords ? data[dataIndex] : data[dataIndex + 3];
      var w2 = _bigEndianWords ? data[dataIndex + 1] : data[dataIndex + 2];
      var w1 = _bigEndianWords ? data[dataIndex + 2] : data[dataIndex + 1];
      var w0 = _bigEndianWords ? data[dataIndex + 3] : data[dataIndex];
      dataIndex += 4;
      var word = (w3 & 0xff) << 24;
      word |= (w2 & _MASK_8) << 16;
      word |= (w1 & _MASK_8) << 8;
      word |= (w0 & _MASK_8);
      _currentChunk[wordIndex] = word;
    }
  }

  // Convert a 32-bit word to four bytes.
  List<int> _wordToBytes(int word) {
    List<int> bytes = new List(_BYTES_PER_WORD);
    bytes[0] = (word >> (_bigEndianWords ? 24 : 0)) & _MASK_8;
    bytes[1] = (word >> (_bigEndianWords ? 16 : 8)) & _MASK_8;
    bytes[2] = (word >> (_bigEndianWords ? 8 : 16)) & _MASK_8;
    bytes[3] = (word >> (_bigEndianWords ? 0 : 24)) & _MASK_8;
    return bytes;
  }

  // Iterate through data updating the hash computation for each
  // chunk.
  void _iterate() {
    var len = _pendingData.length;
    var chunkSizeInBytes = _chunkSizeInWords * _BYTES_PER_WORD;
    if (len >= chunkSizeInBytes) {
      var index = 0;
      for (; (len - index) >= chunkSizeInBytes; index += chunkSizeInBytes) {
        _bytesToChunk(_pendingData, index);
        _updateHash(_currentChunk);
      }
      _pendingData = _pendingData.sublist(index, len);
    }
  }

  // Finalize the data. Add a 1 bit to the end of the message. Expand with
  // 0 bits and add the length of the message.
  void _finalizeData() {
    _pendingData.add(0x80);
    var contentsLength = _lengthInBytes + 9;
    var chunkSizeInBytes = _chunkSizeInWords * _BYTES_PER_WORD;
    var finalizedLength = _roundUp(contentsLength, chunkSizeInBytes);
    var zeroPadding = finalizedLength - contentsLength;
    for (var i = 0; i < zeroPadding; i++) {
      _pendingData.add(0);
    }
    var lengthInBits = _lengthInBytes * _BITS_PER_BYTE;
    assert(lengthInBits < pow(2, 32));
    if (_bigEndianWords) {
      _pendingData.addAll(_wordToBytes(0));
      _pendingData.addAll(_wordToBytes(lengthInBits & _MASK_32));
    } else {
      _pendingData.addAll(_wordToBytes(lengthInBits & _MASK_32));
      _pendingData.addAll(_wordToBytes(0));
    }
  }
}


/**
 * Interface for cryptographic hash functions.
 *
 * The [add] method is used to add data to the hash. The [close] method
 * is used to extract the message digest.
 *
 * Once the [close] method has been called no more data can be added using the
 * [add] method. If [add] is called after the first call to [close] a
 * HashException is thrown.
 *
 * If multiple instances of a given Hash is needed the [newInstance]
 * method can provide a new instance.
 */
// TODO(floitsch): make Hash implement Sink, EventSink or similar.
abstract class Hash {
  /**
   * Add a list of bytes to the hash computation.
   */
  void add(List<int> data);

  /**
   * Finish the hash computation and extract the message digest as
   * a list of bytes.
   */
  List<int> close();

  /**
   * Internal block size of the hash in bytes.
   *
   * This is exposed for use by the HMAC class which needs to know the
   * block size for the [Hash] it is using.
   */
  int get blockSize;
}

/**
 * SHA1 hash function implementation.
 */
class SHA1 extends _HashBase {
  final List<int> _w;

  // Construct a SHA1 hasher object.
  SHA1() : _w = new List(80), super(16, 5, true) {
    _h[0] = 0x67452301;
    _h[1] = 0xEFCDAB89;
    _h[2] = 0x98BADCFE;
    _h[3] = 0x10325476;
    _h[4] = 0xC3D2E1F0;
  }

  // Compute one iteration of the SHA1 algorithm with a chunk of
  // 16 32-bit pieces.
  void _updateHash(List<int> m) {
    assert(m.length == 16);

    var a = _h[0];
    var b = _h[1];
    var c = _h[2];
    var d = _h[3];
    var e = _h[4];

    for (var i = 0; i < 80; i++) {
      if (i < 16) {
        _w[i] = m[i];
      } else {
        var n = _w[i - 3] ^ _w[i - 8] ^ _w[i - 14] ^ _w[i - 16];
        _w[i] = _rotl32(n, 1);
      }
      var t = _add32(_add32(_rotl32(a, 5), e), _w[i]);
      if (i < 20) {
        t = _add32(_add32(t, (b & c) | (~b & d)), 0x5A827999);
      } else if (i < 40) {
        t = _add32(_add32(t, (b ^ c ^ d)), 0x6ED9EBA1);
      } else if (i < 60) {
        t = _add32(_add32(t, (b & c) | (b & d) | (c & d)), 0x8F1BBCDC);
      } else {
        t = _add32(_add32(t, b ^ c ^ d), 0xCA62C1D6);
      }

      e = d;
      d = c;
      c = _rotl32(b, 30);
      b = a;
      a = t & _MASK_32;
    }

    _h[0] = _add32(a, _h[0]);
    _h[1] = _add32(b, _h[1]);
    _h[2] = _add32(c, _h[2]);
    _h[3] = _add32(d, _h[3]);
    _h[4] = _add32(e, _h[4]);
  }
}

abstract class _CryptoUtils {

  static const int PAD = 61; // '='
  static const int CR = 13;  // '\r'
  static const int LF = 10;  // '\n'
  static const int LINE_LENGTH = 76;

  static const String _encodeTable =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  static const String _encodeTableUrlSafe =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

  // Lookup table used for finding Base 64 alphabet index of a given byte.
  // -2 : Outside Base 64 alphabet.
  // -1 : '\r' or '\n'
  //  0 : = (Padding character).
  // >0 : Base 64 alphabet index of given byte.
  static const List<int> _decodeTable =
      const [ -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -2, -2, -1, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, 62, -2, 63,
              52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2,  0, -2, -2,
              -2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
              15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, 63,
              -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
              41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2 ];

  static String bytesToBase64(List<int> bytes,
                              [bool urlSafe = false,
                               bool addLineSeparator = false]) {
    int len = bytes.length;
    if (len == 0) {
      return "";
    }
    final String lookup = urlSafe ? _encodeTableUrlSafe : _encodeTable;
    // Size of 24 bit chunks.
    final int remainderLength = len.remainder(3);
    final int chunkLength = len - remainderLength;
    // Size of base output.
    int outputLen = ((len ~/ 3) * 4) + ((remainderLength > 0) ? 4 : 0);
    // Add extra for line separators.
    if (addLineSeparator) {
      outputLen += ((outputLen - 1) ~/ LINE_LENGTH) << 1;
    }
    List<int> out = new List<int>(outputLen);

    // Encode 24 bit chunks.
    int j = 0, i = 0, c = 0;
    while (i < chunkLength) {
      int x = ((bytes[i++] << 16) & 0xFFFFFF) |
              ((bytes[i++] << 8) & 0xFFFFFF) |
                bytes[i++];
      out[j++] = lookup.codeUnitAt(x >> 18);
      out[j++] = lookup.codeUnitAt((x >> 12) & 0x3F);
      out[j++] = lookup.codeUnitAt((x >> 6)  & 0x3F);
      out[j++] = lookup.codeUnitAt(x & 0x3f);
      // Add optional line separator for each 76 char output.
      if (addLineSeparator && ++c == 19 && j < outputLen - 2) {
        out[j++] = CR;
        out[j++] = LF;
        c = 0;
      }
    }

    // If input length if not a multiple of 3, encode remaining bytes and
    // add padding.
    if (remainderLength == 1) {
      int x = bytes[i];
      out[j++] = lookup.codeUnitAt(x >> 2);
      out[j++] = lookup.codeUnitAt((x << 4) & 0x3F);
      out[j++] = PAD;
      out[j++] = PAD;
    } else if (remainderLength == 2) {
      int x = bytes[i];
      int y = bytes[i + 1];
      out[j++] = lookup.codeUnitAt(x >> 2);
      out[j++] = lookup.codeUnitAt(((x << 4) | (y >> 4)) & 0x3F);
      out[j++] = lookup.codeUnitAt((y << 2) & 0x3F);
      out[j++] = PAD;
    }

    return new String.fromCharCodes(out);
  }
}
