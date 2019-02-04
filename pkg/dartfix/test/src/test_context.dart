// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server_client/protocol.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartfix/src/context.dart';
import 'package:test/test.dart';

class TestContext with ResourceProviderMixin implements Context {
  @override
  String get workingDir => convertPath('/usr/some/non/existing/directory');

  @override
  bool exists(String filePath) => true;

  @override
  void exit(int code) {
    throw TestExit(code);
  }

  @override
  bool isDirectory(String filePath) => !filePath.endsWith('.dart');
}

class TestExit {
  final int code;

  TestExit(this.code);

  @override
  String toString() => 'TestExit($code)';
}

class TestLogger implements Logger {
  final Ansi ansi;
  final stdoutBuffer = new StringBuffer();
  final stderrBuffer = new StringBuffer();

  TestLogger() : this.ansi = new Ansi(false);

  @override
  void flush() {}

  @override
  bool get isVerbose => false;

  @override
  Progress progress(String message) {
    return new SimpleProgress(this, message);
  }

  @override
  void stderr(String message) {
    stderrBuffer.writeln(message);
  }

  @override
  void stdout(String message) {
    stdoutBuffer.writeln(message);
  }

  @override
  void trace(String message) {}
}

void expectHasSuggestion(
    List<DartFixSuggestion> suggestions, String expectedText) {
  for (DartFixSuggestion suggestion in suggestions) {
    if (suggestion.description.contains(expectedText)) {
      return;
    }
  }
  fail('Failed to find suggestion containing: $expectedText');
}

void expectDoesNotHaveSuggestion(
    List<DartFixSuggestion> suggestions, String expectedText) {
  for (DartFixSuggestion suggestion in suggestions) {
    if (suggestion.description.contains(expectedText)) {
      fail('Did not expect to find suggestion containing: $expectedText');
    }
  }
}

File findFile(String relPath) {
  Directory dir = Directory.current;
  while (true) {
    final file = new File.fromUri(dir.uri.resolve(relPath));
    if (file.existsSync()) {
      return file;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Failed to find $relPath');
    }
    dir = parent;
  }
}

String findValue(File pubspec, String key) {
  List<String> lines = pubspec.readAsLinesSync();
  for (String line in lines) {
    if (line.trim().startsWith('$key:')) {
      return line.split(':')[1].trim();
    }
  }
  fail('Failed to find $key in ${pubspec.path}');
}
