// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library message_extraction_test;

import 'package:unittest/unittest.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import '../data_directory.dart';

final dart = Platform.executable;

// TODO(alanknight): We have no way of knowing what the package-root is,
// so when we're running under the test framework, which sets the
// package-root, we use a horrible hack and infer it from the executable.
final packageDir = _findPackageDir(dart);

/**
 * Find our package directory from the executable. If we seem to be running
 * from out/Release<arch>/dart or the equivalent Debug, then use the packages
 * directory under Release<arch>. Otherwise return null, indicating to use
 * the normal pub packages directory.
 */
String _findPackageDir(executable) {
  var oneUp = path.dirname(executable);
  var tail = path.basename(oneUp);
  // If we're running from test.dart, we want e.g. out/ReleaseIA32/packages
  if (tail.contains('Release') || tail.contains('Debug')) {
      return path.join(oneUp, 'packages/');
  }
  // Check for the case where we're running Release<arch>/dart-sdk/bin/dart
  // (pub bots)
  var threeUp = path.dirname(path.dirname(oneUp));
  tail = path.basename(threeUp);
  if (tail.contains('Release') || tail.contains('Debug')) {
      return path.join(threeUp, 'packages/');
  }
  // Otherwise we will rely on the normal packages directory.
  return null;
}

/** If our package root directory is set, return it as a VM argument. */
final vmArgs = (packageDir == null) ? [] : ['--package-root=$packageDir'];

/**
 * Translate a file path into this test directory, regardless of the
 * working directory.
 */
String dir([String s]) {
  if (s != null && s.startsWith("--")) { // Don't touch command-line options.
    return s;
  } else {
   return path.join(intlDirectory, 'test', 'message_extraction', s);
  }
}

main() {
  test("Test round trip message extraction, translation, code generation, "
      "and printing", () {
    deleteGeneratedFiles();
    return extractMessages(null).then((result) {
      return generateTranslationFiles(result);
    }).then((result) {
      return generateCodeFromTranslation(result);
    }).then((result) {
      return runGeneratedCode(result);
    }).then(verifyResult)
    .whenComplete(deleteGeneratedFiles);
  });
}

void deleteGeneratedFiles() {
  var files = [dir('intl_messages.json'), dir('translation_fr.json'),
      dir('foo_messages_fr.dart'), dir('foo_messages_de_DE.dart'),
      dir('translation_de_DE.json'), dir('foo_messages_all.dart')];
  files.map((name) => new File(name)).forEach((x) {
    if (x.existsSync()) x.deleteSync();});
}

/**
 * Run the process with the given list of filenames, which we assume
 * are in dir() and need to be qualified in case that's not our working
 * directory.
 */
Future<ProcessResult> run(ProcessResult previousResult, List<String> filenames)
{
  // If there's a failure in one of the sub-programs, print its output.
  if (previousResult != null) {
    if (previousResult.exitCode != 0) {
      print("Error running sub-program:");
    }
    print(previousResult.stdout);
    print(previousResult.stderr);
    print("exitCode=${previousResult.exitCode}");
  }
  var filesInTheRightDirectory = filenames.map((x) => dir(x)).toList();
  // Inject the script argument --output-dir in between the script and its
  // arguments.
  var args = []
      ..addAll(vmArgs)
      ..add(filesInTheRightDirectory.first)
      ..addAll(["--output-dir=${dir()}"])
      ..addAll(filesInTheRightDirectory.skip(1));
  var result = Process.run(dart, args);
  return result;
}

Future<ProcessResult> extractMessages(ProcessResult previousResult) => run(
    previousResult,
    ['extract_to_json.dart', '--suppress-warnings', 'sample_with_messages.dart',
        'part_of_sample_with_messages.dart']);

Future<ProcessResult> generateTranslationFiles(ProcessResult previousResult) =>
    run(
        previousResult,
        ['make_hardcoded_translation.dart', 'intl_messages.json']);

Future<ProcessResult> generateCodeFromTranslation(ProcessResult previousResult)
    => run(
        previousResult,
        ['generate_from_json.dart', '--generated-file-prefix=foo_',
         'sample_with_messages.dart',
             'part_of_sample_with_messages.dart', 'translation_fr.json',
             'translation_de_DE.json' ]);

Future<ProcessResult> runGeneratedCode(ProcessResult previousResult) =>
    run(previousResult, ['sample_with_messages.dart']);

verifyResult(results) {
  var lineIterator;
  verify(String s) {
    lineIterator.moveNext();
    var value = lineIterator.current;
    expect(value, s);
  }

  var output = results.stdout;
  var lines = output.split("\n");
  // If it looks like these are CRLF delimited, then use that.
  if (lines.first.endsWith("\r")) {
    lines = output.split("\r\n");
  }
  lineIterator = lines.iterator..moveNext();
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

  var fr_lines = lines.skip(1).skipWhile(
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
}
