// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('scanner_bench');
#import('scannerlib.dart');
#import('scanner_implementation.dart');
#source('source_list.dart');

/**
 * A common superclass for scanner benchmarks.
 */
class ScannerBench {
  void main(List<String> arguments) {
    for (String argument in arguments) {
      checkExistence(argument);
    }
    tokenizeAll(print, 10, arguments);
    tokenizeAll((x) {}, 1000, arguments);
    tokenizeAll(print, 10, arguments);
  }

  void tokenizeAll(void log(String s), int iterations, List<String> arguments) {
    VerboseProgressBar bar = new VerboseProgressBar(iterations);
    bar.begin();
    for (int i = 0; i < iterations; i++) {
      bar.tick();
      Stopwatch timer = new Stopwatch();
      timer.start();
      int charCount = 0;
      for (final String argument in arguments) {
        charCount += tokenizeOne(argument);
      }
      timer.stop();
      bar.recordScore(charCount / timer.elapsedInMs());
      log("Tokenized ${arguments.length} files " +
          "(total size = ${charCount} chars) " +
          "in ${timer.elapsedInMs()}ms");
    }
    bar.end();
  }

  int tokenizeOne(String filename) {
    return getBytes(filename, (bytes) {
      Scanner scanner = makeScanner(bytes);
      try {
        printTokens(scanner.tokenize());
      } catch (MalformedInputException e) {
        print("${filename}: ${e}");
      }
    });
  }

  void printTokens(Token token) {
    // TODO(ahe): Turn this into a proper test.
    return;
    StringBuffer sb = new StringBuffer();
    for (; token != null; token = token.next) {
      if (token.kind < 127) {
        sb.add(new String.fromCharCodes([token.kind]));
      } else {
        sb.add(token.kind);
      }
      sb.add(":");
      sb.add(token);
      sb.add(" ");
    }
    print(sb.toString());
  }

  abstract int getBytes(String filename, void callback(bytes));
  abstract Scanner makeScanner(bytes);
  abstract void checkExistence(String filename);
}

class ProgressBar {
  static final String hashes = "##############################################";
  static final String spaces = "                                              ";
  static final int GEOMEAN_COUNT = 50;

  final String esc;
  final String up;
  final String clear;
  final int total;
  final List<num> scores;
  int ticks = 0;

  ProgressBar(int total) : this.escape(total, new String.fromCharCodes([27]));

  ProgressBar.escape(this.total, String esc)
    : esc = esc, up = "$esc[1A", clear = "$esc[K", scores = new List<num>();

  void begin() {
    if (total > 10) {
      print("[$spaces] 0%");
      print("$up[${hashes.substring(0, ticks * spaces.length ~/ total)}");
    }
  }

  void tick() {
    if (total > 10 && ticks % 5 === 0) {
      print("$up$clear[$spaces] ${ticks * 100 ~/ total}% ${score()}");
      print("$up[${hashes.substring(0, ticks * spaces.length ~/ total)}");
    }
    ++ticks;
  }

  void end() {
    if (total > 10) {
      print("$up$clear[$hashes] 100% ${score()}");
    }
  }

  void recordScore(num newScore) {
    scores.addLast(newScore);
  }

  int score() {
    num geoMean = 1;
    int count = Math.min(scores.length, GEOMEAN_COUNT);
    for (int i = scores.length - count; i < scores.length; i++) {
      geoMean *= scores[i];
    }
    geoMean = Math.pow(geoMean, 1/Math.max(count, 1));
    return geoMean.round().toInt();
  }
}

class VerboseProgressBar {
  final int total;
  int ticks = 0;

  VerboseProgressBar(int this.total);

  void begin() {
  }

  void tick() {
    ++ticks;
  }

  void end() {
  }

  void recordScore(num score) {
    if (total > 10) {
      print("$ticks, $score, ${ticks * 100 ~/ total}%");
    }
  }
}
