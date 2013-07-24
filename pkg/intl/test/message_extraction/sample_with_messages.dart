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
import "package:intl/message_lookup_by_library.dart";
import "dart:async";
import "package:intl/src/intl_helpers.dart";
import "foo_messages_all.dart";

part 'part_of_sample_with_messages.dart';

message1() => Intl.message("This is a message", name: 'message1', desc: 'foo' );

message2(x) => Intl.message("Another message with parameter $x",
    name: 'message2', desc: 'Description 2', args: [x]);

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
alwaysAccented() =>
    Intl.message("This string is always translated", locale: 'fr',
        name: 'alwaysTranslated');

// Test interpolation with curly braces around the expression, but it must
// still be just a variable reference.
trickyInterpolation(s) =>
    Intl.message("Interpolation is tricky when it ends a sentence like ${s}.",
        name: 'trickyInterpolation', args: [s]);

leadingQuotes() => Intl.message("\"So-called\"", name: 'leadingQuotes');

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

// A standalone gender message where we don't provide name or args. This should
// be rejected by validation code.
invalidOuterGender(g) => Intl.gender(g, other: 'o');

// A trivial nested plural/gender where both are done directly rather than
// in interpolations.
nestedOuter(number, gen) => Intl.plural(number,
    other: Intl.gender(gen, male: "$number male", other: "$number other"),
    name: 'nestedOuter',
    args: [number, gen]);

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

  // A function that is unnamed and assigned to a variable. It's also nested
  // within another function definition.
  var messageVariable = (a, b, c) => Intl.message(
      "Characters that need escaping, e.g slashes \\ dollars \${ (curly braces "
      "are ok) and xml reserved characters <& and quotes \" "
      "parameters $a, $b, and $c",
      name: 'message3',
      args: [a, b, c]);

  print("-------------------------------------------");
  print("Printing messages for ${locale.locale}");
  Intl.withLocale(locale.locale, () {
    print(message1());
    print(message2("hello"));
    print(messageVariable(1,2,3));
    print(multiLine());
    print(types(1, "b", ["c", "d"]));
    print(leadingQuotes());
    print(alwaysAccented());
    print(trickyInterpolation("this"));
    var thing = new YouveGotMessages();
    print(thing.method());
    print(thing.nonLambda());
    var x = YouveGotMessages.staticMessage();
    print(YouveGotMessages.staticMessage());
    print(notAlwaysTranslated());
    print(originalNotInBMP());
    print(escapable());

    print(thing.plurals(0));
    print(thing.plurals(1));
    print(thing.plurals(2));
    var alice = new Person("Alice", "female");
    var bob = new Person("Bob", "male");
    var cat = new Person("cat", null);
    print(thing.whereTheyWent(alice, "house"));
    print(thing.whereTheyWent(bob, "house"));
    print(thing.whereTheyWent(cat, "litter box"));
    print(thing.nested([alice, bob], "magasin"));
    print(thing.nested([alice], "magasin"));
    print(thing.nested([], "magasin"));
    print(thing.nested([bob, bob], "magasin"));
    print(thing.nested([alice, alice], "magasin"));

    print(outerPlural(0));
    print(outerPlural(1));
    print(outerGender("male"));
    print(outerGender("female"));
    print(nestedOuter(7, "male"));
  });
}

var localeToUse = 'en_US';

main() {
  var fr = new Intl("fr");
  var english = new Intl("en_US");
  var de = new Intl("de_DE");
  initializeMessages(fr.locale).then((_) => printStuff(fr));
  initializeMessages(de.locale).then((_) => printStuff(de));
  printStuff(english);
}