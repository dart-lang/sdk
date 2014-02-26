/// Decodes bytes using the correct name. See [decodeBytes].
library char_encodings;

import 'dart:collection';
import 'package:utf/utf.dart';

// TODO(jmesserly): this function is conspicuously absent from dart:utf.
/// Returns true if the [bytes] starts with a UTF-8 byte order mark.
/// Since UTF-8 doesn't have byte order, it's somewhat of a misnomer, but it is
/// used in HTML to detect the UTF-
bool hasUtf8Bom(List<int> bytes, [int offset = 0, int length]) {
  int end = length != null ? offset + length : bytes.length;
  return (offset + 3) <= end &&
      bytes[offset] == 0xEF &&
      bytes[offset + 1] == 0xBB &&
      bytes[offset + 2] == 0xBF;
}

// TODO(jmesserly): it's unfortunate that this has to be one-shot on the entire
// file, but dart:utf does not expose stream-based decoders yet.
/// Decodes the [bytes] with the provided [encoding] and returns an iterable for
/// the codepoints. Supports the major unicode encodings as well as ascii and
/// and windows-1252 encodings.
Iterable<int> decodeBytes(String encoding, List<int> bytes,
    [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  if (length == null) length = bytes.length;
  final replace = replacementCodepoint;
  switch (encoding) {
    case 'ascii':
      bytes = bytes.sublist(offset, offset + length);
      // TODO(jmesserly): this was taken from runtime/bin/string_stream.dart
      for (int byte in bytes) {
        if (byte > 127) {
          // TODO(jmesserly): ideally this would be DecoderException, like the
          // one thrown in runtime/bin/string_stream.dart, but we don't want to
          // depend on dart:io.
          throw new FormatException("Illegal ASCII character $byte");
        }
      }
      return bytes;

    case 'windows-1252':
    case 'cp1252':
      return decodeWindows1252AsIterable(bytes, offset, length, replace);

    case 'utf-8':
      // NOTE: to match the behavior of the other decode functions, we eat the
      // utf-8 BOM here.
      if (hasUtf8Bom(bytes, offset, length)) {
        offset += 3;
        length -= 3;
      }
      return decodeUtf8AsIterable(bytes, offset, length, replace);

    case 'utf-16':
      return decodeUtf16AsIterable(bytes, offset, length, replace);
    case 'utf-16-be':
      return decodeUtf16beAsIterable(bytes, offset, length, true, replace);
    case 'utf-16-le':
      return decodeUtf16leAsIterable(bytes, offset, length, true, replace);

    case 'utf-32':
      return decodeUtf32AsIterable(bytes, offset, length, replace);
    case 'utf-32-be':
      return decodeUtf32beAsIterable(bytes, offset, length, true, replace);
    case 'utf-32-le':
      return decodeUtf32leAsIterable(bytes, offset, length, true, replace);

    default:
      throw new ArgumentError('Encoding $encoding not supported');
  }
}


// TODO(jmesserly): use dart:utf once http://dartbug.com/6476 is fixed.
/// Returns the code points for the [input]. This works like [String.charCodes]
/// but it decodes UTF-16 surrogate pairs.
List<int> toCodepoints(String input) {
  var newCodes = <int>[];
  for (int i = 0; i < input.length; i++) {
    var c = input.codeUnitAt(i);
    if (0xD800 <= c && c <= 0xDBFF) {
      int next = i + 1;
      if (next < input.length) {
        var d = input.codeUnitAt(next);
        if (0xDC00 <= d && d <= 0xDFFF) {
          c = 0x10000 + ((c - 0xD800) << 10) + (d - 0xDC00);
          i = next;
        }
      }
    }
    newCodes.add(c);
  }
  return newCodes;
}


/// Decodes [windows-1252](http://en.wikipedia.org/wiki/Windows-1252) bytes as
/// an iterable. Thus, the consumer can only convert as much of the input as
/// needed. Set the [replacementCharacter] to null to throw an [ArgumentError]
/// rather than replace the bad value.
IterableWindows1252Decoder decodeWindows1252AsIterable(List<int> bytes,
    [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableWindows1252Decoder(bytes, offset, length,
      replacementCodepoint);
}


/// Return type of [decodeWindows1252AsIterable] and variants. The Iterable type
/// provides an iterator on demand and the iterator will only translate bytes
/// as requested by the user of the iterator. (Note: results are not cached.)
class IterableWindows1252Decoder extends IterableBase<int> {
  final List<int> bytes;
  final int offset;
  final int length;
  final int replacementCodepoint;

  IterableWindows1252Decoder(List<int> this.bytes, [int this.offset = 0,
      int this.length = null,
      int this.replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]);

  Windows1252Decoder get iterator =>
      new Windows1252Decoder(bytes, offset, length, replacementCodepoint);
}


/// Provides an iterator of Unicode codepoints from windows-1252 encoded bytes.
/// The parameters can set an offset into a list of bytes (as int), limit the
/// length of the values to be decoded, and override the default Unicode
/// replacement character. Set the replacementCharacter to null to throw an
/// ArgumentError rather than replace the bad value. The return value
/// from this method can be used as an Iterable (e.g. in a for-loop).
class Windows1252Decoder implements Iterator<int> {
  final int replacementCodepoint;
  final List<int> _bytes;
  int _offset;
  final int _length;

  Windows1252Decoder(List<int> bytes, [int offset = 0, int length,
      this.replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT])
      : _bytes = bytes,
        _offset = offset - 1,
        _length = length == null ? bytes.length : length;

  bool get _inRange => _offset >= 0 && _offset < _length;
  int get current => _inRange ? _mapChar(_bytes[_offset]) : null;

  bool moveNext() {
    _offset++;
    return _inRange;
  }

  int _mapChar(int char) {
    // TODO(jmesserly): this is duplicating entitiesWindows1252 and
    // replacementCharacters from constants.dart
    switch (char) {
      case 0x80: return 0x20AC; // EURO SIGN
      case 0x82: return 0x201A; // SINGLE LOW-9 QUOTATION MARK
      case 0x83: return 0x0192; // LATIN SMALL LETTER F WITH HOOK
      case 0x84: return 0x201E; // DOUBLE LOW-9 QUOTATION MARK
      case 0x85: return 0x2026; // HORIZONTAL ELLIPSIS
      case 0x86: return 0x2020; // DAGGER
      case 0x87: return 0x2021; // DOUBLE DAGGER
      case 0x88: return 0x02C6; // MODIFIER LETTER CIRCUMFLEX ACCENT
      case 0x89: return 0x2030; // PER MILLE SIGN
      case 0x8A: return 0x0160; // LATIN CAPITAL LETTER S WITH CARON
      case 0x8B: return 0x2039; // SINGLE LEFT-POINTING ANGLE QUOTATION MARK
      case 0x8C: return 0x0152; // LATIN CAPITAL LIGATURE OE
      case 0x8E: return 0x017D; // LATIN CAPITAL LETTER Z WITH CARON
      case 0x91: return 0x2018; // LEFT SINGLE QUOTATION MARK
      case 0x92: return 0x2019; // RIGHT SINGLE QUOTATION MARK
      case 0x93: return 0x201C; // LEFT DOUBLE QUOTATION MARK
      case 0x94: return 0x201D; // RIGHT DOUBLE QUOTATION MARK
      case 0x95: return 0x2022; // BULLET
      case 0x96: return 0x2013; // EN DASH
      case 0x97: return 0x2014; // EM DASH
      case 0x98: return 0x02DC; // SMALL TILDE
      case 0x99: return 0x2122; // TRADE MARK SIGN
      case 0x9A: return 0x0161; // LATIN SMALL LETTER S WITH CARON
      case 0x9B: return 0x203A; // SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
      case 0x9C: return 0x0153; // LATIN SMALL LIGATURE OE
      case 0x9E: return 0x017E; // LATIN SMALL LETTER Z WITH CARON
      case 0x9F: return 0x0178; // LATIN CAPITAL LETTER Y WITH DIAERESIS

      case 0x81:
      case 0x8D:
      case 0x8F:
      case 0x90:
      case 0x9D:
        if (replacementCodepoint == null) {
          throw new ArgumentError(
              "Invalid windows-1252 code point $char at $_offset");
        }
        return replacementCodepoint;
    }
    return char;
  }
}
