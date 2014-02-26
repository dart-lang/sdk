library encoding_parser;

import 'dart:collection';
import 'constants.dart';
import 'inputstream.dart';

// TODO(jmesserly): I converted StopIteration to StateError("No more elements").
// Seems strange to throw this from outside of an iterator though.
/// String-like object with an associated position and various extra methods
/// If the position is ever greater than the string length then an exception is
/// raised.
class EncodingBytes extends IterableBase<String> {
  final String _bytes;
  int _position = -1;

  EncodingBytes(this._bytes);

  Iterator<String> get iterator => _bytes.split('').iterator;

  int get length => _bytes.length;

  String next() {
    var p = _position = _position + 1;
    if (p >= length) {
      throw new StateError("No more elements");
    } else if (p < 0) {
      throw new RangeError(p);
    }
    return _bytes[p];
  }

  String previous() {
    var p = _position;
    if (p >= length) {
      throw new StateError("No more elements");
    } else if (p < 0) {
      throw new RangeError(p);
    }
    _position = p = p - 1;
    return _bytes[p];
  }

  set position(int value) {
    if (_position >= length) {
      throw new StateError("No more elements");
    }
    _position = value;
  }

  int get position {
    if (_position >= length) {
      throw new StateError("No more elements");
    }
    if (_position >= 0) {
      return _position;
    } else {
      return 0;
    }
  }

  String get currentByte => _bytes[position];

  /// Skip past a list of characters. Defaults to skipping [isWhitespace].
  String skipChars([CharPreciate skipChars]) {
    if (skipChars == null) skipChars = isWhitespace;
    var p = position;  // use property for the error-checking
    while (p < length) {
      var c = _bytes[p];
      if (!skipChars(c)) {
        _position = p;
        return c;
      }
      p += 1;
    }
    _position = p;
    return null;
  }

  String skipUntil(CharPreciate untilChars) {
    var p = position;
    while (p < length) {
      var c = _bytes[p];
      if (untilChars(c)) {
        _position = p;
        return c;
      }
      p += 1;
    }
    return null;
  }

  /// Look for a sequence of bytes at the start of a string. If the bytes
  /// are found return true and advance the position to the byte after the
  /// match. Otherwise return false and leave the position alone.
  bool matchBytes(String bytes) {
    var p = position;
    if (_bytes.length < p + bytes.length) {
      return false;
    }
    var data = _bytes.substring(p, p + bytes.length);
    if (data == bytes) {
      position += bytes.length;
      return true;
    }
    return false;
  }

  /// Look for the next sequence of bytes matching a given sequence. If
  /// a match is found advance the position to the last byte of the match
  bool jumpTo(String bytes) {
    var newPosition = _bytes.indexOf(bytes, position);
    if (newPosition >= 0) {
      _position = newPosition + bytes.length - 1;
      return true;
    } else {
      throw new StateError("No more elements");
    }
  }

  String slice(int start, [int end]) {
    if (end == null) end = length;
    if (end < 0) end += length;
    return _bytes.substring(start, end - start);
  }
}

/// Mini parser for detecting character encoding from meta elements.
class EncodingParser {
  final EncodingBytes data;
  String encoding;

  /// [bytes] - the data to work on for encoding detection.
  EncodingParser(List<int> bytes)
      // Note: this is intentionally interpreting bytes as codepoints.
      : data = new EncodingBytes(new String.fromCharCodes(bytes).toLowerCase());

  String getEncoding() {
    final methodDispatch = [
      ["<!--", handleComment],
      ["<meta", handleMeta],
      ["</", handlePossibleEndTag],
      ["<!", handleOther],
      ["<?", handleOther],
      ["<", handlePossibleStartTag]];

    try {
      for (var byte in data) {
        var keepParsing = true;
        for (var dispatch in methodDispatch) {
          if (data.matchBytes(dispatch[0])) {
            try {
              keepParsing = dispatch[1]();
              break;
            } on StateError catch (e) {
              keepParsing = false;
              break;
            }
          }
        }
        if (!keepParsing) {
          break;
        }
      }
    } on StateError catch (e) {
      // Catch this here to match behavior of Python's StopIteration
    }
    return encoding;
  }

  /// Skip over comments.
  bool handleComment() => data.jumpTo("-->");

