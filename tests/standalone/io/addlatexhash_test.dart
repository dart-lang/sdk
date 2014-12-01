#!/usr/bin/env dart
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// testing ../../../tools/addlatexhash.dart

import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../tools/addlatexhash.dart';

final scriptDir = path.dirname(path.fromUri(Platform.script));
final dartRootDir = path.dirname(path.dirname(path.dirname(scriptDir)));
final dartRootPath = dartRootDir.toString();

// Check that the given ProcessResult indicates success; if so
// return the standard output, otherwise report the failure
checkAction(result, errorMessage) {
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    throw errorMessage;
  }
  return result.stdout;
}

oneTestCutMatch(line, re, expected) {
  var result = cutMatch(line, new RegExp(re).firstMatch(line));
  if (result != expected) {
    throw "cutMatch '$re' from '$line' yields '$result' != '$expected'";
  }
}

void testCutMatch() {
  oneTestCutMatch("test", "", "test");
  oneTestCutMatch("test", "e", "tst");
  oneTestCutMatch("test", "te", "st");
  oneTestCutMatch("test", "st", "te");
  oneTestCutMatch("test", "test", "");
}

oneTestSisp(sispFun, nameSuffix, line, expected) {
  var result = sispFun(line);
  if (result != expected) {
    throw "sispIsDart$nameSuffix '$line' yields $result";
  }
}

testSisp() {
  oneTestSisp(sispIsDartBegin, "Begin", "\\begin{dartCode}\n", true);
  oneTestSisp(sispIsDartBegin, "Begin", " \\begin{dartCode}\n", true);
  oneTestSisp(sispIsDartBegin, "Begin", "whatever else ..", false);
  oneTestSisp(sispIsDartEnd, "End", "\\end{dartCode}", true);
  oneTestSisp(sispIsDartEnd, "End", " \\end{dartCode}\t  \n", true);
  oneTestSisp(sispIsDartEnd, "End", "whatever else ..", false);
}

// Check that the hash values of paragraphs in the specially prepared
// LaTeX source 'addlatexhash_test_src.tex' are identical in groups
// of eight (so we get 8 identical hash values, then another hash
// value 8 times, etc.)
testSameHash() {
  // set up temporary directory to hold output
  final tmpDir = Directory.systemTemp.createTempSync("addlatexhash_test");
  final tmpDirPath = tmpDir.path;

  // file names/paths for file containing groups of 8 variants of a paragraph
  const par8timesName = "addlatexhash_test_src";
  const par8timesFileName = "$par8timesName.tex";
  final par8timesDirPath = path.join(dartRootDir, "tests", "standalone", "io");
  final par8timesPath = path.join(par8timesDirPath, par8timesFileName);
  final tmpPar8timesPath = path.join(tmpDirPath, par8timesFileName);

  // file names paths for output
  final hashName = par8timesName + "-hash";
  final hashFileName = "$hashName.tex";
  final hashPath = path.join(tmpDirPath, hashFileName);
  final listName = par8timesName + "-list";
  final listFileName = "$listName.txt";
  final listPath = path.join(tmpDirPath, listFileName);

  // dart executable
  final dartExecutable = Platform.executable;
  if (dartExecutable == "") throw "dart executable not available";

  // actions to take
  runAddHash() =>
      Process.runSync(dartExecutable,
                      [path.join(dartRootPath, "tools", "addlatexhash.dart"),
                       tmpPar8timesPath,
                       hashPath,
                       listPath]);

  // perform test
  new File(par8timesPath).copySync(tmpPar8timesPath);
  checkAction(runAddHash(), "addlatexhash.dart failed");
  var listFile = new File(listPath);
  var listLines = listFile.readAsLinesSync();
  var latestLine = null;
  var sameCount = 0;
  for (var line in listLines) {
    if (!line.startsWith("  ")) continue; // section marker
    if (line.startsWith("  %")) continue; // transformed text "comment"
    if (line != latestLine) {
      // new hash, check for number of equal hashes, then reset
      if (sameCount % 8 == 0) {
        // saw zero or more blocks of 8 identical hash values: OK
        latestLine = line;
        sameCount = 1;
      } else {
        throw "normalization failed to produce same result";
      }
    } else {
      sameCount++;
    }
  }
}

// Check that the LaTeX source transformation done by addlatexhash.dart
// does not affect the generated output, as seen via dvi2tty and diff.
// NB: Not part of normal testing (only local): latex and dvi2tty are
// not installed in the standard test environment.
testSameDVI() {
  // set up /tmp directory to hold output
  final tmpDir = Directory.systemTemp.createTempSync("addlatexhash_test");
  final tmpDirPath = tmpDir.path;

  // file names/paths for original spec
  const specName = "dartLangSpec";
  const specFileName = "$specName.tex";
  final specDirPath = path.join(dartRootDir, "docs", "language");
  final specPath = path.join(specDirPath, specFileName);
  final tmpSpecPath = path.join(tmpDirPath, specFileName);
  const specDviFileName = "$specName.dvi";
  final specDviPath = path.join(tmpDirPath, specDviFileName);

  // file names/paths for associated sty
  const styFileName = "dart.sty";
  final styPath = path.join(specDirPath, styFileName);
  final tmpStyPath = path.join(tmpDirPath, styFileName);

  // file names paths for output
  const hashName = "dartLangSpec-hash";
  const hashFileName = "$hashName.tex";
  final hashPath = path.join(tmpDirPath, hashFileName);
  final hashDviPath = path.join(tmpDirPath, "$hashName.dvi");

  final listName = "$specName-list";
  final listFileName = "$listName.txt";
  final listPath = path.join(tmpDirPath, listFileName);

  // dart executable
  final dartExecutable = Platform.executable;
  if (dartExecutable == "") throw "dart executable not available";

  // actions to take; rely on having latex and dvi2tty in PATH
  runLatex(fileName,workingDirectory) =>
      Process.runSync("latex", [fileName], workingDirectory: workingDirectory);

  runAddHash() =>
      Process.runSync(dartExecutable,
                      [path.join(dartRootPath, "tools", "addlatexhash.dart"),
                       tmpSpecPath,
                       hashPath,
                       listPath]);

  runDvi2tty(dviFile) =>
      Process.runSync("dvi2tty", [dviFile], workingDirectory: tmpDir.path);

  chkDvi2tty(file, subject) =>
      checkAction(runDvi2tty(file), "dvitty on $subject failed");

  // perform test
  var renewLMHashCmd = r"\renewcommand{\LMHash}[1]{\OriginalLMHash{xxxx}}";
  new File(styPath)
      .copySync(tmpStyPath)
      .writeAsStringSync(renewLMHashCmd, mode: FileMode.APPEND);
  new File(specPath).copySync(tmpSpecPath);

  checkAction(runAddHash(),"addlatexhash.dart failed");
  for (var i = 0; i < 5; i++) {
    checkAction(runLatex(specName, tmpDirPath), "LaTeX on spec failed");
  }
  for (var i = 0; i < 5; i++) {
    checkAction(runLatex(hashFileName, tmpDirPath), "LaTeX on output failed");
  }
  if (chkDvi2tty(specDviPath, "spec") != chkDvi2tty(hashDviPath, "output")) {
    throw "dvi2tty spec != dvitty output";
  }
}

main([args]) {
  testCutMatch();
  testSisp();
  testSameHash();
  // latex and dvi2tty are not installed in the standard test environment
  if (args.length > 0 && args[0] == "local") testSameDVI();
}
