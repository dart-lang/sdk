// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library microlytics;

import 'channels.dart';

/// Very limited implementation of an API to report usage to Google Analytics.
/// No Personally Identifiable Information must ever be passed to this class.
class AnalyticsLogger {
  final Channel _channel;
  final String _clientID;
  final String _analyticsID;
  final String _appName;
  final String _appVersion;
  final String _messagePrefix; //Computed prefix for analytics messages

  /// Create a new logger
  /// [channel] represents how this is going to be sent, this would typically
  /// be a [RateLimitingBufferedChannel] wrapping either a [HttpRequestChannel]
  /// or a [HttpClientChannel].
  /// [clientID] is a version 4 UUID associated with the site or app.
  /// [appName] is an application name.
  /// [appVersion] is a verion string.
  AnalyticsLogger(Channel channel, String clientID, String analyticsID,
      String appName, String appVersion)
      : this._channel = channel,
      this._clientID = clientID,
      this._analyticsID = analyticsID,
      this._appName = appName,
      this._appVersion = appVersion,
      this._messagePrefix =
        "v=1"
        "&tid=$analyticsID"
        "&cid=$clientID"
        "&an=$appName"
        "&av=$appVersion";

  void logAnonymousTiming(String category, String variable, int ms) {
    category = Uri.encodeComponent(category);
    variable = Uri.encodeComponent(variable);
    _channel.sendData(
        "${this._messagePrefix}"
        "&t=timing"
        "&utc=$category"
        "&utv=$variable"
        "&utt=$ms");
  }

  void logAnonymousEvent(String category, String event) {
    category = Uri.encodeComponent(category);
    event = Uri.encodeComponent(event);
    _channel.sendData(
        "${this._messagePrefix}"
        "&t=event"
        "&ec=$category"
        "&ea=$event");
  }
}

