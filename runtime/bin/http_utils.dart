// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _HttpUtils {
  static String decodeUrlEncodedString(String urlEncoded) {
    void invalidEscape() {
      // TODO(sgjesse): Handle the error.
    }

    StringBuffer result = new StringBuffer();
    for (int ii = 0; urlEncoded.length > ii; ++ii) {
      if ('+' == urlEncoded[ii]) {
        result.add(' ');
      } else if ('%' == urlEncoded[ii] &&
                 urlEncoded.length - 2 > ii) {
        try {
          int charCode =
            Math.parseInt('0x' + urlEncoded.substring(ii + 1, ii + 3));
          if (charCode <= 0x7f) {
            result.add(new String.fromCharCodes([charCode]));
            ii += 2;
          } else {
            invalidEscape();
            return '';
          }
        } catch (BadNumberFormatException ignored) {
          invalidEscape();
          return '';
        }
      } else {
        result.add(urlEncoded[ii]);
      }
    }
    return result.toString();
  }

  static Map<String, String> splitQueryString(String queryString) {
    Map<String, String> result = new Map<String, String>();
    int currentPosition = 0;
    while (currentPosition < queryString.length) {
      int position = queryString.indexOf("=", currentPosition);
      if (position == -1) {
        break;
      }
      String name = queryString.substring(currentPosition, position);
      currentPosition = position + 1;
      position = queryString.indexOf("&", currentPosition);
      String value;
      if (position == -1) {
        value = queryString.substring(currentPosition);
        currentPosition = queryString.length;
      } else {
        value = queryString.substring(currentPosition, position);
        currentPosition = position + 1;
      }
      result[_HttpUtils.decodeUrlEncodedString(name)] =
        _HttpUtils.decodeUrlEncodedString(value);
    }
    return result;
  }
}
