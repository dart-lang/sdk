// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.pattern;

import 'dart:async';
import 'dart:io';

import 'package:pathos/path.dart' as path;

import '../../descriptor.dart';
import '../../scheduled_test.dart';
import '../utils.dart';

/// A function that takes a name for a [Descriptor] and returns a [Descriptor].
/// This is used for [PatternDescriptor]s, where the name isn't known
/// ahead-of-time.
typedef Descriptor EntryCreator(String name);

/// A descriptor that matches filesystem entities by [Pattern] rather than
/// by [String]. It's used only for validation.
///
/// This class takes an [EntryCreator], which should return a [Descriptor] that
/// will be used to validate the concrete filesystem entities that match the
/// [pattern].
class PatternDescriptor extends Descriptor {
  /// The [Pattern] this matches filenames against. Note that the pattern must
  /// match the entire basename of the file.
  final Pattern pattern;

  /// The function used to generate the [Descriptor] for filesystem entities
  /// matching [pattern].
  final EntryCreator _fn;

  PatternDescriptor(Pattern pattern, this._fn)
      : super('$pattern'),
        pattern = pattern;

  /// Validates that there is some filesystem entity in [parent] that matches
  /// [pattern] and the child entry. This finds all entities in [parent]
  /// matching [pattern], then passes each of their names to the [EntityCreator]
  /// and validates the result. If exactly one succeeds, [this] is considered
  /// valid.
  Future validate([String parent]) => schedule(() => validateNow(parent),
      "validating ${describe()}");

  Future validateNow([String parent]) {
    if (parent == null) parent = defaultRoot;
    // TODO(nweiz): make sure this works with symlinks.
    var matchingEntries = new Directory(parent).listSync()
        .map((entry) => entry is File ? entry.fullPathSync() : entry.path)
        .where((entry) => fullMatch(path.basename(entry), pattern))
        .toList();
    matchingEntries.sort();

    if (matchingEntries.isEmpty) {
      throw "No entry found in '$parent' matching ${_patternDescription}.";
    }

    return Future.wait(matchingEntries.map((entry) {
      var descriptor = _fn(path.basename(entry));
      return descriptor.validateNow(parent).then((_) {
        return new Pair(null, descriptor.describe());
      }).catchError((error) {
        return new Pair(error.toString(), descriptor.describe());
      });
    })).then((results) {
      var matches = results.where((result) => result.first == null).toList();
      // If exactly one entry matching [pattern] validated, we're happy.
      if (matches.length == 1) return;

      // If more than one entry matching [pattern] validated, that's bad.
      if (matches.length > 1) {
        var resultString = matches.map((result) {
          return prefixLines(result.last, firstPrefix: '* ', prefix: '  ');
        }).join('\n');

        throw "Multiple valid entries found in '$parent' matching "
                "$_patternDescription:\n"
            "$resultString";
      }

      // If no entries matching [pattern] validated, that's also bad.
      var resultString = results.map((result) {
        return prefixLines(
            "Caught error\n"
            "${prefixLines(result.first)}\n"
            "while validating\n"
            "${prefixLines(result.last)}",
            firstPrefix: '* ', prefix: '  ');
      }).join('\n');

      throw "No valid entries found in '$parent' matching "
              "$_patternDescription:\n"
          "$resultString";
    });
  }

  String describe() => "entry matching $_patternDescription";

  String get _patternDescription {
    if (pattern is String) return "'$pattern'";
    if (pattern is! RegExp) return '$pattern';

    var regExp = pattern as RegExp;
    var flags = new StringBuffer();
    if (!regExp.isCaseSensitive) flags.write('i');
    if (regExp.isMultiLine) flags.write('m');
    return '/${regExp.pattern}/$flags';
  }

  Future create([String parent]) => new Future.error(
      new UnsupportedError("Pattern descriptors don't support create()."));

  Stream<List<int>> load(String pathToLoad) => errorStream(
      new UnsupportedError("Pattern descriptors don't support load()."));

  Stream<List<int>> read() => errorStream(new UnsupportedError("Pattern "
      "descriptors don't support read()."));
}
