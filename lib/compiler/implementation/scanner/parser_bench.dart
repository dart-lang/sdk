// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A benchmark for the Dart parser.
 */
class ParserBench extends BaseParserBench {
  int charCount = 0;
  double score = 0.0;

  Token scanFileNamed(String filename) {
    Token token;
    getBytes(filename, (bytes) {
      Scanner scanner = makeScanner(bytes);
      try {
        token = scanner.tokenize();
        printTokens(token);
        charCount += scanner.charOffset;
      } catch (MalformedInputException e) {
        print("${filename}: ${e}");
      }
    });
    return token;
  }

  void timedParseAll(List<String> arguments) {
    charCount = 0;
    Stopwatch timer = new Stopwatch();
    timer.start();
    BenchListener listener = parseAll(arguments);
    timer.stop();
    print("Parsing (${listener.libraryTagCount} tags, "
          "${listener.classCount} classes, "
          "${listener.interfaceCount} interfaces, "
          "${listener.aliasCount} typedefs, "
          "${listener.topLevelMemberCount} top-level members) "
          "took ${timer.elapsedInMs()}ms");
  }

  BenchListener parseAll(List<String> arguments) {
    charCount = 0;
    Stopwatch timer = new Stopwatch();
    timer.start();
    BenchListener listener = new BenchListener();
    for (String argument in arguments) {
      parseFileNamed(argument, listener);
    }
    timer.stop();
    score = charCount / timer.elapsedInMs();
    return listener;
  }

  void parseFileNamed(String argument, Listener listener) {
    bool failed = true;
    try {
      PartialParser parser = new PartialParser(listener);
      parser.parseUnit(scanFileNamed(argument));
      failed = false;
    } finally {
      if (failed) print('Error in ${argument}');
    }
  }

  void main(List<String> arguments) {
    for (int i = 0; i < 10; i++) {
      timedParseAll(arguments);
    }
    final int iterations = 500;
    VerboseProgressBar bar = new VerboseProgressBar(iterations);
    bar.begin();
    for (int i = 0; i < iterations; i++) {
      bar.tick();
      parseAll(arguments);
      bar.recordScore(score);
    }
    bar.end();
    for (int i = 0; i < 10; i++) {
      timedParseAll(arguments);
    }
  }
}

main() {
  new ParserBench().main(argv);
}

class BenchListener extends Listener {
  int aliasCount = 0;
  int classCount = 0;
  int interfaceCount = 0;
  int libraryTagCount = 0;
  int topLevelMemberCount = 0;

  void beginTopLevelMember(Token token) {
    topLevelMemberCount++;
  }

  void beginLibraryTag(Token token) {
    libraryTagCount++;
  }

  void beginInterface(Token token) {
    interfaceCount++;
  }

  void beginClass(Token token) {
    classCount++;
  }

  void beginFunctionTypeAlias(Token token) {
    aliasCount++;
  }
}
