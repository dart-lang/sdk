// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ----------------------------------------------------------------------
// Code to create the URI scanner table used by `uri.dart`.
//
// This file exists in case someone, some day, will want to change the
// representation of the tables, maybe if Dart gets `Uint8List` literals.
// It should not otherwise be necessary to re-generate the tables.
//
// The table is stored in the `uri.dart` file as a 1-byte string literal.
// This script generates the string literal and prints it on stdout.
// If passed the `-u filename` flag, it instead updates the file directly.
// The file should be the `sdk/lib/core/uri.dart` file, which contains markers
// showing where to insert the generated code.

import "dart:io";
import "dart:typed_data";

/// Index of the position of that `:` after a scheme.
const int _schemeEndIndex = 1;

/// Index of the position of the character just before the host name.
const int _hostStartIndex = 2;

/// Index of the position of the `:` before a port value.
const int _portStartIndex = 3;

/// Index of the position of the first character of a path.
const int _pathStartIndex = 4;

/// Index of the position of the `?` before a query.
const int _queryStartIndex = 5;

/// Index of the position of the `#` before a fragment.
const int _fragmentStartIndex = 6;

/// Index of a position where the URI was determined to be "non-simple".
const int _notSimpleIndex = 7;

// Initial state for scanner.
const int _uriStart = 0;

// If scanning of a URI terminates in this state or above,
// consider the URI non-simple
const int _nonSimpleEndStates = 14;

// Initial state for scheme validation.
const int _schemeStart = 20;

void main(List<String> args) {
  var tables = _createTables();
  var literalBuilder = StringLiteralBuilder("_scannerTables");
  for (var table in tables) {
    literalBuilder.writeBytes(table, hexAll: true);
  }
  var tableString = literalBuilder.close();

  var result = """
// Use tools/generate_uri_parser_tables.dart to generate this code
// if necessary.

// --------------------------------------------------------------------
// Constants used to read the scanner result.
// The indices points into the table filled by [_scan] which contains
// recognized positions in the scanned URI.
// The `0` index is only used internally.

/// Index of the position of that `:` after a scheme.
const int _schemeEndIndex = $_schemeEndIndex;

/// Index of the position of the character just before the host name.
const int _hostStartIndex = $_hostStartIndex;

/// Index of the position of the `:` before a port value.
const int _portStartIndex = $_portStartIndex;

/// Index of the position of the first character of a path.
const int _pathStartIndex = $_pathStartIndex;

/// Index of the position of the `?` before a query.
const int _queryStartIndex = $_queryStartIndex;

/// Index of the position of the `#` before a fragment.
const int _fragmentStartIndex = $_fragmentStartIndex;

/// Index of a position where the URI was determined to be "non-simple".
const int _notSimpleIndex = $_notSimpleIndex;

// Initial state for scanner.
const int _uriStart = $_uriStart;

// If scanning of a URI terminates in this state or above,
// consider the URI non-simple
const int _nonSimpleEndStates = $_nonSimpleEndStates;

// Initial state for scheme validation.
const int _schemeStart = $_schemeStart;

// --------------------------------------------------------------------
/// Transition tables are used to scan a URI to determine its structure.
///
/// The tables represent a state machine with output.
///
/// To scan the URI, start in the [_uriStart] state, then read each character
/// of the URI in order, from start to end, and for each character perform a
/// transition to a new state while writing the current position
/// into the output buffer at a designated index.
///
/// Each state, represented by an integer which is an index into
/// [_scannerTables], has a set of transitions, one for each character.
/// The transitions are encoded as a 5-bit integer representing the next state
/// and a 3-bit index into the output table.
///
/// For URI scanning, only characters in the range U+0020 through U+007E are
/// interesting; all characters outside that range are treated the same.
/// The tables only contain 96 entries, representing the 95 characters in the
/// interesting range, and one entry for all values outside the range.
/// The character entries are stored in one `String` of 96 characters per state,
/// with the transition for a character at position `character ^ 0x60`,
/// which maps the range U+0020 .. U+007F into positions 0 .. 95.
/// All remaining characters are mapped to position 31 (`0x7f ^ 0x60`), which
/// represents the transition for all remaining characters.
$tableString
// --------------------------------------------------------------------
/// Scan a string using the [_scannerTables] state machine.
///
/// Scans [uri] from [start] to [end], starting in state [state] and
/// writing output into [indices].
///
/// Returns the final state.
int _scan(String uri, int start, int end, int state, List<int> indices) {
  const int stateTableSize = 96;
  assert(end <= uri.length);
  for (int i = start; i < end; i++) {
    // Xor with 0x60 to move range 0x20-0x7f into 0x00-0x5f
    int char = uri.codeUnitAt(i) ^ 0x60;
    // Use 0x1f (nee 0x7f) to represent all unhandled characters.
    if (char > 0x5f) char = 0x1f;
    int transition = _scannerTables.codeUnitAt(state * stateTableSize + char);
    state = transition & 0x1f;
    indices[transition >> 5] = i;
  }
  return state;
}
""";
  if (args.isEmpty || !args.first.startsWith("-u")) {
    print(result);
    return;
  }
  var arg = args.first;
  var filePath = "sdk/lib/core/uri.dart";
  // Default file location, if run from root of SDK.
  if (arg.length > 2) {
    filePath = arg.substring(2);
  } else if (args.length > 1) {
    filePath = args[1];
  }
  var file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln("Cannot find file: $filePath");
    exit(1);
  }
  var contents = file.readAsStringSync();
  var pattern = RegExp(r"^// --- URI PARSER TABLE --- (start|end) --- [^]*?^",
      multiLine: true);
  var matches = pattern.allMatches(contents).toList();
  if (matches.length != 2) {
    stderr.writeln("Cannot find marked section in file $filePath");
    exit(1);
  }
  var start = matches.first.end;
  var end = matches.last.start;
  var newContents = contents.replaceRange(start, end, result);
  if (newContents != contents) {
    file.writeAsStringSync(newContents);
    print("$filePath updated.");
  } else {
    stderr.writeln("No update needed.");
    return;
  }
}

