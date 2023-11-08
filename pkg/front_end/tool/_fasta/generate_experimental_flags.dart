// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;

import 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show $A, $MINUS, $a, $z;

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';

import 'package:dart_style/dart_style.dart' show DartFormatter;

import 'package:yaml/yaml.dart' show YamlMap, loadYaml;

import '../../test/utils/io_utils.dart' show computeRepoDirUri;

void main(List<String> arguments) {
  final Uri repoDir = computeRepoDirUri();
  new File.fromUri(computeFeAnalyzerSharedGeneratedFile(repoDir))
      .writeAsStringSync(generateFeAnalyzerSharedFile(repoDir), flush: true);
  new File.fromUri(computeCfeGeneratedFile(repoDir))
      .writeAsStringSync(generateCfeFile(repoDir), flush: true);
  new File.fromUri(computeKernelGeneratedFile(repoDir))
      .writeAsStringSync(generateKernelFile(repoDir), flush: true);
}

Uri computeFeAnalyzerSharedGeneratedFile(Uri repoDir) {
  return repoDir
      .resolve("pkg/_fe_analyzer_shared/lib/src/experiments/flags.dart");
}

Uri computeCfeGeneratedFile(Uri repoDir) {
  return repoDir.resolve(
      "pkg/front_end/lib/src/api_prototype/experimental_flags_generated.dart");
}

Uri computeKernelGeneratedFile(Uri repoDir) {
  return repoDir.resolve("pkg/kernel/lib/default_language_version.dart");
}

Uri computeYamlFile(Uri repoDir) {
  return repoDir.resolve("tools/experimental_features.yaml");
}

Uri computeAllowListFile(Uri repoDir) {
  return repoDir.resolve("sdk/lib/_internal/allowed_experiments.json");
}

String _getFeatureCategory(Map<dynamic, dynamic> feature) {
  return feature["category"] ?? "language";
}

bool _isLanguageFeature(String category) {
  return category == "language";
}

bool _isCfeFeature(String category) {
  return _isLanguageFeature(category) || category == "CFE";
}

String generateFeAnalyzerSharedFile(Uri repoDir) {
  Uri yamlFile = computeYamlFile(repoDir);
  Map<dynamic, dynamic> yaml =
      loadYaml(new File.fromUri(yamlFile).readAsStringSync());

  StringBuffer sb = new StringBuffer();

  sb.write('''
// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/front_end/tool/fasta.dart generate-experimental-flags' to update.
''');

  int currentVersionMajor;
  int currentVersionMinor;
  {
    String currentVersion = getAsVersionNumberString(yaml['current-version'])!;
    List<String> split = currentVersion.split(".");
    currentVersionMajor = int.parse(split[0]);
    currentVersionMinor = int.parse(split[1]);
  }
  sb.write('''
const Version defaultLanguageVersion = const Version($currentVersionMajor, $currentVersionMinor);

/// Enum for experimental flags shared between the CFE and the analyzer.
enum ExperimentalFlag {
''');

  Map<String, dynamic> features = {};
  Map<dynamic, dynamic> yamlFeatures = yaml['features'];
  for (MapEntry<dynamic, dynamic> entry in yamlFeatures.entries) {
    String category = _getFeatureCategory(entry.value);
    if (!_isLanguageFeature(category)) {
      // Skip a feature with a category that's not language.
      // In the future we might want to generate different code for different
      // things.
      continue;
    }
    features[entry.key] = entry.value;
  }

  List<String> keys = features.keys.toList()..sort();
  for (String key in keys) {
    String identifier = keyToIdentifier(key);
    String enabledInVersion;
    String? enabledIn =
        getAsVersionNumberString((features[key] as YamlMap)['enabledIn']);
    if (enabledIn == null) {
      enabledInVersion = 'defaultLanguageVersion';
    } else {
      List<String> split = enabledIn.split(".");
      int enabledInMajor = int.parse(split[0]);
      int enabledInMinor = int.parse(split[1]);
      enabledInVersion = 'const Version($enabledInMajor, $enabledInMinor)';
    }
    bool? expired = (features[key] as YamlMap)['expired'];
    bool shipped = (features[key] as YamlMap)['enabledIn'] != null;
    if (shipped) {
      if (expired == false) {
        throw 'Cannot mark shipped feature "$key" as "expired: false"';
      }
    }
    String releasedInVersion;
    String? experimentalReleaseVersion = getAsVersionNumberString(
        (features[key] as YamlMap)['experimentalReleaseVersion']);
    if (experimentalReleaseVersion != null) {
      List<String> split = experimentalReleaseVersion.split(".");
      int releaseMajor = int.parse(split[0]);
      int releaseMinor = int.parse(split[1]);
      releasedInVersion = 'const Version($releaseMajor, $releaseMinor)';
    } else if (enabledIn != null) {
      List<String> split = enabledIn.split(".");
      int releaseMajor = int.parse(split[0]);
      int releaseMinor = int.parse(split[1]);
      releasedInVersion = 'const Version($releaseMajor, $releaseMinor)';
    } else {
      releasedInVersion = 'defaultLanguageVersion';
    }

    sb.writeln('''
  ${identifier}(
      name: '$key',
      isEnabledByDefault: $shipped,
      isExpired: ${expired == true},
      experimentEnabledVersion: $enabledInVersion,
      experimentReleasedVersion: $releasedInVersion),
''');
  }
  sb.write('''
  ;

  final String name;
  final bool isEnabledByDefault;
  final bool isExpired;
  final Version experimentEnabledVersion;
  final Version experimentReleasedVersion;

  const ExperimentalFlag({
      required this.name,
      required this.isEnabledByDefault,
      required this.isExpired,
      required this.experimentEnabledVersion,
      required this.experimentReleasedVersion});
}

class Version {
  final int major;
  final int minor;

  const Version(this.major, this.minor);

  String toText() => '\$major.\$minor';

  @override
  String toString() => toText();
}
''');

  return new DartFormatter().format("$sb");
}

