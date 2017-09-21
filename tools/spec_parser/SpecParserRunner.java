// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import java.util.Scanner;
import java.util.List;
import java.util.ArrayList;

/// Class for `main` which will parse files given as lines on stdio.
public class SpecParserRunner {
  public static void main(String[] args) throws Exception {
    if (args.length != 0) {
      System.err.println("No command line arguments expected.");
      System.err.println("Files to parse are accepted on the standard input.");
      System.exit(1);
    }

    Scanner scanner = new Scanner(System.in);
    String[] filenames = new String[1];
    while (scanner.hasNextLine()) {
      String filename = scanner.nextLine().trim();
      filenames[0] = filename;
      System.out.println("---------- " + filename + " ----------");
      SpecParser.main(filenames);
    }
  }
}
