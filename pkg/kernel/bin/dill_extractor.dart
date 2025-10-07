// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';

void main(List<String> args) {
  if (args.length != 2) {
    throw "Need 2 arguments: The input dill and the output dir.";
  }

  File dill = new File(args[0]);
  if (!dill.existsSync()) {
    throw "${args[0]} is not an existing file.";
  }

  Directory dir = new Directory(args[1]);
  if (dir.existsSync()) {
    print("Warning: ${args[1]} is an existing dir.");
  } else if (!dir.parent.existsSync()) {
    print(
        "Warning: ${dir.parent} is not an existing dir, but will be created.");
    dir.createSync(recursive: true);
  } else {
    dir.createSync();
  }

  Component component = new Component();
  try {
    Uint8List bytes = dill.readAsBytesSync();
    new BinaryBuilder(bytes).readComponent(component);
  } catch (e, st) {
    print("Error when loading $dill:");
    print(e);
    print("Error thrown via:");
    print(st);
    exit(1);
  }

  Map<String, Uri> packagesToRoot = {};
  Map<Uri, String> rootsToPackage = {};
  Set<MapEntry<Uri, Source>> nonPackageUris = {};
  int writes = 0;
  for (MapEntry<Uri, Source> sourceEntry in component.uriToSource.entries) {
    Uri uri = sourceEntry.value.importUri ??
        sourceEntry.value.fileUri ??
        sourceEntry.key;
    Uri fileUri = sourceEntry.key;
    if (uri.isScheme("dart")) continue;
    if (!uri.isScheme("package")) {
      nonPackageUris.add(sourceEntry);
    } else {
      // Package uri. Calculate root.
      String package = uri.pathSegments[0];
      String relativeFromPackageUri = uri.pathSegments.skip(1).join("/");
      String relativeFromFileUri = fileUri.pathSegments
          .skip(fileUri.pathSegments.length - uri.pathSegments.length + 1)
          .join("/");
      if (relativeFromPackageUri != relativeFromFileUri) {
        throw "Expected $relativeFromPackageUri and $relativeFromFileUri to be "
            "the same (from $uri and $fileUri)";
      }
      List<String> rootPathSegments = fileUri.pathSegments
          .take(fileUri.pathSegments.length - uri.pathSegments.length + 1)
          .toList();
      if (rootPathSegments[rootPathSegments.length - 1] == "lib") {
        rootPathSegments[rootPathSegments.length - 1] = "";
      } else {
        rootPathSegments.add("");
      }
      Uri root = fileUri.replace(pathSegments: rootPathSegments);
      Uri? existingRoot = packagesToRoot[package];
      if (existingRoot != null && existingRoot != root) {
        throw "Previously found root for $package to be $existingRoot "
            "but now found $root";
      } else if (existingRoot == null) {
        packagesToRoot[package] = root;
        rootsToPackage[root] = package;
      }

      Uri newPlacement = dir.uri.resolve("$package/lib/$relativeFromFileUri");
      File.fromUri(newPlacement)
        ..createSync(recursive: true)
        ..writeAsBytesSync(sourceEntry.value.source);
      writes++;
    }
  }

  for (MapEntry<Uri, Source> sourceEntry in nonPackageUris) {
    Uri fileUri = sourceEntry.key;
    Uri possibleRoot = fileUri.resolve(".");
    while (!rootsToPackage.containsKey(possibleRoot)) {
      Uri newPossibleRoot = possibleRoot.resolve("..");
      if (newPossibleRoot != possibleRoot) {
        possibleRoot = newPossibleRoot;
      } else {
        throw "Failure on $fileUri";
      }
    }
    String package = rootsToPackage[possibleRoot]!;

    String relativeFromFileUri = fileUri.pathSegments
        .skip(possibleRoot.pathSegments.length - 1)
        .join("/");
    Uri newPlacement = dir.uri.resolve("$package/$relativeFromFileUri");
    File.fromUri(newPlacement)
      ..createSync(recursive: true)
      ..writeAsBytesSync(sourceEntry.value.source);
    writes++;
  }

  Map<String, Version> packagesToLowestLanguageVersion = {};
  for (Library lib in component.libraries) {
    if (lib.importUri.isScheme("package")) {
      String package = lib.importUri.pathSegments[0];
      Version? existing = packagesToLowestLanguageVersion[package];
      Version libLanguageVersion = lib.languageVersion;
      if (existing == null) {
        packagesToLowestLanguageVersion[package] = libLanguageVersion;
      } else if (existing > libLanguageVersion) {
        packagesToLowestLanguageVersion[package] = libLanguageVersion;
      }
    }
  }
  List<Map<String, dynamic>> packages = [];
  Map<String, dynamic> packageConfig = {
    "configVersion": 2,
    "packages": packages,
  };
  for (MapEntry<String, Uri> package in packagesToRoot.entries) {
    Version version = packagesToLowestLanguageVersion[package.key]!;
    packages.add({
      "name": package.key,
      "rootUri": "../${package.key}",
      "packageUri": "lib/",
      "languageVersion": version.toText()
    });
  }
  File.fromUri(dir.uri.resolve(".dart_tool/package_config.json"))
    ..createSync(recursive: true)
    ..writeAsStringSync(json.encode(packageConfig));

  print("Done. Wrote $writes source files.");
}
