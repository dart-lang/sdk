// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:dartdev/src/core.dart';
import 'package:dartdev/src/native_assets_bundling.dart';
import 'package:path/path.dart' as path;

final _rpathUri = Uri.file('@rpath/');

/// Sets the install names of the code assets in [dylibs], after they have been
/// copied to their final location.
///
/// A dylib finds its dependencies by the install names in its load commands, so
/// the install name of each dylib is set to its new location, and the
/// references to it in the other dylibs are changed to match.
///
/// If [relocatable] is true (`dart build cli`), the new install name is
/// `@rpath/lib/<file name>`. Otherwise (`dart run` and `dart test`), it is the
/// absolute path of the dylib.
///
/// If [relocatable] is false, a dylib whose header has no room for its new
/// install name, such as a prebuilt one linked without
/// `-headerpad_max_install_names`, keeps its own install name and a warning is
/// printed. Its dependents still reference it by its absolute path, and so does
/// the VM. dyld matches a load against the path an image was loaded from, so
/// every load of that path gets the same image. dyld records an image under its
/// real path, so this is done only for a dylib in a directory without
/// symlinks. The kept install name stays visible to dyld for the rest of the
/// process: a later load of that `@rpath/` name, or of its bare file name, gets
/// this image.
///
/// A dylib without room still fails if changing its references to other code
/// assets makes its load commands larger, as for a prebuilt dylib that
/// references them by `@rpath/` names.
Future<void> rewriteInstallNames(
  List<({String assetId, Uri dylib})> dylibs, {
  required bool relocatable,
}) async {
  final oldToNewInstallNames = <String, String>{};
  final dylibInfos =
      <
        ({
          String assetId,
          Uri dylib,
          String newInstallName,
          String oldInstallName,
        })
      >[];

  await Future.wait(
    dylibs.map((info) async {
      final (:assetId, :dylib) = info;
      final newInstallName = relocatable
          ? _rpathUri
                .resolveUri(libOutputDirectoryUri)
                .resolve(dylib.pathSegments.last)
                .toFilePath()
          : dylib.toFilePath();
      final oldInstallName = await _getInstallName(dylib);
      oldToNewInstallNames[oldInstallName] = newInstallName;
      dylibInfos.add((
        assetId: assetId,
        dylib: dylib,
        newInstallName: newInstallName,
        oldInstallName: oldInstallName,
      ));
    }),
  );

  await Future.wait(
    dylibInfos.map((info) async {
      final (:assetId, :dylib, :newInstallName, :oldInstallName) = info;
      // `dart build cli` makes a bundle to ship, in which every install name
      // must be the relocatable one, so it fails on any error.
      final keepInstallNameIfItDoesNotFit =
          !relocatable && await _isInCanonicalDirectory(dylib);
      final installNameSet = await _setInstallNames(
        dylib,
        newInstallName,
        oldToNewInstallNames,
        keepInstallNameIfItDoesNotFit: keepInstallNameIfItDoesNotFit,
      );
      if (!installNameSet) {
        log.stderr(
          'Warning: Code asset "$assetId" keeps its install name '
          '"$oldInstallName", because the header of '
          '${dylib.pathSegments.last} has no room for its new install name '
          'and dependency paths. The asset still loads. Linking the dylib '
          'with -headerpad_max_install_names avoids this.',
        );
      }
      await _codeSignDylib(dylib);
    }),
  );
}

/// Whether the directory of [dylib] is a canonical path.
///
/// Through a symlink, a dylib that is replaced while a process has it loaded
/// would load as a second copy, unless its install name is the path it is
/// loaded from.
Future<bool> _isInCanonicalDirectory(Uri dylib) async {
  final directory = File.fromUri(dylib).parent;
  return path.equals(await directory.resolveSymbolicLinks(), directory.path);
}

Future<String> _getInstallName(Uri dylib) async {
  final otoolResult = await Process.run('otool', ['-D', dylib.toFilePath()]);
  if (otoolResult.exitCode != 0) {
    throw Exception(
      'Failed to get install name for dylib $dylib: ${otoolResult.stderr}',
    );
  }
  final architectureSections = parseOtoolArchitectureSections(
    otoolResult.stdout,
  );
  if (architectureSections.length != 1) {
    throw Exception(
      'Expected a single architecture section in otool output: $otoolResult',
    );
  }
  return architectureSections.values.first.single;
}

