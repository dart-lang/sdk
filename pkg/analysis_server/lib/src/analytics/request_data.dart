// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analytics/percentile_calculator.dart';

/// Data about the requests that have been responded to that have the same
/// method.
class RequestData {
  /// The name of the requests.
  final String method;

  /// The percentile calculator for latency times. The _latency time_ is the
  /// time from when the client sent the request until the time the server
  /// started processing the request.
  final PercentileCalculator latencyTimes = PercentileCalculator();

  /// The percentile calculator for response times. The _response time_ is the
  /// time from when the server started processing the request until the time
  /// the response was sent.
  final PercentileCalculator responseTimes = PercentileCalculator();

  /// A table mapping the names of fields in a request's parameters to the
  /// percentile calculators related to the value of the parameter (such as the
  /// length of a list).
  final Map<String, PercentileCalculator> additionalPercentiles = {};

  /// A table mapping the name of a field in a request's parameters and the name
  /// of an enum constant to the number of times that the given constant was
  /// used as the value of the field.
  final Map<String, Map<String, int>> additionalEnumCounts = {};

  /// Initialize a newly create data holder for requests with the given
  /// [method].
  RequestData(this.method);

  /// Record the occurrence of the enum constant with the given [enumName] for
  /// the field with the given [name].
  void addEnumValue<E>(String name, String enumName) {
    var counts = additionalEnumCounts.putIfAbsent(name, () => {});
    counts[enumName] = (counts[enumName] ?? 0) + 1;
  }

  /// Record a [value] for the field with the given [name].
  void addValue(String name, int value) {
    additionalPercentiles
        .putIfAbsent(name, PercentileCalculator.new)
        .addValue(value);
  }
}
