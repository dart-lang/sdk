// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/messages.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/fasta/scanner/io.dart';
import 'package:front_end/src/scanner/token.dart' as analyzer;

/// Implementation of [Instrumentation] which checks property/value pairs
/// against expectations encoded in source files using "/*@...*/" comments.
class ValidatingInstrumentation implements Instrumentation {
  static final _ESCAPE_SEQUENCE = new RegExp(r'\\(.)');

  /// Map from feature names to the property names they are short for.
  static const _FEATURES = const {
    'inference': const [
      'topType',
      'typeArg',
      'typeArgs',
      'promotedType',
      'type',
      'returnType',
      'target',
    ],
  };

  /// Map from file URI to the as-yet unsatisfied expectations from that file,
  /// organized by file offset.
  final _unsatisfiedExpectations = <Uri, Map<int, List<_Expectation>>>{};

  /// Information about "testedFeatures" annotations, organized by file URI and
  /// file offset.  The inner map is guaranteed to be in ascending order of
  /// file offset.
  final _testedFeaturesState = <Uri, Map<int, Set<String>>>{};

  /// String descriptions of the expectation mismatches found so far.
  final _problems = <String>[];

  /// Fixes that would need to be performed on source files in order for all
  /// expectations to be met, organized by file URI.  The inner map is not
  /// guaranteed to be in ascending order of file offset.
  final _fixes = <Uri, List<_Fix>>{};

  /// Indicates whether any expectation mismatches were found.
  ///
  /// Should be called after [finish].
  bool get hasProblems => _problems.isNotEmpty;

  /// Gets a description of all expectation mismatches that were found, in a
  /// form suitable for printing to the console.
  ///
  /// Should be called after [finish].
  String get problemsAsString => _problems.join('\n');

  /// Checks whether the property/value pairs passed to [record] match the
  /// expectations loaded by [loadExpectations].
  void finish() {
    _unsatisfiedExpectations.forEach((uri, expectationsForUri) {
      expectationsForUri.forEach((offset, expectationsAtOffset) {
        for (var expectation in expectationsAtOffset) {
          _problem(
              uri,
              offset,
              'expected ${expectation.property}=${expectation.value}, '
              'got nothing',
              new _Fix(
                  expectation.commentOffset, expectation.commentLength, ''));
        }
      });
    });
  }

  /// Updates the source file at [uri] based on the actual property/value
  /// pairs that were observed.
  Future<Null> fixSource(Uri uri, bool offsetsCountCharacters) async {
    uri = Uri.base.resolveUri(uri);
    var fixes = _fixes[uri];
    if (fixes == null) return;
    File file = new File.fromUri(uri);
    var bytes = (await file.readAsBytes()).toList();
    int convertOffset(int offset) {
      if (offsetsCountCharacters) {
        return UTF8.encode(UTF8.decode(bytes).substring(0, offset)).length;
      } else {
        return offset;
      }
    }

    // Apply the fixes in reverse order so that offsets don't need to be
    // adjusted after each fix.
    fixes.sort((a, b) => b.offset.compareTo(a.offset));
    for (var fix in fixes) {
      bytes.replaceRange(convertOffset(fix.offset),
          convertOffset(fix.offset + fix.length), UTF8.encode(fix.replacement));
    }
    await file.writeAsBytes(bytes);
  }

