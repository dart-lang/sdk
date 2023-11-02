// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generate a json file representing the files in the Dart SDK and their sizes.
/// Print out instructions for opening Dart DevTools to visualize this info.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

late final String dartSdkPath;

final List<FileStats> fileStats = [];

void main(List<String> arguments) {
  final vm = Platform.resolvedExecutable;
  dartSdkPath = p.dirname(p.dirname(vm));
  final version =
      File(p.join(dartSdkPath, 'version')).readAsStringSync().trim();

  final sdkData = build(Directory(dartSdkPath), extra: {
    'comment-1': 'Dart SDK $version',
    'comment-2': '<size>',
    'type': 'web',
  });
  final sdkSize = fileStats.fold<int>(0, (previous, e) => previous + e.size);

  sdkData['comment-2'] = sizeMB(sdkSize);
  final outFile = File('sdk-size.json');
  outFile.writeAsStringSync(JsonEncoder.withIndent('').convert(sdkData));

  const width = 52;

  print('Large SDK files');
  print('-----------------');
  fileStats.sort();
  for (var stat in fileStats) {
    if (stat.size < 2 * 1042 * 1024) break;

    print('${stat.path.padRight(width)}: ${sizeMB(stat.size)}');
  }

  print('');
  print('SDK: $dartSdkPath');
  print('Version: $version');
  print('Size: ${sizeMB(sdkSize)}');

  print('');
  print('Wrote data to ${outFile.path}; to view the SDK size treemap, run:');
  print('');
  print('  dart devtools --app-size-base=${outFile.path}');
  print('');
}

String sizeMB(int size) => '${(size / (1024.0 * 1024)).toStringAsFixed(1)}MB';

Map build(FileSystemEntity entity, {Map<String, String> extra = const {}}) {
  const fsBlockSize = 4096.0;

  if (entity is File) {
    final size =
        ((entity.lengthSync() / fsBlockSize).ceilToDouble() * fsBlockSize)
            .truncate();
    fileStats.add(FileStats(p.relative(entity.path, from: dartSdkPath), size));
    return {
      'n': entity.name,
      'value': size,
    };
  } else {
    entity as Directory;

    return {
      ...extra,
      'n': '${entity.name}/',
      'children': [
        ...entity.listSyncSorted().map(build),
      ],
    };
  }
}

extension FileSystemEntityExtension on FileSystemEntity {
  String get name => p.basename(path);
}

extension DirectoryExtension on Directory {
  List<FileSystemEntity> listSyncSorted() {
    return listSync()..sort((a, b) => a.name.compareTo(b.name));
  }
}

class FileStats implements Comparable<FileStats> {
  final String path;
  final int size;

  FileStats(this.path, this.size);

  @override
  int compareTo(FileStats other) => other.size - size;
}