/// Creates a literal of the form
/// ```dart
/// const String someName = "ab\x82azx......"
///     "more bytes and escapes \xff        "
///     "....";
/// ```
/// while escaping non-printable charactes, `"`, `$` and `\`,
/// and trying to fit as many characters on each line as possible.
class StringLiteralBuilder {
  final buffer = StringBuffer();
  String indent;
  var lineLength = 0;
  StringLiteralBuilder(String name, {int indent = 0})
      : indent = " " * (indent + 4) {
    if (indent > 0) buffer.write(" " * indent);
    buffer
      ..write("const String ")
      ..write(name)
      ..write(" = \"");
    lineLength = buffer.length;
  }

  void writeBytes(Uint8List bytes, {bool hexAll = false}) {
    for (var byte in bytes) {
      var string = hexAll ? hex(byte) : charString(byte);
      lineLength += string.length;
      if (lineLength > 79) {
        buffer
          ..write('"\n')
          ..write(indent)
          ..write('"');
        lineLength = indent.length + 1 + string.length;
      }
      buffer.write(string);
    }
  }

  /// Terminates the string literal.
  ///
  /// Do not call use builder after calling close.
  String close() {
    if (lineLength < 78) {
      buffer.write("\";\n");
    } else {
      buffer
        ..write("\"\n")
        ..write(indent)
        ..write(";\n");
    }
    return buffer.toString();
  }

  static String charString(int byte) {
    // Recognized characters that need escaping, or has a short escape.
    switch (byte) {
      case 0x08:
        return r"\b";
      case 0x09:
        return r"\t";
      case 0x0a:
        return r"\n";
      case 0x0b:
        return r"\v";
      case 0x0c:
        return r"\f";
      case 0x0d:
        return r"\r";
      case 0x22:
        return r'\"';
      case 0x5c:
        return r"\\";
      case 0x24:
        return r"\$";
    }
    // All control characters.
    if (byte & 0x60 == 0 || byte == 0x7F) {
      // 0x00 - 0x1F, 0x80 - 0xBF, 0x7F
      return hex(byte);
    }
    return String.fromCharCode(byte);
  }

  static String hex(int byte) {
    const digits = "0123456789ABCDEF";
    return "\\x${digits[byte >> 4]}${digits[byte & 0xf]}";
  }
}

