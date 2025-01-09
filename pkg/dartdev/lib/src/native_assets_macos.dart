// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/native_assets_bundling.dart';
import 'package:native_assets_cli/code_assets.dart';

final _rpathUri = Uri.file('@rpath/');

Future<void> rewriteInstallNames(
  List<Uri> dylibs, {
  required bool relocatable,
}) async {
  final oldToNewInstallNames = <String, String>{};
  final dylibInfos = <(Uri, String)>[];

  await Future.wait(dylibs.map((dylib) async {
    final newInstallName = relocatable
        ? _rpathUri
            .resolveUri(libOutputDirectoryUri)
            .resolve(dylib.pathSegments.last)
            .toFilePath()
        : dylib.toFilePath();
    final oldInstallName = await _getInstallName(dylib);
    oldToNewInstallNames[oldInstallName] = newInstallName;
    dylibInfos.add((dylib, newInstallName));
  }));

  await Future.wait(dylibInfos.map((info) async {
    final (dylib, newInstallName) = info;
    await _setInstallNames(dylib, newInstallName, oldToNewInstallNames);
    await _codeSignDylib(dylib);
  }));
}

Future<String> _getInstallName(Uri dylib) async {
  final otoolResult = await Process.run(
    'otool',
    [
      '-D',
      dylib.toFilePath(),
    ],
  );
  if (otoolResult.exitCode != 0) {
    throw Exception(
      'Failed to get install name for dylib $dylib: ${otoolResult.stderr}',
    );
  }
  final architectureSections =
      parseOtoolArchitectureSections(otoolResult.stdout);
  if (architectureSections.length != 1) {
    throw Exception(
      'Expected a single architecture section in otool output: $otoolResult',
    );
  }
  return architectureSections.values.first.single;
}

Future<void> _setInstallNames(
  Uri dylib,
  String newInstallName,
  Map<String, String> oldToNewInstallNames,
) async {
  final installNameToolResult = await Process.run(
    'install_name_tool',
    [
      '-id',
      newInstallName,
      for (final entry in oldToNewInstallNames.entries) ...[
        '-change',
        entry.key,
        entry.value,
      ],
      dylib.toFilePath(),
    ],
  );
  if (installNameToolResult.exitCode != 0) {
    throw Exception(
      'Failed to set install names for dylib $dylib:\n'
      'id -> $newInstallName\n'
      'dependencies -> $oldToNewInstallNames\n'
      '${installNameToolResult.stderr}',
    );
  }
}

Future<void> _codeSignDylib(Uri dylib) async {
  final codesignResult = await Process.run(
    'codesign',
    [
      '--force',
      '--sign',
      '-',
      dylib.toFilePath(),
    ],
  );
  if (codesignResult.exitCode != 0) {
    throw Exception(
      'Failed to codesign dylib $dylib: ${codesignResult.stderr}',
    );
  }
}

Map<Architecture?, List<String>> parseOtoolArchitectureSections(String output) {
  // The output of `otool -D`, for example, looks like below. For each
  // architecture, there is a separate section.
  //
  // /build/native_assets/ios/buz.framework/buz (architecture x86_64):
  // @rpath/libbuz.dylib
  // /build/native_assets/ios/buz.framework/buz (architecture arm64):
  // @rpath/libbuz.dylib
  //
  // Some versions of `otool` don't print the architecture name if the
  // binary only has one architecture:
  //
  // /build/native_assets/ios/buz.framework/buz:
  // @rpath/libbuz.dylib

  const Map<String, Architecture> outputArchitectures = <String, Architecture>{
    'arm': Architecture.arm,
    'arm64': Architecture.arm64,
    'x86_64': Architecture.x64,
  };
  final RegExp architectureHeaderPattern =
      RegExp(r'^[^(]+( \(architecture (.+)\))?:$');
  final Iterator<String> lines = output.trim().split('\n').iterator;
  Architecture? currentArchitecture;
  final Map<Architecture?, List<String>> architectureSections =
      <Architecture?, List<String>>{};

  while (lines.moveNext()) {
    final String line = lines.current;
    final Match? architectureHeader =
        architectureHeaderPattern.firstMatch(line);
    if (architectureHeader != null) {
      if (architectureSections.containsKey(null)) {
        throw Exception(
          'Expected a single architecture section in otool output: $output',
        );
      }
      final String? architectureString = architectureHeader.group(2);
      if (architectureString != null) {
        currentArchitecture = outputArchitectures[architectureString];
        if (currentArchitecture == null) {
          throw Exception(
            'Unknown architecture in otool output: $architectureString',
          );
        }
      }
      architectureSections[currentArchitecture] = <String>[];
      continue;
    } else {
      architectureSections[currentArchitecture]!.add(line.trim());
    }
  }

  return architectureSections;
}
