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

import 'intl.dart';
import 'src/intl_message.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

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
 * If we have more than one set of messages to generate in a particular
 * directory we may want to prefix some to distinguish them.
 */
String generatedFilePrefix = '';

/**
 * This represents a message and its translation. We assume that the translation
 * has some identifier that allows us to figure out the original message it
 * corresponds to, and that it may want to transform the translated text in
 * some way, e.g. to turn whatever format the translation uses for variables
 * into a Dart string interpolation. Specific translation
 * mechanisms are expected to subclass this.
 */
abstract class TranslatedMessage {
  /**
   * The identifier for this message. In the simplest case, this is the name
   * parameter from the Intl.message call,
   * but it can be any identifier that this program and the output of the
   * translation can agree on as identifying a message.
   */
  final String id;

  /** Our translated version of all the [originalMessages]. */
  final Message translated;

  /**
   * The original messages that we are a translation of. There can
   *  be more than one original message for the same translation.
   */
  List<MainMessage> originalMessages;

  /**
   * For backward compatibility, we still have the originalMessage API.
   */
  MainMessage get originalMessage => originalMessages.first;
  set originalMessage(MainMessage m) => originalMessages = [m];

  TranslatedMessage(this.id, this.translated);

  Message get message => translated;

  toString() => id.toString();
}

/**
 * We can't use a hyphen in a Dart library name, so convert the locale
 * separator to an underscore.
 */
String _libraryName(String x) => 'messages_' + x.replaceAll('-', '_');

/**
 * Generate a file <[generated_file_prefix]>_messages_<[locale]>.dart
 * for the [translations] in [locale] and put it in [targetDir].
 */
void generateIndividualMessageFile(String basicLocale,
    Iterable<TranslatedMessage> translations, String targetDir) {
  var result = new StringBuffer();
  var locale = new MainMessage().escapeAndValidateString(
      Intl.canonicalizedLocale(basicLocale));
  result.write(prologue(locale));
  // Exclude messages with no translation and translations with no matching
  // original message (e.g. if we're using some messages from a larger catalog)
  var usableTranslations =  translations.where(
      (each) => each.originalMessages != null && each.message != null).toList();
  for (var each in usableTranslations) {
    for (var original in each.originalMessages) {
      original.addTranslation(locale, each.message);
    }
  }
  usableTranslations.sort((a, b) =>
      a.originalMessages.first.name.compareTo(b.originalMessages.first.name));
  for (var translation in usableTranslations) {
    for (var original in translation.originalMessages) {
      result
          ..write("  ")
          ..write(original.toCodeForLocale(locale))
          ..write("\n\n");
    }
  }
  result.write("\n  final messages = const {\n");
  var entries = usableTranslations
      .expand((translation) => translation.originalMessages)
      .map((original) => original.name)
      .map((name) => "    \"$name\" : $name");
  result
      ..write(entries.join(",\n"))
      ..write("\n  };\n}");

  // To preserve compatibility, we don't use the canonical version of the locale
  // in the file name.
  var filename =
      path.join(targetDir,"${generatedFilePrefix}messages_$basicLocale.dart");
  new File(filename).writeAsStringSync(result.toString());
}

/**
 * This returns the mostly constant string used in
 * [generateIndividualMessageFile] for the beginning of the file,
 * parameterized by [locale].
 */
String prologue(String locale) => """
/**
 * DO NOT EDIT. This is code generated via pkg/intl/generate_localized.dart
 * This is a library that provides messages for a $locale locale. All the
 * messages from the main program should be duplicated here with the same
 * function name.
 */

library ${_libraryName(locale)};
import 'package:$intlImportPath/intl.dart';
import 'package:$intlImportPath/message_lookup_by_library.dart';

final messages = new MessageLookup();

class MessageLookup extends MessageLookupByLibrary {

  get localeName => '$locale';
""";


_deferredName(locale) => "lazy_${_libraryName(locale)}";

/**
 * This section generates the messages_all.dart file based on the list of
 * [allLocales].
 */
String generateMainImportFile() {
  var output = new StringBuffer();
  output.write(mainPrologue);
  for (var locale in allLocales) {
    var baseFile = '${generatedFilePrefix}messages_$locale.dart';
    var file = importForGeneratedFile(baseFile);
    // TODO(alanknight): Restore this once deferred loading works in dartj2s.
    // Issue 12824
    //    output.write("@${_deferredName(locale)}\n");
    output.write("import '$file' as ${_libraryName(locale)};\n");
  }
  output.write("\n");
  // Issue 12824
  //for (var locale in allLocales) {
  //  output.write("const ${_deferredName(locale)} = const DeferredLibrary");
  //  output.write("('${_libraryName(locale)}');\n");
  //}
  //output.write("\nconst deferredLibraries = const {\n");
  //for (var locale in allLocales) {
  //  output.write("  '$locale' : ${_deferredName(locale)},\n");
  //}
  //output.write("};\n");
  output.write(
    "\nMessageLookupByLibrary _findExact(localeName) {\n"
    "  switch (localeName) {\n");
  for (var rawLocale in allLocales) {
    var locale = Intl.canonicalizedLocale(rawLocale);
    output.write(
        "    case '$locale' : return ${_libraryName(locale)}.messages;\n");
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
Future initializeMessages(String localeName) {
  initializeInternalMessageLookup(() => new CompositeMessageLookup());
  messageLookup.addLocale(localeName, _findGeneratedMessagesFor);
  // TODO(alanknight): Restore once Issue 12824 is fixed.
  // var lib = deferredLibraries[localeName];
  // return lib == null ? new Future.value(false) : lib.load();
  return new Future.value(true);
}

MessageLookupByLibrary _findGeneratedMessagesFor(locale) {
  var actualLocale = Intl.verifiedLocale(locale, (x) => _findExact(x) != null,
      onFailure: (_) => null);
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}
""";
