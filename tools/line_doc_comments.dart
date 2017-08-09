#!/usr/bin/env dart

/// Converts block-style Doc comments in Dart code to line style.
library line_doc_comments;

import 'dart:io';

import 'package:path/path.dart' as path;

final oneLineBlock = new RegExp(r'^(\s*)/\*\*\s?(.*)\*/\s*$');
final startBlock = new RegExp(r'^(\s*)/\*\*(.*)$');
final blockLine = new RegExp(r'^\s*\*\s?(.*)$');
final endBlock = new RegExp(r'^\s*\*/\s*$');

main(List<String> args) {
  if (args.length != 1) {
    print('Converts "/**"-style block doc comments in a directory ');
    print('containing Dart code to "///"-style line doc comments.');
    print('');
    print('Usage: line_doc_coments.dart <dir>');
    return;
  }

  var dir = new Directory(args[0]);
  dir.list(recursive: true, followLinks: false).listen((entity) {
    if (entity is File) {
      var file = entity.path;
      if (path.extension(file) != '.dart') return;
      fixFile(file);
    }
  });
}

void fixFile(String path) {
  var file = new File(path);
  file.readAsLines().then((lines) => fixContents(lines, path)).then((fixed) {
    return new File(path).writeAsString(fixed);
  }).then((file) {
    print(file.path);
  });
}

String fixContents(List<String> lines, String path) {
  var buffer = new StringBuffer();
  var linesOut = 0;
  var inBlock = false;
  var indent;

  for (var line in lines) {
    var oldLine = line;
    if (inBlock) {
      // See if it's the end of the comment.
      if (endBlock.hasMatch(line)) {
        inBlock = false;

        // Just a pointless line, delete it!
        line = null;
      } else {
        var match = blockLine.firstMatch(line);
        if (match != null) {
          var comment = match[1];
          if (comment != '') {
            line = '$indent/// $comment';
          } else {
            line = '$indent///';
          }
        }
      }
    } else {
      // See if it's a one-line block comment like: /** Blah. */
      var match = oneLineBlock.firstMatch(line);
      if (match != null) {
        var comment = match[2];
        if (comment != '') {
          // Remove the extra space before the `*/`
          if (comment.endsWith(' ')) {
            comment = comment.substring(0, comment.length - 1);
          }
          line = '${match[1]}/// $comment';
        } else {
          line = '${match[1]}///';
        }
      } else {
        // See if it's the start of a block doc comment.
        match = startBlock.firstMatch(line);
        if (match != null) {
          inBlock = true;
          indent = match[1];
          if (match[2] != '') {
            // Got comment on /** line.
            line = match[2];
          } else {
            // Just a pointless line, delete it!
            line = null;
          }
        }
      }
    }

    if (line != null) {
      linesOut++;

      // Warn about lines that crossed 80 columns as a result of the change.
      if (line.length > 80 && oldLine.length <= 80) {
        const _PURPLE = '\u001b[35m';
        const _RED = '\u001b[31m';
        const _NO_COLOR = '\u001b[0m';

        print('$_PURPLE$path$_NO_COLOR:$_RED$linesOut$_NO_COLOR: '
            'line exceeds 80 cols:\n    $line');
      }

      buffer.write('$line\n');
    }
  }

  return buffer.toString();
}
