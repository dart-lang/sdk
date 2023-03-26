// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:meta/meta.dart';

/// Handles reading and writing of simple preferences for user prompts to allow
/// the user to opt-out of seeing prompts in future.
///
/// All values are read/written real-time (not cached) so that multiple server
/// instances can see each others values without restarting.
class UserPromptPreferences {
  final ResourceProvider resourceProvider;
  final InstrumentationService instrumentationService;

  final _jsonEncoder = JsonEncoder.withIndent('  ');

  /// The file for storing preferences.
  @visibleForTesting
  late final File preferencesFile;

  UserPromptPreferences(this.resourceProvider, this.instrumentationService) {
    preferencesFile = (resourceProvider.getStateLocation('.prompts')!..create())
        .getChildAssumingFile('preferences.json');
  }

  bool get showDartFixPrompts => _readBool('showDartFixPrompts', true);
  set showDartFixPrompts(bool value) => _writeBool('showDartFixPrompts', value);

  bool _readBool(String name, bool defaultValue) =>
      _readValue(name, defaultValue);

  /// Reads the preferences file and decodes as JSON.
  ///
  /// Returns `null` if the file does not exist or cannot be read/parsed for
  /// any reason.
  Map<String, Object?>? _readFile() {
    try {
      final contents = preferencesFile.readAsStringSync();
      return jsonDecode(contents) as Map<String, Object?>;
    } on FileSystemException catch (_) {
      // File did not exist, do nothing.
      return null;
    } on FormatException catch (e) {
      instrumentationService.logError(
        'Failed to parse preferences JSON from ${preferencesFile.path}: $e',
      );
      return null;
    }
  }

  /// Reads the value for [name] from the preferences file.
  ///
  /// Returns [defaultValue] if it does not exist or cannot be read for any
  /// reason.
  T _readValue<T>(String name, T defaultValue) {
    final values = _readFile();
    if (values == null) {
      return defaultValue;
    }
    final value = values[name];
    if (value is! T) {
      return defaultValue;
    }
    return value;
  }

  /// Writes [value] for [name] to the preferences file.
  ///
  /// Returns whether the write was successful. If unsuccessful, the error is
  /// written to the instrumentation log.
  bool _writeBool(String name, bool value) => _writeValue(name, value);

  /// Write [data] to the preferences file as JSON.
  ///
  /// Returns whether the write was successful. If unsuccessful, the error is
  /// written to the instrumentation log.
  bool _writeFile(Map<String, Object?> data) {
    try {
      final contents = _jsonEncoder.convert(data);
      preferencesFile.writeAsStringSync(contents);
      return true;
    } catch (e) {
      // Don't fail if we can't write (eg. file locked by another process).
      instrumentationService.logError('Failed to write prompt preferences: $e');
      return false;
    }
  }

  /// Writes [value] for [name] to the preferences file.
  ///
  /// Only [bool], [num], [String] are allowed.
  ///
  /// Returns whether the write was successful. If unsuccessful, the error is
  /// written to the instrumentation log.
  bool _writeValue<T>(String name, T value) {
    assert(value is bool || value is num || value is String);
    final data = _readFile() ?? {};
    data[name] = value;
    return _writeFile(data);
  }
}
