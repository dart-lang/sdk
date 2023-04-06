// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/services/user_prompts/user_prompts.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:path/src/context.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UserPromptPreferencesTest);
  });
}

@reflectiveTest
class UserPromptPreferencesTest with ResourceProviderMixin {
  late final preferences = UserPromptPreferences(
    _optionalStateResourceProvider,
    NoopInstrumentationService(),
  );

  late final preferencesFile = preferences.preferencesFile;

  late final _optionalStateResourceProvider =
      _OptionalStateMemoryResourceProvider(resourceProvider);

  String get currentFileContents => preferencesFile!.readAsStringSync();

  Map<String, Object?> get currentFileJson =>
      jsonDecode(currentFileContents) as Map<String, Object?>;

  bool get fileExists => preferencesFile!.exists;

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
    preferencesFile!.writeAsStringSync('Not JSON');

    expect(preferences.showDartFixPrompts, isTrue);

    // Ensure we can persist over the corrupt file.
    preferences.showDartFixPrompts = false;
    expect(
      currentFileJson,
      {'showDartFixPrompts': false},
    );
  }

  /// Test that we default to showing the prompt if the file doesn't exist.
  Future<void> test_noFile() async {
    expect(fileExists, isFalse);
    expect(preferences.canPersist, isTrue);
    expect(preferences.showDartFixPrompts, isTrue);
  }

  /// Test that we don't show prompts if we can't persist an opt-out.
  Future<void> test_noStateLocation() async {
    // Simulate getStateLocation() returning null.
    _optionalStateResourceProvider.returnNullStateLocation = true;

    expect(preferences.canPersist, isFalse);
    expect(preferences.showDartFixPrompts, isFalse);
    preferences.showDartFixPrompts = true; // ignored
    expect(preferences.showDartFixPrompts, isFalse);
  }

  Future<void> test_readsExternallyUpdatedFile() async {
    // Write our own value.
    preferences.showDartFixPrompts = true;
    expect(
      currentFileJson,
      {'showDartFixPrompts': true},
    );

    // Update the file directly to another value.
    preferencesFile!.writeAsStringSync(
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

/// Wraps [MemoryResourceProvider] making [getStateLocation] return a nullable
/// [Folder] since the standard implementation of [MemoryResourceProvider]
/// removes the option for null.
class _OptionalStateMemoryResourceProvider implements ResourceProvider {
  /// Whether to return [null] from [getStateLocation] instead of an in-memory
  /// folder.
  bool returnNullStateLocation = false;

  final MemoryResourceProvider _provider;

  _OptionalStateMemoryResourceProvider(this._provider);

  @override
  Context get pathContext => _provider.pathContext;

  @override
  File getFile(String path) => _provider.getFile(path);

  @override
  Folder getFolder(String path) => _provider.getFolder(path);

  @override
  Resource getResource(String path) => _provider.getResource(path);

  @override
  Folder? getStateLocation(String name) {
    return returnNullStateLocation ? null : _provider.getStateLocation(name);
  }
}
