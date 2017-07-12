// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.uri_translator_impl;

import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'package:front_end/file_system.dart'
    show FileSystem, FileSystemException;
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:package_config/packages_file.dart' as packages_file show parse;

import 'deprecated_problems.dart' show deprecated_inputError;

/// Read the JSON file with defined SDK libraries from the given [uri] in the
/// [fileSystem] and return the mapping from parsed Dart library names (e.g.
/// `math`) to file URIs.
Future<Map<String, Uri>> computeDartLibraries(
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

Future<Map<String, List<Uri>>> computeDartPatches(
    FileSystem fileSystem, Uri uri) async {
  // TODO(ahe): Read patch information.
  return const <String, List<Uri>>{};
}

/// Implementation of [UriTranslator] for absolute `dart` and `package` URIs.
class UriTranslatorImpl implements UriTranslator {
  /// Mapping from Dart library names (e.g. `math`) to file URIs.
  final Map<String, Uri> dartLibraries;

  // TODO(ahe): We probably want this to be `Map<String, Uri>`, that is, just
  // one patch library (with parts).
  /// Mapping from Dart library names to the file URIs of patches to apply.
  final Map<String, List<Uri>> dartPatches;

  /// Mapping from package names (e.g. `angular`) to the file URIs.
  final Map<String, Uri> packages;

  UriTranslatorImpl(this.dartLibraries, this.dartPatches, this.packages);

  @override
  List<Uri> getDartPatches(String libraryName) => dartPatches[libraryName];

  @override
  bool isPlatformImplementation(Uri uri) {
    if (uri.scheme != "dart") return false;
    String path = uri.path;
    return dartLibraries[path] == null || path.startsWith("_");
  }

  @override
  Uri translate(Uri uri) {
    if (uri.scheme == "dart") return _translateDartUri(uri);
    if (uri.scheme == "package") return _translatePackageUri(uri);
    return null;
  }

  /// Return the file URI that corresponds to the given `dart` URI, or `null`
  /// if there is no corresponding Dart library registered.
  Uri _translateDartUri(Uri uri) {
    if (!uri.isScheme('dart')) return null;
    String path = uri.path;

    int index = path.indexOf('/');
    if (index == -1) return dartLibraries[path];

    String libraryName = path.substring(0, index);
    String relativePath = path.substring(index + 1);
    Uri libraryFileUri = dartLibraries[libraryName];
    return libraryFileUri?.resolve(relativePath);
  }

  /// Return the file URI that corresponds to the given `package` URI, or
  /// `null` if the `package` [uri] format is invalid, or there is no
  /// corresponding package registered.
  Uri _translatePackageUri(Uri uri) {
    int index = uri.path.indexOf("/");
    if (index == -1) return null;
    String name = uri.path.substring(0, index);
    String path = uri.path.substring(index + 1);
    Uri root = packages[name];
    if (root == null) return null;
    return root.resolve(path);
  }

  static Future<UriTranslator> parse(FileSystem fileSystem, Uri sdk,
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

    var dartLibraries = await computeDartLibraries(fileSystem, librariesJson);
    return new UriTranslatorImpl(dartLibraries,
        await computeDartPatches(fileSystem, patches), parsedPackages);
  }
}
