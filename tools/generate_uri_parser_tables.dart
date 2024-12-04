// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
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

// Indices in the position array, where transitions write
// their current position.

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

// Significant states and state related numbers.

/// Initial state for scanner.
const int _uriStart = 0;

/// If scanning of a URI terminates in this state or above,
/// consider the URI non-simple
const int _nonSimpleEndStates = 14;

/// Initial state for scheme validation.
const int _schemeStart = 20;

/// Number of states total.
const int _stateCount = 22;

/// Number of bits used to store a state.
///
/// Satisfies `1 << stateBits >= _stateCount`.
/// Also used as shift for extra information in the transition table.
const int _stateBits = 5;

/// Mask of low `_stateBits` bits, to extract state from transition table entry.
const int _stateMask = (1 << _stateBits) - 1;

// Table structure constants.
//
// The table contains entries only for characters in the range U+0020 to U+007F.
// The input characters are permuted to make the lookup easy.

/// Input characters are xor'ed with this value.
///
/// That puts the range 0x20-0x7f into the range 0x00-0x5F,
/// which is easily usable as a an index into a table of length 0x60,
/// and checking if the value was originally in the range 0x20-0x7f can
/// be done by a single `<= 0x5f` (since the value is a string character unit,
/// which is known to be positive).
const int _charXor = 0x60;

/// Limit of valid characters after xor'ing with the above value.
const int _xorCharLimit = 0x5f;

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

/// Initial state for scanner.
const int _uriStart = $_uriStart;

/// If scanning of a URI terminates in this state or above,
/// consider the URI non-simple
const int _nonSimpleEndStates = $_nonSimpleEndStates;