String generateKernelFile(Uri repoDir) {
  Uri yamlFile = computeYamlFile(repoDir);
  Map<dynamic, dynamic> yaml =
      loadYaml(new File.fromUri(yamlFile).readAsStringSync());

  int currentVersionMajor;
  int currentVersionMinor;
  {
    String currentVersion = getAsVersionNumberString(yaml['current-version'])!;
    List<String> split = currentVersion.split(".");
    currentVersionMajor = int.parse(split[0]);
    currentVersionMinor = int.parse(split[1]);
  }

  StringBuffer sb = new StringBuffer();

  sb.write('''
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/front_end/tool/fasta.dart generate-experimental-flags' to update.

import "ast.dart";

const Version defaultLanguageVersion = const Version($currentVersionMajor, $currentVersionMinor);
''');

  return new DartFormatter().format("$sb");
}

String generateCfeFile(Uri repoDir) {
  Uri yamlFile = computeYamlFile(repoDir);
  Map<dynamic, dynamic> yaml =
      loadYaml(new File.fromUri(yamlFile).readAsStringSync());

  StringBuffer sb = new StringBuffer();

  sb.write('''
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/front_end/tool/fasta.dart generate-experimental-flags' to update.

part of 'experimental_flags.dart';
''');

  Map<String, dynamic> features = {};
  Map<dynamic, dynamic> yamlFeatures = yaml['features'];
  for (MapEntry<dynamic, dynamic> entry in yamlFeatures.entries) {
    String category = _getFeatureCategory(entry.value);
    if (!_isCfeFeature(category)) {
      // Skip a feature with a category that's not language or CFE.
      // In the future we might want to generate different code for different
      // things.
      continue;
    }
    features[entry.key] = entry.value;
  }

  List<String> keys = features.keys.toList()..sort();

  sb.write('''

/// An experiment flag including its fixed properties.
class ExperimentalFlag {
  /// The name of this flag as used in the --enable-experiment option.
  final String name;

  /// `true` if this experimental feature is enabled by default.
  ///
  /// When `true`, the feature can still be disabled in individual libraries
  /// with a language version below the [experimentEnabledVersion], and if not
  /// [isExpired], the feature can also be disabled by using a 'no-' prefix
  /// in the --enable-experiment option.
  final bool isEnabledByDefault;

  /// `true` if this feature can no longer be changed using the
  /// --enable-experiment option.
  ///
  /// Libraries can still opt out of the feature by using a language version
  /// below the [experimentEnabledVersion].
  final bool isExpired;
  final Version enabledVersion;

  /// The minimum version that supports this feature.
  ///
  /// If the feature is not enabled by default, this is the current language
  /// version.
  final Version experimentEnabledVersion;

  /// The minimum version that supports this feature in allowed libraries.
  ///
  /// Allowed libraries are specified in
  /// 
  ///    sdk/lib/_internal/allowed_experiments.json
  final Version experimentReleasedVersion;

  const ExperimentalFlag(
      {required this.name,
      required this.isEnabledByDefault,
      required this.isExpired,
      required this.enabledVersion,
      required this.experimentEnabledVersion,
      required this.experimentReleasedVersion});
''');
  for (String key in keys) {
    String identifier = keyToIdentifier(key);
    String enabledInVersion;
    String? enabledIn =
        getAsVersionNumberString((features[key] as YamlMap)['enabledIn']);
    if (enabledIn == null) {
      enabledInVersion = 'defaultLanguageVersion';
    } else {
      List<String> split = enabledIn.split(".");
      int enabledInMajor = int.parse(split[0]);
      int enabledInMinor = int.parse(split[1]);
      enabledInVersion = 'const Version($enabledInMajor, $enabledInMinor)';
    }
    bool? expired = (features[key] as YamlMap)['expired'];
    bool shipped = (features[key] as YamlMap)['enabledIn'] != null;
    if (shipped) {
      if (expired == false) {
        throw 'Cannot mark shipped feature "$key" as "expired: false"';
      }
    }
    String releasedInVersion;
    String? experimentalReleaseVersion = getAsVersionNumberString(
        (features[key] as YamlMap)['experimentalReleaseVersion']);
    if (experimentalReleaseVersion != null) {
      List<String> split = experimentalReleaseVersion.split(".");
      int releaseMajor = int.parse(split[0]);
      int releaseMinor = int.parse(split[1]);
      releasedInVersion = 'const Version($releaseMajor, $releaseMinor)';
    } else if (enabledIn != null) {
      List<String> split = enabledIn.split(".");
      int releaseMajor = int.parse(split[0]);
      int releaseMinor = int.parse(split[1]);
      releasedInVersion = 'const Version($releaseMajor, $releaseMinor)';
    } else {
      releasedInVersion = 'defaultLanguageVersion';
    }

    sb.writeln('''
  static const ExperimentalFlag ${identifier} =
    const ExperimentalFlag(
      name: '$key',
      isEnabledByDefault: $shipped,
      isExpired: ${expired == true},
      enabledVersion: $enabledInVersion,
      experimentEnabledVersion: $enabledInVersion,
      experimentReleasedVersion: $releasedInVersion);
''');
  }
  sb.write('''
}
''');

  sb.write('''
/// Interface for accessing the global state of experimental features. 
class GlobalFeatures {
  final Map<ExperimentalFlag, bool> explicitExperimentalFlags;
  final AllowedExperimentalFlags? allowedExperimentalFlags;
  final Map<ExperimentalFlag, bool>? defaultExperimentFlagsForTesting;
  final Map<ExperimentalFlag, Version>? experimentEnabledVersionForTesting;
  final Map<ExperimentalFlag, Version>? experimentReleasedVersionForTesting;

  GlobalFeatures(this.explicitExperimentalFlags,
      {this.allowedExperimentalFlags,
      this.defaultExperimentFlagsForTesting,
      this.experimentEnabledVersionForTesting,
      this.experimentReleasedVersionForTesting});

  GlobalFeature _computeGlobalFeature(ExperimentalFlag flag) {
    return new GlobalFeature(
        flag,
        isExperimentEnabled(flag,
            defaultExperimentFlagsForTesting: defaultExperimentFlagsForTesting,
            explicitExperimentalFlags: explicitExperimentalFlags));
  }

  LibraryFeature _computeLibraryFeature(
      ExperimentalFlag flag, Uri canonicalUri, Version libraryVersion) {
    return new LibraryFeature(
        flag,
        isExperimentEnabledInLibrary(flag, canonicalUri,
            defaultExperimentFlagsForTesting: defaultExperimentFlagsForTesting,
            explicitExperimentalFlags: explicitExperimentalFlags,
            allowedExperimentalFlags: allowedExperimentalFlags),
        getExperimentEnabledVersionInLibrary(
            flag, canonicalUri, explicitExperimentalFlags,
            allowedExperimentalFlags: allowedExperimentalFlags,
            defaultExperimentFlagsForTesting: defaultExperimentFlagsForTesting,
            experimentEnabledVersionForTesting:
                experimentEnabledVersionForTesting,
            experimentReleasedVersionForTesting:
                experimentReleasedVersionForTesting),
        isExperimentEnabledInLibraryByVersion(
            flag, canonicalUri, libraryVersion,
            defaultExperimentFlagsForTesting: defaultExperimentFlagsForTesting,
            explicitExperimentalFlags: explicitExperimentalFlags,
            allowedExperimentalFlags: allowedExperimentalFlags));
  }
''');
  for (String key in keys) {
    String identifier = keyToIdentifier(key);
    sb.write('''

  GlobalFeature? _${identifier};
  GlobalFeature get ${identifier} =>
      _${identifier} ??= _computeGlobalFeature(ExperimentalFlag.${identifier});    
''');
  }
  sb.write('''
}

/// Interface for accessing the state of experimental features within a
/// specific library.
class LibraryFeatures {
  final GlobalFeatures globalFeatures;
  final Uri canonicalUri;
  final Version libraryVersion;

  LibraryFeatures(this.globalFeatures, this.canonicalUri, this.libraryVersion);
''');
  for (String key in keys) {
    String identifier = keyToIdentifier(key);
    sb.write('''

  LibraryFeature? _${identifier};
  LibraryFeature get ${identifier} => _${identifier} ??= globalFeatures
      ._computeLibraryFeature(
          ExperimentalFlag.${identifier},
          canonicalUri,
          libraryVersion);
''');
  }

  sb.write('''

  /// Returns the [LibraryFeature] corresponding to [experimentalFlag].
  LibraryFeature fromSharedExperimentalFlags(
      shared.ExperimentalFlag experimentalFlag) {
    switch (experimentalFlag) {
  ''');
  for (String key in keys) {
    String category = _getFeatureCategory(features[key]!);
    if (!_isLanguageFeature(category)) continue;

    String identifier = keyToIdentifier(key);
    sb.writeln('''
      case shared.ExperimentalFlag.${identifier}:
        return ${identifier};''');
  }
  sb.write('''
      default:
        throw new UnsupportedError(
            'LibraryFeatures.fromSharedExperimentalFlags(\$experimentalFlag)');
    }
  }
  ''');
  sb.write('''
}
''');

  sb.write('''
ExperimentalFlag? parseExperimentalFlag(String flag) {
  switch (flag) {
''');
  for (String key in keys) {
    sb.writeln('    case "$key":');
    sb.writeln('     return ExperimentalFlag.${keyToIdentifier(key)};');
  }
  sb.write('''  }
  return null;
}

final Map<ExperimentalFlag, bool> defaultExperimentalFlags = {
''');
  for (String key in keys) {
    sb.writeln('''
  ExperimentalFlag.${keyToIdentifier(key)}:
      ExperimentalFlag.${keyToIdentifier(key)}.isEnabledByDefault,''');
  }
  sb.write('''
};
''');

  Uri allowListFile = computeAllowListFile(repoDir);
  AllowedExperiments allowedExperiments = parseAllowedExperiments(
      new File.fromUri(allowListFile).readAsStringSync());

  sb.write('''
const AllowedExperimentalFlags defaultAllowedExperimentalFlags =
    const AllowedExperimentalFlags(
''');
  sb.writeln('sdkDefaultExperiments: {');
  for (String sdkDefaultExperiment
      in allowedExperiments.sdkDefaultExperiments) {
    sb.writeln('ExperimentalFlag.${keyToIdentifier(sdkDefaultExperiment)},');
  }
  sb.writeln('},');
  sb.writeln('sdkLibraryExperiments: {');
  allowedExperiments.sdkLibraryExperiments
      .forEach((String library, List<String> experiments) {
    sb.writeln('"$library": {');
    for (String experiment in experiments) {
      sb.writeln('ExperimentalFlag.${keyToIdentifier(experiment)},');
    }
    sb.writeln('},');
  });
  sb.writeln('},');
  sb.writeln('packageExperiments: {');
  allowedExperiments.packageExperiments
      .forEach((String package, List<String> experiments) {
    sb.writeln('"$package": {');
    for (String experiment in experiments) {
      sb.writeln('ExperimentalFlag.${keyToIdentifier(experiment)},');
    }
    sb.writeln('},');
  });
  sb.writeln('});');

  sb.write('''
  const Map<shared.ExperimentalFlag, ExperimentalFlag> sharedExperimentalFlags 
     = {
  ''');
  for (String key in keys) {
    String category = _getFeatureCategory(features[key]!);
    if (!_isLanguageFeature(category)) continue;

    sb.writeln('''
    shared.ExperimentalFlag.${keyToIdentifier(key)}:
    ExperimentalFlag.${keyToIdentifier(key)},''');
  }
  sb.write('''
  };
  ''');

  return new DartFormatter().format("$sb");
}

String keyToIdentifier(String key, {bool upperCaseFirst = false}) {
  StringBuffer identifier = StringBuffer();
  bool first = true;
  for (int index = 0; index < key.length; ++index) {
    int code = key.codeUnitAt(index);
    if (code == $MINUS) {
      ++index;
      code = key.codeUnitAt(index);
      if ($a <= code && code <= $z) {
        code = code - $a + $A;
      }
    }
    if (first && upperCaseFirst && $a <= code && code <= $z) {
      code = code - $a + $A;
    }
    first = false;
    identifier.writeCharCode(code);
  }
  return identifier.toString();
}

String? getAsVersionNumberString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is double) return "$value";
  throw "Unexpected value: $value (${value.runtimeType})";
}
