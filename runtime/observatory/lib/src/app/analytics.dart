// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

class Analytics {
  static final _UA = 'UA-26406144-17';
  static final _name = 'Observatory';
  static final _version = const String.fromEnvironment('OBS_VER');
  static final _googleAnalytics = new AnalyticsHtml(_UA, _name, _version);

  static initialize() {
    // We only send screen views. This is allowed without user permission.
    // Note, before flipping this to be true we need a UI to allow users to
    // control this.
    _googleAnalytics.analyticsOpt = AnalyticsOpt.optOut;
  }

  /// Called whenever an Observatory page is viewed.
  static Future reportPageView(Uri uri) {
    // Only report analytics when running in JavaScript.
    if (Utils.runningInJavaScript()) {
      // The screen name is the uri's path. e.g. inspect, profile.
      final screenName = uri.path;
      return _googleAnalytics.sendScreenView(screenName);
    } else {
      return new Future.value(null);
    }
  }
}
