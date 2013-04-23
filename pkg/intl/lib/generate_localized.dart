// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This provides utilities for generating localized versions of
 * messages. It does not stand alone, but expects to be given
 * TranslatedMessage objects and generate code for a particular locale
 * based on them.
 *
 * An example of usage can be found
 * in test/message_extract/generate_from_json.dart
 */
library generate_localized;

import 'extract_messages.dart';
import 'src/intl_message.dart';
import 'dart:io';
import 'package:pathos/path.dart' as path;

/**
 * If the import path following package: is something else, modify the
 * [intlImportPath] variable to change the import directives in the generated
 * code.
 */
var intlImportPath = 'intl';

/**
 * If the path to the generated files is something other than the current
 * directory, update the [generatedImportPath] variable to change the import
 * directives in the generated code.
 */
var generatedImportPath = '';

/**
 * Given a base file, return the file prefixed with the path to import it.
 * By default, that is in the current directory, but if [generatedImportPath]
 * has been set, then use that as a prefix.
 */
String importForGeneratedFile(String file) =>
    generatedImportPath.isEmpty ? file : "$generatedImportPath/$file";

/**
 * A list of all the locales for which we have translations. Code that does
 * the reading of translations should add to this.
 */
List<String> allLocales = [];

/**
 * This represents a message and its translation. We assume that the translation
 * has some identifier that allows us to figure out the original message it
 * corresponds to, and that it may want to transform the translated text in
 * some way, e.g. to turn whatever format the translation uses for variables
 * into a Dart string interpolation. Specific translation
 * mechanisms are expected to subclass this.
 */
abstract class TranslatedMessage {
  /** The identifier for this message. In the simplest case, this is the name.*/
  var id;

  String translatedString;
  IntlMessage originalMessage;
  TranslatedMessage(this.id, this.translatedString);

  String get message => translatedString;
}

/**
 * We can't use a hyphen in a Dart library name, so convert the locale
 * separator to an underscore.
 */
String asLibraryName(String x) => x.replaceAll('-', '_');

/**
 * Generate a file messages_<locale>.dart for the [translations] in
 * [locale].
 */
void generateIndividualMessageFile(String locale,
    Iterable<TranslatedMessage> translations, String targetDir) {
  var result = new StringBuffer();
  locale = new IntlMessage().escapeAndValidate(locale, locale);
  result.write(prologue(locale));
  for (var each in translations) {
    var message = each.originalMessage;
    if (each.message != null) {
      message.addTranslation(locale, each.message);
    }
  }
  var sorted = translations.where((each) => each.message != null).toList();
  sorted.sort((a, b) =>
      a.originalMessage.name.compareTo(b.originalMessage.name));
  for (var each in sorted) {
    result.write("  ");
    result.write(each.originalMessage.toCode(locale));
    result.write("\n\n");
  }
  result.write("\n  final messages = const {\n");
  var entries = sorted
      .map((translation) => translation.originalMessage.name)
      .map((name) => "    \"$name\" : $name");
  result.write(entries.join(",\n"));
  result.write("\n  };\n}");

  var output = new File(path.join(targetDir, "messages_$locale.dart"));
  output.writeAsStringSync(result.toString());
}

/**
 * This returns the mostly constant string used in
 * [generateIndividualMessageFile] for the
 * beginning of the file, parameterized by [locale].
 */
String prologue(String locale) => """
/**
 * DO NOT EDIT. This is code generated via pkg/intl/generate_localized.dart
 * This is a library that provides messages for a $locale locale. All the
 * messages from the main program should be duplicated here with the same
 * function name.
 */

library messages_${locale.replaceAll('-','_')};
import 'package:$intlImportPath/intl.dart';
import 'package:$intlImportPath/message_lookup_by_library.dart';

final messages = new MessageLookup();

class MessageLookup extends MessageLookupByLibrary {

  get localeName => '$locale';
""";

/**
 * This section generates the messages_all.dart file based on the list of
 * [allLocales].
 */
String generateMainImportFile() {
  var output = new StringBuffer();
  output.write(mainPrologue);
  for (var each in allLocales) {
    var baseFile = 'messages_$each.dart';
    var file = importForGeneratedFile(baseFile);
    output.write("import '$file' as ${asLibraryName(each)};\n");
  }
  output.write(
    "\nMessageLookupByLibrary _findExact(localeName) {\n"
    "  switch (localeName) {\n");
  for (var each in allLocales) {
    output.write(
        "    case '$each' : return ${asLibraryName(each)}.messages;\n");
  }
  output.write(closing);
  return output.toString();
}

/**
 * Constant string used in [generateMainImportFile] for the beginning of the
 * file.
 */
var mainPrologue = """
/**
 * DO NOT EDIT. This is code generated via pkg/intl/generate_localized.dart
 * This is a library that looks up messages for specific locales by
 * delegating to the appropriate library.
 */

library messages_all;

import 'dart:async';
import 'package:$intlImportPath/message_lookup_by_library.dart';
import 'package:$intlImportPath/src/intl_helpers.dart';
import 'package:$intlImportPath/intl.dart';

""";

/**
 * Constant string used in [generateMainImportFile] as the end of the file.
 */
const closing = """
    default: return null;
  }
}

/** User programs should call this before using [localeName] for messages.*/
initializeMessages(localeName) {
  initializeInternalMessageLookup(() => new CompositeMessageLookup());
  messageLookup.addLocale(localeName, _findGeneratedMessagesFor);
  return new Future.value();
}

MessageLookupByLibrary _findGeneratedMessagesFor(locale) {
  var actualLocale = Intl.verifiedLocale(locale, (x) => _findExact(x) != null);
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}
""";
