// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/services/user_prompts/user_prompts.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UserPromptPreferencesTest);
  });
}

@reflectiveTest
class UserPromptPreferencesTest with ResourceProviderMixin {
  late UserPromptPreferences preferences;
  late File preferencesFile;

  String get currentFileContents => preferencesFile.readAsStringSync();

  Map<String, Object?> get currentFileJson =>
      jsonDecode(currentFileContents) as Map<String, Object?>;
  bool get fileExists => preferencesFile.exists;
  void setUp() {
    preferences = UserPromptPreferences(
      resourceProvider,
      NoopInstrumentationService(),
    );
    preferencesFile = preferences.preferencesFile;
  }

  Future<void> test_createFile() async {
    expect(fileExists, isFalse);
    preferences.showDartFixPrompts = true;
    expect(fileExists, isTrue);
    expect(
      currentFileJson,
      {'showDartFixPrompts': true},
    );
  }

  Future<void> test_handlesCorruptFile() async {
    // Write a corrupt file and ensure we get the usual default (true).
    preferencesFile.writeAsStringSync('Not JSON');

    expect(preferences.showDartFixPrompts, isTrue);

    // Ensure we can persist over the corrupt file.
    preferences.showDartFixPrompts = false;
    expect(
      currentFileJson,
      {'showDartFixPrompts': false},
    );
  }

  Future<void> test_readsExternallyUpdatedFile() async {
    // Write our own value.
    preferences.showDartFixPrompts = true;
    expect(
      currentFileJson,
      {'showDartFixPrompts': true},
    );

    // Update the file directly to another value.
    preferencesFile.writeAsStringSync(
      jsonEncode({'showDartFixPrompts': false}),
    );

    // Ensure reading the flag gets the updated value.
    expect(preferences.showDartFixPrompts, isFalse);
  }

  Future<void> test_updateFile() async {
    preferences.showDartFixPrompts = true;
    expect(
      currentFileJson,
      {'showDartFixPrompts': true},
    );

    preferences.showDartFixPrompts = false;
    expect(
      currentFileJson,
      {'showDartFixPrompts': false},
    );
  }
}
