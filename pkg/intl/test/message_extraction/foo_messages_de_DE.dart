/**
 * DO NOT EDIT. This is code generated via pkg/intl/generate_localized.dart
 * This is a library that provides messages for a de_DE locale. All the
 * messages from the main program should be duplicated here with the same
 * function name.
 */

library messages_de_DE;
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

class MessageLookup extends MessageLookupByLibrary {

  get localeName => 'de_DE';
  static alwaysTranslated() => "Diese Zeichenkette wird immer übersetzt";

  static escapable() => "Escapes: \n\r\f\b\t\v.";

  static leadingQuotes() => "\"Sogenannt\"";

  static message1() => "Dies ist eine Nachricht";

  static message2(x) => "Eine weitere Meldung mit dem Parameter $x";

  static message3(a, b, c) => "Zeichen, die Flucht benötigen, zB Schrägstriche \\ Dollar \${ (geschweiften Klammern sind ok) und xml reservierte Zeichen <& und Zitate \" Parameter $a, $b und $c";

  static method() => "Dies ergibt sich aus einer Methode";

  static multiLine() => "Dieser String erstreckt sich über mehrere Zeilen erstrecken.";

  static nestedMessage(names, number, combinedGender, place) => "${Intl.gender(combinedGender, female: '${Intl.plural(number, one: '$names ging in dem $place', other: '$names gingen zum $place')}', other: '${Intl.plural(number, zero: 'Niemand ging zu $place', one: '${names} ging zum $place', other: '${names} gingen zum $place')}')}";

  static nestedOuter(number, gen) => "${Intl.plural(number, other: '${Intl.gender(gen, male: '$number Mann', other: '$number andere')}')}";

  static nestedSelect(currency, amount) => "${Intl.select(currency, {'CDN': '${Intl.plural(amount, one: '$amount Kanadischer dollar', other: '$amount Kanadischen dollar')}', 'other': 'whatever', })}";

  static nonLambda() => "Diese Methode ist nicht eine Lambda";

  static originalNotInBMP() => "Antike griechische Galgenmännchen Zeichen: 𐅆𐅇";

  static outerGender(g) => "${Intl.gender(g, female: 'Frau', male: 'Mann', other: 'andere')}";

  static outerPlural(n) => "${Intl.plural(n, zero: 'Null', one: 'ein', other: 'einige')}";

  static outerSelect(currency, amount) => "${Intl.select(currency, {'CDN': '$amount Kanadischen dollar', 'other': '$amount einige Währung oder anderen.', })}";

  static plurals(num) => "${Intl.plural(num, zero: 'Ist Null Plural?', one: 'Dies ist einmalig', other: 'Dies ist Plural ($num).')}";

  static staticMessage() => "Dies ergibt sich aus einer statischen Methode";

  static trickyInterpolation(s) => "Interpolation ist schwierig, wenn es einen Satz wie dieser endet ${s}.";

  static types(a, b, c) => "$a, $b, $c";

  static whereTheyWentMessage(name, gender, place) => "${Intl.gender(gender, female: '${name} ging zu ihrem ${place}', male: '${name} ging zu seinem ${place}', other: '${name} ging zu seinem ${place}')}";


  final messages = const {
    "alwaysTranslated" : alwaysTranslated,
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
    "originalNotInBMP" : originalNotInBMP,
    "outerGender" : outerGender,
    "outerPlural" : outerPlural,
    "outerSelect" : outerSelect,
    "plurals" : plurals,
    "staticMessage" : staticMessage,
    "trickyInterpolation" : trickyInterpolation,
    "types" : types,
    "whereTheyWentMessage" : whereTheyWentMessage
  };
}