  /// Loads expectations from the source file located at [uri].
  ///
  /// Should be called before [finish].
  Future<Null> loadExpectations(Uri uri) async {
    uri = Uri.base.resolveUri(uri);
    var bytes = await readBytesFromFile(uri);
    var expectations = _unsatisfiedExpectations.putIfAbsent(uri, () => {});
    var testedFeaturesState = _testedFeaturesState.putIfAbsent(uri, () => {});
    ScannerResult result = scan(bytes, includeComments: true);
    for (Token token = result.tokens; !token.isEof; token = token.next) {
      for (analyzer.Token commentToken = token.precedingComments;
          commentToken != null;
          commentToken = commentToken.next) {
        String lexeme = commentToken.lexeme;
        if (lexeme.startsWith('/*@') && lexeme.endsWith('*/')) {
          var expectation = lexeme.substring(3, lexeme.length - 2);
          var equals = expectation.indexOf('=');
          String property;
          String value;
          if (equals == -1) {
            property = expectation;
            value = '';
          } else {
            property = expectation.substring(0, equals);
            value = expectation
                .substring(equals + 1)
                .replaceAllMapped(_ESCAPE_SEQUENCE, (m) => m.group(1));
          }
          property = property.trim();
          value = value.trim();
          if (property == 'testedFeatures') {
            Set<String> state = new Set<String>();
            for (String feature in value.split(',')) {
              feature = feature.trim();
              // If an unrecognized feature name is found, it is assumed to be
              // just a property name.
              state.addAll(_FEATURES[feature] ?? [feature]);
            }
            testedFeaturesState[commentToken.offset] = state;
          } else {
            var offset = token.charOffset;
            var expectationsAtOffset =
                expectations.putIfAbsent(offset, () => []);
            expectationsAtOffset.add(new _Expectation(
                property, value, commentToken.offset, commentToken.length));
          }
        }
      }
    }
  }

  @override
  void record(
      Uri uri, int offset, String property, InstrumentationValue value) {
    uri = Uri.base.resolveUri(uri);
    var expectationsForUri = _unsatisfiedExpectations[uri];
    if (expectationsForUri == null) return;
    var expectationsAtOffset = expectationsForUri[offset];
    if (expectationsAtOffset != null) {
      for (int i = 0; i < expectationsAtOffset.length; i++) {
        var expectation = expectationsAtOffset[i];
        if (expectation.property == property) {
          if (!value.matches(expectation.value)) {
            _problemWithStack(
                uri,
                offset,
                'expected $property=${expectation.value}, got '
                '$property=${value.toString()}',
                new _Fix(expectation.commentOffset, expectation.commentLength,
                    _makeExpectationComment(property, value)));
          }
          expectationsAtOffset.removeAt(i);
          return;
        }
      }
    }
    // Unexpected property/value pair.  See if we should report.
    if (_shouldCheck(property, uri, offset)) {
      _problemWithStack(
          uri,
          offset,
          'expected nothing, got $property=${value.toString()}',
          new _Fix(offset, 0, _makeExpectationComment(property, value)));
    }
  }

  String _escape(String s) {
    s = s.replaceAll(r'\', r'\\');
    if (s.endsWith('/')) {
      s = '$s ';
    }
    return s.replaceAll('/*', r'/\*').replaceAll('*/', r'*\/');
  }

  String _formatProblem(
      Uri uri, int offset, String desc, StackTrace stackTrace) {
    return format(
        uri, offset, '$desc${stackTrace == null ? '' : '\n$stackTrace'}');
  }

  String _makeExpectationComment(String property, InstrumentationValue value) {
    return '/*@$property=${_escape(value.toString())}*/';
  }

  void _problem(Uri uri, int offset, String desc, _Fix fix) {
    _problems.add(_formatProblem(uri, offset, desc, null));
    _fixes.putIfAbsent(uri, () => []).add(fix);
  }

  void _problemWithStack(Uri uri, int offset, String desc, _Fix fix) {
    _problems.add(_formatProblem(uri, offset, desc, StackTrace.current));
    _fixes.putIfAbsent(uri, () => []).add(fix);
  }

  bool _shouldCheck(String property, Uri uri, int offset) {
    var state = false;
    var testedFeaturesStateForUri = _testedFeaturesState[uri];
    if (testedFeaturesStateForUri == null) return false;
    for (int i in testedFeaturesStateForUri.keys) {
      if (i > offset) break;
      var testedFeaturesStateAtOffset = testedFeaturesStateForUri[i];
      state = testedFeaturesStateAtOffset.contains(property);
    }
    return state;
  }
}

class _Expectation {
  final String property;
  final String value;
  final int commentOffset;
  final int commentLength;

  _Expectation(
      this.property, this.value, this.commentOffset, this.commentLength);
}

class _Fix {
  final int offset;
  final int length;
  final String replacement;

  _Fix(this.offset, this.length, this.replacement);
}
