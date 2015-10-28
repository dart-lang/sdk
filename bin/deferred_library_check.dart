// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A command-line tool that verifies that deferred libraries split the code as
/// expected.
/// This tool checks that the output from dart2js meets a given specification,
/// given in a YAML file. The format of the YAML file is:
///
///     main:
///       packages:
///         - some_package
///         - other_package
///
///     foo:
///       packages:
///         - foo
///         - bar
///
///     baz:
///       packages:
///         - baz
///         - quux
///
/// The YAML file consists of a list of declarations, one for each deferred
/// part expected in the output. At least one of these parts must be named
/// "main"; this is the main part that contains the program entrypoint. Each
/// top-level part contains a list of package names that are expected to be
/// contained in that part. Any package that is not explicitly listed is
/// expected to be in the main part. For instance, in the example YAML above
/// the part named "baz" is expected to contain the packages "baz" and "quux".
///
/// The names for parts given in the specification YAML file (besides "main")
/// are arbitrary and just used for reporting when the output does not meet the
/// specification.
library dart2js_info.bin.deferred_library_check;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:quiver/collection.dart';
import 'package:yaml/yaml.dart';

Future main(List<String> args) async {
  if (args.length < 2) {
    usage();
    exit(1);
  }
  var info = await infoFromFile(args[0]);
  var manifest = await manifestFromFile(args[1]);

  // For each part in the manifest, record the expected "packages" for that
  // part.
  var packages = <String, String>{};
  for (var part in manifest.keys) {
    for (var package in manifest[part]['packages']) {
      if (packages.containsKey(package)) {
        print('You cannot specify that package "$package" maps to both parts '
            '"$part" and "${packages[package]}".');
        exit(1);
      }
      packages[package] = part;
    }
  }

  var guessedPartMapping = new BiMap<String, String>();
  guessedPartMapping['main'] = 'main';

  bool anyFailed = false;

  checkInfo(BasicInfo info) {
    var lib = getLibraryOf(info);
    if (lib != null && isPackageUri(lib.uri)) {
      var packageName = getPackageName(lib.uri);
      var outputUnitName = info.outputUnit.name;
      var expectedPart;
      if (packages.containsKey(packageName)) {
        expectedPart = packages[packageName];
      } else {
        expectedPart = 'main';
      }
      var expectedOutputUnit = guessedPartMapping[expectedPart];
      if (expectedOutputUnit == null) {
        guessedPartMapping[expectedPart] = outputUnitName;
      } else {
        if (expectedOutputUnit != outputUnitName) {
          // TODO(het): add options for how to treat unspecified packages
          if (!packages.containsKey(packageName)) {
            print('"${info.name}" from package "$packageName" was not declared '
                'to be in an explicit part but was not in the main part');
          } else {
            var actualPart = guessedPartMapping.inverse[outputUnitName];
            print('"${info.name}" from package "$packageName" was specified to '
                'be in part $expectedPart but is in part $actualPart');
          }
          anyFailed = true;
        }
      }
    }
  }

  info.functions.forEach(checkInfo);
  info.fields.forEach(checkInfo);
  if (anyFailed) {
    print('The dart2js output did not meet the specification.');
  } else {
    print('The dart2js output meets the specification');
  }
}

LibraryInfo getLibraryOf(Info info) {
  var current = info;
  while (current is! LibraryInfo) {
    if (current == null) {
      return null;
    }
    current = current.parent;
  }
  return current;
}

bool isPackageUri(Uri uri) => uri.scheme == 'package';

String getPackageName(Uri uri) {
  assert(isPackageUri(uri));
  return uri.pathSegments.first;
}

Future<AllInfo> infoFromFile(String fileName) async {
  var file = await new File(fileName).readAsString();
  return new AllInfoJsonCodec().decode(JSON.decode(file));
}

Future manifestFromFile(String fileName) async {
  var file = await new File(fileName).readAsString();
  return loadYaml(file);
}

void usage() {
  print('''
usage: dart2js_info_deferred_library_check dump.info.json manifest.yaml''');
}
