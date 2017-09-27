// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:math';

typedef String CellTextCallback(dynamic item);

enum ALIGNMENT { left, center, right }
enum TEXTBEHAVIOUR { truncateLeft, truncateRight, wrap }

/// [OutputTable] defines a base class for outputting tabular data to outputs.
abstract class OutputTable {
  void addHeader(Column column, CellTextCallback callback);
  void print(List items);
  void printToSink(List items, StringSink sink);
}

/// [ScripTable] outputs items without any formatting except tabs for
/// separators.
class ScriptTable extends OutputTable {
  final Map<Column, CellTextCallback> _columns = {};
  @override
  void addHeader(Column column, CellTextCallback callback) {
    _columns[column] = callback;
  }

  @override
  void print(List items) {
    printToSink(items, io.stdout);
  }

  @override
  void printToSink(List items, StringSink sink) {
    if (_columns.length == 0) {
      return;
    }
    // Print headers.
    var columns = _columns.keys.toList();
    columns.forEach((column) {
      if (column != columns[0]) {
        sink.write("\t");
      }
      sink.write(column.header);
    });
    sink.writeln("");

    // Print items.
    items.forEach((item) {
      columns.forEach((column) {
        if (column != columns[0]) {
          sink.write("\t");
        }
        sink.write(_columns[column](item));
      });
      sink.writeln("");
    });
  }
}

/// [ConsoleTable] outputs a list of items as a table, width a default width of
/// 80 units. Column sizes can be set individually. If zero-width for a column
/// is specified, the free available space is distributed equally amongst these.
/// The table can be styled by giving it a custom template.
class ConsoleTable extends OutputTable {
  final int width;
  final Template template;

  final Map<Column, CellTextCallback> _columns = {};

  ConsoleTable({this.width = 80, this.template = minimal});

  /// [addHeader] adds a new column to the table. When a row is processed the
  /// callback given will be invoked with the item for the row.
  @override
  void addHeader(Column column, CellTextCallback callback) {
    _columns[column] = callback;
  }

  /// Prints the [items] as a table in columns given by [addHeader] to stdout.
  @override
  void print(List items) {
    printToSink(items, io.stdout);
  }

  /// Prints the [items] as a table in columns given by [addHeader] to [sink].
  @override
  void printToSink(List items, StringSink sink) {
    if (_columns.length == 0) {
      return;
    }

    // Precompute allocated width.
    var allocatedWidth = 0;
    var zeroWidthColumns = 0;

    _columns.keys.forEach((column) {
      if (column.width == 0) {
        zeroWidthColumns++;
      } else {
        allocatedWidth += column.width;
      }
    });

    // Free width is the default width, subtracted by the already allocated
    // width and the column separators.
    var freeWidth = width -
        allocatedWidth -
        (_columns.length - 1) * template.columnDivider.length -
        2 * template.leftRightFrame.length;
    if (zeroWidthColumns > 0 && freeWidth > 0) {
      // Distribute free width among columns with 0 width;
      var cellWidth = (freeWidth / zeroWidthColumns).round();
      _columns.keys.forEach((column) {
        if (column.width != 0) {
          return;
        }
        if (zeroWidthColumns == 1) {
          column._computedWidth = freeWidth;
        } else {
          column._computedWidth = cellWidth;
          freeWidth -= cellWidth;
          zeroWidthColumns--;
        }
      });
    }
    // At this point, all column widths are either calculated or should not be
    // rendered.
    _printTopBottomDivider(sink);
    _printHeader(sink);
    _printHeaderDivider(sink);
    bool isFirst = true;
    items.forEach((item) {
      if (!isFirst) {
        _printRowDivider(sink);
      }
      var cellStrings = _columns.keys
          .where((column) => column._computedWidth > 0)
          .map((column) {
        var strings = _breakText(_columns[column](item) ?? "",
            column._computedWidth, column.headerBehaviour);
        return strings
            .map((str) =>
                _alignPadText(str, column._computedWidth, column.alignment))
            .toList();
      }).toList();
      _printRowAlignTop(cellStrings, sink);
      isFirst = false;
    });
    _printTopBottomDivider(sink);
  }

  void _printTopBottomDivider(StringSink sink) {
    if (template.topBottomFrame.length > 0) {
      sink.writeln("${template.cornerJoin}"
          "${template.topBottomFrame * (width - 2 * template.cornerJoin.length)}"
          "${template.cornerJoin}");
    }
  }

  void _printHeaderDivider(StringSink sink) {
    if (template.headerDivider.length > 0) {
      sink.writeln("${template.rowJoin}"
          "${template.headerDivider * (width - 2 * template.rowJoin.length)}"
          "${template.rowJoin}");
    }
  }

  void _printRowDivider(StringSink sink) {
    if (template.rowDivider.length > 0) {
      sink.write(template.rowJoin);
      bool isFirst = true;
      _columns.keys.forEach((column) {
        if (column._computedWidth > 0) {
          if (!isFirst) {
            sink.write(template.cellJoin);
          }
          sink.write(template.rowDivider * column._computedWidth);
          isFirst = false;
        }
      });
      sink.writeln(template.rowJoin);
    }
  }

  void _printHeader(StringSink sink) {
    var cellStrings = _columns.keys
        .where((column) => column._computedWidth > 0)
        .map((column) {
      var strings = _breakText(
          column.header ?? "", column._computedWidth, column.headerBehaviour);
      var cellStrings = strings
          .map((str) =>
              _alignPadText(str, column._computedWidth, column.alignment))
          .toList();
      return cellStrings;
    }).toList();
    _printRowAlignBase(cellStrings, sink);
  }

