library verify_messages;

import "print_to_list.dart";
import "package:unittest/unittest.dart";

verifyResult(ignored) {
  test("Verify message translation output", actuallyVerifyResult);
}
actuallyVerifyResult() {
  var lineIterator;
  verify(String s) {
    lineIterator.moveNext();
    var value = lineIterator.current;
    expect(value, s);
  }

  var expanded = lines.expand((line) => line.split("\n")).toList();
  lineIterator = expanded.iterator..moveNext();
  verify("Printing messages for en_US");
  verify("This is a message");
  verify("Another message with parameter hello");
  verify("Characters that need escaping, e.g slashes \\ dollars \${ "
      "(curly braces are ok) and xml reserved characters <& and "
      "quotes \" parameters 1, 2, and 3");
  verify("This string extends across multiple lines.");
  verify("1, b, [c, d]");
  verify('"So-called"');
  verify("Cette chaîne est toujours traduit");
  verify("Interpolation is tricky when it ends a sentence like this.");
  verify("This comes from a method");
  verify("This method is not a lambda");
  verify("This comes from a static method");
  verify("This is missing some translations");
  verify("Ancient Greek hangman characters: 𐅆𐅇.");
  verify("Escapable characters here: ");

  verify('Is zero plural?');
  verify('This is singular.');
  verify('This is plural (2).');
  verify('This is plural (3).');
  verify('This is plural (4).');
  verify('This is plural (5).');
  verify('This is plural (6).');
  verify('This is plural (7).');
  verify('This is plural (8).');
  verify('This is plural (9).');
  verify('This is plural (10).');
  verify('This is plural (11).');
  verify('This is plural (20).');
  verify('This is plural (100).');
  verify('This is plural (101).');
  verify('This is plural (100000).');
  verify('Alice went to her house');
  verify('Bob went to his house');
  verify('cat went to its litter box');
  verify('Alice, Bob sont allés au magasin');
  verify('Alice est allée au magasin');
  verify('Personne n\'est allé au magasin');
  verify('Bob, Bob sont allés au magasin');
  verify('Alice, Alice sont allées au magasin');
  verify('none');
  verify('one');
  verify('m');
  verify('f');
  verify('7 male');
  verify('7 Canadian dollars');
  verify('5 some currency or other.');
  verify('1 Canadian dollar');
  verify('2 Canadian dollars');
  verify('1 thing:');
  verify('2 things:');
  verify('Hello World');
  verify('Hello World');
  verify('rent');
  verify('rent');

  var fr_lines = expanded.skip(1).skipWhile(
      (line) => !line.contains('----')).toList();
  lineIterator = fr_lines.iterator..moveNext();
  verify("Printing messages for fr");
  verify("Il s'agit d'un message");
  verify("Un autre message avec un seul paramètre hello");
  verify(
      "Caractères qui doivent être échapper, par exemple barres \\ "
      "dollars \${ (les accolades sont ok), et xml/html réservés <& et "
      "des citations \" "
      "avec quelques paramètres ainsi 1, 2, et 3");
  verify("Cette message prend plusiers lignes.");
  verify("1, b, [c, d]");
  verify('"Soi-disant"');
  verify("Cette chaîne est toujours traduit");
  verify(
      "L'interpolation est délicate quand elle se termine une "
          "phrase comme this.");
  verify("Cela vient d'une méthode");
  verify("Cette méthode n'est pas un lambda");
  verify("Cela vient d'une méthode statique");
  verify("Ce manque certaines traductions");
  verify("Anciens caractères grecs jeux du pendu: 𐅆𐅇.");
  verify("Escapes: ");
  verify("\r\f\b\t\v.");

  verify('Est-ce que nulle est pluriel?');
  verify('C\'est singulier');
  verify('C\'est pluriel (2).');
  verify('C\'est pluriel (3).');
  verify('C\'est pluriel (4).');
  verify('C\'est pluriel (5).');
  verify('C\'est pluriel (6).');
  verify('C\'est pluriel (7).');
  verify('C\'est pluriel (8).');
  verify('C\'est pluriel (9).');
  verify('C\'est pluriel (10).');
  verify('C\'est pluriel (11).');
  verify('C\'est pluriel (20).');
  verify('C\'est pluriel (100).');
  verify('C\'est pluriel (101).');
  verify('C\'est pluriel (100000).');
  verify('Alice est allée à sa house');
  verify('Bob est allé à sa house');
  verify('cat est allé à sa litter box');
  verify('Alice, Bob étaient allés à la magasin');
  verify('Alice était allée à la magasin');
  verify('Personne n\'avait allé à la magasin');
  verify('Bob, Bob étaient allés à la magasin');
  verify('Alice, Alice étaient allées à la magasin');
  verify('rien');
  verify('un');
  verify('homme');
  verify('femme');
  verify('7 homme');
  verify('7 dollars Canadiens');
  verify('5 certaine devise ou autre.');
  verify('1 dollar Canadien');
  verify('2 dollars Canadiens');
  verify('1 chose:');
  verify('2 choses:');
  verify('Bonjour tout le monde');
  verify('Bonjour tout le monde');
  verify('louer');
  verify('loyer');

  var de_lines = fr_lines.skip(1).skipWhile(
      (line) => !line.contains('----')).toList();
  lineIterator = de_lines.iterator..moveNext();
  verify("Printing messages for de_DE");
  verify("Dies ist eine Nachricht");
  verify("Eine weitere Meldung mit dem Parameter hello");
  verify(
      "Zeichen, die Flucht benötigen, zB Schrägstriche \\ Dollar "
      "\${ (geschweiften Klammern sind ok) und xml reservierte Zeichen <& und "
      "Zitate \" Parameter 1, 2 und 3");
  verify("Dieser String erstreckt sich über mehrere "
      "Zeilen erstrecken.");
  verify("1, b, [c, d]");
  verify('"Sogenannt"');
  // This is correct, the message is forced to French, even in a German locale.
  verify("Cette chaîne est toujours traduit");
  verify(
      "Interpolation ist schwierig, wenn es einen Satz wie dieser endet this.");
  verify("Dies ergibt sich aus einer Methode");
  verify("Diese Methode ist nicht eine Lambda");
  verify("Dies ergibt sich aus einer statischen Methode");
  verify("This is missing some translations");
  verify("Antike griechische Galgenmännchen Zeichen: 𐅆𐅇");
  verify("Escapes: ");
  verify("\r\f\b\t\v.");

  verify('Ist Null Plural?');
  verify('Dies ist einmalig');
  verify('Dies ist Plural (2).');
  verify('Dies ist Plural (3).');
  verify('Dies ist Plural (4).');
  verify('Dies ist Plural (5).');
  verify('Dies ist Plural (6).');
  verify('Dies ist Plural (7).');
  verify('Dies ist Plural (8).');
  verify('Dies ist Plural (9).');
  verify('Dies ist Plural (10).');
  verify('Dies ist Plural (11).');
  verify('Dies ist Plural (20).');
  verify('Dies ist Plural (100).');
  verify('Dies ist Plural (101).');
  verify('Dies ist Plural (100000).');
  verify('Alice ging zu ihrem house');
  verify('Bob ging zu seinem house');
  verify('cat ging zu seinem litter box');
  verify('Alice, Bob gingen zum magasin');
  verify('Alice ging in dem magasin');
  verify('Niemand ging zu magasin');
  verify('Bob, Bob gingen zum magasin');
  verify('Alice, Alice gingen zum magasin');
  verify('Null');
  verify('ein');
  verify('Mann');
  verify('Frau');
  verify('7 Mann');
  verify('7 Kanadischen dollar');
  verify('5 einige Währung oder anderen.');
  verify('1 Kanadischer dollar');
  verify('2 Kanadischen dollar');
  verify('eins:');
  verify('2 Dinge:');
  verify('Hallo Welt');
  verify('Hallo Welt');
  verify('mieten');
  verify('Miete');
}
