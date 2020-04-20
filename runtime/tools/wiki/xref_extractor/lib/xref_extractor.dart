// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library for converting cquery cache into condensed symbol location
// information expected by our xref markdown extension.

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:path/path.dart' as p;

typedef FileFilterCallback = bool Function(String path);

/// Load cquery cache from the given directory and accumulate all symbols
/// (global functions and class methods) for the Dart SDK related sources
/// matching the given filter.
Future<void> generateXRef(String cqueryCachePath, String sdkRootPath,
    FileFilterCallback fileFilter) async {
  final cacheRoot =
      Directory(p.join(cqueryCachePath, sdkRootPath.replaceAll('/', '@')));
  final files = cacheRoot
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList();
  print('Processing ${files.length} indexes available in ${cacheRoot.path}');

  final cache = CqueryCache(fileFilter: fileFilter);
  files.forEach(cache.loadFile);

  final classesByName = <String, Class>{
    for (var entry in cache.classes.entries)
      if (entry.value.name != null && entry.value.name != '')
        entry.value.name: entry.value
  };

  final database = {
    'commit': await currentCommitHash(),
    'files': cache.filesByIndex,
    'classes': classesByName,
    'functions': cache.globals.uniqueMembers
  };

  File('xref.json').writeAsStringSync(jsonEncode(database));
  print('... done (written xref.json)');
}

/// Helper class representing symbol information contained in the cquery cache.
class CqueryCache {
  final files = <String, int>{};
  final filesByIndex = [];

  final classes = <num, Class>{};
  final globals = Class('\$Globals');

  FileFilterCallback fileFilter;

  CqueryCache({this.fileFilter});

  int addFile(String name) => files.putIfAbsent(name, () {
        filesByIndex.add(name);
        return filesByIndex.length - 1;
      });

  Location makeLocation(String file, int lineNo) =>
      Location(addFile(file), lineNo);

  // cquery used to serialize USRs as integers but they are now serialized as
  // doubles (with .0 at the end) for some reason. This might even lead to
  // incorrect deserialization with a loss of a precise USR value - but
  // should not lead to any issues as long as two different classes don't
  // have conflicting USRs.
  Class findClassByUsr(num usr) => classes.putIfAbsent(usr, () => Class());

  void defineClass(num usr, String name, Location loc) {
    final cls = findClassByUsr(usr);
    if (cls.name != null && cls.name != '' && cls.name != name) {
      throw 'Mismatched names';
    }
    if (name != '') cls.name = name;
    if (cls.loc == null) {
      cls.loc = loc;
    } else {
      cls.loc = Location.invalid;
    }
  }

  void loadFile(File indexFile) {
    final result = jsonDecode(indexFile.readAsStringSync().split('\n')[1]);

    // Check if we are interested in the original source file.
    final sourceFile =
        p.basenameWithoutExtension(indexFile.path).replaceAll('@', '/');
    if (!fileFilter(sourceFile)) return;

    // Extract classes defined in the file.
    for (var type in result['types']) {
      if (type['kind'] != SymbolKind.Class) continue;
      final extent = type['extent'];
      if (extent == null) continue;

      final detailedName = type['detailed_name'];
      final lineStart = int.parse(extent.substring(0, extent.indexOf(':')));
      defineClass(
          type['usr'], detailedName, makeLocation(sourceFile, lineStart));
    }

    // Extract class methods defined in the file.
    for (var func in result['funcs']) {
      final kind = func['kind'];
      if (kind != SymbolKind.Method && kind != SymbolKind.StaticMethod) {
        continue;
      }
      final extent = func['extent'];
      if (extent == null) continue;
      final short = shortName(func);
      final lineStart = int.parse(extent.substring(0, extent.indexOf(':')));
      if (func['declaring_type'] == null) {
        continue;
      }
      findClassByUsr(result['types'][func['declaring_type']]['usr'])
          .defineMember(short, makeLocation(sourceFile, lineStart));
    }

    // Extract global functions defined in the file.
    for (var func in result['funcs']) {
      final kind = func['kind'];
      if (kind != SymbolKind.Function) continue;
      final extent = func['extent'];
      if (extent == null) continue;
      final short = shortName(func);
      final lineStart = int.parse(extent.substring(0, extent.indexOf(':')));
      globals.defineMember(short, makeLocation(sourceFile, lineStart));
    }
  }
}

class Class {
  String name;
  Location loc;

  // Member to definition location map. If the same symbol has multiple
  // definitions then we mark it with [Location.invalid].
  Map<String, Location> members;

  Class([this.name]);

  void defineMember(String name, Location loc) {
    members ??= <String, Location>{};
    members[name] = members.containsKey(name) ? Location.invalid : loc;
  }

  dynamic toJson() {
    final result = [loc?.toJson() ?? 0];
    if (members != null) {
      final res = uniqueMembers;
      if (res.isNotEmpty) {
        result.add(res);
      }
    }
    return result;
  }

  Map<String, Location> get uniqueMembers => <String, Location>{
        for (var entry in members.entries)
          if (entry.value != Location.invalid) entry.key: entry.value
      };
}

class Location {
  final int file;
  final int lineNo;

  const Location(this.file, this.lineNo);

  String toJson() => identical(this, invalid) ? null : '$file:$lineNo';

  @override
  String toString() => '$file:$lineNo';

  static const invalid = Location(-1, -1);
}

String shortName(entity) {
  final offset = entity['short_name_offset'];
  final length = entity['short_name_size'] ?? 0;
  final detailedName = entity['detailed_name'];
  if (length == 0) return detailedName;
  return detailedName.substring(offset, offset + length);
}

Future<String> currentCommitHash() async {
  final results = await Process.run('git', ['rev-parse', 'HEAD']);
  return results.stdout;
}

/// Kind of the symbol. Taken from LSP specifications and cquery source code.
abstract class SymbolKind {
  static const Unknown = 0;

  static const File = 1;
  static const Module = 2;
  static const Namespace = 3;
  static const Package = 4;
  static const Class = 5;
  static const Method = 6;
  static const Property = 7;
  static const Field = 8;
  static const Constructor = 9;
  static const Enum = 10;
  static const Interface = 11;
  static const Function = 12;
  static const Variable = 13;
  static const Constant = 14;
  static const String = 15;
  static const Number = 16;
  static const Boolean = 17;
  static const Array = 18;
  static const Object = 19;
  static const Key = 20;
  static const Null = 21;
  static const EnumMember = 22;
  static const Struct = 23;
  static const Event = 24;
  static const Operator = 25;
  static const TypeParameter = 26;

  // cquery extensions.
  static const TypeAlias = 252;
  static const Parameter = 253;
  static const StaticMethod = 254;
  static const Macro = 255;
}
