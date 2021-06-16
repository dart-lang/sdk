// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(bkonyi): remove once package:devtools_server_api is available
// See https://github.com/flutter/devtools/issues/2958.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:usage/usage_io.dart';

import 'file_system.dart';

/// Access the file '~/.flutter'.
class FlutterUsage {
  /// Create a new Usage instance; [versionOverride] and [configDirOverride] are
  /// used for testing.
  FlutterUsage({
    String settingsName = 'flutter',
    String? versionOverride,
    String? configDirOverride,
  }) {
    _analytics = AnalyticsIO('', settingsName, '');
  }

  late Analytics _analytics;

  /// Does the .flutter store exist?
  static bool get doesStoreExist {
    return LocalFileSystem.flutterStoreExists();
  }

  bool get isFirstRun => _analytics.firstRun;

  bool get enabled => _analytics.enabled;

  set enabled(bool value) => _analytics.enabled = value;

  String get clientId => _analytics.clientId;
}

// Access the DevTools on disk store (~/.devtools/.devtools).
class DevToolsUsage {
  /// Create a new Usage instance; [versionOverride] and [configDirOverride] are
  /// used for testing.
  DevToolsUsage({
    String? versionOverride,
    String? configDirOverride,
  }) {
    LocalFileSystem.maybeMoveLegacyDevToolsStore();
    properties = IOPersistentProperties(
      storeName,
      documentDirPath: LocalFileSystem.devToolsDir(),
    );
  }

  static const storeName = '.devtools';

  /// The activeSurvey is the property name of a top-level property
  /// existing or created in the file ~/.devtools
  /// If the property doesn't exist it is created with default survey values:
  ///
  ///   properties[activeSurvey]['surveyActionTaken'] = false;
  ///   properties[activeSurvey]['surveyShownCount'] = 0;
  ///
  /// It is a requirement that the API apiSetActiveSurvey must be called before
  /// calling any survey method on DevToolsUsage (addSurvey, rewriteActiveSurvey,
  /// surveyShownCount, incrementSurveyShownCount, or surveyActionTaken).
  String? _activeSurvey;

  late IOPersistentProperties properties;

  static const _surveyActionTaken = 'surveyActionTaken';
  static const _surveyShownCount = 'surveyShownCount';

  void reset() {
    properties.remove('firstRun');
    properties['enabled'] = false;
  }

  bool get isFirstRun {
    properties['firstRun'] = properties['firstRun'] == null;
    return properties['firstRun'];
  }

  bool get enabled {
    if (properties['enabled'] == null) {
      properties['enabled'] = false;
    }

    return properties['enabled'];
  }

  set enabled(bool? value) {
    properties['enabled'] = value;
    return properties['enabled'];
  }

  bool surveyNameExists(String? surveyName) => properties[surveyName] != null;

  void _addSurvey(String? surveyName) {
    assert(activeSurvey == surveyName);
    rewriteActiveSurvey(false, 0);
  }

  String? get activeSurvey => _activeSurvey;

  set activeSurvey(String? surveyName) {
    _activeSurvey = surveyName;

    if (!surveyNameExists(activeSurvey)) {
      // Create the survey if property is non-existent in ~/.devtools
      _addSurvey(activeSurvey);
    }
  }

  /// Need to rewrite the entire survey structure for property to be persisted.
  void rewriteActiveSurvey(bool? actionTaken, int? shownCount) {
    properties[activeSurvey] = {
      _surveyActionTaken: actionTaken,
      _surveyShownCount: shownCount,
    };
  }

  int? get surveyShownCount {
    final prop = properties[activeSurvey];
    if (prop[_surveyShownCount] == null) {
      rewriteActiveSurvey(prop[_surveyActionTaken], 0);
    }
    return properties[activeSurvey][_surveyShownCount];
  }

  void incrementSurveyShownCount() {
    surveyShownCount; // Ensure surveyShownCount has been initialized.
    final prop = properties[activeSurvey];
    rewriteActiveSurvey(prop[_surveyActionTaken], prop[_surveyShownCount] + 1);
  }

  bool get surveyActionTaken {
    return properties[activeSurvey][_surveyActionTaken] == true;
  }

  set surveyActionTaken(bool? value) {
    final prop = properties[activeSurvey];
    rewriteActiveSurvey(value, prop[_surveyShownCount]);
  }
}

abstract class PersistentProperties {
  PersistentProperties(this.name);

  final String name;

  dynamic operator [](String key);

  void operator []=(String key, dynamic value);

  /// Re-read settings from the backing store.
  ///
  /// May be a no-op on some platforms.
  void syncSettings();
}

const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');

class IOPersistentProperties extends PersistentProperties {
  IOPersistentProperties(
    String name, {
    String? documentDirPath,
  }) : super(name) {
    final String fileName = name.replaceAll(' ', '_');
    documentDirPath ??= LocalFileSystem.devToolsDir();
    _file = File(path.join(documentDirPath, fileName));
    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
    }
    syncSettings();
  }

  IOPersistentProperties.fromFile(File file) : super(path.basename(file.path)) {
    _file = file;
    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
    }
    syncSettings();
  }

  late File _file;

  Map? _map;

  @override
  dynamic operator [](String? key) => _map![key];

  @override
  void operator []=(String? key, dynamic value) {
    if (value == null && !_map!.containsKey(key)) return;
    if (_map![key] == value) return;

    if (value == null) {
      _map!.remove(key);
    } else {
      _map![key] = value;
    }

    try {
      _file.writeAsStringSync(_jsonEncoder.convert(_map) + '\n');
    } catch (_) {}
  }

  @override
  void syncSettings() {
    try {
      String contents = _file.readAsStringSync();
      if (contents.isEmpty) contents = '{}';
      _map = jsonDecode(contents);
    } catch (_) {
      _map = {};
    }
  }

  void remove(String propertyName) {
    _map!.remove(propertyName);
  }
}
