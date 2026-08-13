// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'models.dart';

/// Apply a single contiguous text edit.
String applyEdit(String before, MutationEdit e) {
  return before.replaceRange(e.offset, e.offset + e.length, e.replacement);
}

/// Discovers .dart files under [roots], skipping generated/build/tooling dirs.
List<String> discoverDartFiles(List<String> roots, String repo) {
  var result = <String>[];
  for (var root in roots) {
    if (!io.Directory(root).existsSync()) continue;
    for (var entry in io.Directory(
      root,
    ).listSync(recursive: true, followLinks: false)) {
      if (entry is io.File && entry.path.endsWith('.dart')) {
        var relPath = p.relative(entry.path, from: repo);
        if (relPath.endsWith('.g.dart') ||
            relPath.contains(RegExp(r'(^|/)build/')) ||
            relPath.contains(RegExp(r'(^|/)\.dart_tool/'))) {
          continue;
        }
        result.add(entry.path);
      }
    }
  }
  result.sort();
  return result;
}

double medianSpeedup(List<double> xs) {
  var ys = xs.where((e) => e.isFinite && e > 0).toList()..sort();
  if (ys.isEmpty) return 1.0;
  var mid = ys.length ~/ 2;
  return ys.length.isOdd ? ys[mid] : (ys[mid - 1] + ys[mid]) / 2.0;
}

double p90Speedup(List<double> xs) {
  var ys = xs.where((e) => e.isFinite && e > 0).toList()..sort();
  if (ys.isEmpty) return 1.0;
  var idx = (ys.length * 0.9).floor().clamp(0, ys.length - 1);
  return ys[idx];
}

/// Stateless pick of an index in [0, upper).
int pickIndex(int upper, List<Object?> seedParts) {
  if (upper <= 1) return 0;
  var random = Random(seedOf(seedParts));
  return random.nextInt(upper);
}

/// Stable 32-bit seed from [parts] using SHA-256 over a canonical encoding.
/// Supports: null, String, int. Extend with more tags if needed.
int seedOf(Iterable<Object?> parts) {
  var sb = StringBuffer();
  for (var part in parts) {
    switch (part) {
      case null:
        sb.write('N;');
      case String():
        sb
          ..write('S')
          ..write(part.length)
          ..write(':')
          ..write(part)
          ..write(';');
      case int():
        sb
          ..write('I')
          ..write(part)
          ..write(';');
      default:
        throw UnimplementedError('Unsupported: ${part.runtimeType}');
    }
  }
  var bytes = sha256.convert(utf8.encode(sb.toString())).bytes;
  return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
}

/// Returns A/B speedup as A_time/B_time; defaults to 1.0 on missing/zeros.
double speedup(Map<String, Object?> m) {
  var a = (m['A_time_ms'] as num?)?.toDouble() ?? 0.0;
  var b = (m['B_time_ms'] as num?)?.toDouble() ?? 0.0;
  if (a <= 0 || b <= 0) return 1.0;
  return a / b;
}

Iterable<String> splitCsv(String str) {
  return str.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
}

String timestampId() {
  String pad(int v) => v < 10 ? '0$v' : '$v';

  var n = DateTime.now().toUtc();
  return '${n.year}${pad(n.month)}${pad(n.day)}T'
      '${pad(n.hour)}${pad(n.minute)}${pad(n.second)}Z';
}

/// Pretty JSON writer with recursive directories creation.
void writeJson(String path, Object? data) {
  io.File(path).createSync(recursive: true);
  io.File(path).writeAsStringSync(JsonEncoder.withIndent('  ').convert(data));
}
