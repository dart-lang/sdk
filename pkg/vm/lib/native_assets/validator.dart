// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart';
import 'package:vm/kernel_front_end.dart';
import 'package:yaml/yaml.dart';

import 'diagnostic_message.dart';

class NativeAssetsValidator {
  final ErrorDetector errorDetector;
  List<Uri> involvedFiles = [];

  NativeAssetsValidator(this.errorDetector);

  void _reportError(String message, {Severity severity = Severity.error}) {
    errorDetector(NativeAssetsDiagnosticMessage(
      message: message,
      involvedFiles: involvedFiles,
      severity: severity,
    ));
  }

  /// Parses and validates [nativeAssetsYamlString].
  ///
  /// Returns the parsed result if valid, otherwise `null`.
  ///
  /// Reports errors to [errorDetector].
  Map? parseAndValidate(String nativeAssetsYamlString) {
    late final Object? nativeAssetsYaml;
    try {
      nativeAssetsYaml = loadYaml(nativeAssetsYamlString) as Object?;
    } on YamlException catch (e) {
      _reportError("File not formatted as yaml: $e $nativeAssetsYamlString.");
      return null;
    }
    if (nativeAssetsYaml == null) {
      _reportError("File not formatted as yaml: $nativeAssetsYamlString.");
      return null;
    }

    final nativeAssetsYamlPruned = _validateAndPrune(nativeAssetsYaml);

    return nativeAssetsYamlPruned;
  }

  static const _formatVersionKey = 'format-version';
  static const _nativeAssetsKey = 'native-assets';

  /// Modifies [object] to prune invalid data that only causes warnings.
  ///
  /// Returns `null` if invalid.
  Map? _validateAndPrune(Object object) {
    if (object is! Map) {
      _reportError('Unexpected root object: $object. Expected a Map.');
      return null;
    }
    var isValid = true;
    if (!object.containsKey(_formatVersionKey)) {
      _reportError('Expected $_formatVersionKey in $object.');
      isValid = false;
    } else {
      isValid &= _validateFormatVersion(object[_formatVersionKey]);
    }
    if (!object.containsKey(_nativeAssetsKey)) {
      _reportError('Expected $_nativeAssetsKey in $object.');
      isValid = false;
    } else {
      var nativeAssets = object[_nativeAssetsKey];
      if (nativeAssets is Map) {
        // Make native-assets modifiable.
        nativeAssets = Map.from(nativeAssets);
        object = Map.from(object);
        object[_nativeAssetsKey] = nativeAssets;
      }
      isValid &= _validateNativeAssets(nativeAssets);
    }
    if (!isValid) return null;
    return object;
  }

  /// The VM cannot consume newer formats with breaking changes.
  static const _maximumMajor = 1;

  /// This VM cannot consume too old versions.
  static const _minimumMajor = 1;
  static const _minimumMinor = 0;
  static const _minimumPatch = 0;
  static const _minimumVersion = [_minimumMajor, _minimumMinor, _minimumPatch];

  /// Validate [_formatVersionKey] contents.
  ///
  /// Checks the major version upper bound and all version lower bounds.
  bool _validateFormatVersion(Object object) {
    if (object is! List || object.length != 3) {
      _reportError(
          'Unexpected format version: $object. Expected a List with length 3.');
      return false;
    }
    final major = object[0];
    final minor = object[1];
    final patch = object[2];
    if (major > _maximumMajor) {
      _reportError(
          'Unexpected format version: $object. Major version above $_maximumMajor not supported.');
      return false;
    }
    if (major > _minimumMajor) return true;
    if (major < _minimumMajor) {
      _reportError(
          'Unexpected format version: $object. Versions below $_minimumVersion not supported.');
      return false;
    }
    if (minor > _minimumMinor) return true;
    if (minor < _minimumMinor) {
      _reportError(
          'Unexpected format version: $object. Versions below $_minimumVersion not supported.');
      return false;
    }
    if (patch < _minimumPatch) {
      _reportError(
          'Unexpected format version: $object. Versions below $_minimumVersion not supported.');
      return false;
    }
    return true;
  }

  /// Validate [_nativeAssetsKey] contents.
  bool _validateNativeAssets(Object object) {
    if (object is! Map) {
      _reportError('Unexpected native-assets: $object. Expected a Map.');
      return false;
    }
    var isValid = true;
    final invalidTargets = [];
    for (final entry in object.entries) {
      final target = entry.key;
      final validTarget = _validateTarget(target);
      if (!validTarget) {
        invalidTargets.add(target);
      } else {
        isValid &= _validateAssets(entry.value);
      }
    }
    for (final target in invalidTargets) {
      object.remove(target);
    }
    return isValid;
  }

  // TODO(http://dartbug.com/49803): Get this from `package:native` when that
  // is merged.
  static const _validTargets = [
    'android_arm',
    'android_arm64',
    'android_ia32',
    'android_x64',
    'fuchsia_arm64',
    'fuchsia_x64',
    'ios_arm',
    'ios_arm64',
    'ios_x64',
    'iossimulator_arm64',
    'iossimulator_x64',
    'linux_arm',
    'linux_arm64',
    'linux_ia32',
    'linux_riscv32',
    'linux_riscv64',
    'linux_x64',
    'macos_arm64',
    'macos_x64',
    'windows_arm64',
    'windows_ia32',
    'windows_x64',
  ];

  /// An invalid target is considered only a warning.
  ///
  /// For example, we may remove ia32 at some point, but we might have existing
  /// yamls lingering around.
  bool _validateTarget(Object object) {
    if (!_validTargets.contains(object)) {
      _reportError('Unexpected target: $object. Valid targets: $_validTargets.',
          severity: Severity.warning);
      return false;
    }
    return true;
  }

  bool _validateAssets(Object object) {
    if (object is! Map) {
      _reportError('Unexpected assets mapping: $object. Expected a Map.');
      return false;
    }
    var isValid = true;
    for (final entry in object.entries) {
      isValid &= _validateAsset(entry.key);
      isValid &= _validateAssetPath(entry.value);
    }
    return isValid;
  }

  bool _validateAsset(Object object) {
    if (object is! String) {
      _reportError('Unexpected assets name: $object. Expected a String.');
      return false;
    }
    return true;
  }

  final _pathTypesWithPath = [
    'absolute',
    'relative',
    'system',
  ];

  late final _validPathTypes = [
    ..._pathTypesWithPath,
    'executable',
    'process',
  ]..sort();

  bool _validateAssetPath(Object object) {
    if (object is! List || object.isEmpty) {
      _reportError(
          'Unexpected asset path: $object. Expected a non-empty List.');
      return false;
    }
    final pathType = object[0];
    if (pathType is! String || !_validPathTypes.contains(pathType)) {
      _reportError(
          'Unexpected path type: $pathType. Valid path types: $_validPathTypes.');
      return false;
    }
    final needsPath = _pathTypesWithPath.contains(pathType);
    final listLength = 1 + (needsPath ? 1 : 0);
    if (object.length != listLength) {
      _reportError(
          'Unexpected asset path: $object. Expected list with $listLength elements.');
      return false;
    }
    if (needsPath) {
      final path = object[1];
      if (path is! String) {
        _reportError('Unexpected path: $path. Expected a String.');
        return false;
      }
    }
    return true;
  }
}
