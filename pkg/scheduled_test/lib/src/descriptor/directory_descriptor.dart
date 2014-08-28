// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.directory;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

import '../../descriptor.dart';
import '../../scheduled_test.dart';
import '../utils.dart';

/// A descriptor describing a directory containing multiple files.
class DirectoryDescriptor extends Descriptor implements LoadableDescriptor {
  /// The entries contained within this directory. This is intentionally
  /// mutable.
  final List<Descriptor> contents;

  DirectoryDescriptor(String name, Iterable<Descriptor> contents)
      : super(name),
        contents = contents.toList();

  /// Creates a directory descriptor named [name] based on a directory on the
  /// physical directory at [path].
  ///
  /// Note that reading from the filesystem isn't scheduled; it occurs as soon
  /// as this descriptor is constructed.
  DirectoryDescriptor.fromFilesystem(String name, String path)
      : this(name, new Directory(path).listSync().map((entity) {
          if (entity is Directory) {
            return new DirectoryDescriptor.fromFilesystem(
                p.basename(entity.path), entity.path);
          } else if (entity is File) {
            return new FileDescriptor.binary(
                p.basename(entity.path), entity.readAsBytesSync());
          }
          // Ignore broken symlinks.
        }));

  Future create([String parent]) => schedule(() {
    if (parent == null) parent = defaultRoot;
    var fullPath = p.join(parent, name);
    return Chain.track(new Directory(fullPath).create(recursive: true))
        .then((_) {
      return Future.wait(
          contents.map((entry) => entry.create(fullPath)).toList());
    });
  }, 'creating directory:\n${describe()}');

  Future validate([String parent]) => schedule(() => validateNow(parent),
      'validating directory:\n${describe()}');

  Future validateNow([String parent]) {
    if (parent == null) parent = defaultRoot;
    var fullPath = p.join(parent, name);
    if (!new Directory(fullPath).existsSync()) {
      fail("Directory not found: '$fullPath'.");
    }

    return Future.wait(contents.map((entry) {
      return syncFuture(() => entry.validateNow(fullPath))
          .then((_) => null)
          .catchError((e) => e);
    })).then((results) {
      var errors = results.where((e) => e != null);
      if (errors.isEmpty) return;
      throw _DirectoryValidationError.merge(errors);
    });
  }

  Stream<List<int>> load(String pathToLoad) {
    return futureStream(syncFuture(() {
      if (p.posix.isAbsolute(pathToLoad)) {
        throw new ArgumentError("Can't load absolute path '$pathToLoad'.");
      }

      var split = p.posix.split(p.posix.normalize(pathToLoad));
      if (split.isEmpty || split.first == '.' || split.first == '..') {
        throw new ArgumentError("Can't load '$pathToLoad' from within "
            "'$name'.");
      }

      var requiresReadable = split.length == 1;
      var matchingEntries = contents.where((entry) {
        return entry.name == split.first && (requiresReadable ?
            entry is ReadableDescriptor :
            entry is LoadableDescriptor);
      }).toList();

      var adjective = requiresReadable ? 'readable' : 'loadable';
      if (matchingEntries.length == 0) {
        fail("Couldn't find a $adjective entry named '${split.first}' within "
             "'$name'.");
      } else if (matchingEntries.length > 1) {
        fail("Found multiple $adjective entries named '${split.first}' within "
             "'$name'.");
      } else {
        var remainingPath = split.sublist(1);
        if (remainingPath.isEmpty) {
          return (matchingEntries.first as ReadableDescriptor).read();
        } else {
          return (matchingEntries.first as LoadableDescriptor)
              .load(p.posix.joinAll(remainingPath));
        }
      }
    }));
  }

  String describe() {
    if (contents.isEmpty) return name;

    var buffer = new StringBuffer();
    buffer.writeln(name);
    for (var entry in contents.take(contents.length - 1)) {
      var entryString = prefixLines(entry.describe(), prefix: '|   ')
          .replaceFirst('|   ', '|-- ');
      buffer.writeln(entryString);
    }

    var lastEntryString = prefixLines(contents.last.describe(), prefix: '    ')
        .replaceFirst('    ', "'-- ");
    buffer.write(lastEntryString);
    return buffer.toString();
  }
}

/// A class for formatting errors thrown by [DirectoryDescriptor].
class _DirectoryValidationError {
  final Iterable<String> errors;

  /// Flatten nested [_DirectoryValidationError]s in [errors] to create a single
  /// list of errors.
  static _DirectoryValidationError merge(Iterable errors) {
    return new _DirectoryValidationError(errors.expand((error) {
      if (error is _DirectoryValidationError) return error.errors;
      return [error];
    }));
  }

  _DirectoryValidationError(Iterable errors)
      : errors = errors.map((e) => e.toString()).toList();

  String toString() {
    if (errors.length == 1) return errors.single;
    return errors.map((e) => prefixLines(e, prefix: '  ', firstPrefix: '* '))
        .join('\n');
  }
}