  bool handleMeta() {
    if (!isWhitespace(data.currentByte)) {
      // if we have <meta not followed by a space so just keep going
      return true;
    }
    // We have a valid meta element we want to search for attributes
    while (true) {
      // Try to find the next attribute after the current position
      var attr = getAttribute();
      if (attr == null) return true;

      if (attr[0] == "charset") {
        var tentativeEncoding = attr[1];
        var codec = codecName(tentativeEncoding);
        if (codec != null) {
          encoding = codec;
          return false;
        }
      } else if (attr[0] == "content") {
        var contentParser = new ContentAttrParser(new EncodingBytes(attr[1]));
        var tentativeEncoding = contentParser.parse();
        var codec = codecName(tentativeEncoding);
        if (codec != null) {
          encoding = codec;
          return false;
        }
      }
    }
    return true; // unreachable
  }

  bool handlePossibleStartTag() => handlePossibleTag(false);

  bool handlePossibleEndTag() {
    data.next();
    return handlePossibleTag(true);
  }

  bool handlePossibleTag(bool endTag) {
    if (!isLetter(data.currentByte)) {
      //If the next byte is not an ascii letter either ignore this
      //fragment (possible start tag case) or treat it according to
      //handleOther
      if (endTag) {
        data.previous();
        handleOther();
      }
      return true;
    }

    var c = data.skipUntil(isSpaceOrAngleBracket);
    if (c == "<") {
      // return to the first step in the overall "two step" algorithm
      // reprocessing the < byte
      data.previous();
    } else {
      //Read all attributes
      var attr = getAttribute();
      while (attr != null) {
        attr = getAttribute();
      }
    }
    return true;
  }

  bool handleOther() => data.jumpTo(">");

  /// Return a name,value pair for the next attribute in the stream,
  /// if one is found, or null
  List<String> getAttribute() {
    // Step 1 (skip chars)
    var c = data.skipChars((x) => x == "/" || isWhitespace(x));
    // Step 2
    if (c == ">" || c == null) {
      return null;
    }
    // Step 3
    var attrName = [];
    var attrValue = [];
    // Step 4 attribute name
    while (true) {
      if (c == null) {
        return null;
      } else if (c == "=" && attrName.length > 0) {
        break;
      } else if (isWhitespace(c)) {
        // Step 6!
        c = data.skipChars();
        c = data.next();
        break;
      } else if (c == "/" || c == ">") {
        return [attrName.join(), ""];
      } else if (isLetter(c)) {
        attrName.add(c.toLowerCase());
      } else {
        attrName.add(c);
      }
      // Step 5
      c = data.next();
    }
    // Step 7
    if (c != "=") {
      data.previous();
      return [attrName.join(), ""];
    }
    // Step 8
    data.next();
    // Step 9
    c = data.skipChars();
    // Step 10
    if (c == "'" || c == '"') {
      // 10.1
      var quoteChar = c;
      while (true) {
        // 10.2
        c = data.next();
        if (c == quoteChar) {
          // 10.3
          data.next();
          return [attrName.join(), attrValue.join()];
        } else if (isLetter(c)) {
          // 10.4
          attrValue.add(c.toLowerCase());
        } else {
          // 10.5
          attrValue.add(c);
        }
      }
    } else if (c == ">") {
      return [attrName.join(), ""];
    } else if (c == null) {
      return null;
    } else if (isLetter(c)) {
      attrValue.add(c.toLowerCase());
    } else {
      attrValue.add(c);
    }
    // Step 11
    while (true) {
      c = data.next();
      if (isSpaceOrAngleBracket(c)) {
        return [attrName.join(), attrValue.join()];
      } else if (c == null) {
        return null;
      } else if (isLetter(c)) {
        attrValue.add(c.toLowerCase());
      } else {
        attrValue.add(c);
      }
    }
    return null; // unreachable
  }
}


class ContentAttrParser {
  final EncodingBytes data;

  ContentAttrParser(this.data);

  String parse() {
    try {
      // Check if the attr name is charset
      // otherwise return
      data.jumpTo("charset");
      data.position += 1;
      data.skipChars();
      if (data.currentByte != "=") {
        // If there is no = sign keep looking for attrs
        return null;
      }
      data.position += 1;
      data.skipChars();
      // Look for an encoding between matching quote marks
      if (data.currentByte == '"' || data.currentByte == "'") {
        var quoteMark = data.currentByte;
        data.position += 1;
        var oldPosition = data.position;
        if (data.jumpTo(quoteMark)) {
          return data.slice(oldPosition, data.position);
        } else {
          return null;
        }
      } else {
        // Unquoted value
        var oldPosition = data.position;
        try {
          data.skipUntil(isWhitespace);
          return data.slice(oldPosition, data.position);
        } on StateError catch (e) {
          //Return the whole remaining value
          return data.slice(oldPosition);
        }
      }
    } on StateError catch (e) {
      return null;
    }
  }
}


bool isSpaceOrAngleBracket(String char) {
  return char == ">" || char == "<" || isWhitespace(char);
}

typedef bool CharPreciate(String char);
