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
import 'package:intl/src/intl_message.dart';
import 'package:serialization/serialization.dart';

/**
 * A serialization so that we can write out the more complex plural and
 * gender examples to JSON easily. This is a stopgap and should be replaced
 * with a commonly used translation file format.
 */
get serialization => new Serialization()
  ..addRuleFor(new VariableSubstitution(0, null),
      constructorFields: ["index", "parent"])
  ..addRuleFor(new LiteralString("a", null),
      constructorFields: ["string", "parent"])
  ..addRuleFor(new CompositeMessage([], null), constructor: "withParent",
      constructorFields: ["parent"]);
var format = const SimpleFlatFormat();
get writer => serialization.newWriter(format);

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
  "escapable" : "Escapes: \n\r\f\b\t\v.",
  "sameContentsDifferentName" : "Bonjour tout le monde",
  "differentNameSameContents" : "Bonjour tout le monde",
  "rentToBePaid" : "loyer",
  "rentAsVerb" : "louer",
  "plurals" : writer.write(new Plural.from("num",
      [
        ["zero", "Est-ce que nulle est pluriel?"],
        ["one", "C'est singulier"],
        ["other", "C'est pluriel (\$num)."]
      ], null)),
  // TODO(alanknight): These are pretty horrible to write out manually. Provide
  // a better way of reading/writing translations. A real format would be good.
  "whereTheyWentMessage" : writer.write(new Gender.from("gender",
    [
      ["male", [0, " est allé à sa ", 2]],
      ["female", [0, " est allée à sa ", 2]],
      ["other", [0, " est allé à sa ", 2]]
    ], null)),
  // Gratuitously different translation for testing. Ignoring gender of place.
  "nestedMessage" : writer.write(new Gender.from("combinedGender",
    [
      ["other", new Plural.from("number",
        [
          ["zero", "Personne n'avait allé à la \$place"],
          ["one", "\${names} était allé à la \$place"],
          ["other",  "\${names} étaient allés à la \$place"],
        ], null)
      ],
      ["female", new Plural.from("number",
        [
          ["one", "\$names était allée à la \$place"],
          ["other", "\$names étaient allées à la \$place"],
        ], null)
      ]
    ], null
  )),
  "outerPlural" : writer.write(new Plural.from("n",
      [
        ['zero', 'rien'],
        ['one', 'un'],
        ['other', 'quelques-uns']
      ], null)),
  "outerGender" : writer.write(new Gender.from("g",
      [
        ['male', 'homme'],
        ['female', 'femme'],
        ['other', 'autre'],
      ], null)),
  "pluralThatFailsParsing" : writer.write(new Plural.from("noOfThings",
      [
        ['one', '1 chose:'],
        ['other', '\$noOfThings choses:']
      ], null)),
  "nestedOuter" : writer.write ( new Plural.from("number",
      [
        ['other', new Gender.from("gen",
            [["male", "\$number homme"], ["other", "\$number autre"]], null),
        ]
      ], null)),
  "outerSelect" : writer.write(new Select.from("currency",
      [
        ['CDN', '\$amount dollars Canadiens'],
        ['other', '\$amount certaine devise ou autre.'],
      ], null)),
  "nestedSelect" : writer.write(new Select.from("currency",
      [
        ['CDN', new Plural.from('amount',
            [
              ["other", '\$amount dollars Canadiens'],
              ["one", '\$amount dollar Canadien'],
            ], null)
        ],
        ['other', 'N''importe quoi'],
      ], null)),
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
  "escapable" : "Escapes: \n\r\f\b\t\v.",
  "sameContentsDifferentName" : "Hallo Welt",
  "differentNameSameContents" : "Hallo Welt",
  "rentToBePaid" : "Miete",
  "rentAsVerb" : "mieten",
  "plurals" : writer.write(new Plural.from("num",
    [
      ["zero", "Ist Null Plural?"],
      ["one", "Dies ist einmalig"],
      ["other", "Dies ist Plural (\$num)."]
    ], null)),
  // TODO(alanknight): These are pretty horrible to write out manually. Provide
  // a better way of reading/writing translations. A real format would be good.
  "whereTheyWentMessage" : writer.write(new Gender.from("gender",
    [
      ["male", [0, " ging zu seinem ", 2]],
      ["female", [0, " ging zu ihrem ", 2]],
      ["other", [0, " ging zu seinem ", 2]]
    ], null)),
  //Note that we're only using the gender of the people. The gender of the
  //place also matters, but we're not dealing with that here.
  "nestedMessage" : writer.write(new Gender.from("combinedGender",
    [
      ["other", new Plural.from("number",
        [
          ["zero", "Niemand ging zu \$place"],
          ["one", "\${names} ging zum \$place"],
          ["other", "\${names} gingen zum \$place"],
        ], null)
      ],
      ["female", new Plural.from("number",
        [
          ["one", "\$names ging in dem \$place"],
          ["other", "\$names gingen zum \$place"],
        ], null)
      ]
    ], null
  )),
  "outerPlural" : writer.write(new Plural.from("n",
      [
        ['zero', 'Null'],
        ['one', 'ein'],
        ['other', 'einige']
      ], null)),
  "outerGender" : writer.write(new Gender.from("g",
      [
        ['male', 'Mann'],
        ['female', 'Frau'],
        ['other', 'andere'],
      ], null)),
  "pluralThatFailsParsing" : writer.write(new Plural.from("noOfThings",
      [
        ['one', 'eins:'],
        ['other', '\$noOfThings Dinge:']
      ], null)),
  "nestedOuter" : writer.write (new Plural.from("number",
      [
        ['other', new Gender.from("gen",
          [["male", "\$number Mann"], ["other", "\$number andere"]], null),
        ]
       ], null)),
  "outerSelect" : writer.write(new Select.from("currency",
      [
        ['CDN', '\$amount Kanadischen dollar'],
        ['other', '\$amount einige Währung oder anderen.'],
      ], null)),
  "nestedSelect" : writer.write(new Select.from("currency",
      [
        ['CDN', new Plural.from('amount',
            [
              ["other", '\$amount Kanadischen dollar'],
              ["one", '\$amount Kanadischer dollar'],
            ], null)
        ],
        ['other', 'whatever'],
      ], null)),
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
  file.writeAsStringSync(JSON.encode(translated));
}

main(List<String> args) {
  if (args.length == 0) {
    print('Usage: make_hardcoded_translation [--output-dir=<dir>] '
        '[originalFile.json]');
    exit(0);
  }
  var parser = new ArgParser();
  parser.addOption("output-dir", defaultsTo: '.',
      callback: (value) => targetDir = value);
  parser.parse(args);

  var fileArgs = args.where((x) => x.contains('.json'));

  var messages = JSON.decode(new File(fileArgs.first).readAsStringSync());
  translate(messages, "fr", french);
  translate(messages, "de_DE", german);
}
