// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'configuration.dart';
import 'path.dart';

// This is the maximum time we expect stdout/stderr of subprocesses to deliver
// data after we've got the exitCode.
const Duration MAX_STDIO_DELAY = const Duration(seconds: 30);

String MAX_STDIO_DELAY_PASSED_MESSAGE =
    """Not waiting for stdout/stderr from subprocess anymore
 ($MAX_STDIO_DELAY passed). Please note that this could be an indicator
 that there is a hanging process which we were unable to kill.""";

/// The names of the packages that are available for use in tests.
const testPackages = const [
  "async_helper",
  "collection",
  "expect",
  "js",
  "matcher",
  "meta",
  "path",
  "stack_trace",
  "unittest"
];

class DebugLogger {
  static IOSink _sink;

  /**
   * If [path] was null, the DebugLogger will write messages to stdout.
   */
  static void init(Path path, {bool append: false}) {
    if (path != null) {
      var mode = append ? FileMode.APPEND : FileMode.WRITE;
      _sink = new File(path.toNativePath()).openWrite(mode: mode);
    }
  }

  static void close() {
    if (_sink != null) {
      _sink.close();
      _sink = null;
    }
  }

  static String _formatErrorMessage(String msg, error) {
    if (error == null) return msg;
    msg += ": $error";
    // TODO(floitsch): once the dart-executable that is bundled
    // with the Dart sources is updated, pass a trace parameter too and do:
    // if (trace != null) msg += "\nStackTrace: $trace";
    return msg;
  }

  static void info(String msg, [error]) {
    msg = _formatErrorMessage(msg, error);
    _print("$_datetime Info: $msg");
  }

  static void warning(String msg, [error]) {
    msg = _formatErrorMessage(msg, error);
    _print("$_datetime Warning: $msg");
  }

  static void error(String msg, [error]) {
    msg = _formatErrorMessage(msg, error);
    _print("$_datetime Error: $msg");
  }

  static void _print(String msg) {
    if (_sink != null) {
      _sink.writeln(msg);
    } else {
      print(msg);
    }
  }

  static String get _datetime => "${new DateTime.now()}";
}

String prettifyJson(Object json, {int startIndentation: 0, int shiftWidth: 6}) {
  int currentIndentation = startIndentation;
  var buffer = new StringBuffer();

  String indentationString() {
    return new List.filled(currentIndentation, ' ').join('');
  }

  addString(String s, {bool indentation: true, bool newLine: true}) {
    if (indentation) {
      buffer.write(indentationString());
    }
    buffer.write(s.replaceAll("\n", "\n${indentationString()}"));
    if (newLine) buffer.write("\n");
  }

  prettifyJsonInternal(Object obj,
      {bool indentation: true, bool newLine: true}) {
    if (obj is List) {
      addString("[", indentation: indentation);
      currentIndentation += shiftWidth;
      for (var item in obj) {
        prettifyJsonInternal(item, indentation: indentation, newLine: false);
        addString(",", indentation: false);
      }
      currentIndentation -= shiftWidth;
      addString("]", indentation: indentation);
    } else if (obj is Map) {
      addString("{", indentation: indentation);
      currentIndentation += shiftWidth;
      for (var key in obj.keys) {
        addString("$key: ", indentation: indentation, newLine: false);
        currentIndentation += shiftWidth;
        prettifyJsonInternal(obj[key], indentation: false);
        currentIndentation -= shiftWidth;
      }
      currentIndentation -= shiftWidth;
      addString("}", indentation: indentation, newLine: newLine);
    } else {
      addString("$obj", indentation: indentation, newLine: newLine);
    }
  }

  prettifyJsonInternal(json);
  return buffer.toString();
}

/**
 * [areByteArraysEqual] compares a range of bytes from [buffer1] with a
 * range of bytes from [buffer2].
 *
 * Returns [true] if the [count] bytes in [buffer1] (starting at
 * [offset1]) match the [count] bytes in [buffer2] (starting at
 * [offset2]).
 * Otherwise [false] is returned.
 */
bool areByteArraysEqual(
    List<int> buffer1, int offset1, List<int> buffer2, int offset2, int count) {
  if ((offset1 + count) > buffer1.length ||
      (offset2 + count) > buffer2.length) {
    return false;
  }

  for (var i = 0; i < count; i++) {
    if (buffer1[offset1 + i] != buffer2[offset2 + i]) {
      return false;
    }
  }
  return true;
}

