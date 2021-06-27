// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The set of constants and utilities to check file paths.
///
/// The recommended import prefix in `file_paths`.
import 'package:path/path.dart' as p;

/// The file name used for analysis options files.
const String analysisOptionsYaml = 'analysis_options.yaml';

/// File name of Android manifest files.
const String androidManifestXml = 'AndroidManifest.xml';

/// File name of Bazel `BUILD` files.
const String bazelBuild = 'BUILD';

/// The name of the `.dart_tool` directory.
const String dotDartTool = '.dart_tool';

/// File name of package spec files.
const String dotPackages = '.packages';

/// The name of the data file used to specify data-driven fixes.
const String fixDataYaml = 'fix_data.yaml';

/// The name of the package config files.
const String packageConfigJson = 'package_config.json';

/// File name of pubspec files.
const String pubspecYaml = 'pubspec.yaml';

/// Converts the given [path] into absolute and normalized.
String absoluteNormalized(p.Context pathContext, String path) {
  path = path.trim();
  path = pathContext.absolute(path);
  path = pathContext.normalize(path);
  return path;
}

/// Return `true` if [path] is an analysis options file.
bool isAnalysisOptionsYaml(p.Context pathContext, String path) {
  return pathContext.basename(path) == analysisOptionsYaml;
}

/// Return `true` if [path] is a `AndroidManifest.xml` file.
bool isAndroidManifestXml(p.Context pathContext, String path) {
  return pathContext.basename(path) == androidManifestXml;
}

/// Return `true` if [path] is a Bazel `BUILD` file.
bool isBazelBuild(p.Context pathContext, String path) {
  return pathContext.basename(path) == bazelBuild;
}

/// Return `true` if [path] is a Dart file.
bool isDart(p.Context pathContext, String path) {
  return pathContext.extension(path) == '.dart';
}

/// Return `true` if [path] is a `.packages` file.
bool isDotPackages(p.Context pathContext, String path) {
  return pathContext.basename(path) == dotPackages;
}

/// Return `true` if the [path] is a `fix_data.yaml` file.
/// Such files specify data-driven fixes.
bool isFixDataYaml(p.Context pathContext, String path) {
  return pathContext.basename(path) == fixDataYaml;
}

/// Return `true` if [path] is a `.dart_tool/package_config.json` file.
bool isPackageConfigJson(p.Context pathContext, String path) {
  var components = pathContext.split(path);
  return components.length > 2 &&
      components[components.length - 1] == packageConfigJson &&
      components[components.length - 2] == dotDartTool;
}

/// Return `true` if [path] is a `pubspec.yaml` file.
bool isPubspecYaml(p.Context pathContext, String path) {
  return pathContext.basename(path) == pubspecYaml;
}