/// Sets the install name of [dylib] to [newInstallName] and changes the
/// install names of its dependencies with [oldToNewInstallNames].
///
/// If [keepInstallNameIfItDoesNotFit] is true and `install_name_tool` reports
/// that the header of [dylib] has no room for the updated load commands, the
/// install name of [dylib] is left as it is and only its dependencies are
/// changed. If that fails as well, or `install_name_tool` fails for any other
/// reason, this throws.
///
/// Returns whether the install name of [dylib] was set to [newInstallName].
Future<bool> _setInstallNames(
  Uri dylib,
  String newInstallName,
  Map<String, String> oldToNewInstallNames, {
  required bool keepInstallNameIfItDoesNotFit,
}) async {
  final setInstallNamesResult = await _runInstallNameTool(
    dylib,
    oldToNewInstallNames,
    newInstallName: newInstallName,
  );
  if (setInstallNamesResult.exitCode == 0) {
    return true;
  }
  ProcessResult? changeDependenciesResult;
  if (keepInstallNameIfItDoesNotFit &&
      (setInstallNamesResult.stderr as String).contains(
        _loadCommandsDoNotFit,
      )) {
    changeDependenciesResult = await _runInstallNameTool(
      dylib,
      oldToNewInstallNames,
    );
    if (changeDependenciesResult.exitCode == 0) {
      return false;
    }
  }
  throw Exception(
    'Failed to set install names for dylib $dylib'
    '${changeDependenciesResult == null ? '' : ', also after keeping its install name'}:\n'
    'id -> $newInstallName\n'
    'dependencies -> $oldToNewInstallNames\n'
    '${setInstallNamesResult.stderr}'
    '${changeDependenciesResult == null ? '' : '\nAfter keeping the install name:\n${changeDependenciesResult.stderr}'}',
  );
}

/// Runs `install_name_tool` on [dylib] with a `-change` for each entry of
/// [oldToNewInstallNames], and with `-id` if [newInstallName] is given.
Future<ProcessResult> _runInstallNameTool(
  Uri dylib,
  Map<String, String> oldToNewInstallNames, {
  String? newInstallName,
}) => Process.run('install_name_tool', [
  if (newInstallName != null) ...['-id', newInstallName],
  for (final entry in oldToNewInstallNames.entries) ...[
    '-change',
    entry.key,
    entry.value,
  ],
  dylib.toFilePath(),
]);

/// What `install_name_tool` prints when the header of a dylib has no room for
/// the larger load commands.
///
/// If a later version words this differently, the fallback in
/// [_setInstallNames] no longer applies and dartdev fails as before.
const _loadCommandsDoNotFit = 'larger updated load commands do not fit';

Future<void> _codeSignDylib(Uri dylib) async {
  final codesignResult = await Process.run('codesign', [
    '--force',
    '--sign',
    '-',
    dylib.toFilePath(),
  ]);
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
  final RegExp architectureHeaderPattern = RegExp(
    r'^[^(]+( \(architecture (.+)\))?:$',
  );
  final Iterator<String> lines = output.trim().split('\n').iterator;
  Architecture? currentArchitecture;
  final Map<Architecture?, List<String>> architectureSections =
      <Architecture?, List<String>>{};

  while (lines.moveNext()) {
    final String line = lines.current;
    final Match? architectureHeader = architectureHeaderPattern.firstMatch(
      line,
    );
    if (architectureHeader != null) {
      if (architectureSections.containsKey(null)) {
        throw Exception(
          'Expected a single architecture section in otool output: $output',
        );
      }
      final String? architectureString = architectureHeader[2];
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

/// Rewrites the include path for an executable on MacOS.
///
/// The directory structure for `dart build cli` is
///
/// ```
/// bundle/
///   bin/
///     <executable>
///   lib/
///     <dylibs>
/// ```
///
/// So, the `bundle/` directory must be added to the include path to allow for
/// loading dylibs.
Future<void> rewriteInstallPath(Uri executable) async {
  final result = await Process.run('install_name_tool', [
    '-add_rpath',
    '@executable_path/..',
    executable.toFilePath(),
  ]);
  if (result.exitCode != 0) {
    throw Exception('Failed to add rpath: ${result.stderr}');
  }

  // Resign after modifying.
  final codesignResult = await Process.run('codesign', [
    '--force',
    '--sign',
    '-',
    executable.toFilePath(),
  ]);
  if (codesignResult.exitCode != 0) {
    throw Exception(
      'Failed to codesign dylib $executable: ${codesignResult.stderr}',
    );
  }
}