/**
 * [findBytes] searches for [pattern] in [data] beginning at [startPos].
 *
 * Returns [true] if [pattern] was found in [data].
 * Otherwise [false] is returned.
 */
int findBytes(List<int> data, List<int> pattern, [int startPos = 0]) {
  // TODO(kustermann): Use one of the fast string-matching algorithms!
  for (int i = startPos; i < (data.length - pattern.length); i++) {
    bool found = true;
    for (int j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) {
        found = false;
        break;
      }
    }
    if (found) {
      return i;
    }
  }
  return -1;
}

List<int> encodeUtf8(String string) {
  return UTF8.encode(string);
}

// TODO(kustermann,ricow): As soon we have a debug log we should log
// invalid utf8-encoded input to the log.
// Currently invalid bytes will be replaced by a replacement character.
String decodeUtf8(List<int> bytes) {
  return UTF8.decode(bytes, allowMalformed: true);
}

// This function is pretty stupid and only puts quotes around an argument if
// it the argument contains a space.
String escapeCommandLineArgument(String argument) {
  if (argument.contains(' ')) {
    return '"$argument"';
  }
  return argument;
}

class HashCodeBuilder {
  int _value = 0;

  void add(Object object) {
    _value = ((_value * 31) ^ object.hashCode) & 0x3FFFFFFF;
  }

  void addJson(Object object) {
    if (object == null ||
        object is num ||
        object is String ||
        object is Uri ||
        object is bool) {
      add(object);
    } else if (object is List) {
      object.forEach(addJson);
    } else if (object is Map) {
      for (var key in object.keys.toList()..sort()) {
        addJson(key);
        addJson(object[key]);
      }
    } else {
      throw new Exception("Can't build hashcode for non json-like object "
          "(${object.runtimeType})");
    }
  }

  int get value => _value;
}

bool deepJsonCompare(Object a, Object b) {
  if (a == null || a is num || a is String || a is Uri) {
    return a == b;
  } else if (a is List) {
    if (b is List) {
      if (a.length != b.length) return false;

      for (int i = 0; i < a.length; i++) {
        if (!deepJsonCompare(a[i], b[i])) return false;
      }
      return true;
    }
    return false;
  } else if (a is Map) {
    if (b is Map) {
      if (a.length != b.length) return false;

      for (var key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!deepJsonCompare(a[key], b[key])) return false;
      }
      return true;
    }
    return false;
  } else {
    throw new Exception("Can't compare two non json-like objects "
        "(a: ${a.runtimeType}, b: ${b.runtimeType})");
  }
}

class UniqueObject {
  static int _nextId = 1;
  final int _hashCode;

  int get hashCode => _hashCode;
  operator ==(Object other) =>
      other is UniqueObject && _hashCode == other._hashCode;

  UniqueObject() : _hashCode = ++_nextId;
}

class LastModifiedCache {
  Map<String, DateTime> _cache = <String, DateTime>{};

  /**
   * Returns the last modified date of the given [uri].
   *
   * The return value will be cached for future queries. If [uri] is a local
   * file, it's last modified [Date] will be returned. If the file does not
   * exist, null will be returned instead.
   * In case [uri] is not a local file, this method will always return
   * the current date.
   */
  DateTime getLastModified(Uri uri) {
    if (uri.scheme == "file") {
      if (_cache.containsKey(uri.path)) {
        return _cache[uri.path];
      }
      var file = new File(new Path(uri.path).toNativePath());
      _cache[uri.path] = file.existsSync() ? file.lastModifiedSync() : null;
      return _cache[uri.path];
    }
    return new DateTime.now();
  }
}

class ExistsCache {
  Map<String, bool> _cache = <String, bool>{};

  /**
   * Returns true if the file in [path] exists, false otherwise.
   *
   * The information will be cached.
   */
  bool doesFileExist(String path) {
    if (!_cache.containsKey(path)) {
      _cache[path] = new File(path).existsSync();
    }
    return _cache[path];
  }
}

class TestUtils {
  /**
   * Any script using TestUtils must set dartDirUri to a file:// URI
   * pointing to the root of the Dart checkout.
   */
  static void setDartDirUri(Uri uri) {
    dartDirUri = uri;
    dartDir = new Path(uri.toFilePath());
  }

  static math.Random rand = new math.Random.secure();
  static Uri dartDirUri;
  static Path dartDir;
  static LastModifiedCache lastModifiedCache = new LastModifiedCache();
  static ExistsCache existsCache = new ExistsCache();
  static Path currentWorkingDirectory = new Path(Directory.current.path);

