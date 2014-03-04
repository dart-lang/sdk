#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A main program that takes as input a source Dart file and a number
 * of JSON files representing translations of messages from the corresponding
 * Dart file. See extract_to_json.dart and make_hardcoded_translation.dart.
 *
 * This produces a series of files named
 * "messages_<locale>.dart" containing messages for a particular locale
 * and a main import file named "messages_all.dart" which has imports all of
 * them and provides an initializeMessages function.
 */
library generate_from_json;

import 'dart:convert';
import 'dart:io';
import 'package:intl/extract_messages.dart';
import 'package:intl/src/intl_message.dart';
import 'package:intl/generate_localized.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:serialization/serialization.dart';

/**
 * Keeps track of all the messages we have processed so far, keyed by message
 * name.
 */
Map<String, List<MainMessage>> messages;

main(List<String> args) {
  var targetDir;
  var parser = new ArgParser();
  parser.addFlag("suppress-warnings", defaultsTo: false,
      callback: (x) => suppressWarnings = x);
  parser.addOption("output-dir", defaultsTo: '.',
      callback: (x) => targetDir = x);
  parser.addOption("generated-file-prefix", defaultsTo: '',
      callback: (x) => generatedFilePrefix = x);
  parser.parse(args);
  var dartFiles = args.where((x) => x.endsWith("dart")).toList();
  var jsonFiles = args.where((x) => x.endsWith(".json")).toList();
  if (dartFiles.length == 0 || jsonFiles.length == 0) {
    print('Usage: generate_from_json [--output-dir=<dir>]'
        ' [--generated-file-prefix=<prefix>] file1.dart file2.dart ...'
        ' translation1.json translation2.json ...');
    exit(0);
  }

  // We're re-parsing the original files to find the corresponding messages,
  // so if there are warnings extracting the messages, suppress them.
  suppressWarnings = true;
  var allMessages = dartFiles.map((each) => parseFile(new File(each)));

  messages = new Map();
  for (var eachMap in allMessages) {
    eachMap.forEach((key, value) =>
        messages.putIfAbsent(key, () => []).add(value));
  }
  for (var arg in jsonFiles) {
    var file = new File(arg);
    generateLocaleFile(file, targetDir);
  }

  var mainImportFile = new File(path.join(targetDir,
      '${generatedFilePrefix}messages_all.dart'));
  mainImportFile.writeAsStringSync(generateMainImportFile());
}

var s = new Serialization();
var format = const SimpleFlatFormat();
var r = s.newReader(format);

recreateIntlObjects(key, value) {
  if (value == null) return null;
  if (value is String || value is int) return Message.from(value, null);
  if (value is List) {
    var newThing = r.read(value);
    return newThing;
  }
  throw new FormatException("Invalid input data $value");
}

/**
 * Create the file of generated code for a particular locale. We read the json
 * data and create [BasicTranslatedMessage] instances from everything,
 * excluding only the special _locale attribute that we use to indicate the
 * locale.
 */
void generateLocaleFile(File file, String targetDir) {
  var src = file.readAsStringSync();
  var data = JSON.decode(src);
  data.forEach((k, v) => data[k] = recreateIntlObjects(k, v));
  var locale = data["_locale"].string;
  allLocales.add(locale);

  var translations = [];
  data.forEach((key, value) {
    if (key[0] != "_") {
      translations.add(new BasicTranslatedMessage(key, value));
    }
  });
  generateIndividualMessageFile(locale, translations, targetDir);
}

/**
 * A TranslatedMessage that just uses the name as the id and knows how to look
 * up its original messages in our [messages].
 */
class BasicTranslatedMessage extends TranslatedMessage {
  BasicTranslatedMessage(String name, translated) :
      super(name, translated);

  List<MainMessage> get originalMessages => (super.originalMessages == null) ?
      _findOriginals() : super.originalMessages;

  // We know that our [id] is the name of the message, which is used as the
  //key in [messages].
  List<MainMessage> _findOriginals() => originalMessages = messages[id];
}
