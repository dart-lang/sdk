// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Builds the wasmer runtime library, to by used by package:wasm. Requires
// rustc, cargo, clang, and clang++. If a target triple is not specified, it
// will default to the host target.
// Usage: dart run wasm:setup [target-triple]

import 'dart:convert';
import 'dart:io' hide exit;

import 'package:wasm/src/shared.dart';

Future<void> main(List<String> args) async {
  if (args.length > 1) {
    print('Usage: $invocationString [target-triple]');
    exitCode = 64; // bad usage
    return;
  }

  final target = args.isNotEmpty ? args[0] : await _getTargetTriple();

  try {
    await _main(target);
  } on ProcessException catch (e) {
    final invocation = [e.executable, ...e.arguments].join(' ');
    print('FAILED with exit code ${e.errorCode} `$invocation`');
    exitCode = 70; // software error
    return;
  }
}

Uri _getSdkDir() {
  // The common case, and how cli_util.dart computes the Dart SDK directory,
  // path.dirname called twice on Platform.resolvedExecutable.
  final exe = Uri.file(Platform.resolvedExecutable);
  final commonSdkDir = exe.resolve('../../dart-sdk/');
  if (FileSystemEntity.isDirectorySync(commonSdkDir.path)) {
    return commonSdkDir;
  }

  // This is the less common case where the user is in the checked out Dart
  // SDK, and is executing dart via:
  // ./out/ReleaseX64/dart ...
  final checkedOutSdkDir = exe.resolve('../dart-sdk/');
  if (FileSystemEntity.isDirectorySync(checkedOutSdkDir.path)) {
    return checkedOutSdkDir;
  }

  final homebrewOutSdkDir = exe.resolve('..');
  final homebrewIncludeDir = homebrewOutSdkDir.resolve('include');
  if (FileSystemEntity.isDirectorySync(homebrewIncludeDir.path)) {
    return homebrewOutSdkDir;
  }

  // If neither returned above, we return the common case:
  return commonSdkDir;
}

Uri _getOutDir(Uri root) {
  final pkgRoot = packageRootUri(root);
  if (pkgRoot == null) {
    throw Exception('$pkgConfigFile not found');
  }
  return pkgRoot.resolve(wasmToolDir);
}

String _getOutLib(String target) {
  final os = RegExp(r'^.*-.*-(.*)').firstMatch(target)?.group(1) ?? '';
  if (os == 'darwin' || os == 'ios') {
    return appleLib;
  } else if (os == 'windows') {
    return 'wasmer.dll';
  }
  return linuxLib;
}

Future<String> _getTargetTriple() async {
  final _regexp = RegExp(r'^([^=]+)="(.*)"$');
  final process = await Process.start('rustc', ['--print', 'cfg']);
  final sub = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => stderr.writeln(line));
  final cfg = <String, String?>{};
  await process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) {
    final match = _regexp.firstMatch(line);
    if (match != null) cfg[match.group(1)!] = match.group(2);
  });
  await sub.cancel();
  var arch = cfg['target_arch'] ?? 'unknown';
  var vendor = cfg['target_vendor'] ?? 'unknown';
  var os = cfg['target_os'] ?? 'unknown';
  if (os == 'macos') os = 'darwin';
  var env = cfg['target_env'];
  return [arch, vendor, os, env]
      .where((element) => element != null && element.isNotEmpty)
      .join('-');
}

Future<void> _run(String exe, List<String> args) async {
  print('\n$exe ${args.join(' ')}\n');
  final process =
      await Process.start(exe, args, mode: ProcessStartMode.inheritStdio);
  final result = await process.exitCode;
  if (result != 0) {
    throw ProcessException(exe, args, '', result);
  }
}

Future<void> _main(String target) async {
  final sdkDir = _getSdkDir();
  final binDir = Platform.script;
  final outDir = _getOutDir(Directory.current.uri);
  final outLib = outDir.resolve(_getOutLib(target)).path;

  print('Dart SDK directory: ${sdkDir.path}');
  print('Script directory: ${binDir.path}');
  print('Output directory: ${outDir.path}');
  print('Target: $target');
  print('Output library: $outLib');

  // Build wasmer crate.
  await _run('cargo', [
    'build',
    '--target',
    target,
    '--target-dir',
    outDir.path,
    '--manifest-path',
    binDir.resolve('Cargo.toml').path,
    '--release'
  ]);

  const dartApiDlImplPath = 'include/internal/dart_api_dl_impl.h';

  final dartApiDlImplFile = File.fromUri(sdkDir.resolve(dartApiDlImplPath));
  // Hack around a bug with dart_api_dl_impl.h include path in dart_api_dl.c.
  if (!dartApiDlImplFile.existsSync()) {
    Directory(outDir.resolve('include/internal/').path)
        .createSync(recursive: true);
    await dartApiDlImplFile.copy(outDir.resolve(dartApiDlImplPath).path);
  }

  // Build dart_api_dl.o.
  await _run('clang', [
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
  await _run('clang++', [
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
  await _run('clang++', [
    '-shared',
    '-fPIC',
    '-target',
    target,
    outDir.resolve('dart_api_dl.o').path,
    outDir.resolve('finalizers.o').path,
    outDir.resolve('$target/release/libwasmer.a').path,
    '-o',
    outLib
  ]);
}
