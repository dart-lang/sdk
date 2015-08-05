// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.server_options;

import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

//TODO: consider renaming (https://github.com/dart-lang/sdk/issues/23927)
const _optionsFileName = '.dart_analysis_server.yaml';

/// The shared options instance.
ServerOptions _serverOptions;

/// Server options.
ServerOptions get serverOptions {
  if (_serverOptions == null) {
    _serverOptions = _loadOptions();
  }
  return _serverOptions;
}

/// Find the options file relative to the user's home directory.
/// Returns `null` if there is none or the user's homedir cannot
/// be derived from the platform's environment (e.g., `HOME` and
/// `UserProfile` for mac/Linux and Windows respectively).
File _findOptionsFile() {
  String home;
  Map<String, String> envVars = Platform.environment;
  if (Platform.isMacOS || Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  }

  if (home == null) {
    return null;
  }

  return new File(path.context.join(home, _optionsFileName));
}

ServerOptions _loadOptions() {
  File optionsFile = _findOptionsFile();
  try {
    if (optionsFile != null && optionsFile.existsSync()) {
      return new ServerOptions.fromFile(optionsFile);
    }
  } catch (e) {
    // Fall through.
  }
  return new ServerOptions._empty();
}

/// Describes options captured in an external options file.
/// `ServerOptions` are described in a file `dart_analysis_server.options`
/// located in the user's home directory. Options are defined in YAML and
/// read once and cached. In order for changes to be picked up, server needs
/// to be restarted.
class ServerOptions {
  final Map<String, dynamic> _options = new HashMap<String, dynamic>();

  /// Load options from the given [contents].
  ServerOptions.fromContents(String contents) {
    _readOptions(contents);
  }

  /// Load options from the given [options] file.
  factory ServerOptions.fromFile(File options) =>
      new ServerOptions.fromContents(options.readAsStringSync());

  /// Create an empty options object.
  ServerOptions._empty();

  /// Get the value for `key` from the options file.
  dynamic operator [](String key) => _options[key];

  /// Get a String value for this `key` or [defaultValue] if undefined
  /// or not a String.
  String getStringValue(String key, {String defaultValue: null}) {
    var value = _options[key];
    if (value is String) {
      return value;
    }
    return defaultValue;
  }

  /// Test whether the given [booleanPropertyKey] is set to the value `true`,
  /// falling back to [defaultValue] if undefined.
  /// For example:
  ///     myDebugOption1:true
  ///     myDebugOption2:TRUE # Also true (case and trailing whitespace are ignored).
  ///     myDebugOption3:false
  ///     myDebugOption4:off  # Treated as `false`.
  ///     myDebugOption5:on   # Also read as `false`.
  bool isSet(String booleanPropertyKey, {bool defaultValue: false}) {
    var value = _options[booleanPropertyKey];
    if (value == null) {
      return defaultValue;
    }
    return value == true;
  }

  void _readOptions(String contents) {
    var doc = loadYaml(contents);
    if (doc is YamlMap) {
      doc.forEach((k, v) {
        if (k is String) {
          _options[k] = v;
        }
      });
    }
  }
}
