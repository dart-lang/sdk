// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_parser.media_type;

import 'package:collection/collection.dart';
import 'package:string_scanner/string_scanner.dart';

// All of the following regular expressions come from section 2.2 of the HTTP
// spec: http://www.w3.org/Protocols/rfc2616/rfc2616-sec2.html
final _lws = new RegExp(r"(?:\r\n)?[ \t]+");
final _token = new RegExp(r'[^()<>@,;:"\\/[\]?={} \t\x00-\x1F\x7F]+');
final _quotedString = new RegExp(r'"(?:[^"\x00-\x1F\x7F]|\\.)*"');
final _quotedPair = new RegExp(r'\\(.)');

/// A regular expression matching any number of [_lws] productions in a row.
final _whitespace = new RegExp("(?:${_lws.pattern})*");

/// A regular expression matching a character that is not a valid HTTP token.
final _nonToken = new RegExp(r'[()<>@,;:"\\/\[\]?={} \t\x00-\x1F\x7F]');

/// A regular expression matching a character that needs to be backslash-escaped
/// in a quoted string.
final _escapedChar = new RegExp(r'["\x00-\x1F\x7F]');

/// A class representing an HTTP media type, as used in Accept and Content-Type
/// headers.
///
/// This is immutable; new instances can be created based on an old instance by
/// calling [change].
class MediaType {
  /// The primary identifier of the MIME type.
  final String type;

  /// The secondary identifier of the MIME type.
  final String subtype;

  /// The parameters to the media type.
  ///
  /// This map is immutable.
  final Map<String, String> parameters;

  /// The media type's MIME type.
  String get mimeType => "$type/$subtype";

  /// Parses a media type.
  ///
  /// This will throw a FormatError if the media type is invalid.
  factory MediaType.parse(String mediaType) {
    // This parsing is based on sections 3.6 and 3.7 of the HTTP spec:
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html.
    try {
      var scanner = new StringScanner(mediaType);
      scanner.scan(_whitespace);
      scanner.expect(_token);
      var type = scanner.lastMatch[0];
      scanner.expect('/');
      scanner.expect(_token);
      var subtype = scanner.lastMatch[0];
      scanner.scan(_whitespace);

      var parameters = {};
      while (scanner.scan(';')) {
        scanner.scan(_whitespace);
        scanner.expect(_token);
        var attribute = scanner.lastMatch[0];
        scanner.expect('=');

        var value;
        if (scanner.scan(_token)) {
          value = scanner.lastMatch[0];
        } else {
          scanner.expect(_quotedString);
          var quotedString = scanner.lastMatch[0];
          value = quotedString.substring(1, quotedString.length - 1).
              replaceAllMapped(_quotedPair, (match) => match[1]);
        }

        scanner.scan(_whitespace);
        parameters[attribute] = value;
      }

      scanner.expectDone();
      return new MediaType(type, subtype, parameters);
    } on FormatException catch (error) {
      throw new FormatException(
          'Invalid media type "$mediaType": ${error.message}');
    }
  }

  MediaType(this.type, this.subtype, [Map<String, String> parameters])
      : this.parameters = new UnmodifiableMapView(
          parameters == null ? {} : new Map.from(parameters));

  /// Returns a copy of this [MediaType] with some fields altered.
  ///
  /// [type] and [subtype] alter the corresponding fields. [mimeType] is parsed
  /// and alters both the [type] and [subtype] fields; it cannot be passed along
  /// with [type] or [subtype].
  ///
  /// [parameters] overwrites and adds to the corresponding field. If
  /// [clearParameters] is passed, it replaces the corresponding field entirely
  /// instead.
  MediaType change({String type, String subtype, String mimeType,
      Map<String, String> parameters, bool clearParameters: false}) {
    if (mimeType != null) {
      if (type != null) {
        throw new ArgumentError("You may not pass both [type] and [mimeType].");
      } else if (subtype != null) {
        throw new ArgumentError("You may not pass both [subtype] and "
            "[mimeType].");
      }

      var segments = mimeType.split('/');
      if (segments.length != 2) {
        throw new FormatException('Invalid mime type "$mimeType".');
      }

      type = segments[0];
      subtype = segments[1];
    }

    if (type == null) type = this.type;
    if (subtype == null) subtype = this.subtype;
    if (parameters == null) parameters = {};

    if (!clearParameters) {
      var newParameters = parameters;
      parameters = new Map.from(this.parameters);
      parameters.addAll(newParameters);
    }

    return new MediaType(type, subtype, parameters);
  }

  /// Converts the media type to a string.
  ///
  /// This will produce a valid HTTP media type.
  String toString() {
    var buffer = new StringBuffer()
        ..write(type)
        ..write("/")
        ..write(subtype);

    parameters.forEach((attribute, value) {
      buffer.write("; $attribute=");
      if (_nonToken.hasMatch(value)) {
        buffer
          ..write('"')
          ..write(value.replaceAllMapped(
              _escapedChar, (match) => "\\" + match[0]))
          ..write('"');
      } else {
        buffer.write(value);
      }
    });

    return buffer.toString();
  }
}
