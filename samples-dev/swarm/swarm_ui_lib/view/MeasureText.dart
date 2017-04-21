// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of view;

// TODO(jacobr): handle splitting lines on symbols such as '-' that aren't
// whitespace but are valid word breaking points.
/**
 * Utility class to efficiently word break and measure text without requiring
 * access to the DOM.
 */
class MeasureText {
  static CanvasRenderingContext2D _context;

  final String font;
  num _spaceLength;
  num _typicalCharLength;

  static const String ELLIPSIS = '...';

  MeasureText(this.font) {
    if (_context == null) {
      CanvasElement canvas = new Element.tag('canvas');
      _context = canvas.getContext('2d');
    }
    if (_spaceLength == null) {
      _context.font = font;
      _spaceLength = _context.measureText(' ').width;
      _typicalCharLength = _context.measureText('k').width;
    }
  }

  // TODO(jacobr): we are DOA for i18N...
  // the right solution is for the server to send us text perparsed into words
  // perhaps even with hints on the guess for the correct breaks so on the
  // client all we have to do is verify and fix errors rather than perform the
  // full calculation.
  static bool isWhitespace(String character) {
    return character == ' ' || character == '\t' || character == '\n';
  }

  num get typicalCharLength {
    return _typicalCharLength;
  }

  String quickTruncate(String text, num lineWidth, int maxLines) {
    int targetLength = lineWidth * maxLines ~/ _typicalCharLength;
    // Advance to next word break point.
    while (targetLength < text.length && !isWhitespace(text[targetLength])) {
      targetLength++;
    }

    if (targetLength < text.length) {
      return '${text.substring(0, targetLength)}$ELLIPSIS';
    } else {
      return text;
    }
  }

  /**
   * Add line broken text as html separated by <br> elements.
   * Returns the number of lines in the output.
   * This function is safe to call with [:sb == null:] in which case just the
   * line count is returned.
   */
  int addLineBrokenText(
      StringBuffer sb, String text, num lineWidth, int maxLines) {
    // Strip surrounding whitespace. This ensures we create zero lines if there
    // is no visible text.
    text = text.trim();

    // We can often avoid performing a full line break calculation when only
    // the number of lines and not the actual linebreaks is required.
    if (sb == null) {
      _context.font = font;
      int textWidth = _context.measureText(text).width.toInt();
      // By the pigeon hole principle, the resulting text will require at least
      // maxLines if the raw text is longer than the amount of text that will
      // fit on maxLines - 1.  We add the length of a whitespace
      // character to the lineWidth as each line is separated by a whitespace
      // character. We assume all whitespace characters have the same length.
      if (textWidth >= (lineWidth + _spaceLength) * (maxLines - 1)) {
        return maxLines;
      } else if (textWidth == 0) {
        return 0;
      } else if (textWidth < lineWidth) {
        return 1;
      }
      // Fall through to the regular line breaking calculation as the number
      // of lines required is unclear.
    }
    int lines = 0;
    lineBreak(text, lineWidth, maxLines, (int start, int end, num width) {
      lines++;
      if (lines == maxLines) {
        // Overflow case... there may be more lines of text than we can handle.
        // Add a few characters to the last line so that the browser will
        // render ellipses correctly.
        // TODO(jacobr): make this optional and only add characters until
        // the first whitespace character encountered.
        end = Math.min(end + 50, text.length);
      }
      if (sb != null) {
        if (lines > 1) {
          sb.write('<br>');
        }
        // TODO(jacobr): HTML escape this text.
        sb.write(text.substring(start, end));
      }
    });
    return lines;
  }

  void lineBreak(String text, num lineWidth, int maxLines, Function callback) {
    _context.font = font;
    int lines = 0;
    num currentLength = 0;
    int startIndex = 0;
    int wordStartIndex = null;
    int lastWordEndIndex = null;
    bool lastWhitespace = true;
    // TODO(jacobr): optimize this further.
    // To simplify the logic, we simulate injecting a whitespace character
    // at the end of the string.
    for (int i = 0, len = text.length; i <= len; i++) {
      // Treat the char after the end of the string as whitespace.
      bool whitespace = i == len || isWhitespace(text[i]);
      if (whitespace && !lastWhitespace) {
        num wordLength =
            _context.measureText(text.substring(wordStartIndex, i)).width;
        // TODO(jimhug): Replace the line above with this one to workaround
        //               dartium bug - error: unimplemented code
        // num wordLength = (i - wordStartIndex) * 17;
        currentLength += wordLength;
        if (currentLength > lineWidth) {
          // Edge case:
          // It could be the very first word we ran into was too long for a
          // line in which case  we let it have its own line.
          if (lastWordEndIndex != null) {
            lines++;
            callback(startIndex, lastWordEndIndex, currentLength - wordLength);
          }
          if (lines == maxLines) {
            return;
          }
          startIndex = wordStartIndex;
          currentLength = wordLength;
        }
        lastWordEndIndex = i;
        currentLength += _spaceLength;
        wordStartIndex = null;
      } else if (wordStartIndex == null && !whitespace) {
        wordStartIndex = i;
      }
      lastWhitespace = whitespace;
    }
    if (currentLength > 0) {
      callback(startIndex, text.length, currentLength);
    }
  }
}
