// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of utf;

// TODO(jmesserly): would be nice to have this on String (dartbug.com/6501).
/**
 * Provide a list of Unicode codepoints for a given string.
 */
List<int> stringToCodepoints(String str) {
  // Note: str.codeUnits gives us 16-bit code units on all Dart implementations.
  // So we need to convert.
  return utf16CodeUnitsToCodepoints(str.codeUnits);
}

/**
 * Generate a string from the provided Unicode codepoints.
 *
 * *Deprecated* Use [String.fromCharCodes] instead.
 */
@deprecated
String codepointsToString(List<int> codepoints) {
  return new String.fromCharCodes(codepoints);
}
/**
 * Decodes the UTF-16 bytes as an iterable. Thus, the consumer can only convert
 * as much of the input as needed. Determines the byte order from the BOM,
 * or uses big-endian as a default. This method always strips a leading BOM.
 * Set the [replacementCodepoint] to null to throw an ArgumentError
 * rather than replace the bad value. The default value for
 * [replacementCodepoint] is U+FFFD.
 */
IterableUtf16Decoder decodeUtf16AsIterable(List<int> bytes, [int offset = 0,
    int length, int replacementCodepoint =
    UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableUtf16Decoder._(
      () => new Utf16BytesToCodeUnitsDecoder(bytes, offset, length,
      replacementCodepoint), replacementCodepoint);
}

/**
 * Decodes the UTF-16BE bytes as an iterable. Thus, the consumer can only
 * convert as much of the input as needed. This method strips a leading BOM by
 * default, but can be overridden by setting the optional parameter [stripBom]
 * to false. Set the [replacementCodepoint] to null to throw an
 * ArgumentError rather than replace the bad value. The default
 * value for the [replacementCodepoint] is U+FFFD.
 */
IterableUtf16Decoder decodeUtf16beAsIterable(List<int> bytes, [int offset = 0,
    int length, bool stripBom = true, int replacementCodepoint =
    UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableUtf16Decoder._(
      () => new Utf16beBytesToCodeUnitsDecoder(bytes, offset, length, stripBom,
      replacementCodepoint), replacementCodepoint);
}

/**
 * Decodes the UTF-16LE bytes as an iterable. Thus, the consumer can only
 * convert as much of the input as needed. This method strips a leading BOM by
 * default, but can be overridden by setting the optional parameter [stripBom]
 * to false. Set the [replacementCodepoint] to null to throw an
 * ArgumentError rather than replace the bad value. The default
 * value for the [replacementCodepoint] is U+FFFD.
 */
IterableUtf16Decoder decodeUtf16leAsIterable(List<int> bytes, [int offset = 0,
    int length, bool stripBom = true, int replacementCodepoint =
    UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableUtf16Decoder._(
      () => new Utf16leBytesToCodeUnitsDecoder(bytes, offset, length, stripBom,
      replacementCodepoint), replacementCodepoint);
}

/**
 * Produce a String from a sequence of UTF-16 encoded bytes. This method always
 * strips a leading BOM. Set the [replacementCodepoint] to null to throw  an
 * ArgumentError rather than replace the bad value. The default
 * value for the [replacementCodepoint] is U+FFFD.
 */
String decodeUtf16(List<int> bytes, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  Utf16BytesToCodeUnitsDecoder decoder = new Utf16BytesToCodeUnitsDecoder(bytes,
      offset, length, replacementCodepoint);
  List<int> codeunits = decoder.decodeRest();
  return new String.fromCharCodes(
      utf16CodeUnitsToCodepoints(codeunits, 0, null, replacementCodepoint));
}

/**
 * Produce a String from a sequence of UTF-16BE encoded bytes. This method
 * strips a leading BOM by default, but can be overridden by setting the
 * optional parameter [stripBom] to false. Set the [replacementCodepoint] to
 * null to throw an ArgumentError rather than replace the bad value.
 * The default value for the [replacementCodepoint] is U+FFFD.
 */
String decodeUtf16be(List<int> bytes, [int offset = 0, int length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  List<int> codeunits = (new Utf16beBytesToCodeUnitsDecoder(bytes, offset,
      length, stripBom, replacementCodepoint)).decodeRest();
  return new String.fromCharCodes(
      utf16CodeUnitsToCodepoints(codeunits, 0, null, replacementCodepoint));
}

/**
 * Produce a String from a sequence of UTF-16LE encoded bytes. This method
 * strips a leading BOM by default, but can be overridden by setting the
 * optional parameter [stripBom] to false. Set the [replacementCodepoint] to
 * null to throw an ArgumentError rather than replace the bad value.
 * The default value for the [replacementCodepoint] is U+FFFD.
 */
String decodeUtf16le(List<int> bytes, [int offset = 0, int length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  List<int> codeunits = (new Utf16leBytesToCodeUnitsDecoder(bytes, offset,
      length, stripBom, replacementCodepoint)).decodeRest();
  return new String.fromCharCodes(
      utf16CodeUnitsToCodepoints(codeunits, 0, null, replacementCodepoint));
}

/**
 * Produce a list of UTF-16 encoded bytes. This method prefixes the resulting
 * bytes with a big-endian byte-order-marker.
 */
List<int> encodeUtf16(String str) =>
    encodeUtf16be(str, true);

/**
 * Produce a list of UTF-16BE encoded bytes. By default, this method produces
 * UTF-16BE bytes with no BOM.
 */
List<int> encodeUtf16be(String str, [bool writeBOM = false]) {
  List<int> utf16CodeUnits = _stringToUtf16CodeUnits(str);
  List<int> encoding =
      new List<int>(2 * utf16CodeUnits.length + (writeBOM ? 2 : 0));
  int i = 0;
  if (writeBOM) {
    encoding[i++] = UNICODE_UTF_BOM_HI;
    encoding[i++] = UNICODE_UTF_BOM_LO;
  }
  for (int unit in utf16CodeUnits) {
    encoding[i++] = (unit & UNICODE_BYTE_ONE_MASK) >> 8;
    encoding[i++] = unit & UNICODE_BYTE_ZERO_MASK;
  }
  return encoding;
}

/**
 * Produce a list of UTF-16LE encoded bytes. By default, this method produces
 * UTF-16LE bytes with no BOM.
 */
List<int> encodeUtf16le(String str, [bool writeBOM = false]) {
  List<int> utf16CodeUnits = _stringToUtf16CodeUnits(str);
  List<int> encoding =
      new List<int>(2 * utf16CodeUnits.length + (writeBOM ? 2 : 0));
  int i = 0;
  if (writeBOM) {
    encoding[i++] = UNICODE_UTF_BOM_LO;
    encoding[i++] = UNICODE_UTF_BOM_HI;
  }
  for (int unit in utf16CodeUnits) {
    encoding[i++] = unit & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit & UNICODE_BYTE_ONE_MASK) >> 8;
  }
  return encoding;
}

/**
 * Identifies whether a List of bytes starts (based on offset) with a
 * byte-order marker (BOM).
 */
bool hasUtf16Bom(List<int> utf32EncodedBytes, [int offset = 0, int length]) {
  return hasUtf16beBom(utf32EncodedBytes, offset, length) ||
      hasUtf16leBom(utf32EncodedBytes, offset, length);
}

/**
 * Identifies whether a List of bytes starts (based on offset) with a
 * big-endian byte-order marker (BOM).
 */
bool hasUtf16beBom(List<int> utf16EncodedBytes, [int offset = 0, int length]) {
  int end = length != null ? offset + length : utf16EncodedBytes.length;
  return (offset + 2) <= end &&
      utf16EncodedBytes[offset] == UNICODE_UTF_BOM_HI &&
      utf16EncodedBytes[offset + 1] == UNICODE_UTF_BOM_LO;
}

/**
 * Identifies whether a List of bytes starts (based on offset) with a
 * little-endian byte-order marker (BOM).
 */
bool hasUtf16leBom(List<int> utf16EncodedBytes, [int offset = 0, int length]) {
  int end = length != null ? offset + length : utf16EncodedBytes.length;
  return (offset + 2) <= end &&
      utf16EncodedBytes[offset] == UNICODE_UTF_BOM_LO &&
      utf16EncodedBytes[offset + 1] == UNICODE_UTF_BOM_HI;
}

List<int> _stringToUtf16CodeUnits(String str) {
  return codepointsToUtf16CodeUnits(str.codeUnits);
}

typedef ListRangeIterator _CodeUnitsProvider();

/**
 * Return type of [decodeUtf16AsIterable] and variants. The Iterable type
 * provides an iterator on demand and the iterator will only translate bytes
 * as requested by the user of the iterator. (Note: results are not cached.)
 */
// TODO(floitsch): Consider removing the extend and switch to implements since
// that's cheaper to allocate.
class IterableUtf16Decoder extends IterableBase<int> {
  final _CodeUnitsProvider codeunitsProvider;
  final int replacementCodepoint;

  IterableUtf16Decoder._(this.codeunitsProvider, this.replacementCodepoint);

  Utf16CodeUnitDecoder get iterator =>
      new Utf16CodeUnitDecoder.fromListRangeIterator(codeunitsProvider(),
          replacementCodepoint);
}

/**
 * Convert UTF-16 encoded bytes to UTF-16 code units by grouping 1-2 bytes
 * to produce the code unit (0-(2^16)-1). Relies on BOM to determine
 * endian-ness, and defaults to BE.
 */
abstract class Utf16BytesToCodeUnitsDecoder implements ListRangeIterator {
  // TODO(kevmoo): should this field be private?
  final ListRangeIterator utf16EncodedBytesIterator;
  final int replacementCodepoint;
  int _current = null;

  Utf16BytesToCodeUnitsDecoder._fromListRangeIterator(
      this.utf16EncodedBytesIterator, this.replacementCodepoint);

  factory Utf16BytesToCodeUnitsDecoder(List<int> utf16EncodedBytes, [
      int offset = 0, int length,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
    if (length == null) {
      length = utf16EncodedBytes.length - offset;
    }
    if (hasUtf16beBom(utf16EncodedBytes, offset, length)) {
      return new Utf16beBytesToCodeUnitsDecoder(utf16EncodedBytes, offset + 2,
          length - 2, false, replacementCodepoint);
    } else if (hasUtf16leBom(utf16EncodedBytes, offset, length)) {
      return new Utf16leBytesToCodeUnitsDecoder(utf16EncodedBytes, offset + 2,
          length - 2, false, replacementCodepoint);
    } else {
      return new Utf16beBytesToCodeUnitsDecoder(utf16EncodedBytes, offset,
          length, false, replacementCodepoint);
    }
  }

  /**
   * Provides a fast way to decode the rest of the source bytes in a single
   * call. This method trades memory for improved speed in that it potentially
   * over-allocates the List containing results.
   */
  List<int> decodeRest() {
    List<int> codeunits = new List<int>(remaining);
    int i = 0;
    while (moveNext()) {
      codeunits[i++] = current;
    }
    if (i == codeunits.length) {
      return codeunits;
    } else {
      List<int> truncCodeunits = new List<int>(i);
      truncCodeunits.setRange(0, i, codeunits);
      return truncCodeunits;
    }
  }

  int get current => _current;

  bool moveNext() {
    _current = null;
    int remaining = utf16EncodedBytesIterator.remaining;
    if (remaining == 0) {
      _current = null;
      return false;
    }
    if (remaining == 1) {
      utf16EncodedBytesIterator.moveNext();
      if (replacementCodepoint != null) {
        _current = replacementCodepoint;
        return true;
      } else {
        throw new ArgumentError(
            "Invalid UTF16 at ${utf16EncodedBytesIterator.position}");
      }
    }
    _current = decode();
    return true;
  }

  int get position => utf16EncodedBytesIterator.position ~/ 2;

  void backup([int by = 1]) {
    utf16EncodedBytesIterator.backup(2 * by);
  }

  int get remaining => (utf16EncodedBytesIterator.remaining + 1) ~/ 2;

  void skip([int count = 1]) {
    utf16EncodedBytesIterator.skip(2 * count);
  }

  int decode();
}

/**
 * Convert UTF-16BE encoded bytes to utf16 code units by grouping 1-2 bytes
 * to produce the code unit (0-(2^16)-1).
 */
class Utf16beBytesToCodeUnitsDecoder extends Utf16BytesToCodeUnitsDecoder {
  Utf16beBytesToCodeUnitsDecoder(List<int> utf16EncodedBytes, [
      int offset = 0, int length, bool stripBom = true,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) :
      super._fromListRangeIterator(
          (new ListRange(utf16EncodedBytes, offset, length)).iterator,
          replacementCodepoint) {
    if (stripBom && hasUtf16beBom(utf16EncodedBytes, offset, length)) {
      skip();
    }
  }

  int decode() {
    utf16EncodedBytesIterator.moveNext();
    int hi = utf16EncodedBytesIterator.current;
    utf16EncodedBytesIterator.moveNext();
    int lo = utf16EncodedBytesIterator.current;
    return (hi << 8) + lo;
  }
}

/**
 * Convert UTF-16LE encoded bytes to utf16 code units by grouping 1-2 bytes
 * to produce the code unit (0-(2^16)-1).
 */
class Utf16leBytesToCodeUnitsDecoder extends Utf16BytesToCodeUnitsDecoder {
  Utf16leBytesToCodeUnitsDecoder(List<int> utf16EncodedBytes, [
      int offset = 0, int length, bool stripBom = true,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) :
      super._fromListRangeIterator(
          (new ListRange(utf16EncodedBytes, offset, length)).iterator,
          replacementCodepoint) {
    if (stripBom && hasUtf16leBom(utf16EncodedBytes, offset, length)) {
      skip();
    }
  }

  int decode() {
    utf16EncodedBytesIterator.moveNext();
    int lo = utf16EncodedBytesIterator.current;
    utf16EncodedBytesIterator.moveNext();
    int hi = utf16EncodedBytesIterator.current;
    return (hi << 8) + lo;
  }
}