/// Initial state for scheme validation.
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
/// All remaining characters are mapped to position 0x1f (`0x7f ^ 0x60`), which
/// represents the transition for all remaining characters.
$tableString
// --------------------------------------------------------------------
/// Scan a string using the [_scannerTables] state machine.
///
/// Scans [uri] from [start] to [end], starting in state [state] and
/// writing output into [indices].
///
/// Returns the final state. If that state is greater than or equal to
/// [_nonSimpleEndStates], the general URI scan should consider the
/// result non-simple, even if no position has been written to
/// [_notSimpleIndex] of [indices].
int _scan(String uri, int start, int end, int state, List<int> indices) {
  // Number of characters in table for each state (range 0x20..0x60).
  const int stateTableSize = 0x60;
  // Value to xor input character with to make valid range start at zero.
  const int _charXor = $_charXor;
  // Limit on valid values after doing xor.
  const int _xorCharLimit = $_xorCharLimit;
  // Entry used for invalid input characters (not in the range 0x20-0x7f).
  const int _invalidChar = 0x7F ^ _charXor;
  // Shift to extract write position from transition table entry.
  const int _writeIndexShift = $_stateBits;
  // Mask for state part of transition table entry.
  const int _stateMask = $_stateMask;

  assert(end <= uri.length);
  for (int i = start; i < end; i++) {
    int char = uri.codeUnitAt(i) ^ _charXor;
    if (char > _xorCharLimit) char = _invalidChar;
    int transition = _scannerTables.codeUnitAt(state * stateTableSize + char);
    state = transition & _stateMask;
    indices[transition >> _writeIndexShift] = i;
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
/// while escaping non-printable characters, `"`, `$` and `\`,
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

/// Creates the tables for `_scannerTables` used by [Uri.parse].
///
/// See `_scannerTables` in `sdk/lib/core/uri.dart` for the generated format.
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
/// start instead. This case is checked manually post-scanning (such a path
/// needs to be normalized to end in "../", so the URI shouldn't be considered
/// simple).
List<Uint8List> _createTables() {
  // States used to scan a URI from scratch.
  assert(_uriStart == 0);
  const int uriStart = _uriStart;
  const int schemeOrPath = uriStart + 1;
  const int authOrPath = schemeOrPath + 1;
  const int authOrPathSlash = authOrPath + 1;
  const int userInfoOrHost0 = authOrPathSlash + 1;
  const int userInfoOrHost = userInfoOrHost0 + 1;
  const int userInfoOrPort0 = userInfoOrHost + 1;
  const int userInfoOrPort = userInfoOrPort0 + 1;
  const int ipv6Host = userInfoOrPort + 1;
  const int relPathSeg = ipv6Host + 1;
  const int pathSeg = relPathSeg + 1;
  const int path = pathSeg + 1;
  const int query = path + 1;
  const int fragment = query + 1;
  const int schemeOrPathDot = fragment + 1; // Path ends in `.`.
  const int schemeOrPathDot2 = schemeOrPathDot + 1; // Path ends in `..`.
  const int relPathSegDot = schemeOrPathDot2 + 1; // Path ends in `.`.
  const int relPathSegDot2 = relPathSegDot + 1; // Path ends in `..`.
  const int pathSegDot = relPathSegDot2 + 1; // Path ends in `.`.
  const int pathSegDot2 = pathSegDot + 1; // Path ends in `..`.
  assert(_notSimpleIndex == schemeOrPathDot);

  // States used to validate a scheme after its end position has been found.
  // A separate state machine in the same table.
  const int scheme0 = pathSegDot2 + 1;
  const int scheme = scheme0 + 1;
  assert(scheme0 == _schemeStart);

  // Total number of states for the scanner.
  const int stateCount = scheme + 1;
  assert(stateCount == _stateCount);
  assert(1 << _stateBits >= stateCount);

  // Constants encoding the write-index for the state transition into the top 3
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
  const subDelimiters = r"!$&'()*+,;=";
  // The `pchar` characters of RFC 3986: characters that may occur in a path,
  // excluding escapes.
  const pchar = "$unreserved$subDelimiters";

  var tables = List<Uint8List>.generate(stateCount, (_) => Uint8List(96));

  // Helper function which initialize the table for [state] with a default
  // transition and returns the table.
  Uint8List build(int state, int defaultTransition) =>
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

  // Helper function which sets the transition for all characters in the
  // range from `range[0]` to `range[1]` to [transition] in the [target] table.
  //
  // The [range] must be a two-character string where both characters are in
  // the U+0020 .. U+007E range and the former character must have a lower
  // code point than the latter.
  void setRange(Uint8List target, String range, int transition) {
    for (int i = range.codeUnitAt(0), n = range.codeUnitAt(1); i <= n; i++) {
      target[i ^ 0x60] = transition;
    }
  }

  // Create the transitions for each state.
  Uint8List b;

  // Entry point of URI-scanner state machine.
  // Validate as path. If it is a scheme, we recognize that
  // and validate it later.
  b = build(uriStart, schemeOrPath | notSimple);
  setChars(b, pchar, schemeOrPath);
  setChars(b, ".", schemeOrPathDot);
  setChars(b, ":", authOrPath | schemeEnd); // Handle later.
  setChars(b, "/", authOrPathSlash);
  setChars(b, r"\", authOrPathSlash | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(schemeOrPathDot, schemeOrPath | notSimple);
  setChars(b, pchar, schemeOrPath);
  setChars(b, ".", schemeOrPathDot2);
  setChars(b, ':', authOrPath | schemeEnd);
  setChars(b, r"/\", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(schemeOrPathDot2, schemeOrPath | notSimple);
  setChars(b, pchar, schemeOrPath);
  setChars(b, "%", schemeOrPath | notSimple);
  setChars(b, ':', authOrPath | schemeEnd);
  setChars(b, "/", relPathSeg);
  setChars(b, r"\", relPathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(schemeOrPath, schemeOrPath | notSimple);
  setChars(b, pchar, schemeOrPath);
  setChars(b, ':', authOrPath | schemeEnd);
  setChars(b, "/", pathSeg);
  setChars(b, r"\", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(authOrPath, path | notSimple);
  setChars(b, pchar, path | pathStart);
  setChars(b, "/", authOrPathSlash | pathStart);
  setChars(b, r"\", authOrPathSlash | pathStart); // This should be non-simple.
  setChars(b, ".", pathSegDot | pathStart);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(authOrPathSlash, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, "/", userInfoOrHost0 | hostStart);
  setChars(b, r"\", userInfoOrHost0 | hostStart); // This should be non-simple.
  setChars(b, ".", pathSegDot);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(userInfoOrHost0, userInfoOrHost | notSimple);
  setChars(b, pchar, userInfoOrHost);
  setRange(b, "AZ", userInfoOrHost | notSimple);
  setChars(b, ":", userInfoOrPort0 | portStart);
  setChars(b, "@", userInfoOrHost0 | hostStart);
  setChars(b, "[", ipv6Host | notSimple);
  setChars(b, "/", pathSeg | pathStart);
  setChars(b, r"\", pathSeg | pathStart); // This should be non-simple.
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(userInfoOrHost, userInfoOrHost | notSimple);
  setChars(b, pchar, userInfoOrHost);
  setRange(b, "AZ", userInfoOrHost | notSimple);
  setChars(b, ":", userInfoOrPort0 | portStart);
  setChars(b, "@", userInfoOrHost0 | hostStart);
  setChars(b, "/", pathSeg | pathStart);
  setChars(b, r"\", pathSeg | pathStart); // This should be non-simple.
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(userInfoOrPort0, userInfoOrPort | notSimple);
  setRange(b, "19", userInfoOrPort);
  setChars(b, "@", userInfoOrHost0 | hostStart);
  setChars(b, "/", pathSeg | pathStart);
  setChars(b, r"\", pathSeg | pathStart); // This should be non-simple.
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(userInfoOrPort, userInfoOrPort | notSimple);
  setRange(b, "09", userInfoOrPort);
  setChars(b, "@", userInfoOrHost0 | hostStart);
  setChars(b, "/", pathSeg | pathStart);
  setChars(b, r"\", pathSeg | pathStart); // This should be non-simple.
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(ipv6Host, ipv6Host);
  setChars(b, "]", userInfoOrHost);

  b = build(relPathSeg, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, ".", relPathSegDot);
  setChars(b, r"/\", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(relPathSegDot, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, ".", relPathSegDot2);
  setChars(b, r"/\", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(relPathSegDot2, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, "/", relPathSeg);
  setChars(b, r"\", relPathSeg | notSimple);
  setChars(b, "?", query | queryStart); // This should be non-simple.
  setChars(b, "#", fragment | fragmentStart); // This should be non-simple.

  b = build(pathSeg, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, ".", pathSegDot);
  setChars(b, "/", pathSeg);
  setChars(b, r"\", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(pathSegDot, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, ".", pathSegDot2);
  setChars(b, r"/\", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(pathSegDot2, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, r"/\", pathSeg | notSimple);
  setChars(b, "?", query | queryStart);
  setChars(b, "#", fragment | fragmentStart);

  b = build(path, path | notSimple);
  setChars(b, pchar, path);
  setChars(b, "/", pathSeg);
  setChars(b, r"\", pathSeg | notSimple);
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
