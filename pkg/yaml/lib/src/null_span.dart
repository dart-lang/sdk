// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.null_span;

import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart';

/// A [Span] with no location information.
///
/// This is used with [YamlMap.wrap] and [YamlList.wrap] to provide means of
/// accessing a non-YAML map that behaves transparently like a map parsed from
/// YAML.
class NullSpan extends Span {
  Location get end => start;
  final text = "";

  NullSpan(String sourceUrl)
      : this._(new NullLocation(sourceUrl));

  NullSpan._(Location location)
      : super(location, location, false);

  String formatLocationMessage(String message, {bool useColors: false,
      String color}) {
    var locationMessage = sourceUrl == null ? "in an unknown location" :
        "in ${p.prettyUri(sourceUrl)}";
    return "$locationMessage: $message";
  }
}

/// A [Location] with no location information.
///
/// This is used with [YamlMap.wrap] and [YamlList.wrap] to provide means of
/// accessing a non-YAML map that behaves transparently like a map parsed from
/// YAML.
class NullLocation extends Location {
  final String sourceUrl;
  final line = 0;
  final column = 0;

  String get formatString => sourceUrl == null ? "unknown location" : sourceUrl;

  NullLocation(this.sourceUrl)
      : super(0);
}
