// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.uri;

/**
 * Javascript-like URI encode/decode functions.
 * The documentation here borrows heavily from the original Javascript
 * doumentation on MDN at:
 * https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects
 */

/**
 * A JavaScript-like URI encoder. Encodes Uniform Resource Identifier [uri]
 * by replacing each instance of certain characters by one, two, three, or four
 * escape sequences representing the UTF-8 encoding of the character (will
 * only be four escape sequences for characters composed of two "surrogate"
 * characters). This assumes that [uri] is a complete URI, so does not encode
 * reserved characters that have special meaning in the URI: [:#;,/?:@&=+\$:]
 * It returns the escaped URI.
 */
String encodeUri(String uri) {
  // Bit vector of 128 bits where each bit indicate whether a
  // character code on the 0-127 needs to be escaped or not.
  const canonicalTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               ! #$ &'()*+,-./
      0xf7da,   // 0x20 - 0x2f  0101101111101111
                //              0123456789:; = ?
      0xafff,   // 0x30 - 0x3f  1111111111110101
                //              @ABCDEFGHIJKLMNO
      0xffff,   // 0x40 - 0x4f  1111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010
  return _uriEncode(canonicalTable, uri);
}

/**
 * An implementation of JavaScript's decodeURIComponent function.
 * Decodes a Uniform Resource Identifier [uri] previously created by
 * encodeURI or by a similar routine. It replaces each escape sequence
 * in [uri] with the character that it represents. It does not decode
 * escape sequences that could not have been introduced by encodeURI.
 * It returns the unescaped URI.
 */
String decodeUri(String uri) {
  return _uriDecode(uri);
}

/**
 * A javaScript-like URI component encoder, this encodes a URI
 * [component] by replacing each instance of certain characters by one,
 * two, three, or four escape sequences representing the UTF-8 encoding of
 * the character (will only be four escape sequences for characters composed
 * of two "surrogate" characters).
 * To avoid unexpected requests to the server, you should call
 * encodeURIComponent on any user-entered parameters that will be passed as
 * part of a URI. For example, a user could type "Thyme &time=again" for a
 * variable comment. Not using encodeURIComponent on this variable will give
 * comment=Thyme%20&time=again. Note that the ampersand and the equal sign
 * mark a new key and value pair. So instead of having a POST comment key
 * equal to "Thyme &time=again", you have two POST keys, one equal to "Thyme "
 * and another (time) equal to again.
 * It returns the escaped string.
 */
String encodeUriComponent(String component) {
  // Bit vector of 128 bits where each bit indicate whether a
  // character code on the 0-127 needs to be escaped or not.
  const canonicalTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !     '()*  -.
      0x6782,   // 0x20 - 0x2f  0100000111100110
                //              0123456789
      0x03ff,   // 0x30 - 0x3f  1111111111000000
                //              @ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010
  return _uriEncode(canonicalTable, component);
}

/**
 * An implementation of JavaScript's decodeURIComponent function.
 * Decodes a Uniform Resource Identifier (URI) [component] previously
 * created by encodeURIComponent or by a similar routine.
 * It returns the unescaped string.
 */
String decodeUriComponent(String encodedComponent) {
  return _uriDecode(encodedComponent);
}

/**
 * This is the internal implementation of JavaScript's encodeURI function.
 * It encodes all characters in the string [text] except for those
 * that appear in [canonicalTable], and returns the escaped string.
 */
String _uriEncode(List<int> canonicalTable, String text) {
  final String hex = '0123456789ABCDEF';
  var byteToHex = (int v) => '%${hex[v >> 4]}${hex[v & 0x0f]}';
  StringBuffer result = new StringBuffer();
  for (int i = 0; i < text.length; i++) {
    int ch = text.codeUnitAt(i);
    if (ch < 128 && ((canonicalTable[ch >> 4] & (1 << (ch & 0x0f))) != 0)) {
      result.write(text[i]);
    } else if (text[i] == " ") {
      result.write("+");
    } else {
      if (ch >= 0xD800 && ch < 0xDC00) {
        // Low surrogate. We expect a next char high surrogate.
        ++i;
        int nextCh = text.length == i ? 0 : text.codeUnitAt(i);
        if (nextCh >= 0xDC00 && nextCh < 0xE000) {
          // convert the pair to a U+10000 codepoint
          ch = 0x10000 + ((ch - 0xD800) << 10) + (nextCh - 0xDC00);
        } else {
          throw new ArgumentError('Malformed URI');
        }
      }
      for (int codepoint in codepointsToUtf8([ch])) {
        result.write(byteToHex(codepoint));
      }
    }
  }
  return result.toString();
}

/**
 * Convert a byte (2 character hex sequence) in string [s] starting
 * at position [pos] to its ordinal value
 */
int _hexCharPairToByte(String s, int pos) {
  int byte = 0;
  for (int i = 0; i < 2; i++) {
    var charCode = s.codeUnitAt(pos + i);
    if (0x30 <= charCode && charCode <= 0x39) {
      byte = byte * 16 + charCode - 0x30;
    } else {
      // Check ranges A-F (0x41-0x46) and a-f (0x61-0x66).
      charCode |= 0x20;
      if (0x61 <= charCode && charCode <= 0x66) {
        byte = byte * 16 + charCode - 0x57;
      } else {
        throw new ArgumentError("Invalid URL encoding");
      }
    }
  }
  return byte;
}

/**
 * A JavaScript-like decodeURI function. It unescapes the string [text] and
 * returns the unescaped string.
 */
String _uriDecode(String text) {
  StringBuffer result = new StringBuffer();
  List<int> codepoints = new List<int>();
  for (int i = 0; i < text.length;) {
    String ch = text[i];
    if (ch != '%') {
      if (ch == '+') {
        result.write(" ");
      } else {
        result.write(ch);
      }
      i++;
    } else {
      codepoints.clear();
      while (ch == '%') {
        if (++i > text.length - 2) {
          throw new ArgumentError('Truncated URI');
        }
        codepoints.add(_hexCharPairToByte(text, i));
        i += 2;
        if (i == text.length)
          break;
        ch = text[i];
      }
      result.write(decodeUtf8(codepoints));
    }
  }
  return result.toString();
}

