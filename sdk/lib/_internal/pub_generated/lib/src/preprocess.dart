// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.preprocess;

import 'package:pub_semver/pub_semver.dart';
import 'package:string_scanner/string_scanner.dart';

/// Runs a simple preprocessor over [input] to remove sections that are
/// incompatible with the available barback version.
///
/// [versions] are the available versions of each installed package, and
/// [sourceUrl] is a [String] or [Uri] indicating where [input] came from. It's
/// used for error reporting.
///
/// For the most part, the preprocessor leaves text in the source document
/// alone. However, it handles two types of lines specially. Lines that begin
/// with `//>` are uncommented by the preprocessor, and lines that begin with
/// `//#` are operators.
///
/// The preprocessor currently supports one top-level operator, "if":
///
///     //# if barback >=0.14.1
///       ...
///     //# else
///       ...
///     //# end
///
/// If can check against any package installed in the current package. It can
/// check the version of the package, as above, or (if the version range is
/// omitted) whether the package exists at all. If the condition is true,
/// everything within the first block is included in the output and everything
/// within the second block is removed; otherwise, the first block is removed
/// and the second block is included. The `else` block is optional.
///
/// It's important that the preprocessor syntax also be valid Dart code, because
/// pub loads the source files before preprocessing and runs them against the
/// version of barback that was compiled into pub. This is why the `//>` syntax
/// exists: so that code can be hidden from the running pub process but still be
/// visible to the barback isolate. For example:
///
///     //# if barback >= 0.14.1
///       ClassMirror get aggregateClass => reflectClass(AggregateTransformer);
///     //# else
///     //>   ClassMirror get aggregateClass => null;
///     //# end
String preprocess(String input, Map<String, Version> versions, sourceUrl) {
  // Short-circuit if there are no preprocessor directives in the file.
  if (!input.contains(new RegExp(r"^//[>#]", multiLine: true))) return input;
  return new _Preprocessor(input, versions, sourceUrl).run();
}

/// The preprocessor class.
class _Preprocessor {
  /// The scanner over the input string.
  final StringScanner _scanner;

  final Map<String, Version> _versions;

  /// The buffer to which the output is written.
  final _buffer = new StringBuffer();

  _Preprocessor(String input, this._versions, sourceUrl)
      : _scanner = new StringScanner(input, sourceUrl: sourceUrl);

  /// Run the preprocessor and return the processed output.
  String run() {
    while (!_scanner.isDone) {
      if (_scanner.scan(new RegExp(r"//#[ \t]*"))) {
        _if();
      } else {
        _emitText();
      }
    }

    _scanner.expectDone();
    return _buffer.toString();
  }

  /// Emit lines of the input document directly until an operator is
  /// encountered.
  void _emitText() {
    while (!_scanner.isDone && !_scanner.matches("//#")) {
      if (_scanner.scan("//>")) {
        if (!_scanner.matches("\n")) _scanner.expect(" ");
      }

      _scanner.scan(new RegExp(r"[^\n]*\n?"));
      _buffer.write(_scanner.lastMatch[0]);
    }
  }

  /// Move through lines of the input document without emitting them until an
  /// operator is encountered.
  void _ignoreText() {
    while (!_scanner.isDone && !_scanner.matches("//#")) {
      _scanner.scan(new RegExp(r"[^\n]*\n?"));
    }
  }

  /// Handle an `if` operator.
  void _if() {
    _scanner.expect(new RegExp(r"if[ \t]+"), name: "if statement");
    _scanner.expect(new RegExp(r"[a-zA-Z0-9_]+"), name: "package name");
    var package = _scanner.lastMatch[0];

    _scanner.scan(new RegExp(r"[ \t]*"));
    var constraint = VersionConstraint.any;
    if (_scanner.scan(new RegExp(r"[^\n]+"))) {
      try {
        constraint = new VersionConstraint.parse(_scanner.lastMatch[0]);
      } on FormatException catch (error) {
        _scanner.error("Invalid version constraint: ${error.message}");
      }
    }
    _scanner.expect("\n");

    var allowed =
        _versions.containsKey(package) &&
        constraint.allows(_versions[package]);
    if (allowed) {
      _emitText();
    } else {
      _ignoreText();
    }

    _scanner.expect("//#");
    _scanner.scan(new RegExp(r"[ \t]*"));
    if (_scanner.scan("else")) {
      _scanner.expect("\n");
      if (allowed) {
        _ignoreText();
      } else {
        _emitText();
      }
      _scanner.expect("//#");
      _scanner.scan(new RegExp(r"[ \t]*"));
    }

    _scanner.expect("end");
    if (!_scanner.isDone) _scanner.expect("\n");
  }
}
