// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.translate_uri;

import 'dart:async' show Future;

import 'dart:convert' show JSON;

import 'package:front_end/file_system.dart'
    show FileSystem, FileSystemException;

import 'package:package_config/packages_file.dart' as packages_file show parse;

import 'deprecated_problems.dart' show deprecated_inputError;

class TranslateUri {
  final Map<String, Uri> packages;
  final Map<String, Uri> dartLibraries;

  // TODO(ahe): We probably want this to be `Map<String, Uri>`, that is, just
  // one patch library (with parts).
  final Map<String, List<Uri>> patches;

  TranslateUri(this.packages, this.dartLibraries, this.patches);

  Uri translate(Uri uri) {
    if (uri.scheme == "dart") return translateDartUri(uri);
    if (uri.scheme == "package") return translatePackageUri(uri);
    return null;
  }

  Uri translateDartUri(Uri uri) {
    if (!uri.isScheme('dart')) return null;
    String path = uri.path;

    int index = path.indexOf('/');
    if (index == -1) return dartLibraries[path];

    String libraryName = path.substring(0, index);
    String relativePath = path.substring(index + 1);
    Uri libraryFileUri = dartLibraries[libraryName];
    return libraryFileUri?.resolve(relativePath);
  }

  Uri translatePackageUri(Uri uri) {
    int index = uri.path.indexOf("/");
    if (index == -1) return null;
    String name = uri.path.substring(0, index);
    String path = uri.path.substring(index + 1);
    Uri root = packages[name];
    if (root == null) return null;
    return root.resolve(path);
  }

  /// Returns true if [uri] is private to the platform libraries (and thus not
  /// accessible from user code).
  bool isPlatformImplementation(Uri uri) {
    if (uri.scheme != "dart") return false;
    String path = uri.path;
    return dartLibraries[path] == null || path.startsWith("_");
  }

  static Future<TranslateUri> parse(FileSystem fileSystem, Uri sdk,
      {Uri packages}) async {
    Uri librariesJson = sdk?.resolve("lib/libraries.json");

    // TODO(ahe): Provide a value for this file.
    Uri patches = null;

    packages ??= Uri.base.resolve(".packages");

    List<int> bytes;
    try {
      bytes = await fileSystem.entityForUri(packages).readAsBytes();
    } on FileSystemException catch (e) {
      deprecated_inputError(packages, -1, e.message);
    }

    Map<String, Uri> parsedPackages;
    try {
      parsedPackages = packages_file.parse(bytes, packages);
    } on FormatException catch (e) {
      return deprecated_inputError(packages, e.offset, e.message);
    }
    return new TranslateUri(
        parsedPackages,
        await computeLibraries(fileSystem, librariesJson),
        await computePatches(fileSystem, patches));
  }
}

Future<Map<String, Uri>> computeLibraries(
    FileSystem fileSystem, Uri uri) async {
  if (uri == null) return const <String, Uri>{};
  Map<String, String> libraries = JSON
      .decode(await fileSystem.entityForUri(uri).readAsString())["libraries"];
  Map<String, Uri> result = <String, Uri>{};
  libraries.forEach((String name, String path) {
    result[name] = uri.resolveUri(new Uri.file(path));
  });
  return result;
}

Future<Map<String, List<Uri>>> computePatches(
    FileSystem fileSystem, Uri uri) async {
  // TODO(ahe): Read patch information.
  return const <String, List<Uri>>{};
}
