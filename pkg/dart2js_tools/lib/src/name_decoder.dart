// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Logic to deobfuscate minified names that appear in error messages.

import 'package:source_maps/source_maps.dart';

import 'dart2js_mapping.dart';
import 'trace.dart';

String translate(String error, Dart2jsMapping mapping, StackTraceLine line,
    TargetEntry entry) {
  for (var decoder in _errorMapDecoders) {
    var result = decoder.decode(error, mapping, line, entry);
    // More than one decoder might be applied on a single error message. This
    // can be useful, for example, if an error contains details about a member
    // and the type.
    if (result != null) error = result;
  }
  return error;
}

/// A decoder that matches an error against a regular expression and
/// uses data from the source-file and source-map file to translate minified
/// names to un-minified names.
abstract class ErrorMapDecoder {
  RegExp get _matcher;

  /// Decode [error] that was reported in [line] and has a corresponding [entry]
  /// in the source-map file. The provided [mapping] includes additional
  /// minification data that may be used to decode the error message.
  String decode(String error, Dart2jsMapping mapping, StackTraceLine line,
      TargetEntry entry) {
    if (error == null) return null;
    var match = _matcher.firstMatch(error);
    if (match == null) return null;
    var result = _decodeInternal(match, mapping, line, entry);
    if (result == null) return null;
    return '${error.substring(0, match.start)}'
        '$result${error.substring(match.end, error.length)}';
  }

  String _decodeInternal(Match match, Dart2jsMapping mapping,
      StackTraceLine line, TargetEntry entry);
}

typedef String ErrorDecoder(Match match, Dart2jsMapping mapping,
    StackTraceLine line, TargetEntry entry);

class MinifiedNameDecoder extends ErrorMapDecoder {
  final RegExp _matcher = new RegExp("minified:([a-zA-Z]*)");

  String _decodeInternal(Match match, Dart2jsMapping mapping,
      StackTraceLine line, TargetEntry entry) {
    var minifiedName = match.group(1);
    var name = mapping.globalNames[minifiedName];
    if (name == null) return null;
    return name;
  }
}

class CannotReadPropertyDecoder extends ErrorMapDecoder {
  final RegExp _matcher = new RegExp("Cannot read property '([^']*)' of");

  String _decodeInternal(Match match, Dart2jsMapping mapping,
      StackTraceLine line, TargetEntry entry) {
    var minifiedName = match.group(1);
    var name = mapping.instanceNames[minifiedName];
    if (name == null) return null;
    return "Cannot read property '$name' of";
  }
}

List<ErrorMapDecoder> _errorMapDecoders = [
  new MinifiedNameDecoder(),
  new CannotReadPropertyDecoder()
];
