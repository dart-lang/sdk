// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Builds the wasmer runtime library, to by used by package:wasm. Requires
// rustc, cargo, clang, and clang++. If a target triple is not specified, it
// will default to the host target.
// Usage: dart setup.dart [target-triple]

import 'dart:convert';
import 'dart:io';

Uri getSdkDir() {
  // The common case, and how cli_util.dart computes the Dart SDK directory,
  // path.dirname called twice on Platform.resolvedExecutable.
  final exe = Uri.file(Platform.resolvedExecutable);
  final commonSdkDir = exe.resolve('../../dart-sdk/');
  if (Directory(commonSdkDir.path).existsSync()) {
    return commonSdkDir;
  }

  // This is the less common case where the user is in the checked out Dart
  // SDK, and is executing dart via:
  // ./out/ReleaseX64/dart ...
  final checkedOutSdkDir = exe.resolve('../dart-sdk/');
  if (Directory(checkedOutSdkDir.path).existsSync()) {
    return checkedOutSdkDir;
  }

  final homebrewOutSdkDir = exe.resolve('..');
  final homebrewIncludeDir = homebrewOutSdkDir.resolve('include');
  if (Directory(homebrewIncludeDir.path).existsSync()) {
    return homebrewOutSdkDir;
  }

  // If neither returned above, we return the common case:
  return commonSdkDir;
}

Uri getOutDir(Uri root) {
  // Traverse up until we see a `.dart_tool/package_config.json` file.
  do {
    if (File.fromUri(root.resolve('.dart_tool/package_config.json'))
        .existsSync()) {
      return root.resolve('.dart_tool/wasm/');
    }
  } while (root != (root = root.resolve('..')));
  throw Exception(".dart_tool/package_config.json not found");
}

String getOutLib(String target) {
  final os = RegExp(r'^.*-.*-(.*)').firstMatch(target)?.group(1) ?? '';
  if (os == 'darwin' || os == 'ios') {
    return 'libwasmer.dylib';
  } else if (os == 'windows') {
    return 'wasmer.dll';
  }
  return 'libwasmer.so';
}

Future<String> getTargetTriple() async {
  final process = await Process.start('rustc', ['--print', 'cfg']);
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => stderr.writeln(line));
  final cfg = {};
  await process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    final match = RegExp(r'^([^=]+)="(.*)"$').firstMatch(line);
    if (match != null) cfg[match.group(1)] = match.group(2);
  }).asFuture();
  String arch = cfg['target_arch'] ?? 'unknown';
  String vendor = cfg['target_vendor'] ?? 'unknown';
  String os = cfg['target_os'] ?? 'unknown';
  if (os == 'macos') os = 'darwin';
  String? env = cfg['target_env'];
  return [arch, vendor, os, env]
      .where((element) => element != null && element.isNotEmpty)
      .join('-');
}

Future<void> run(String exe, List<String> args) async {
  print('\n$exe ${args.join(' ')}\n');
  final process = await Process.start(exe, args);
  process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => print(line));
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => stderr.writeln(line));
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print('Command failed with exit code ${exitCode}');
    exit(exitCode);
  }
}

Future<void> main(List<String> args) async {
  if (args.length > 1) {
    print('Usage: dart setup.dart [target-triple]');
    exit(1);
  }

  final target = args.isNotEmpty ? args[0] : await getTargetTriple();
  final sdkDir = getSdkDir();
  final binDir = Platform.script;
  final outDir = getOutDir(binDir);
  final outLib = outDir.resolve(getOutLib(target)).path;

  print('Dart SDK directory: ${sdkDir.path}');
  print('Script directory: ${binDir.path}');
  print('Output directory: ${outDir.path}');
  print('Target: $target');
  print('Output library: $outLib');

  // Build wasmer crate.
  await run('cargo', [
    'build',
    '--target',
    target,
    '--target-dir',
    outDir.path,
    '--manifest-path',
    binDir.resolve('Cargo.toml').path,
    '--release'
  ]);

  final dartApiDlImplFile =
      File.fromUri(sdkDir.resolve('include/internal/dart_api_dl_impl.h'));
  // Hack around a bug with dart_api_dl_impl.h include path in dart_api_dl.c.
  if (!dartApiDlImplFile.existsSync()) {
    Directory(outDir.resolve('include/internal/').path)
        .createSync(recursive: true);
    await dartApiDlImplFile
        .copy(outDir.resolve('include/internal/dart_api_dl_impl.h').path);
  }

  // Build dart_api_dl.o.
  await run('clang', [
    '-DDART_SHARED_LIB',
    '-DNDEBUG',
    '-fno-exceptions',
    '-fPIC',
    '-O3',
    '-target',
    target,
    '-I',
    sdkDir.resolve('include/').path,
    '-I',
    outDir.resolve('include/').path,
    '-c',
    sdkDir.resolve('include/dart_api_dl.c').path,
    '-o',
    outDir.resolve('dart_api_dl.o').path
  ]);

  // Build finalizers.o.
  await run('clang++', [
    '-DDART_SHARED_LIB',
    '-DNDEBUG',
    '-fno-exceptions',
    '-fno-rtti',
    '-fPIC',
    '-O3',
    '-std=c++11',
    '-target',
    target,
    '-I',
    sdkDir.path,
    '-I',
    outDir.resolve('include/').path,
    '-c',
    binDir.resolve('finalizers.cc').path,
    '-o',
    outDir.resolve('finalizers.o').path
  ]);

  // Link wasmer, dart_api_dl, and finalizers to create the output library.
  await run('clang++', [
    '-shared',
    '-Wl,--no-as-needed',
    '-Wl,--fatal-warnings',
    '-Wl,-z,now',
    '-Wl,-z,noexecstack',
    '-Wl,-z,relro',
    '-Wl,--build-id=none',
    '-fPIC',
    '-Wl,-O1',
    '-Wl,--gc-sections',
    '-target',
    target,
    outDir.resolve('dart_api_dl.o').path,
    outDir.resolve('finalizers.o').path,
    outDir.resolve('' + target + '/release/libwasmer.a').path,
    '-o',
    outLib
  ]);
}
