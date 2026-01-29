#!tools/sdks/dart-sdk/bin/dart
// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' as convert show json;
import 'dart:io';

import 'package:pool/pool.dart';

final pool = Pool(Platform.numberOfProcessors);

Future<void> buildOffsetsExtractor(List<String> args) async {
  // Build all configurations
  await forAllConfigurationsMode((
    String buildDir,
    String mode,
    String arch,
  ) async {
    print('Building $buildDir');
    await run([
      'tools/build.py',
      ...args,
      '-a$arch',
      '-m$mode',
      '--no-rbe',
      'offsets_extractor',
      'offsets_extractor_aotruntime',
    ]);
    print('Building $buildDir - done');
  });
}

Future<String> runOffsetsExtractor() async {
  final (jit, aot) = await (
    forAllConfigurationsMode((String buildDir, _, __) async {
      return await run(['$buildDir/offsets_extractor']);
    }).then<String>((lines) => lines.join(',\n')),
    forAllConfigurationsMode((String buildDir, _, __) async {
      return await run(['$buildDir/offsets_extractor_aotruntime']);
    }).then<String>((lines) => lines.join(',\n')),
  ).wait;

  final buf = StringBuffer();
  buf.writeln('[');
  buf.writeln(jit);
  buf.writeln(',');
  buf.writeln(aot);
  buf.writeln(']');
  return buf.toString();
}

String toCValue(Object? value) {
  final intValue = int.parse(value as String);
  if (intValue == -1) return '-1';
  if (intValue < 0) {
    return '-0x${(-intValue).toRadixString(16)}';
  }
  return '0x${intValue.toRadixString(16)}';
}

Future<void> writeCHeaderFile(List json) async {
  final extractedOffsetsFile =
      'runtime/vm/compiler/runtime_offsets_extracted.h';

  final old = File(extractedOffsetsFile).readAsStringSync();
  final header = old.substring(0, old.indexOf('\n#if '));
  final footer = old.substring(old.lastIndexOf('\n#endif '));

  final output = StringBuffer();
  output.writeln(header);
  for (final config in json) {
    final product = (config['product'] as bool) ? '' : '!';
    final productDef = '${product}defined(PRODUCT)';
    final arch = (config['arch'] as String).toUpperCase();
    final archDef = 'defined(TARGET_ARCH_$arch)';
    final compressed = (config['compressed'] as bool) ? '' : '!';
    final compressedDef = '${compressed}defined(DART_COMPRESSED_POINTERS)';
    final aot = (config['aot'] as bool) ? 'AOT_' : '';
    final prefix = 'static constexpr dart::compiler::target::word $aot';
    final offsets = config['offsets'] as List;
    output.writeln('#if $productDef && $archDef && $compressedDef');
    for (final offset in offsets) {
      final kind = offset['kind'] as String;
      switch (kind) {
        case 'value':
          final cls = offset['class'] as String;
          final name = offset['name'] as String;
          final value = toCValue(offset['value']);
          output.writeln('$prefix${cls}_$name = $value;');
          break;
        case 'array':
          final cls = offset['class'] as String;
          final startOffset = toCValue(offset['startOffset']);
          final elemSize = toCValue(offset['elemSize']);
          output.writeln('$prefix${cls}_elements_start_offset = $startOffset;');
          output.writeln('$prefix${cls}_element_size = $elemSize;');
          break;
        case 'range':
          final cls = offset['class'] as String;
          final name = offset['name'] as String;
          final values = (offset['values'] as List).map(toCValue).toList();
          output.writeln('$prefix${cls}_$name[] = {${values.join(', ')}};');
          break;
      }
    }
    output.writeln('#endif  // $productDef &&');
    output.writeln('        // $archDef &&');
    output.writeln('        // $compressedDef');
    output.writeln();
  }
  output.writeln(footer);
  File(extractedOffsetsFile).writeAsStringSync(output.toString());
  print('Written $extractedOffsetsFile');
  print('Running `git cl format $extractedOffsetsFile');
  await run(['git', 'cl', 'format', extractedOffsetsFile]);
}

