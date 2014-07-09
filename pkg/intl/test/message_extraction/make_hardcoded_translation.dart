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

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';

/** A list of the French translations that we will produce. */
var french = {
  "types" : r"{a}, {b}, {c}",
  "multiLine" : "Cette message prend plusiers lignes.",
  "message2" : r"Un autre message avec un seul paramètre {x}",
  "alwaysTranslated" : "Cette chaîne est toujours traduit",
  "message1" : "Il s'agit d'un message",
  "leadingQuotes" : "\"Soi-disant\"",
  "trickyInterpolation" : r"L'interpolation est délicate "
    r"quand elle se termine une phrase comme {s}.",
  "message3" : "Caractères qui doivent être échapper, par exemple barres \\ "
    "dollars \${ (les accolades sont ok), et xml/html réservés <& et "
    "des citations \" "
    "avec quelques paramètres ainsi {a}, {b}, et {c}",
  "method" : "Cela vient d'une méthode",
  "nonLambda" : "Cette méthode n'est pas un lambda",
  "staticMessage" : "Cela vient d'une méthode statique",
  "notAlwaysTranslated" : "Ce manque certaines traductions",
  "thisNameIsNotInTheOriginal" : "Could this lead to something malicious?",
  "originalNotInBMP" : "Anciens caractères grecs jeux du pendu: 𐅆𐅇.",
  "escapable" : "Escapes: \n\r\f\b\t\v.",
  "sameContentsDifferentName" : "Bonjour tout le monde",
  "differentNameSameContents" : "Bonjour tout le monde",
  "rentToBePaid" : "loyer",
  "rentAsVerb" : "louer",
  "plurals" : 
      "{num,plural, =0{Est-ce que nulle est pluriel?}=1{C'est singulier}"
      "other{C'est pluriel ({num}).}}",
  "whereTheyWentMessage" : "{gender,select, male{{name} est allé à sa {place}}"
      "female{{name} est allée à sa {place}}other{{name}"
          " est allé à sa {place}}}",
  // Gratuitously different translation for testing. Ignoring gender of place.
  "nestedMessage" : "{combinedGender,select, "
    "other{"
      "{number,plural, "
        "=0{Personne n'avait allé à la {place}}"
        "=1{{names} était allé à la {place}}"
        "other{{names} étaient allés à la {place}}"
      "}"
    "}"
    "female{"
      "{number,plural, "
        "=1{{names} était allée à la {place}}"
        "other{{names} étaient allées à la {place}}"
      "}"
    "}"
  "}",
  "outerPlural" : "{n,plural, =0{rien}=1{un}other{quelques-uns}}",
  "outerGender" : "{g,select, male{homme}female{femme}other{autre}}",
  "pluralThatFailsParsing" : "{noOfThings,plural, "
    "=1{1 chose:}other{{noOfThings} choses:}}",
  "nestedOuter" : "{number,plural, other{"
    "{gen,select, male{{number} homme}other{{number} autre}}}}",
  "outerSelect" : "{currency,select, CDN{{amount} dollars Canadiens}"
    "other{{amount} certaine devise ou autre.}}}",
  "nestedSelect" : "{currency,select, CDN{{amount,plural, "
      "=1{{amount} dollar Canadien}"
      "other{{amount} dollars Canadiens}}}"
    "other{N'importe quoi}"
    "}}"
};

/** A list of the German translations that we will produce. */
var german = {
  "types" : r"{a}, {b}, {c}",
  "multiLine" : "Dieser String erstreckt sich über mehrere Zeilen erstrecken.",
  "message2" : r"Eine weitere Meldung mit dem Parameter {x}",
  "alwaysTranslated" : "Diese Zeichenkette wird immer übersetzt",
  "message1" : "Dies ist eine Nachricht",
  "leadingQuotes" : "\"Sogenannt\"",
  "trickyInterpolation" : r"Interpolation ist schwierig, wenn es einen Satz "
      "wie dieser endet {s}.",
  "message3" : "Zeichen, die Flucht benötigen, zB Schrägstriche \\ Dollar "
    "\${ (geschweiften Klammern sind ok) und xml reservierte Zeichen <& und "
    "Zitate \" Parameter {a}, {b} und {c}",
  "method" : "Dies ergibt sich aus einer Methode",

  "nonLambda" : "Diese Methode ist nicht eine Lambda",
  "staticMessage" : "Dies ergibt sich aus einer statischen Methode",
  "thisNameIsNotInTheOriginal" : "Could this lead to something malicious?",
  "originalNotInBMP" : "Antike griechische Galgenmännchen Zeichen: 𐅆𐅇",
  "escapable" : "Escapes: \n\r\f\b\t\v.",
  "sameContentsDifferentName" : "Hallo Welt",
  "differentNameSameContents" : "Hallo Welt",
  "rentToBePaid" : "Miete",
  "rentAsVerb" : "mieten",
  "plurals" : "{num,plural, =0{Ist Null Plural?}=1{Dies ist einmalig}"
      "other{Dies ist Plural ({num}).}}",
  "whereTheyWentMessage" : "{gender,select, male{{name} ging zu seinem {place}}"
      "female{{name} ging zu ihrem {place}}other{{name} ging zu seinem {place}}}",
  //Note that we're only using the gender of the people. The gender of the
  //place also matters, but we're not dealing with that here.
  "nestedMessage" : "{combinedGender,select, "
    "other{"
      "{number,plural, "
        "=0{Niemand ging zu {place}}"
        "=1{{names} ging zum {place}}"
        "other{{names} gingen zum {place}}"
      "}"
    "}"
    "female{"
      "{number,plural, "
        "=1{{names} ging in dem {place}}"
        "other{{names} gingen zum {place}}"
      "}"
    "}"
  "}",
  "outerPlural" : "{n,plural, =0{Null}=1{ein}other{einige}}",
  "outerGender" : "{g,select, male{Mann}female{Frau}other{andere}}",
  "pluralThatFailsParsing" : "{noOfThings,plural, "
    "=1{eins:}other{{noOfThings} Dinge:}}",
  "nestedOuter" : "{number,plural, other{"
    "{gen,select, male{{number} Mann}other{{number} andere}}}}",
  "outerSelect" : "{currency,select, CDN{{amount} Kanadischen dollar}"
    "other{{amount} einige Währung oder anderen.}}}",
  "nestedSelect" : "{currency,select, CDN{{amount,plural, "
      "=1{{amount} Kanadischer dollar}"
      "other{{amount} Kanadischen dollar}}}"
    "other{whatever}"
    "}"
};

/** The output directory for translated files. */
String targetDir;

/**
 * Generate a translated json version from [originals] in [locale] looking
 * up the translations in [translations].
 */
void translate(Map originals, String locale, Map translations) {
  var translated = {"_locale" : locale};
  originals.forEach((name, text) {
    translated[name] = translations[name];
  });
  var file = new File(path.join(targetDir, 'translation_$locale.arb'));
  file.writeAsStringSync(JSON.encode(translated));
}

main(List<String> args) {
  if (args.length == 0) {
    print('Usage: make_hardcoded_translation [--output-dir=<dir>] '
        '[originalFile.arb]');
    exit(0);
  }
  var parser = new ArgParser();
  parser.addOption("output-dir", defaultsTo: '.',
      callback: (value) => targetDir = value);
  parser.parse(args);

  var fileArgs = args.where((x) => x.contains('.arb'));

  var messages = JSON.decode(new File(fileArgs.first).readAsStringSync());
  translate(messages, "fr", french);
  translate(messages, "de_DE", german);
}
