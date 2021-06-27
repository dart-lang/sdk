// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'templates/console_full.dart';
import 'templates/console_simple.dart';
import 'templates/package_simple.dart';
import 'templates/server_shelf.dart';
import 'templates/web_simple.dart';

final _substituteRegExp = RegExp(r'__([a-zA-Z]+)__');
final _nonValidSubstituteRegExp = RegExp('[^a-zA-Z]');

final List<Generator> generators = [
  ConsoleSimpleGenerator(),
  ConsoleFullGenerator(),
  PackageSimpleGenerator(),
  ServerShelfGenerator(),
  WebSimpleGenerator(),
];

Generator getGenerator(String id) =>
    generators.firstWhere((g) => g.id == id, orElse: () => null);

/// An abstract class which both defines a template generator and can generate a
/// user project based on this template.
abstract class Generator implements Comparable<Generator> {
  final String id;
  final String label;
  final String description;
  final List<String> categories;

  final List<TemplateFile> files = [];
  TemplateFile _entrypoint;

  Generator(
    this.id,
    this.label,
    this.description, {
    this.categories = const [],
  });

  /// The entrypoint of the application; the main file for the project, which an
  /// IDE might open after creating the project.
  TemplateFile get entrypoint => _entrypoint;

  TemplateFile addFile(String path, String contents) {
    return addTemplateFile(TemplateFile(path, contents));
  }

  /// Add a new template file.
  TemplateFile addTemplateFile(TemplateFile file) {
    files.add(file);
    return file;
  }

  /// Return the template file wih the given [path].
  TemplateFile getFile(String path) =>
      files.firstWhere((file) => file.path == path, orElse: () => null);

  /// Set the main entrypoint of this template. This is the 'most important'
  /// file of this template. An IDE might use this information to open this file
  /// after the user's project is generated.
  void setEntrypoint(TemplateFile entrypoint) {
    if (_entrypoint != null) throw StateError('entrypoint already set');
    if (entrypoint == null) throw StateError('entrypoint is null');
    _entrypoint = entrypoint;
  }

  void generate(
    String projectName,
    GeneratorTarget target, {
    Map<String, String> additionalVars,
  }) {
    final vars = {
      'projectName': projectName,
      'description': description,
      'year': DateTime.now().year.toString(),
      'author': '<your name>',
      if (additionalVars != null) ...additionalVars,
    };

    for (TemplateFile file in files) {
      final resultFile = file.runSubstitution(vars);
      final filePath = resultFile.path;
      target.createFile(filePath, resultFile.content);
    }
  }

  int numFiles() => files.length;

  @override
  int compareTo(Generator other) =>
      id.toLowerCase().compareTo(other.id.toLowerCase());

  /// Return some user facing instructions about how to finish installation of
  /// the template.
  ///
  /// [directory] is the directory of the generated project.
  ///
  /// [scriptPath] is the path of the default target script
  /// (e.g., bin/foo.dart) **without** an extension. If null, the implicit run
  /// command will be output by default (e.g., dart run).
  String getInstallInstructions(
    String directory,
    String scriptPath,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('  cd ${p.relative(directory)}');
    if (scriptPath != null) {
      buffer.write('  dart run $scriptPath.dart');
    } else {
      buffer.write('  dart run');
    }
    return buffer.toString();
  }

  @override
  String toString() => '[$id: $description]';
}

/// An abstract implementation of a [Generator].
abstract class DefaultGenerator extends Generator {
  DefaultGenerator(
    String id,
    String label,
    String description, {
    List<String> categories = const [],
  }) : super(id, label, description, categories: categories);
}

/// A target for a [Generator]. This class knows how to create files given a
/// path for the file (relative to the particular [GeneratorTarget] instance),
/// and the binary content for the file.
abstract class GeneratorTarget {
  /// Create a file at the given path with the given contents.
  void createFile(String path, List<int> contents);
}

/// This class represents a file in a generator template. The contents could
/// either be binary or text. If text, the contents may contain mustache
/// variables that can be substituted (`__myVar__`).
class TemplateFile {
  final String path;
  final String content;

  TemplateFile(this.path, this.content);

  FileContents runSubstitution(Map<String, String> parameters) {
    if (path == 'pubspec.yaml' && parameters['author'] == '<your name>') {
      parameters = Map.from(parameters);
      parameters['author'] = 'Your Name';
    }

    final newPath = substituteVars(path, parameters);
    final newContents = _createContent(parameters);

    return FileContents(newPath, newContents);
  }

  List<int> _createContent(Map<String, String> vars) {
    return utf8.encode(substituteVars(content, vars));
  }
}

class FileContents {
  final String path;
  final List<int> content;

  FileContents(this.path, this.content);
}

/// Given a `String` [str] with mustache templates, and a [Map] of String key /
/// value pairs, substitute all instances of `__key__` for `value`. I.e.,
///
/// ```
/// Foo __projectName__ baz.
/// ```
///
/// and
///
/// ```
/// {'projectName': 'bar'}
/// ```
///
/// becomes:
///
/// ```
/// Foo bar baz.
/// ```
///
/// A key value can only be an ASCII string made up of letters: A-Z, a-z.
/// No whitespace, numbers, or other characters are allowed.
@visibleForTesting
String substituteVars(String str, Map<String, String> vars) {
  if (vars.keys.any((element) => element.contains(_nonValidSubstituteRegExp))) {
    throw ArgumentError('vars.keys can only contain letters.');
  }

  return str.replaceAllMapped(_substituteRegExp, (match) {
    final item = vars[match[1]];

    if (item == null) {
      return match[0];
    } else {
      return item;
    }
  });
}
