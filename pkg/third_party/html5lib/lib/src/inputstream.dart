library inputstream;

import 'dart:collection';
import 'package:utf/utf.dart';
import 'package:source_span/source_span.dart';
import 'char_encodings.dart';
import 'constants.dart';
import 'utils.dart';
import 'encoding_parser.dart';

/// Hooks to call into dart:io without directly referencing it.
class ConsoleSupport {
  List<int> bytesFromFile(source) => null;
}

// TODO(jmesserly): use lazy init here when supported.
ConsoleSupport consoleSupport = new ConsoleSupport();

/// Provides a unicode stream of characters to the HtmlTokenizer.
///
/// This class takes care of character encoding and removing or replacing
/// incorrect byte-sequences and also provides column and line tracking.
class HtmlInputStream {
  /// Number of bytes to use when looking for a meta element with
  /// encoding information.
  static const int numBytesMeta = 512;

  /// Encoding to use if no other information can be found.
  static const String defaultEncoding = 'windows-1252';

  /// The name of the character encoding.
  String charEncodingName;

  /// True if we are certain about [charEncodingName], false for tenative.
  bool charEncodingCertain = true;

  final bool generateSpans;

  /// Location where the contents of the stream were found.
  final String sourceUrl;

  List<int> _rawBytes;

  /// Raw UTF-16 codes, used if a Dart String is passed in.
  Iterable<int> _rawChars;

  Queue<String> errors;

  SourceFile fileInfo;

  List<int> _lineStarts;

  List<int> _chars;

  int _offset;

  /// Initialises the HtmlInputStream.
  ///
  /// HtmlInputStream(source, [encoding]) -> Normalized stream from source
  /// for use by html5lib.
  ///
  /// [source] can be either a [String] or a [List<int>] containing the raw
  /// bytes, or a file if [consoleSupport] is initialized.
  ///
  /// The optional encoding parameter must be a string that indicates
  /// the encoding.  If specified, that encoding will be used,
  /// regardless of any BOM or later declaration (such as in a meta
  /// element)
  ///
  /// [parseMeta] - Look for a <meta> element containing encoding information
  HtmlInputStream(source, [String encoding, bool parseMeta = true,
        this.generateSpans = false, this.sourceUrl])
      : charEncodingName = codecName(encoding) {

    if (source is String) {
      _rawChars = toCodepoints(source);
      charEncodingName = 'utf-8';
      charEncodingCertain = true;
    } else if (source is List<int>) {
      _rawBytes = source;
    } else {
      // TODO(jmesserly): it's unfortunate we need to read all bytes in advance,
      // but it's necessary because of how the UTF decoders work.
      _rawBytes = consoleSupport.bytesFromFile(source);

      if (_rawBytes == null) {
        // TODO(jmesserly): we should accept some kind of stream API too.
        // Unfortunately dart:io InputStream is async only, which won't work.
        throw new ArgumentError("'source' must be a String or "
            "List<int> (of bytes). You can also pass a RandomAccessFile if you"
            "`import 'package:html5lib/parser_console.dart'` and call "
            "`useConsole()`.");
      }
    }

    // Detect encoding iff no explicit "transport level" encoding is supplied
    if (charEncodingName == null) {
      detectEncoding(parseMeta);
    }

    reset();
  }

  void reset() {
    errors = new Queue<String>();

    _offset = 0;
    _lineStarts = <int>[0];
    _chars = <int>[];

    if (_rawChars == null) {
      _rawChars = decodeBytes(charEncodingName, _rawBytes);
    }

    bool skipNewline = false;
    for (var c in _rawChars) {
      if (skipNewline) {
        skipNewline = false;
        if (c == NEWLINE) continue;
      }

      if (invalidUnicode(c)) errors.add('invalid-codepoint');

      if (0xD800 <= c && c <= 0xDFFF) {
        c = 0xFFFD;
      } else if (c == RETURN) {
        skipNewline = true;
        c = NEWLINE;
      }

      _chars.add(c);
      if (c == NEWLINE) _lineStarts.add(_chars.length);
    }

    // Free decoded characters if they aren't needed anymore.
    if (_rawBytes != null) _rawChars = null;

    // TODO(sigmund): Don't parse the file at all if spans aren't being
    // generated.
    fileInfo = new SourceFile.decoded(_chars, url: sourceUrl);
  }


  void detectEncoding([bool parseMeta = true]) {
    // First look for a BOM
    // This will also read past the BOM if present
    charEncodingName = detectBOM();
    charEncodingCertain = true;

    // If there is no BOM need to look for meta elements with encoding
    // information
    if (charEncodingName == null && parseMeta) {
      charEncodingName = detectEncodingMeta();
      charEncodingCertain = false;
    }
    // If all else fails use the default encoding
    if (charEncodingName == null) {
      charEncodingCertain = false;
      charEncodingName = defaultEncoding;
    }

    // Substitute for equivalent encodings:
    if (charEncodingName.toLowerCase() == 'iso-8859-1') {
      charEncodingName = 'windows-1252';
    }
  }

