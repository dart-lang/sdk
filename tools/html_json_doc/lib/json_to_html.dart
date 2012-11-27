// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Library for taking a JSON file and putting the comments located within into
 * the HTML files the comments are associated with.
 *
 * The format of the JSON file is:
 * 
 *     {
 *       "$filename":
 *         {
 *           "$lineInHtml":
 *             [
 *               "lines of comment",
 *               "here"
 *             ]
 *          },
 *       ...
 *     }
 */
library json_to_html;

import 'dart:json';
import 'dart:io';


/// True if any errors were triggered through the conversion.
bool _anyErrors = false;


/**
 * Take comments from [jsonPath] and apply them to all the files found in
 * [htmlPath]. This will overwrite the files in htmlPath.
 */
Future<bool> convert(Path htmlPath, Path jsonPath) {
  final completer = new Completer();

  final jsonFile = new File.fromPath(jsonPath);
  final htmlDir = new Directory.fromPath(htmlPath);

  if (!jsonFile.existsSync()) {
    print("ERROR: No JSON file found at: ${jsonPath}");
    _anyErrors = true;
    completer.complete(false);
  } else if (!htmlDir.existsSync()) {
    print("ERROR: No HTML directory found at: ${htmlPath}");
    _anyErrors = true;
    completer.complete(false);
  }


  var fileJson = {};
  var jsonRead = jsonFile.readAsStringSync();

  if (jsonRead == '') {
    print('WARNING: no data read from ${jsonPath.filename}');
    _anyErrors = true;
    completer.complete(false);
  } else {
    fileJson = JSON.parse(jsonRead);
  }

  // TODO(amouravski): Refactor to not duplicate code here and in html-to-json.
  // Find html files. (lister)
  final lister = htmlDir.list(recursive: false);

  lister.onFile = (String path) {
    final name = new Path.fromNative(path).filename;

    // Ignore private classes.
    if (name.startsWith('_')) return;

    // Ignore non-dart files.
    if (!name.endsWith('.dart')) return;

    File file = new File(path);

    // TODO(amouravski): Handle missing file.
    if (!file.existsSync()) {
      print('ERROR: cannot find file: $path');
      _anyErrors = true;
      return;
    }

    if (!fileJson.containsKey(name)) {
      print('WARNING: file found that is not in JSON: $path');
      _anyErrors = true;
      return;
    }

    var comments = fileJson[name];

    _convertFile(file, comments);

    fileJson.remove(name);
  };

  lister.onDone = (_) {

    fileJson.forEach((key, _) {
      print('WARNING: the following filename was found in the JSON but not in '
          '${htmlDir.path}:\n"$key"');
      _anyErrors = true;
    });

    completer.complete(_anyErrors);
  };

  return completer.future;
}


/**
 * Inserts the comments from JSON into a single file.
 */
void _convertFile(File file, Map<String, List<String>> comments) {
  var fileLines = file.readAsLinesSync();

  var unusedComments = {};

  comments.forEach((key, comments) {
    var index = fileLines.indexOf(key);
    // If the key is found in any line past the first one.
    if (index > 0 && fileLines[index - 1].trim().startsWith('///') &&
      fileLines[index - 1].contains('@docsEditable')) {

      // Add comments.
      fileLines.insertRange(index - 1, comments.length);
      fileLines.setRange(index - 1, comments.length, comments);
    } else {
      unusedComments.putIfAbsent(key, () => comments);
    }
  });

  unusedComments.forEach((String key, _) {
    print('WARNING: the following key was found in the JSON but not in '
        '${new Path(file.fullPathSync()).filename}:\n"$key"');
    _anyErrors = true;
  });
  
  // TODO(amouravski): file.writeAsStringSync('${Strings.join(fileLines, '\n')}\n');
  var outputStream = file.openOutputStream();
  outputStream.writeString(Strings.join(fileLines, '\n'));
  outputStream.writeString('\n');

  outputStream.onNoPendingWrites = () {
    outputStream.close();
  };
}
