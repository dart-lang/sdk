#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This simulates a translation process, reading the messages generated
 * from extract_message.dart for the files sample_with_messages.dart and
 * part_of_sample_with_messages.dart and writing out hard-coded translations for
 * German and French locales.
 */

import 'dart:io';
import 'dart:json' as json;
import 'package:pathos/path.dart' as path;
import 'find_output_directory.dart';

/** A list of the French translations that we will produce. */
var french = {
  "types" : r"$a, $b, $c",
  "multiLine" : "Cette message prend plusiers lignes.",
  "message2" : r"Un autre message avec un seul paramètre $x",
  "alwaysTranslated" : "Cette chaîne est toujours traduit",
  "message1" : "Il s'agit d'un message",
  "leadingQuotes" : "\"Soi-disant\"",
  "trickyInterpolation" : r"L'interpolation est délicate "
    r"quand elle se termine une phrase comme ${s}.",
  "message3" : "Caractères qui doivent être échapper, par exemple barres \\ "
    "dollars \${ (les accolades sont ok), et xml/html réservés <& et "
    "des citations \" "
    "avec quelques paramètres ainsi \$a, \$b, et \$c",
  "method" : "Cela vient d'une méthode",
  "nonLambda" : "Cette méthode n'est pas un lambda",
  "staticMessage" : "Cela vient d'une méthode statique",
  "notAlwaysTranslated" : "Ce manque certaines traductions",
  "thisNameIsNotInTheOriginal" : "Could this lead to something malicious?",
  "originalNotInBMP" : "Anciens caractères grecs jeux du pendu: 𐅆𐅇.",
  "plural" : """Une des choses difficiles est \${Intl.plural(num,
      {
        '0' : 'la forme plurielle',
        '1' : 'la forme plurielle',
        'other' : 'des formes plurielles'})}""",
   "namedArgs" : "La chose est, \$thing",
   "escapable" : "Escapes: \n\r\f\b\t\v."
};

/** A list of the German translations that we will produce. */
var german = {
  "types" : r"$a, $b, $c",
  "multiLine" : "Dieser String erstreckt sich über mehrere Zeilen erstrecken.",
  "message2" : r"Eine weitere Meldung mit dem Parameter $x",
  "alwaysTranslated" : "Diese Zeichenkette wird immer übersetzt",
  "message1" : "Dies ist eine Nachricht",
  "leadingQuotes" : "\"Sogenannt\"",
  "trickyInterpolation" :
    r"Interpolation ist schwierig, wenn es einen Satz wie dieser endet ${s}.",
  "message3" : "Zeichen, die Flucht benötigen, zB Schrägstriche \\ Dollar "
    "\${ (geschweiften Klammern sind ok) und xml reservierte Zeichen <& und "
    "Zitate \" Parameter \$a, \$b und \$c",
  "method" : "Dies ergibt sich aus einer Methode",
  "nonLambda" : "Diese Methode ist nicht eine Lambda",
  "staticMessage" : "Dies ergibt sich aus einer statischen Methode",
  "originalNotInBMP" : "Antike griechische Galgenmännchen Zeichen: 𐅆𐅇",
  "plurals" : """\${Intl.plural(num,
      {
        '0' : 'Einer der knifflige Dinge ist der Plural',
        '1' : 'Einer der knifflige Dinge ist der Plural',
        'other' : 'Zu den kniffligen Dinge Pluralformen'
      })}""",
   "namedArgs" : "Die Sache ist, \$thing",
   "escapable" : "Escapes: \n\r\f\b\t\v."
};

/** The output directory for translated files. */
String targetDir;

/**
 * Generate a translated json version from [originals] in [locale] looking
 * up the translations in [translations].
 */
void translate(List originals, String locale, Map translations) {
  var translated = {"_locale" : locale};
  for (var each in originals) {
    var name = each["name"];
    translated[name] = translations[name];
  }
  var file = new File(path.join(targetDir, 'translation_$locale.json'));
  file.writeAsStringSync(json.stringify(translated));
}

main() {
  var args = new Options().arguments;
  if (args.length == 0) {
    print('Usage: generate_hardcoded_translation [--output-dir=<dir>] '
        '[originalFile.dart]');
    exit(0);
  }

  targetDir = findOutputDirectory(args);
  var fileArgs = args.where((x) => x.contains('.json'));

  var messages = json.parse(new File(fileArgs.first).readAsStringSync());
  translate(messages, "fr", french);
  translate(messages, "de_DE", german);
}