  void changeEncoding(String newEncoding) {
    if (_rawBytes == null) {
      // We should never get here -- if encoding is certain we won't try to
      // change it.
      throw new StateError('cannot change encoding when parsing a String.');
    }

    newEncoding = codecName(newEncoding);
    if (const ['utf-16', 'utf-16-be', 'utf-16-le'].contains(newEncoding)) {
      newEncoding = 'utf-8';
    }
    if (newEncoding == null) {
      return;
    } else if (newEncoding == charEncodingName) {
      charEncodingCertain = true;
    } else {
      charEncodingName = newEncoding;
      charEncodingCertain = true;
      _rawChars = null;
      reset();
      throw new ReparseException(
          'Encoding changed from $charEncodingName to $newEncoding');
    }
  }

  /// Attempts to detect at BOM at the start of the stream. If
  /// an encoding can be determined from the BOM return the name of the
  /// encoding otherwise return null.
  String detectBOM() {
    // Try detecting the BOM using bytes from the string
    if (hasUtf8Bom(_rawBytes)) {
      return 'utf-8';
    }
    // Note: we don't need to remember whether it was big or little endian
    // because the decoder will do that later. It will also eat the BOM for us.
    if (hasUtf16Bom(_rawBytes)) {
      return 'utf-16';
    }
    if (hasUtf32Bom(_rawBytes)) {
      return 'utf-32';
    }
    return null;
  }

  /// Report the encoding declared by the meta element.
  String detectEncodingMeta() {
    var parser = new EncodingParser(slice(_rawBytes, 0, numBytesMeta));
    var encoding = parser.getEncoding();

    if (const ['utf-16', 'utf-16-be', 'utf-16-le'].contains(encoding)) {
      encoding = 'utf-8';
    }

    return encoding;
  }

  /// Returns the current offset in the stream, i.e. the number of codepoints
  /// since the start of the file.
  int get position => _offset;

  /// Read one character from the stream or queue if available. Return
  /// EOF when EOF is reached.
  String char() {
    if (_offset >= _chars.length) return EOF;
    return new String.fromCharCodes([_chars[_offset++]]);
  }

  String peekChar() {
    if (_offset >= _chars.length) return EOF;
    return new String.fromCharCodes([_chars[_offset]]);
  }

  /// Returns a string of characters from the stream up to but not
  /// including any character in 'characters' or EOF.
  String charsUntil(String characters, [bool opposite = false]) {
    int start = _offset;
    String c;
    while ((c = peekChar()) != null && characters.contains(c) == opposite) {
      _offset++;
    }

    return new String.fromCharCodes(_chars.sublist(start, _offset));
  }

  void unget(String ch) {
    // Only one character is allowed to be ungotten at once - it must
    // be consumed again before any further call to unget
    if (ch != null) {
      _offset--;
      assert(peekChar() == ch);
    }
  }
}


// TODO(jmesserly): the Python code used a regex to check for this. But
// Dart doesn't let you create a regexp with invalid characters.
bool invalidUnicode(int c) {
  if (0x0001 <= c && c <= 0x0008) return true;
  if (0x000E <= c && c <= 0x001F) return true;
  if (0x007F <= c && c <= 0x009F) return true;
  if (0xD800 <= c && c <= 0xDFFF) return true;
  if (0xFDD0 <= c && c <= 0xFDEF) return true;
  switch (c) {
    case 0x000B: case 0xFFFE: case 0xFFFF: case 0x01FFFE: case 0x01FFFF:
    case 0x02FFFE: case 0x02FFFF: case 0x03FFFE: case 0x03FFFF:
    case 0x04FFFE: case 0x04FFFF: case 0x05FFFE: case 0x05FFFF:
    case 0x06FFFE: case 0x06FFFF: case 0x07FFFE: case 0x07FFFF:
    case 0x08FFFE: case 0x08FFFF: case 0x09FFFE: case 0x09FFFF:
    case 0x0AFFFE: case 0x0AFFFF: case 0x0BFFFE: case 0x0BFFFF:
    case 0x0CFFFE: case 0x0CFFFF: case 0x0DFFFE: case 0x0DFFFF:
    case 0x0EFFFE: case 0x0EFFFF: case 0x0FFFFE: case 0x0FFFFF:
    case 0x10FFFE: case 0x10FFFF:
      return true;
  }
  return false;
}

/// Return the python codec name corresponding to an encoding or null if the
/// string doesn't correspond to a valid encoding.
String codecName(String encoding) {
  final asciiPunctuation = new RegExp(
      "[\u0009-\u000D\u0020-\u002F\u003A-\u0040\u005B-\u0060\u007B-\u007E]");

  if (encoding == null) return null;
  var canonicalName = encoding.replaceAll(asciiPunctuation, '').toLowerCase();
  return encodings[canonicalName];
}
