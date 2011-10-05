// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.vm;

import com.google.common.collect.Lists;
import com.google.dart.runner.TestRunner;

import junit.framework.TestCase;
import org.mozilla.javascript.RhinoException;

import java.util.Arrays;
import java.util.List;

/**
 * @author floitsch@google.com (Florian Loitsch)
 *
 * Baseclass to be used for VM-tests. It provides run{Negative|Positive}Test.
 */
abstract class VmTest extends TestCase {
  private String createArgumentsString(String[] commandArray) {
    StringBuffer buffer = new StringBuffer();
    buffer.append("Command: blaze run //third_party/java_src/dart/compiler:dartc_test --");
    int dartDartCount = 0;
    for (String command : commandArray) {
      if (command.equals("--")) {
        dartDartCount++;
        buffer.append(' ');
      } else {
        // dartDartCount == 0: vm options
        // dartDartCount == 1: source files
        // dartDartCount == 2: entry point
        if (dartDartCount == 1) {
          buffer.append(" $(pwd)/");
        } else {
          buffer.append(' ');
        }
      }
      buffer.append(command);
    }
    return buffer.toString();
  }

  String[] addOptimizeOption(String[] commandArray) {
    List<String> commands = Lists.newArrayList(Arrays.asList(commandArray));
    commands.add(0, "--optimize");
    return commands.toArray(new String[0]);
  }

  protected void runNegativeTest(String testName, String... commandArray) {
    try {
      TestRunner.throwingMain(commandArray, System.out, System.err);
      System.out.println(createArgumentsString(commandArray));
      fail();
    } catch (Exception e) {
      // Great. It was supposed to fail.
      return;
    }
  }

  protected void runPositiveTest(String testName, String... commandArray) throws Throwable {
    try {
      TestRunner.throwingMain(commandArray, System.out, System.err);
    } catch (RhinoException e) {
      System.out.println(createArgumentsString(commandArray));
      StringBuffer msg = new StringBuffer();
      msg.append(e.sourceName());
      msg.append(" (" + e.lineNumber() + ":" + e.columnNumber() + ")");
      msg.append(" : " + e.details());
      fail(msg.toString());
    } catch (Throwable e) {
      System.out.println(createArgumentsString(commandArray));
      throw e;
    }
  }
}
