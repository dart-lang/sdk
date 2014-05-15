// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is a program with various [Intl.message] messages. It just prints
 * all of them, and is used for testing of message extraction, translation,
 * and code generation.
 */
library sample;

import "package:intl/intl.dart";
import "foo_messages_all.dart";
import "print_to_list.dart";
import "dart:async";
import "package:unittest/unittest.dart";

part 'part_of_sample_with_messages.dart';

message1() => Intl.message("This is a message", name: 'message1', desc: 'foo' );

message2(x) => Intl.message("Another message with parameter $x",
    name: 'message2', desc: 'Description 2', args: [x], examples: {'x' : 3});

// A string with multiple adjacent strings concatenated together, verify
// that the parser handles this properly.
multiLine() => Intl.message("This "
    "string "
    "extends "
    "across "
    "multiple "
    "lines.",
    name: "multiLine");

// Have types on the enclosing function's arguments.
types(int a, String b, List c) => Intl.message("$a, $b, $c", name: 'types',
    args: [a, b, c]);

// This string will be printed with a French locale, so it will always show
// up in the French version, regardless of the current locale.
alwaysTranslated() =>
    Intl.message("This string is always translated", locale: 'fr',
        name: 'alwaysTranslated');

// Test interpolation with curly braces around the expression, but it must
// still be just a variable reference.
trickyInterpolation(s) =>
    Intl.message("Interpolation is tricky when it ends a sentence like ${s}.",
        name: 'trickyInterpolation', args: [s]);

get leadingQuotes => Intl.message("\"So-called\"", name: 'leadingQuotes');

// A message with characters not in the basic multilingual plane.
originalNotInBMP() => Intl.message("Ancient Greek hangman characters: 𐅆𐅇.",
    name: "originalNotInBMP");

// A string for which we don't provide all translations.
notAlwaysTranslated() => Intl.message("This is missing some translations",
    name: "notAlwaysTranslated");

// This is invalid and should be recognized as such, because the message has
// to be a literal. Otherwise, interpolations would be outside of the function
// scope.
var someString = "No, it has to be a literal string";
noVariables() => Intl.message(someString, name: "noVariables");

// This is unremarkable in English, but the translated versions will contain
// characters that ought to be escaped during code generation.
escapable() => Intl.message("Escapable characters here: ", name: "escapable");

outerPlural(n) => Intl.plural(n, zero: 'none', one: 'one', other: 'some',
    name: 'outerPlural', desc: 'A plural with no enclosing message', args: [n]);

outerGender(g) => Intl.gender(g, male: 'm', female: 'f', other: 'o',
    name: 'outerGender', desc: 'A gender with no enclosing message', args: [g]);

pluralThatFailsParsing(noOfThings) => Intl.plural(noOfThings,
    one: "1 thing:",
    other: "$noOfThings things:",
    name: "pluralThatFailsParsing",
    args: [noOfThings],
    desc: "How many things are there?");

// A standalone gender message where we don't provide name or args. This should
// be rejected by validation code.
invalidOuterGender(g) => Intl.gender(g, other: 'o');

// A general select
outerSelect(currency, amount) => Intl.select(currency,
    {
      "CDN" : "$amount Canadian dollars",
      "other" : "$amount some currency or other."
    },
    name: "outerSelect",
    args: [currency, amount]);

// A select with a plural inside the expressions.
nestedSelect(currency, amount) => Intl.select(currency,
    {
      "CDN" : """${Intl.plural(amount, one: '$amount Canadian dollar',
          other: '$amount Canadian dollars')}""",
      "other" : "Whatever",
    },
    name: "nestedSelect",
    args: [currency, amount]);

// A trivial nested plural/gender where both are done directly rather than
// in interpolations.
nestedOuter(number, gen) => Intl.plural(number,
    other: Intl.gender(gen, male: "$number male", other: "$number other"),
    name: 'nestedOuter',
    args: [number, gen]);

sameContentsDifferentName() => Intl.message("Hello World",
    name: "sameContentsDifferentName",
    desc: "One of two messages with the same contents, but different names");

differentNameSameContents() => Intl.message("Hello World",
    name: "differentNameSameContents",
    desc: "One of two messages with the same contents, but different names");

/// Distinguish two messages with identical text using the meaning parameter.
rentToBePaid() => Intl.message("rent", name: "rentToBePaid",
    meaning: 'Money for rent', desc: "Money to be paid for rent");

