// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ffi';

import 'package:path/path.dart' as p;

final hostArch = switch (Abi.current()) {
  Abi.linuxArm => 'arm',
  Abi.macosArm64 || Abi.linuxArm64 => 'arm64',
  Abi.macosX64 || Abi.linuxX64 => 'x64',
  _ => throw 'Unsupported platform',
};

Future<void> protoc({
  required String protocPath,
  required String protoPath,
  required String plugin,
  required String outDir,
  List<String>? pluginOptions,
  required List<String> protos,
}) async {
  final pluginOut = [...?pluginOptions, outDir].join(':');
  final args = [
    '--proto_path=$protoPath',
    '--plugin=protoc-gen-plugin=$plugin',
    '--plugin_out=$pluginOut',
    ...protos,
  ];
  print('Running: $protocPath ${args.join(' ')}');
  final result = await Process.run(protocPath, args);
  if (result.exitCode != 0) {
    print('protoc invocation failed with ${result.exitCode}');
    print('stdout:');
    print('${result.stdout}');
    print('stderr:');
    print('${result.stderr}');
    throw StateError(
      'failed to generate protobuf files using protoc with $plugin',
    );
  }
}

Future<void> compilePerfettoProtos({
  required String protocPath,
  required String protozeroPath,
  required String outDir,
}) async {
  final protos = Directory('third_party/perfetto/protos')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.proto'))
      .map((f) => f.path)
      .toList();
  await protoc(
    protocPath: protocPath,
    protoPath: 'third_party/perfetto',
    plugin: protozeroPath,
    pluginOptions: ['wrapper_namespace=pbzero'],
    outDir: outDir,
    protos: protos,
  );
  await protoc(
    protocPath: protocPath,
    protoPath: 'third_party/perfetto',
    plugin: 'third_party/perfetto/tools/protoc_gen_dart_wrapper',
    outDir: outDir,
    protos: protos,
  );
}

const noticesToPrepend = r'''
// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
''';

Future<void> copyGeneratedFiles({
  required Set<String> extensions,
  required Directory source,
  required Directory destination,
}) async {
  for (final file in Directory(source.path).listSync(recursive: true)) {
    if (file is File && extensions.contains(p.extension(file.path))) {
      if (file.path.endsWith('.pbenum.dart') &&
          file.readAsStringSync().indexOf('class') == -1) {
        // Drop empty .pbenum.dart files.
        continue;
      }

      final relativePath = p.relative(file.path, from: source.path);
      final destinationPath = p.join(destination.path, relativePath);
      Directory(p.dirname(destinationPath)).createSync(recursive: true);

      final contentsIncludingPrependedNotices =
          noticesToPrepend + file.readAsStringSync();
      File(
        destinationPath,
      ).writeAsStringSync(contentsIncludingPrependedNotices);
    }
  }
}

void createFileThatExportsAllGeneratedDartCode() {
  final file = File('./pkg/vm_service_protos/lib/vm_service_protos.dart');
  if (!file.existsSync()) {
    file.createSync();
  }

  final content = StringBuffer();

  content.writeln(noticesToPrepend);

  final generatedDartFilePaths =
      Directory('./pkg/vm_service_protos/lib/src/protos/perfetto')
          .listSync(recursive: true)
          .where((entity) => entity is File)
          .map((file) => file.path)
          .toList();
  generatedDartFilePaths.sort();
  for (final path in generatedDartFilePaths) {
    final pathToExport = path.replaceAll('./pkg/vm_service_protos/lib/', '');
    content.writeln('export \'$pathToExport\';');
  }

  file.writeAsStringSync(content.toString());
}

final pathDirs = (Platform.environment['PATH'] ?? '').split(':');

String? locateBinaryInPath(String binary) {
  for (var dir in pathDirs) {
    var path = p.join(dir, binary);
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

void main(List<String> args) async {
  if (!Directory('./third_party/perfetto').existsSync()) {
    print('Error: this tool must be run from the root directory of the SDK.');
    exit(1);
    return;
  }

  if (!(Platform.isLinux || Platform.isMacOS)) {
    print('Error: this tool can only run on Linux or Mac OS X');
    exit(1);
    return;
  }

  final protocPath = locateBinaryInPath('protoc');
  final protozeroPath = locateBinaryInPath('protozero_plugin');

  if (protocPath == null) {
    print('Error: protoc binary must be available in PATH');
    exit(1);
  }

  if (protozeroPath == null) {
    print('Error: protozero_plugin binary must be available in PATH');
    exit(1);
  }

  final tempDir = Directory.systemTemp.createTempSync(
    'compile_perfetto_protos',
  );

  try {
    await compilePerfettoProtos(
      protocPath: protocPath,
      protozeroPath: protozeroPath,
      outDir: tempDir.path,
    );
    await copyGeneratedFiles(
      extensions: {'.cc', '.h'},
      destination: Directory('third_party/perfetto'),
      source: tempDir,
    );
    await copyGeneratedFiles(
      extensions: {'.dart'},
      destination: Directory('./pkg/vm_service_protos/lib/src'),
      source: tempDir,
    );
    createFileThatExportsAllGeneratedDartCode();
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
