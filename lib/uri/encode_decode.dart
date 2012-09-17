// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  return _uriEncode(
    "-_.!~*'()#;,/?:@&=+\$0123456789"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", uri);
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
  return _uriEncode(
    "-_.!~*'()0123456789"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", component);
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
 * that appear in [canonical], and returns the escaped string.
 */
String _uriEncode(String canonical, String text) {
  final String hex = '0123456789ABCDEF';
  var byteToHex = (int v) => '%${hex[v >> 4]}${hex[v&0xf]}';
  StringBuffer result = new StringBuffer();
  for (int i = 0; i < text.length; i++) {
    if (canonical.indexOf(text[i]) >= 0) {
      result.add(text[i]);
    } else {
      int ch = text.charCodeAt(i);
      if (ch >= 0xD800 && ch < 0xDC00) {
        // Low surrogate. We expect a next char high surrogate.
        ++i;
        int nextCh = text.length == i ? 0 : text.charCodeAt(i);
        if (nextCh >= 0xDC00 && nextCh < 0xE000) {
          // convert the pair to a U+10000 codepoint
          ch = 0x10000 + ((ch-0xD800) << 10) + (nextCh - 0xDC00);
        } else {
          throw new IllegalArgumentException('Malformed URI');
        }
      }
      for (int codepoint in codepointsToUtf8([ch])) {
        result.add(byteToHex(codepoint));
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
  // An alternative to calling [int.parse] twice would be to take a
  // two character substring and call it once, but that may be less
  // efficient.
  // TODO(lrn): I fail to see how that could possibly be slower than this.
  int d1 = int.parse("0x${s[pos]}");
  int d2 = int.parse("0x${s[pos+1]}");
  return d1 * 16 + d2;
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
      result.add(ch);
      i++;
    } else {
      codepoints.clear();
      while (ch == '%') {
        if (++i > text.length - 2) {
          throw new IllegalArgumentException('Truncated URI');
        }
        codepoints.add(_hexCharPairToByte(text, i));
        i += 2;
        if (i == text.length)
          break;
        ch = text[i];
      }
      result.add(decodeUtf8(codepoints));
    }
  }
  return result.toString();
}

