#!/usr/bin/env dart

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:analyzer/src/services/formatter_impl.dart';


const BINARY_NAME = 'dartfmt';
final dartFileRegExp = new RegExp(r'^[^.].*\.dart$', caseSensitive: false);
final argParser = _initArgParser();
final defaultSelection = new Selection(-1, -1);

var formatterSettings;

CodeKind kind;
bool machineFormat;
bool overwriteFileContents;
Selection selection;
final List<String> paths = [];


const HELP_FLAG = 'help';
const KIND_FLAG = 'kind';
const MACHINE_FLAG = 'machine';
const WRITE_FLAG = 'write';
const SELECTION_FLAG = 'selection';
const TRANSFORM_FLAG = 'transform';
const MAX_LINE_FLAG = 'max_line_length';
const INDENT_FLAG = 'indent';


const FOLLOW_LINKS = false;


main(args) {
  var options = argParser.parse(args);
  if (options['help']) {
    _printUsage();
    return;
  }

  _readOptions(options);

  if (options.rest.isEmpty) {
    _formatStdin(kind);
  } else {
    paths.addAll(options.rest);
    _formatPaths(paths);
  }
}

_readOptions(options) {
  kind = _parseKind(options[KIND_FLAG]);
  machineFormat = options[MACHINE_FLAG];
  overwriteFileContents = options[WRITE_FLAG];
  selection = _parseSelection(options[SELECTION_FLAG]);
  formatterSettings = new FormatterOptions(
      codeTransforms: options[TRANSFORM_FLAG],
      tabsForIndent: _parseTabsForIndent(options[INDENT_FLAG]),
      spacesPerIndent: _parseSpacesPerIndent(options[INDENT_FLAG]),
      pageWidth: _parseLineLength(options[MAX_LINE_FLAG]));
}

/// Translate the indent option into spaces per indent.
int _parseSpacesPerIndent(String indentOption) {
  if (indentOption == 'tab') {
    return 1;
  }
  int spacesPerIndent = _toInt(indentOption);
  if (spacesPerIndent == null) {
    throw new FormatterException('Indentation is specified as an Integer or '
        'the value "tab".');
  }
  return spacesPerIndent;
}

/// Translate the indent option into tabs for indent.
bool _parseTabsForIndent(String indentOption) => indentOption == 'tab';

CodeKind _parseKind(kindOption) {
  switch(kindOption) {
    case 'stmt' :
      return CodeKind.STATEMENT;
    default:
      return CodeKind.COMPILATION_UNIT;
  }
}

int _parseLineLength(String lengthOption) {
  var length = _toInt(lengthOption);
  if (length == null) {
    var val = lengthOption.toUpperCase();
    if (val == 'INF' || val == 'INFINITY') {
      length = -1;
    } else {
      throw new FormatterException('Line length is specified as an Integer or '
          'the value "Inf".');
    }
  }
  return length;
}


Selection _parseSelection(String selectionOption) {
  if(selectionOption == null) return null;

  var units = selectionOption.split(',');
  if (units.length == 2) {
    var offset = _toInt(units[0]);
    var length = _toInt(units[1]);
    if (offset != null && length != null) {
      return new Selection(offset, length);
    }
  }
  throw new FormatterException('Selections are specified as integer pairs '
                               '(e.g., "(offset, length)".');
}

int _toInt(str) => int.parse(str, onError: (_) => null);

_formatPaths(paths) {
  paths.forEach((path) {
    if (FileSystemEntity.isDirectorySync(path)) {
      _formatDirectory(new Directory(path));
    } else {
      _formatFile(new File(path));
    }
  });
}

_formatResource(resource) {
  if (resource is Directory) {
    _formatDirectory(resource);
  } else if (resource is File) {
    _formatFile(resource);
  }
}

_formatDirectory(dir) => dir.listSync(followLinks: FOLLOW_LINKS)
    .forEach((resource) => _formatResource(resource));

