// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:async/async.dart';
import 'package:pub_semver/pub_semver.dart' show Version;
import 'package:tar/tar.dart';
import 'package:yaml/yaml.dart' show loadYaml;

/// Representation of a pub package for testing purposes.
final class Package {
  final String name;
  final Version version;
  final Map<String, Object?> pubspec;
  final Uint8List archive;

  Package._({
    required this.name,
    required this.version,
    required this.pubspec,
    required this.archive,
  });

  /// Create a [Package] from a map of [files], that map from file-path to
  /// file contents.
  ///
  /// The [files] map must contain a 'pubspec.yaml' entry!
  static Future<Package> fromFileMap(Map<String, String> files) async =>
      await fromArchive(
        await collectBytes(
          Stream<TarEntry>.fromIterable(
            files.entries.map(
              (f) => TarEntry.data(
                TarHeader(name: f.key, mode: 420),
                utf8.encode(f.value),
              ),
            ),
          ).transform(tarWriter).transform(gzip.encoder),
        ),
      );

  /// Create a [Package] from a .tar.gz archive.
  static Future<Package> fromArchive(Uint8List archive) async {
    Map<String, Object?>? ps;
    final stream = Stream<List<int>>.value(archive).transform(gzip.decoder);
    await TarReader.forEach(stream, (e) async {
      if (e.name == 'pubspec.yaml') {
        ps = _yamlToJson(await utf8.decodeStream(e.contents));
      }
    });
    final pubspec = ps;
    if (pubspec == null) {
      throw const FormatException('archive must contain a "pubspec.yaml"');
    }

    final name = pubspec['name'];
    if (name is! String) {
      throw const FormatException('pubspec.yaml must contain a "name"');
    }
    final v = pubspec['version'];
    if (v is! String) {
      throw const FormatException('pubspec.yaml must contain a "version"');
    }
    final version = Version.parse(v);

    return Package._(
      name: name,
      version: version,
      pubspec: pubspec,
      archive: archive,
    );
  }
}

Map<String, Object?> _yamlToJson(String yamlString) {
  final yaml = loadYaml(yamlString);
  return _convertYamlNode(yaml) as Map<String, dynamic>;
}

Object? _convertYamlNode(Object? node) {
  if (node is Map) {
    return node.map((k, v) => MapEntry(k.toString(), _convertYamlNode(v)));
  } else if (node is Iterable) {
    return node.map(_convertYamlNode).toList();
  } else {
    return node;
  }
}
