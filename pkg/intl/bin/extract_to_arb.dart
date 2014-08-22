#!/usr/bin/env dart
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This script uses the extract_messages.dart library to find the Intl.message
 * calls in the target dart files and produces ARB format output. See
 * https://code.google.com/p/arb/wiki/ApplicationResourceBundleSpecification
 */
library extract_to_arb;

import 'dart:convert';
import 'dart:io';
import 'package:intl/extract_messages.dart';
import 'package:path/path.dart' as path;
import 'package:intl/src/intl_message.dart';
import 'package:args/args.dart';

main(List<String> args) {
  var targetDir;
  var parser = new ArgParser();
  parser.addFlag("suppress-warnings", defaultsTo: false, callback: (x) =>
      suppressWarnings = x);
  parser.addFlag("warnings-are-errors", defaultsTo: false, callback: (x) =>
      warningsAreErrors = x);

  parser.addOption("output-dir", defaultsTo: '.', callback: (value) => targetDir
      = value);
  parser.parse(args);
  if (args.length == 0) {
    print('Usage: extract_to_arb [--output-dir=<dir>] [files.dart]');
    print('Accepts Dart files and produces intl_messages.json');
    exit(0);
  }
  var allMessages = {};
  for (var arg in args.where((x) => x.contains(".dart"))) {
    var messages = parseFile(new File(arg));
    messages.forEach((k, v) => allMessages.addAll(toARB(v)));
  }
  var file = new File(path.join(targetDir, 'intl_messages.arb'));
  file.writeAsStringSync(JSON.encode(allMessages));
  if (hasWarnings && warningsAreErrors) {
    exit(1);
  }
}

/**
 * This is a placeholder for transforming a parameter substitution from
 * the translation file format into a Dart interpolation. In our case we
 * store it to the file in Dart interpolation syntax, so the transformation
 * is trivial.
 */
String leaveTheInterpolationsInDartForm(MainMessage msg, chunk) {
  if (chunk is String) return chunk;
  if (chunk is int) return "\$${msg.arguments[chunk]}";
  return chunk.toCode();
}

/**
 * Convert the [MainMessage] to a trivial JSON format.
 */
Map toARB(MainMessage message) {
  if (message.messagePieces.isEmpty) return null;
  var out = {};
  out[message.name] = icuForm(message);
  out["@${message.name}"] = arbMetadata(message);
  return out;
}


Map arbMetadata(MainMessage message) {
  var out = {};
  var desc = message.description;
  if (desc != null) {
    out["description"] = desc;
  }
  out["type"] = "text";
  var placeholders = {};
  for (var arg in message.arguments) {
    addArgumentFor(message, arg, placeholders);
  }
  out["placeholders"] = placeholders;
  return out;
}

void addArgumentFor(MainMessage message, String arg, Map result) {
  var extraInfo = {};
  if (message.examples != null && message.examples[arg] != null) {
    extraInfo["example"] = message.examples[arg];
  }
  result[arg] = extraInfo;
}

/**
 * Return a version of the message string with
 * with ICU parameters "{variable}" rather than Dart interpolations "$variable".
 */
String icuForm(MainMessage message) => message.expanded(
    turnInterpolationIntoICUForm);

String turnInterpolationIntoICUForm(Message message, chunk,
    {bool shouldEscapeICU: false}) {
  if (chunk is String) {
    return shouldEscapeICU? escape(chunk) : chunk;
  }
  if (chunk is int && chunk >= 0 && chunk < message.arguments.length) {
    return "{${message.arguments[chunk]}}";
  }
  if (chunk is SubMessage) {
    return chunk.expanded((message, chunk) => turnInterpolationIntoICUForm(
        message, chunk, shouldEscapeICU: true));
  }
  if (chunk is Message) {
    return chunk.expanded((message, chunk) => turnInterpolationIntoICUForm(
        message, chunk, shouldEscapeICU: shouldEscapeICU));
  }
  throw new FormatException("Illegal interpolation: $chunk");
}

String escape(String s) {
  return s.replaceAll("'", "''").replaceAll("{", "'{'").replaceAll("}", "'}'");
}
