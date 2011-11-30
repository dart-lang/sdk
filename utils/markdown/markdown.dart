// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Standalone script for parsing markdown from files and converting to HTML.
#library('markdown_app');

#import('lib.dart');

main() {
  final args = (new Options()).arguments;

  if (args.length > 2) {
    print('Usage:');
    print('  dart markdown.dart <inputfile> [<outputfile>]');
    print('');
    print('Reads a file containing markdown and converts it to HTML.');
    print('If <outputfile> is omitted, prints to stdout.');
    return;
  }

  final source = readFile(args[0]);
  final html = markdownToHtml(source);

  if (args.length == 1) {
    print(html);
  } else {
    writeFile(args[1], html);
  }
}

String readFile(String path) {
  final file = new File(path);
  file.openSync();
  final length = file.lengthSync();
  final buffer = new List<int>(length);
  final bytes = file.readListSync(buffer, 0, length);
  file.closeSync();
  return new String.fromCharCodes(buffer);
}

void writeFile(String path, String text) {
  final file = new File(path);
  final stream = file.openOutputStream();
  stream.write(text.charCodes());
  stream.close();
}
