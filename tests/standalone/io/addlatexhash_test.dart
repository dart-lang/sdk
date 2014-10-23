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

// Check that the LaTeX source transformation done by addlatexhash.dart
// does not affect the generated output, as seen via dvi2tty and diff.
// NB: Not part of normal testing (only local): latex and dvi2tty are
// not installed in the standard test environment.
testNoChange() {
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

  // actions to take
  runLatex(fileName,workingDirectory) =>
      Process.runSync("latex", [fileName], workingDirectory: workingDirectory);

  runAddHash() =>
      Process.runSync("dart",
                      [path.join(dartRootPath, "tools", "addlatexhash.dart"),
                       tmpSpecPath,
                       hashPath]);

  runDvi2tty(dviFile) =>
      Process.runSync("dvi2tty", [dviFile], workingDirectory: tmpDir.path);

  chkDvi2tty(file, subject) =>
      checkAction(runDvi2tty(file), "dvitty on $subject failed");

  // perform test
  new File(styPath).copySync(tmpStyPath);
  new File(specPath).copySync(tmpSpecPath);
  for (var i = 0; i < 5; i++) {
    checkAction(runLatex(specName, tmpDirPath), "LaTeX on spec failed");
  }
  checkAction(runAddHash(),"addlatexhash.dart failed");
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
  // latex and dvi2tty are not installed in the standard test environment
  if (args.length > 0 && args[0] == "local") testNoChange();
}
