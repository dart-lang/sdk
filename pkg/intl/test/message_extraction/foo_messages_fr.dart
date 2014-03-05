/**
 * DO NOT EDIT. This is code generated via pkg/intl/generate_localized.dart
 * This is a library that provides messages for a fr locale. All the
 * messages from the main program should be duplicated here with the same
 * function name.
 */

library messages_fr;
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

class MessageLookup extends MessageLookupByLibrary {

  get localeName => 'fr';
  static alwaysTranslated() => "Cette chaîne est toujours traduit";

  static differentNameSameContents() => "Bonjour tout le monde";

  static escapable() => "Escapes: \n\r\f\b\t\v.";

  static leadingQuotes() => "\"Soi-disant\"";

  static message1() => "Il s\'agit d\'un message";

  static message2(x) => "Un autre message avec un seul paramètre $x";

  static message3(a, b, c) => "Caractères qui doivent être échapper, par exemple barres \\ dollars \${ (les accolades sont ok), et xml/html réservés <& et des citations \" avec quelques paramètres ainsi $a, $b, et $c";

  static method() => "Cela vient d\'une méthode";

  static multiLine() => "Cette message prend plusiers lignes.";

  static nestedMessage(names, number, combinedGender, place) => "${Intl.gender(combinedGender, female: '${Intl.plural(number, one: '$names était allée à la $place', other: '$names étaient allées à la $place')}', other: '${Intl.plural(number, zero: 'Personne n\'avait allé à la $place', one: '${names} était allé à la $place', other: '${names} étaient allés à la $place')}')}";

  static nestedOuter(number, gen) => "${Intl.plural(number, other: '${Intl.gender(gen, male: '$number homme', other: '$number autre')}')}";

  static nestedSelect(currency, amount) => "${Intl.select(currency, {'CDN': '${Intl.plural(amount, one: '$amount dollar Canadien', other: '$amount dollars Canadiens')}', 'other': 'Nimporte quoi', })}";

  static nonLambda() => "Cette méthode n\'est pas un lambda";

  static notAlwaysTranslated() => "Ce manque certaines traductions";

  static originalNotInBMP() => "Anciens caractères grecs jeux du pendu: 𐅆𐅇.";

  static outerGender(g) => "${Intl.gender(g, female: 'femme', male: 'homme', other: 'autre')}";

  static outerPlural(n) => "${Intl.plural(n, zero: 'rien', one: 'un', other: 'quelques-uns')}";

  static outerSelect(currency, amount) => "${Intl.select(currency, {'CDN': '$amount dollars Canadiens', 'other': '$amount certaine devise ou autre.', })}";

  static pluralThatFailsParsing(noOfThings) => "${Intl.plural(noOfThings, one: '1 chose:', other: '$noOfThings choses:')}";

  static plurals(num) => "${Intl.plural(num, zero: 'Est-ce que nulle est pluriel?', one: 'C\'est singulier', other: 'C\'est pluriel ($num).')}";

  static sameContentsDifferentName() => "Bonjour tout le monde";

  static rentAsVerb() => "louer";

  static rentToBePaid() => "loyer";

  static staticMessage() => "Cela vient d\'une méthode statique";

  static trickyInterpolation(s) => "L\'interpolation est délicate quand elle se termine une phrase comme ${s}.";

  static types(a, b, c) => "$a, $b, $c";

  static whereTheyWentMessage(name, gender, place) => "${Intl.gender(gender, female: '${name} est allée à sa ${place}', male: '${name} est allé à sa ${place}', other: '${name} est allé à sa ${place}')}";


  final messages = const {
    "alwaysTranslated" : alwaysTranslated,
    "differentNameSameContents" : differentNameSameContents,
    "escapable" : escapable,
    "leadingQuotes" : leadingQuotes,
    "message1" : message1,
    "message2" : message2,
    "message3" : message3,
    "method" : method,
    "multiLine" : multiLine,
    "nestedMessage" : nestedMessage,
    "nestedOuter" : nestedOuter,
    "nestedSelect" : nestedSelect,
    "nonLambda" : nonLambda,
    "notAlwaysTranslated" : notAlwaysTranslated,
    "originalNotInBMP" : originalNotInBMP,
    "outerGender" : outerGender,
    "outerPlural" : outerPlural,
    "outerSelect" : outerSelect,
    "pluralThatFailsParsing" : pluralThatFailsParsing,
    "plurals" : plurals,
    "sameContentsDifferentName" : sameContentsDifferentName,
    "rentAsVerb" : rentAsVerb,
    "rentToBePaid" : rentToBePaid,
    "staticMessage" : staticMessage,
    "trickyInterpolation" : trickyInterpolation,
    "types" : types,
    "whereTheyWentMessage" : whereTheyWentMessage
  };
}