  /**
   * Generates a random number.
   */
  static int getRandomNumber() {
    return rand.nextInt(0xffffffff);
  }

  /**
   * Creates a directory using a [relativePath] to an existing
   * [base] directory if that [relativePath] does not already exist.
   */
  static Directory mkdirRecursive(Path base, Path relativePath) {
    if (relativePath.isAbsolute) {
      base = new Path('/');
    }
    Directory dir = new Directory(base.toNativePath());
    assert(dir.existsSync());
    var segments = relativePath.segments();
    for (String segment in segments) {
      base = base.append(segment);
      if (base.toString() == "/$segment" &&
          segment.length == 2 &&
          segment.endsWith(':')) {
        // Skip the directory creation for a path like "/E:".
        continue;
      }
      dir = new Directory(base.toNativePath());
      if (!dir.existsSync()) {
        dir.createSync();
      }
      assert(dir.existsSync());
    }
    return dir;
  }

  /**
   * Copy a [source] file to a new place.
   * Assumes that the directory for [dest] already exists.
   */
  static Future copyFile(Path source, Path dest) {
    return new File(source.toNativePath())
        .openRead()
        .pipe(new File(dest.toNativePath()).openWrite());
  }

  static Future copyDirectory(String source, String dest) {
    source = new Path(source).toNativePath();
    dest = new Path(dest).toNativePath();

    var executable = 'cp';
    var args = ['-Rp', source, dest];
    if (Platform.operatingSystem == 'windows') {
      executable = 'xcopy';
      args = [source, dest, '/e', '/i'];
    }
    return Process.run(executable, args).then((ProcessResult result) {
      if (result.exitCode != 0) {
        throw new Exception("Failed to execute '$executable "
            "${args.join(' ')}'.");
      }
    });
  }

  static Future deleteDirectory(String path) {
    // We are seeing issues with long path names on windows when
    // deleting them. Use the system tools to delete our long paths.
    // See issue 16264.
    if (Platform.operatingSystem == 'windows') {
      var native_path = new Path(path).toNativePath();
      // Running this in a shell sucks, but rmdir is not part of the standard
      // path.
      return Process
          .run('rmdir', ['/s', '/q', native_path], runInShell: true)
          .then((ProcessResult result) {
        if (result.exitCode != 0) {
          throw new Exception('Can\'t delete path $native_path. '
              'This path might be too long');
        }
      });
    } else {
      var dir = new Directory(path);
      return dir.delete(recursive: true);
    }
  }

  static void deleteTempSnapshotDirectory(Configuration configuration) {
    if (configuration.compiler == Compiler.appJit ||
        configuration.compiler == Compiler.precompiler) {
      var checked = configuration.isChecked ? '-checked' : '';
      var strong = configuration.isStrong ? '-strong' : '';
      var minified = configuration.isMinified ? '-minified' : '';
      var csp = configuration.isCsp ? '-csp' : '';
      var sdk = configuration.useSdk ? '-sdk' : '';
      var dirName = "${configuration.compiler.name}"
          "$checked$strong$minified$csp$sdk";
      var generatedPath =
          configuration.buildDirectory + "/generated_compilations/$dirName";
      TestUtils.deleteDirectory(generatedPath);
    }
  }

  static final debugLogFilePath = new Path(".debug.log");

  /// If a flaky test did fail, infos about it (i.e. test name, stdin, stdout)
  /// will be written to this file.
  ///
  /// This is useful for debugging flaky tests. When running on a buildbot, the
  /// file can be made visible in the waterfall UI.
  static const flakyFileName = ".flaky.log";

  /// If test.py was invoked with '--write-test-outcome-log it will write
  /// test outcomes to this file.
  static const testOutcomeFileName = ".test-outcome.log";

  /// If test.py was invoked with '--write-result-log it will write
  /// test outcomes to this file in the '--output-directory'.
  static const resultLogFileName = "result.log";

  static void ensureExists(String filename, Configuration configuration) {
    if (!configuration.listTests && !existsCache.doesFileExist(filename)) {
      throw "'$filename' does not exist";
    }
  }

  static Path absolutePath(Path path) {
    if (!path.isAbsolute) {
      return currentWorkingDirectory.join(path);
    }
    return path;
  }

  static int shortNameCounter = 0; // Make unique short file names on Windows.