/// Creates the tables for [_scannerTables] used by [Uri.parse].
///
/// See [_scannerTables] for the generated format.
///
/// The concrete tables are chosen as a trade-off between the number of states
/// needed and the precision of the result.
/// This allows definitely recognizing the general structure of the URI
/// (presence and location of scheme, user-info, host, port, path, query and
/// fragment) while at the same time detecting that some components are not
/// in canonical form (anything containing a `%`, a host-name containing a
/// capital letter). Since the scanner doesn't know whether something is a
/// scheme or a path until it sees `:`, or user-info or host until it sees
/// a `@`, a second pass is needed to validate the scheme and any user-info
/// is considered non-canonical by default.
///
/// The states (starting from [_uriStart]) write positions while scanning
/// a string from `start` to `end` as follows:
///
/// - [_schemeEndIndex]: Should be initialized to `start-1`.
///   If the URI has a scheme, it is set to the position of the `:` after
///   the scheme.
/// - [_hostStartIndex]: Should be initialized to `start - 1`.
///   If the URI has an authority, it is set to the character before the
///   host name - either the second `/` in the `//` leading the authority,
///   or the `@` after a user-info. Comparing this value to the scheme end
///   position can be used to detect that there is a user-info component.
/// - [_portStartIndex]: Should be initialized to `start`.
///   Set to the position of the last `:` in an authority, and unchanged
///   if there is no authority or no `:` in an authority.
///   If this position is after the host start, there is a port, otherwise it
///   is just marking a colon in the user-info component.
/// - [_pathStartIndex]: Should be initialized to `start`.
///   Is set to the first path character unless the path is empty.
///   If the path is empty, the position is either unchanged (`start`) or
///   the first slash of an authority. So, if the path start is before a
///   host start or scheme end, the path is empty.
/// - [_queryStartIndex]: Should be initialized to `end`.
///   The position of the `?` leading a query if the URI contains a query.
/// - [_fragmentStartIndex]: Should be initialized to `end`.
///   The position of the `#` leading a fragment if the URI contains a fragment.
/// - [_notSimpleIndex]: Should be initialized to `start - 1`.
///   Set to another value if the URI is considered "not simple".
///   This is elaborated below.
///
/// # Simple URIs
/// A URI is considered "simple" if it is in a normalized form containing no
/// escapes. This allows us to skip normalization and checking whether escapes
/// are valid, and to extract components without worrying about unescaping.
///
/// The scanner computes a conservative approximation of being "simple".
/// It rejects any URI with an escape, with a user-info component (mainly
/// because they are rare and would increase the number of states in the
/// scanner significantly), with an IPV6 host or with a capital letter in
/// the scheme or host name (the scheme is handled in a second scan using
/// a separate two-state table).
/// Further, paths containing `..` or `.` path segments are considered
/// non-simple except for pure relative paths (no scheme or authority) starting
/// with a sequence of "../" segments.
///
/// The transition tables cannot detect a trailing ".." in the path,
/// followed by a query or fragment, because the segment is not known to be
/// complete until we are past it, and we then need to store the query/fragment
/// start instead. This cast is checked manually post-scanning (such a path
/// needs to be normalized to end in "../", so the URI shouldn't be considered
/// simple).
List<Uint8List> _createTables() {
  // Total number of states for the scanner.
  const int stateCount = 22;

  // States used to scan a URI from scratch.
  const int schemeOrPath = 01;
  const int authOrPath = 02;
  const int authOrPathSlash = 03;
  const int uinfoOrHost0 = 04;
  const int uinfoOrHost = 05;
  const int uinfoOrPort0 = 06;
  const int uinfoOrPort = 07;
  const int ipv6Host = 08;
  const int relPathSeg = 09;
  const int pathSeg = 10;
  const int path = 11;
  const int query = 12;
  const int fragment = 13;
  const int schemeOrPathDot = 14;
  const int schemeOrPathDot2 = 15;
  const int relPathSegDot = 16;
  const int relPathSegDot2 = 17;
  const int pathSegDot = 18;
  const int pathSegDot2 = 19;

  // States used to validate a scheme after its end position has been found.
  const int scheme0 = _schemeStart;
  const int scheme = 21;

  // Constants encoding the write-index for the state transition into the top 5
  // bits of a byte.
  const int schemeEnd = _schemeEndIndex << 5;
  const int hostStart = _hostStartIndex << 5;
  const int portStart = _portStartIndex << 5;
  const int pathStart = _pathStartIndex << 5;
  const int queryStart = _queryStartIndex << 5;
  const int fragmentStart = _fragmentStartIndex << 5;
  const int notSimple = _notSimpleIndex << 5;

  /// The `unreserved` characters of RFC 3986.
  const unreserved =
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._~";

  /// The `sub-delim` characters of RFC 3986.
  const subDelims = r"!$&'()*+,;=";
  // The `pchar` characters of RFC 3986: characters that may occur in a path,
  // excluding escapes.
  const pchar = "$unreserved$subDelims";

  var tables = List<Uint8List>.generate(stateCount, (_) => Uint8List(96));

  // Helper function which initialize the table for [state] with a default
  // transition and returns the table.
  Uint8List build(state, defaultTransition) =>
      tables[state]..fillRange(0, 96, defaultTransition);

  // Helper function which sets the transition for each character in [chars]
  // to [transition] in the [target] table.
  // The [chars] string must contain only characters in the U+0020 .. U+007E
  // range.
  void setChars(Uint8List target, String chars, int transition) {
    for (int i = 0; i < chars.length; i++) {
      var char = chars.codeUnitAt(i);
      target[char ^ 0x60] = transition;
    }
  }

  /// Helper function which sets the transition for all characters in the
  /// range from `range[0]` to `range[1]` to [transition] in the [target] table.
  ///
  /// The [range] must be a two-character string where both characters are in
  /// the U+0020 .. U+007E range and the former character must have a lower
  /// code point than the latter.
  void setRange(Uint8List target, String range, int transition) {
    for (int i = range.codeUnitAt(0), n = range.codeUnitAt(1); i <= n; i++) {
      target[i ^ 0x60] = transition;
    }
  }

  // Create the transitions for each state.
  Uint8List b;

  // Validate as path, if it is a scheme, we handle it later.
  b = build(_uriStart, schemeOrPath | notSimple);
  setChars(b, pchar, schemeOrPath);
  setChars(b, ".", schemeOrPathDot);
  setChars(b, ":", authOrPath | schemeEnd); // Handle later.
  setChars(b, "/", authOrPathSlash);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(schemeOrPathDot, schemeOrPath | notSimple);
  setChars(b, pchar, schemeOrPath);
  setChars(b, ".", schemeOrPathDot2);
  setChars(b, ':', authOrPath | schemeEnd);
  setChars(b, "/", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(schemeOrPathDot2, schemeOrPath | notSimple);
  setChars(b, pchar, schemeOrPath);
  setChars(b, "%", schemeOrPath | notSimple);
  setChars(b, ':', authOrPath | schemeEnd);
  setChars(b, "/", relPathSeg);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(schemeOrPath, schemeOrPath | notSimple);
  setChars(b, pchar, schemeOrPath);
  setChars(b, ':', authOrPath | schemeEnd);
  setChars(b, "/", pathSeg);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(authOrPath, path | notSimple);
  setChars(b, pchar, path | pathStart);
  setChars(b, "/", authOrPathSlash | pathStart);
  setChars(b, ".", pathSegDot | pathStart);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(authOrPathSlash, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, "/", uinfoOrHost0 | hostStart);
  setChars(b, ".", pathSegDot);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(uinfoOrHost0, uinfoOrHost | notSimple);
  setChars(b, pchar, uinfoOrHost);
  setRange(b, "AZ", uinfoOrHost | notSimple);
  setChars(b, ":", uinfoOrPort0 | portStart);
  setChars(b, "@", uinfoOrHost0 | hostStart);
  setChars(b, "[", ipv6Host | notSimple);
  setChars(b, "/", pathSeg | pathStart);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(uinfoOrHost, uinfoOrHost | notSimple);
  setChars(b, pchar, uinfoOrHost);
  setRange(b, "AZ", uinfoOrHost | notSimple);
  setChars(b, ":", uinfoOrPort0 | portStart);
  setChars(b, "@", uinfoOrHost0 | hostStart);
  setChars(b, "/", pathSeg | pathStart);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(uinfoOrPort0, uinfoOrPort | notSimple);
  setRange(b, "19", uinfoOrPort);
  setChars(b, "@", uinfoOrHost0 | hostStart);
  setChars(b, "/", pathSeg | pathStart);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(uinfoOrPort, uinfoOrPort | notSimple);
  setRange(b, "09", uinfoOrPort);
  setChars(b, "@", uinfoOrHost0 | hostStart);
  setChars(b, "/", pathSeg | pathStart);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(ipv6Host, ipv6Host);
  setChars(b, "]", uinfoOrHost);

  b = build(relPathSeg, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, ".", relPathSegDot);
  setChars(b, "/", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(relPathSegDot, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, ".", relPathSegDot2);
  setChars(b, "/", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(relPathSegDot2, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, "/", relPathSeg);
  setChars(b, "?", query | queryStart); // This should be non-simple.
  setChars(b, "#", fragment | fragmentStart); // This should be non-simple.

  b = build(pathSeg, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, ".", pathSegDot);
  setChars(b, "/", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(pathSegDot, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, ".", pathSegDot2);
  setChars(b, "/", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(pathSegDot2, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, "/", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(path, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, "/", pathSeg);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(query, query | notSimple);
  setChars(b, pchar, query);
  setChars(b, "?", query);
  setChars(b, "#", fragment | fragmentStart);

  b = build(fragment, fragment | notSimple);
  setChars(b, pchar, fragment);
  setChars(b, "?", fragment);

  // A separate two-state validator for lower-case scheme names.
  // Any non-scheme character or upper-case letter is marked as non-simple.
  b = build(scheme0, scheme | notSimple);
  setRange(b, "az", scheme);

  b = build(scheme, scheme | notSimple);
  setRange(b, "az", scheme);
  setRange(b, "09", scheme);
  setChars(b, "+-.", scheme);

  return tables;
}
