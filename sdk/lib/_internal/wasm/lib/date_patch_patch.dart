// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

import 'dart:_js_helper' show JS;

@patch
class DateTime {
  @patch
  static int _getCurrentMicros() =>
      (JS<double>("Date.now") * Duration.microsecondsPerMillisecond).toInt();

  @patch
  static String _timeZoneNameForClampedSeconds(int secondsSinceEpoch) =>
      JS<String>(r"""secondsSinceEpoch => {
        const date = new Date(secondsSinceEpoch * 1000);
        const match = /\((.*)\)/.exec(date.toString());
        if (match == null) {
            // This should never happen on any recent browser.
            return '';
        }
        return stringToDartString(match[1]);
      }""", secondsSinceEpoch.toDouble());

  @patch
  static int _timeZoneOffsetInSecondsForClampedSeconds(int secondsSinceEpoch) =>
      JS<double>("s => new Date(s * 1000).getTimezoneOffset() * 60 ",
              secondsSinceEpoch.toDouble())
          .toInt();
}
