// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(bkonyi): remove once package:devtools_server_api is available
// See https://github.com/flutter/devtools/issues/2958.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'usage.dart';

class LocalFileSystem {
  static String _userHomeDir() {
    final String envKey =
        Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
    final String? value = Platform.environment[envKey];
    return value == null ? '.' : value;
  }

  /// Returns the path to the DevTools storage directory.
  static String devToolsDir() {
    return path.join(_userHomeDir(), '.flutter-devtools');
  }

  /// Moves the .devtools file to ~/.flutter-devtools/.devtools if the .devtools file
  /// exists in the user's home directory.
  static void maybeMoveLegacyDevToolsStore() {
    final file = File(path.join(_userHomeDir(), DevToolsUsage.storeName));
    if (file.existsSync()) {
      ensureDevToolsDirectory();
      file.copySync(path.join(devToolsDir(), DevToolsUsage.storeName));
      file.deleteSync();
    }
  }

  /// Creates the ~/.flutter-devtools directory if it does not already exist.
  static void ensureDevToolsDirectory() {
    Directory('${LocalFileSystem.devToolsDir()}').createSync();
  }

  /// Returns a DevTools file from the given path.
  ///
  /// Only files within ~/.flutter-devtools/ can be accessed.
  static File? devToolsFileFromPath(String pathFromDevToolsDir) {
    if (pathFromDevToolsDir.contains('..')) {
      // The passed in path should not be able to walk up the directory tree
      // outside of the ~/.flutter-devtools/ directory.
      return null;
    }
    ensureDevToolsDirectory();
    final file = File(path.join(devToolsDir(), pathFromDevToolsDir));
    if (!file.existsSync()) {
      return null;
    }
    return file;
  }

  /// Returns a DevTools file from the given path as encoded json.
  ///
  /// Only files within ~/.flutter-devtools/ can be accessed.
  static String? devToolsFileAsJson(String pathFromDevToolsDir) {
    final file = devToolsFileFromPath(pathFromDevToolsDir);
    if (file == null) return null;

    final fileName = path.basename(file.path);
    if (!fileName.endsWith('.json')) return null;

    final content = file.readAsStringSync();
    final json = jsonDecode(content);
    json['lastModifiedTime'] = file.lastModifiedSync().toString();
    return jsonEncode(json);
  }

  /// Whether the flutter store file exists.
  static bool flutterStoreExists() {
    final flutterStore = File('${_userHomeDir()}/.flutter');
    return flutterStore.existsSync();
  }
}