  static String getShortName(String path) {
    final PATH_REPLACEMENTS = const {
      "tests_co19_src_Language_12_Expressions_14_Function_Invocation_":
          "co19_fn_invoke_",
      "tests_co19_src_LayoutTests_fast_css_getComputedStyle_getComputedStyle-":
          "co19_css_getComputedStyle_",
      "tests_co19_src_LayoutTests_fast_dom_Document_CaretRangeFromPoint_"
          "caretRangeFromPoint-": "co19_caretrangefrompoint_",
      "tests_co19_src_LayoutTests_fast_dom_Document_CaretRangeFromPoint_"
          "hittest-relative-to-viewport_": "co19_caretrange_hittest_",
      "tests_co19_src_LayoutTests_fast_dom_HTMLLinkElement_link-onerror-"
          "stylesheet-with-": "co19_dom_link-",
      "tests_co19_src_LayoutTests_fast_dom_": "co19_dom",
      "tests_co19_src_LayoutTests_fast_canvas_webgl": "co19_canvas_webgl",
      "tests_co19_src_LibTest_core_AbstractClassInstantiationError_"
          "AbstractClassInstantiationError_": "co19_abstract_class_",
      "tests_co19_src_LibTest_core_IntegerDivisionByZeroException_"
          "IntegerDivisionByZeroException_": "co19_division_by_zero",
      "tests_co19_src_WebPlatformTest_html_dom_documents_dom-tree-accessors_":
          "co19_dom_accessors_",
      "tests_co19_src_WebPlatformTest_html_semantics_embedded-content_"
          "media-elements_": "co19_media_elements",
      "tests_co19_src_WebPlatformTest_html_semantics_": "co19_semantics_",
      "tests_co19_src_WebPlatformTest_html-templates_additions-to-"
          "the-steps-to-clone-a-node_": "co19_htmltemplates_clone_",
      "tests_co19_src_WebPlatformTest_html-templates_definitions_"
          "template-contents-owner": "co19_htmltemplates_contents",
      "tests_co19_src_WebPlatformTest_html-templates_parsing-html-"
          "templates_additions-to-": "co19_htmltemplates_add_",
      "tests_co19_src_WebPlatformTest_html-templates_parsing-html-"
          "templates_appending-to-a-template_": "co19_htmltemplates_append_",
      "tests_co19_src_WebPlatformTest_html-templates_parsing-html-"
          "templates_clearing-the-stack-back-to-a-given-context_":
          "co19_htmltemplates_clearstack_",
      "tests_co19_src_WebPlatformTest_html-templates_parsing-html-"
          "templates_creating-an-element-for-the-token_":
          "co19_htmltemplates_create_",
      "tests_co19_src_WebPlatformTest_html-templates_template-element"
          "_template-": "co19_htmltemplates_element-",
      "tests_co19_src_WebPlatformTest_html-templates_": "co19_htmltemplate_",
      "tests_co19_src_WebPlatformTest_shadow-dom_shadow-trees_":
          "co19_shadow-trees_",
      "tests_co19_src_WebPlatformTest_shadow-dom_elements-and-dom-objects_":
          "co19_shadowdom_",
      "tests_co19_src_WebPlatformTest_shadow-dom_html-elements-in-"
          "shadow-trees_": "co19_shadow_html_",
      "tests_co19_src_WebPlatformTest_html_webappapis_system-state-and-"
          "capabilities_the-navigator-object": "co19_webappapis_navigator_",
      "tests_co19_src_WebPlatformTest_DOMEvents_approved_": "co19_dom_approved_"
    };

    // Some tests are already in [build_dir]/generated_tests.
    String GEN_TESTS = 'generated_tests/';
    if (path.contains(GEN_TESTS)) {
      int index = path.indexOf(GEN_TESTS) + GEN_TESTS.length;
      path = 'multitest/${path.substring(index)}';
    }
    path = path.replaceAll('/', '_');
    final int WINDOWS_SHORTEN_PATH_LIMIT = 58;
    final int WINDOWS_PATH_END_LENGTH = 30;
    if (Platform.operatingSystem == 'windows' &&
        path.length > WINDOWS_SHORTEN_PATH_LIMIT) {
      for (var key in PATH_REPLACEMENTS.keys) {
        if (path.startsWith(key)) {
          path = path.replaceFirst(key, PATH_REPLACEMENTS[key]);
          break;
        }
      }
      if (path.length > WINDOWS_SHORTEN_PATH_LIMIT) {
        ++shortNameCounter;
        var pathEnd = path.substring(path.length - WINDOWS_PATH_END_LENGTH);
        path = "short${shortNameCounter}_$pathEnd";
      }
    }
    return path;
  }
}