  void _printRowAlignBase(List<List<String>> strings, StringSink sink) {
    var height = strings.fold(
        0, (prevValue, strings) => max<int>(prevValue, strings.length));
    for (var i = 0; i < height; i++) {
      for (var j = 0; j < _columns.length; j++) {
        sink.write(j == 0 ? template.leftRightFrame : template.columnDivider);
        if (height - i - 1 >= strings[j].length) {
          sink.write(' ' * strings[j][0].length);
        } else {
          var index = i - (height - strings[j].length);
          sink.write(strings[j][index]);
        }
      }
      sink.writeln(template.leftRightFrame);
    }
  }

  void _printRowAlignTop(List<List<String>> strings, StringSink sink) {
    var height = strings.fold(
        0, (prevValue, strings) => max<int>(prevValue, strings.length));
    for (var i = 0; i < height; i++) {
      for (var j = 0; j < _columns.length; j++) {
        sink.write(j == 0 ? template.leftRightFrame : template.columnDivider);
        if (i >= strings[j].length) {
          sink.write(' ' * strings[j][0].length);
        } else {
          sink.write(strings[j][i]);
        }
      }
      sink.writeln(template.leftRightFrame);
    }
  }

  List<String> _breakText(String text, int width, TEXTBEHAVIOUR textBehaviour) {
    if (text.length <= width) {
      return [text];
    }

    if (textBehaviour == TEXTBEHAVIOUR.truncateLeft ||
        textBehaviour == TEXTBEHAVIOUR.truncateRight) {
      String truncateString = width <= 4 ? ".." : "...";
      int substringLength = (width - truncateString.length);
      String truncatedString = textBehaviour == TEXTBEHAVIOUR.truncateLeft
          ? "${truncateString}${text.substring(text.length - substringLength)}"
          : "${text.substring(0, substringLength)}${truncateString}";
      if (truncatedString.length > width) {
        return [text.substring(0, 1)];
      }
      return [truncatedString];
    }

    // We have to wrap - see if we can find any good places to break.
    List<String> wrappedStrings = [];
    int finger = 0;
    var regexpBlank = new RegExp(r"[ ]");
    var regexpIncludeChars = new RegExp(r"[\-]");
    var regexpAddHyphon = new RegExp(r"[_]");
    while (finger + width < text.length) {
      var nicerIndex = text.lastIndexOf(regexpBlank, finger + width);
      if (nicerIndex > finger) {
        wrappedStrings.add(text.substring(finger, nicerIndex));
        finger = nicerIndex + 1; // change space for return;
        continue;
      }
      nicerIndex = text.lastIndexOf(regexpIncludeChars, finger + width - 1);
      if (nicerIndex > finger) {
        wrappedStrings.add(text.substring(finger, nicerIndex + 1));
        finger = nicerIndex + 1;
        continue;
      }
      nicerIndex = text.lastIndexOf(regexpAddHyphon, finger + width - 2);
      if (nicerIndex > finger) {
        wrappedStrings.add(text.substring(finger, nicerIndex + 1) + '-');
        finger = nicerIndex + 1;
        continue;
      }
      wrappedStrings.add(text.substring(finger, finger + width));
      finger = finger + width;
    }
    var lastSubString = text.substring(finger);
    if (!lastSubString.isEmpty) {
      wrappedStrings.add(lastSubString);
    }
    return wrappedStrings;
  }

  String _alignPadText(String text, int width, ALIGNMENT alignment) {
    switch (alignment) {
      case ALIGNMENT.left:
        return text.padRight(width);
      case ALIGNMENT.right:
        return text.padLeft(width);
      case ALIGNMENT.center:
        int half = ((width / 2) + (text.length) / 2).round();
        String str = text.padLeft(half);
        str = str.padRight(width);
        return str;
    }
    return ""; // Stupid type-checker.
  }
}

/// [Column] defines a column in a table and should be given a descriptive
/// header.
class Column {
  final String header;
  final int width;
  final ALIGNMENT alignment;
  final TEXTBEHAVIOUR headerBehaviour;
  final TEXTBEHAVIOUR cellBehaviour;
  int _computedWidth;

  Column(this.header,
      {this.width = 0,
      this.alignment = ALIGNMENT.left,
      this.headerBehaviour = TEXTBEHAVIOUR.wrap,
      this.cellBehaviour = TEXTBEHAVIOUR.wrap})
      : _computedWidth = width;
}

/// A minimal template with a single hyphon as row-divider.
const Template minimal = const Template();

/// [Template] holds styling information for a table. Each parameter assumes
/// either the empty string or a single character. Let:
///
///   headerDivider - 'h'
///   columnDivider - 'i'
///   rowDivider - 'r'
///   topBottomFrame - '='
///   leftRightFrame - 'I'
///   rowJoin - 'R'
///   cornerJoin 'C'
///   cellJoin - 'X'
///
/// The below shows an example with the characters used
///
/// C===================================================C
/// I column 1 i column 2 i          column 3           I
/// RhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhR
/// I  row 1   i  row 1   i            row 1            I
/// RrrrrrrrrrrXrrrrrrrrrrXrrrrrrrrrrrrrrrrrrrrrrrrrrrrrR
/// I  row 2   i  row 2   i            row 2            I
/// RrrrrrrrrrrXrrrrrrrrrrXrrrrrrrrrrrrrrrrrrrrrrrrrrrrrR
///
class Template {
  final String headerDivider;
  final String columnDivider;
  final String rowDivider;
  final String topBottomFrame;
  final String leftRightFrame;
  final String rowJoin;
  final String cornerJoin;
  final String cellJoin;

  const Template(
      {this.headerDivider = "-",
      this.columnDivider = " ",
      this.rowDivider = "",
      this.topBottomFrame = "",
      this.leftRightFrame = "",
      this.cornerJoin = "",
      this.rowJoin = "",
      this.cellJoin = " "});
}
