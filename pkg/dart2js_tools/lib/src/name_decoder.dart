// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Logic to deobfuscate minified names that appear in error messages.

import 'package:source_maps/source_maps.dart';

import 'dart2js_mapping.dart';
import 'trace.dart';

String translate(String error, Dart2jsMapping mapping,
    [StackTraceLine line, TargetEntry entry]) {
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
    Match lastMatch = null;
    var result = new StringBuffer();
    for (var match in _matcher.allMatches(error)) {
      var decodedMatch = _decodeInternal(match, mapping, line, entry);
      if (decodedMatch == null) {
        continue;
      }
      result.write(error.substring(lastMatch?.end ?? 0, match.start));
      result.write(decodedMatch);
      lastMatch = match;
    }
    if (lastMatch == null) return null;
    result.write(error.substring(lastMatch.end, error.length));
    return '$result';
  }

  String _decodeInternal(Match match, Dart2jsMapping mapping,
      StackTraceLine line, TargetEntry entry);
}

typedef String ErrorDecoder(Match match, Dart2jsMapping mapping,
    StackTraceLine line, TargetEntry entry);

class MinifiedNameDecoder extends ErrorMapDecoder {
  final RegExp _matcher = new RegExp("minified:([a-zA-Z0-9_\$]*)");

  String _decodeInternal(Match match, Dart2jsMapping mapping,
      StackTraceLine line, TargetEntry entry) {
    var minifiedName = match.group(1);
    return mapping.globalNames[minifiedName];
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

abstract class NoSuchMethodDecoderBase extends ErrorMapDecoder {
  String _translateMinifiedName(Dart2jsMapping mapping, String minifiedName) {
    var name = mapping.instanceNames[minifiedName];
    if (name != null) return "'$name'";
    if (minifiedName.startsWith(new RegExp(r'(call)?\$[0-9]'))) {
      int first$ = minifiedName.indexOf(r'$');
      return _expandCallSignature(minifiedName.substring(first$));
    }
    return null;
  }

  String _expandCallSignature(String callSignature) {
    // Minified names are one of these forms:
    //   $0         // positional arguments only
    //   $1$2       // type parameters and positional arguments
    //   $3$name    // positional and named arguments
    //   $1$3$name  // type parameters and positional and named args
    var signature = callSignature.split(r'$');
    var typeArgs = null;
    var totalArgs = null;
    var namedArgs = <String>[];
    for (var arg in signature) {
      if (arg == "") continue;
      var count = int.tryParse(arg);
      if (count != null) {
        if (totalArgs != null) {
          if (typeArgs != null) {
            // unexpected format, leave it unchanged.
            return null;
          }
          typeArgs = totalArgs;
        }
        totalArgs = count;
      } else {
        namedArgs.add(arg);
      }
    }
    var sb = new StringBuffer();
    sb.write("'call'");
    sb.write(" (with ");
    if (typeArgs != null) {
      sb.write("$typeArgs type arguments");
      sb.write(namedArgs.isNotEmpty ? ", " : " and ");
    }
    sb.write("${totalArgs - namedArgs.length} positional arguments");
    if (namedArgs.isNotEmpty) {
      sb.write(typeArgs != null ? "," : "");
      sb.write(" and named arguments '${namedArgs.join("', '")}'");
    }
    sb.write(')');
    return "$sb";
  }
}

class NoSuchMethodDecoder1 extends NoSuchMethodDecoderBase {
  final RegExp _matcher = new RegExp(
      "NoSuchMethodError: method not found: '([^']*)'( on [^\\(]*)? \\(.*\\)");

  String _decodeInternal(Match match, Dart2jsMapping mapping,
      StackTraceLine line, TargetEntry entry) {
    var minifiedName = match.group(1);
    var suffix = match.group(2) ?? '';
    var name = _translateMinifiedName(mapping, minifiedName);
    if (name == null) return null;
    return "NoSuchMethodError: method not found: $name$suffix";
  }
}

class NoSuchMethodDecoder2 extends NoSuchMethodDecoderBase {
  final RegExp _matcher =
      new RegExp("NoSuchMethodError: method not found: '([^']*)'");

  String _decodeInternal(Match match, Dart2jsMapping mapping,
      StackTraceLine line, TargetEntry entry) {
    var minifiedName = match.group(1);
    var name = _translateMinifiedName(mapping, minifiedName);
    if (name == null) return null;
    return "NoSuchMethodError: method not found: $name";
  }
}

class UnhandledNotAFunctionError extends ErrorMapDecoder {
  final RegExp _matcher = new RegExp("Error: ([^']*) is not a function");

  String _decodeInternal(Match match, Dart2jsMapping mapping,
      StackTraceLine line, TargetEntry entry) {
    var minifiedName = match.group(1);
    var name = mapping.instanceNames[minifiedName];
    if (name == null) return null;
    return "Error: $name is not a function";
  }
}

List<ErrorMapDecoder> _errorMapDecoders = [
  new MinifiedNameDecoder(),
  new CannotReadPropertyDecoder(),
  new NoSuchMethodDecoder1(),
  new NoSuchMethodDecoder2(),
  new UnhandledNotAFunctionError(),
];