_formatFile(file) {
  if (_isDartFile(file)) {
    if (_isPatchFile(file) && !paths.contains(file.path)) {
      _log('Skipping patch file "${file.path}"');
      return;
    }
    try {
      var rawSource = file.readAsStringSync();
      var formatted = _format(rawSource, CodeKind.COMPILATION_UNIT);
      if (overwriteFileContents) {
        // Only touch files files whose contents will be changed
        if (rawSource != formatted) {
          file.writeAsStringSync(formatted);
        }
      } else {
        print(formatted);
      }
    } catch (e) {
      _log('Unable to format "${file.path}": $e');
    }
  }
}

_isPatchFile(file) => file.path.endsWith('_patch.dart');

_isDartFile(file) => dartFileRegExp.hasMatch(path.basename(file.path));

_formatStdin(kind) {
  var input = new StringBuffer();
  stdin.transform(new Utf8Decoder())
      .listen((data) => input.write(data),
        onError: (error) => _log('Error reading from stdin'),
        onDone: () => print(_format(input.toString(), kind)));
}

/// Initialize the arg parser instance.
ArgParser _initArgParser() {
  // NOTE: these flags are placeholders only!
  var parser = new ArgParser();
  parser.addFlag(WRITE_FLAG, abbr: 'w', negatable: false,
      help: 'Write reformatted sources to files (overwriting contents).  '
            'Do not print reformatted sources to standard output.');
  parser.addFlag(TRANSFORM_FLAG, abbr: 't', negatable: false,
      help: 'Perform code transformations.');
  parser.addOption(MAX_LINE_FLAG, abbr: 'l', defaultsTo: '80',
      help: 'Wrap lines longer than this length. '
            'To never wrap, specify "Infinity" or "Inf" for short.');
  parser.addOption(INDENT_FLAG, abbr: 'i', defaultsTo: '2',
      help: 'Specify number of spaces per indentation. '
            'To indent using tabs, specify "--$INDENT_FLAG tab".'
            '--- [PROVISIONAL API].', hide: true);
  parser.addOption(KIND_FLAG, abbr: 'k', defaultsTo: 'cu',
      help: 'Specify source snippet kind ("stmt" or "cu") '
            '--- [PROVISIONAL API].', hide: true);
  parser.addOption(SELECTION_FLAG, abbr: 's',
      help: 'Specify selection information as an offset,length pair '
            '(e.g., -s "0,4").', hide: true);
  parser.addFlag(MACHINE_FLAG, abbr: 'm', negatable: false,
      help: 'Produce output in a format suitable for parsing.');
  parser.addFlag(HELP_FLAG, abbr: 'h', negatable: false,
      help: 'Print this usage information.');
  return parser;
}


/// Displays usage information.
_printUsage() {
  var buffer = new StringBuffer();
  buffer..write('$BINARY_NAME formats Dart programs.')
        ..write('\n\n')
        ..write('Without an explicit path, $BINARY_NAME processes the standard '
                'input.  Given a file, it operates on that file; given a '
                'directory, it operates on all .dart files in that directory, '
                'recursively. (Files starting with a period are ignored.) By '
                'default, $BINARY_NAME prints the reformatted sources to '
                'standard output.')
        ..write('\n\n')
        ..write('Usage: $BINARY_NAME [flags] [path...]\n\n')
        ..write('Supported flags are:\n')
        ..write('${argParser.usage}\n\n');
  _log(buffer.toString());
}

/// Format this [src], treating it as the given snippet [kind].
String _format(src, kind) {
  var formatResult = new CodeFormatter(formatterSettings).format(
      kind, src, selection: selection);
  if (machineFormat) {
    if (formatResult.selection == null) {
      formatResult.selection = defaultSelection;
    }
    return _toJson(formatResult);
  }
  return formatResult.source;
}

_toJson(formatResult) =>
    // Actual JSON format TBD
    JSON.encode({'source': formatResult.source,
                 'selection': {
                     'offset': formatResult.selection.offset,
                     'length': formatResult.selection.length
                  }
    });

/// Log the given [msg].
_log(String msg) {
  //TODO(pquitslund): add proper log support
  print(msg);
}