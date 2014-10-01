library pub.preprocess;
import 'package:pub_semver/pub_semver.dart';
import 'package:string_scanner/string_scanner.dart';
String preprocess(String input, Map<String, Version> versions, sourceUrl) {
  if (!input.contains(new RegExp(r"^//[>#]", multiLine: true))) return input;
  return new _Preprocessor(input, versions, sourceUrl).run();
}
class _Preprocessor {
  final StringScanner _scanner;
  final Map<String, Version> _versions;
  final _buffer = new StringBuffer();
  _Preprocessor(String input, this._versions, sourceUrl)
      : _scanner = new StringScanner(input, sourceUrl: sourceUrl);
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
  void _emitText() {
    while (!_scanner.isDone && !_scanner.matches("//#")) {
      if (_scanner.scan("//>")) {
        if (!_scanner.matches("\n")) _scanner.expect(" ");
      }
      _scanner.scan(new RegExp(r"[^\n]*\n?"));
      _buffer.write(_scanner.lastMatch[0]);
    }
  }
  void _ignoreText() {
    while (!_scanner.isDone && !_scanner.matches("//#")) {
      _scanner.scan(new RegExp(r"[^\n]*\n?"));
    }
  }
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