rentAsVerb() => Intl.message("rent", name: "rentAsVerb",
    meaning: 'rent as a verb', desc: "The action of renting, as in rent a car");

printStuff(Intl locale) {

  // Use a name that's not a literal so this will get skipped. Then we have
  // a name that's not in the original but we include it in the French
  // translation. Because it's not in the original it shouldn't get included
  // in the generated catalog and shouldn't get translated.
  if (locale.locale == 'fr') {
    var badName = "thisNameIsNotInTheOriginal";
    var notInOriginal = Intl.message("foo", name: badName);
    if (notInOriginal != "foo") {
      throw "You shouldn't be able to introduce a new message in a translation";
    }
  }

  // A function that is assigned to a variable. It's also nested
  // within another function definition.
  message3(a, b, c) => Intl.message(
      "Characters that need escaping, e.g slashes \\ dollars \${ (curly braces "
      "are ok) and xml reserved characters <& and quotes \" "
      "parameters $a, $b, and $c",
      name: 'message3',
      args: [a, b, c]);
  var messageVariable = message3;

  printOut("-------------------------------------------");
  printOut("Printing messages for ${locale.locale}");
  Intl.withLocale(locale.locale, () {
    printOut(message1());
    printOut(message2("hello"));
    printOut(messageVariable(1,2,3));
    printOut(multiLine());
    printOut(types(1, "b", ["c", "d"]));
    printOut(leadingQuotes);
    printOut(alwaysTranslated());
    printOut(trickyInterpolation("this"));
    var thing = new YouveGotMessages();
    printOut(thing.method());
    printOut(thing.nonLambda());
    var x = YouveGotMessages.staticMessage();
    printOut(YouveGotMessages.staticMessage());
    printOut(notAlwaysTranslated());
    printOut(originalNotInBMP());
    printOut(escapable());

    printOut(thing.plurals(0));
    printOut(thing.plurals(1));
    printOut(thing.plurals(2));
    printOut(thing.plurals(3));
    printOut(thing.plurals(4));
    printOut(thing.plurals(5));
    printOut(thing.plurals(6));
    printOut(thing.plurals(7));
    printOut(thing.plurals(8));
    printOut(thing.plurals(9));
    printOut(thing.plurals(10));
    printOut(thing.plurals(11));
    printOut(thing.plurals(20));
    printOut(thing.plurals(100));
    printOut(thing.plurals(101));
    printOut(thing.plurals(100000));
    var alice = new Person("Alice", "female");
    var bob = new Person("Bob", "male");
    var cat = new Person("cat", null);
    printOut(thing.whereTheyWent(alice, "house"));
    printOut(thing.whereTheyWent(bob, "house"));
    printOut(thing.whereTheyWent(cat, "litter box"));
    printOut(thing.nested([alice, bob], "magasin"));
    printOut(thing.nested([alice], "magasin"));
    printOut(thing.nested([], "magasin"));
    printOut(thing.nested([bob, bob], "magasin"));
    printOut(thing.nested([alice, alice], "magasin"));

    printOut(outerPlural(0));
    printOut(outerPlural(1));
    printOut(outerGender("male"));
    printOut(outerGender("female"));
    printOut(nestedOuter(7, "male"));
    printOut(outerSelect("CDN", 7));
    printOut(outerSelect("EUR", 5));
    printOut(nestedSelect("CDN", 1));
    printOut(nestedSelect("CDN", 2));
    printOut(pluralThatFailsParsing(1));
    printOut(pluralThatFailsParsing(2));
    printOut(differentNameSameContents());
    printOut(sameContentsDifferentName());
    printOut(rentAsVerb());
    printOut(rentToBePaid());
  });
}

var localeToUse = 'en_US';

main() {
  var fr = new Intl("fr");
  var english = new Intl("en_US");
  var de = new Intl("de_DE");
  // Throw in an initialize of a null locale to make sure it doesn't throw.
  initializeMessages(null);

  // Verify that a translated message isn't initially present.
  var messageInGerman = Intl.withLocale('de_DE', message1);
  test("Locales don't work before they're initialized", ()
      => expect(messageInGerman, "This is a message"));

  var f1 = initializeMessages(fr.locale)
      // Since English has the one message which is always translated, we
      // can't print it until French is ready.
      .then((_) => printStuff(english))
      .then((_) => printStuff(fr));
  var f2 = initializeMessages('de-de').then((_) => printStuff(de));
  return Future.wait([f1, f2]);
}