Future<void> writeDartFile(List json) async {
  final extractedOffsetsFile =
      'pkg/native_compiler/lib/runtime/vm_offsets.g.dart';

  final old = File(extractedOffsetsFile).readAsStringSync();
  final header = old.substring(0, old.indexOf('base class '));

  // Filter useful configurations.
  final configs = json
      .where((c) => c['arch'] == 'arm64' && !c['compressed'] && !c['aot'])
      .toList();

  // Collect set of method names to declare in the base class.
  // Collect enums and verify that they are the same across configurations.
  final values = <String>{};
  final arrays = <String>{};
  final ranges = <String>{};
  final enums = <String, String>{};
  for (final config in configs) {
    final offsets = config['offsets'] as List;
    for (final offset in offsets) {
      final kind = offset['kind'] as String;
      switch (kind) {
        case 'value':
          values.add(dartName(offset['class'], offset['name']));
          break;
        case 'array':
          arrays.add(dartName(offset['class'], ''));
          break;
        case 'range':
          ranges.add(dartName(offset['class'], offset['name']));
          break;
        case 'enum':
          {
            final name = offset['name'];
            final elements = (offset['elements'] as List).join(',\n');
            if ((enums[name] ??= elements) != elements) {
              throw 'Enum $name is inconsistent across configurations';
            }
            break;
          }
      }
    }
  }

  // Generate base class.
  final output = StringBuffer();
  output.writeln(header);
  output.writeln('base class VMOffsets {');
  for (final name in values) {
    output.writeln("  int get $name => throw 'Unknown';");
  }
  for (final name in arrays) {
    output.writeln("  int get ${name}_elementsStartOffset => throw 'Unknown';");
    output.writeln("  int get ${name}_elementSize => throw 'Unknown';");
    output.writeln('  int ${name}_elementOffset(int index) => '
        '${name}_elementsStartOffset + index * ${name}_elementSize;');
  }
  for (final name in ranges) {
    output.writeln("  List<int> get $name => throw 'Unknown';");
  }
  output.writeln('}');
  output.writeln('');

  // Generate class per configuration.
  for (final config in configs) {
    final product = (config['product'] as bool) ? 'Product' : '';
    final arch = (config['arch'] as String).capitalized;
    final compressed = (config['compressed'] as bool) ? 'Compressed' : '';
    final aot = (config['aot'] as bool) ? 'AOT' : '';
    output.writeln(
        'final class $arch$product$compressed${aot}VMOffsets extends VMOffsets {');
    final offsets = config['offsets'] as List;
    for (final offset in offsets) {
      final kind = offset['kind'] as String;
      switch (kind) {
        case 'value':
          final name = dartName(offset['class'], offset['name']);
          final value = toCValue(offset['value']);
          output.writeln('  @override int get $name => $value;');
          break;
        case 'array':
          final name = dartName(offset['class'], '');
          final startOffset = toCValue(offset['startOffset']);
          final elemSize = toCValue(offset['elemSize']);
          output.writeln('  @override int get ${name}_elementsStartOffset => '
              '$startOffset;');
          output.writeln('  @override int get ${name}_elementSize => '
              '$elemSize;');
          break;
        case 'range':
          final name = dartName(offset['class'], offset['name']);
          final values = (offset['values'] as List).map(toCValue).toList();
          output.writeln('  @override List<int> get $name => '
              '[${values.join(', ')}];');
          break;
      }
    }
    output.writeln('}');
    output.writeln();
  }

  // Generate enums.
  for (final MapEntry(key: name, value: elements) in enums.entries) {
    output.writeln("enum ${name.capitalized} {");
    output.writeln("  $elements");
    output.writeln('}');
    output.writeln();
  }

  File(extractedOffsetsFile).writeAsStringSync(output.toString());
  print('Written $extractedOffsetsFile');
  print('Running `${Platform.executable} format $extractedOffsetsFile');
  await run([Platform.executable, 'format', extractedOffsetsFile]);
}

String dartName(String cls, String name) {
  final buf = StringBuffer();
  buf.write(cls);
  if (name.isNotEmpty) {
    buf.write('_');
    buf.write(name);
  }
  return buf.toString();
}

Future<List<T>> forAllConfigurationsMode<T>(
  Future<T> Function(String buildDir, String mode, String arch) fun,
) async {
  final archs = [
    'simarm',
    'x64',
    'ia32',
    'simarm64',
    'x64c',
    'simarm64c',
    'simriscv32',
    'simriscv64',
  ];
  final futures = <Future<T>>[];
  for (final mode in ['release', 'product']) {
    for (final arch in archs) {
      final buildDir = 'out/${mode.capitalized}${arch.upper}/';
      futures.add(pool.withResource(() => fun(buildDir, mode, arch)));
    }
  }
  return await Future.wait(futures);
}

Future<String> run(List<String> args) async {
  final result = await Process.run(
    args.first,
    args.skip(1).toList(),
    runInShell: true,
  );
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    print('Running ${args.join(' ')} has failed with exit code $exitCode:');
    print('${result.stdout}');
    print('${result.stderr}');
  }
  return result.stdout;
}

extension on String {
  String get capitalized => substring(0, 1).toUpperCase() + substring(1);
  String get upper => toUpperCase();
}

void main(List<String> args) async {
  final sdkRoot = Platform.script.resolve('../').toFilePath();
  Directory.current = Directory(sdkRoot);

  await buildOffsetsExtractor(args);
  if (exitCode != 0) {
    return;
  }

  final text = await runOffsetsExtractor();
  if (exitCode != 0) {
    return;
  }

  final json = convert.json.decode(text) as List;

  await writeCHeaderFile(json);
  await writeDartFile(json);
}
