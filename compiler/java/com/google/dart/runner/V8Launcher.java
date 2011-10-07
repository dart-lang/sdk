// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.runner;

import com.google.common.collect.Lists;
import com.google.debugging.sourcemap.SourceMapping;
import com.google.debugging.sourcemap.proto.Mapping.OriginalMapping;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * @author floitsch@google.com (Florian Loitsch)
 *
 * Runs a given JS-script in d8 (part of V8).
 */
public class V8Launcher implements JavaScriptLauncher {
  private static class Drainer implements Runnable {
    private final InputStream stream;
    private final List<String> lines;
    private final PrintStream out;

    public Drainer(InputStream stream, PrintStream out, List<String> lines) {
      this.stream = stream;
      this.lines = lines;
      this.out = out;
    }

    @Override
    public void run() {
      BufferedReader r = new BufferedReader(new InputStreamReader(stream));
      String str;
      try {
        while ((str = r.readLine()) != null) {
          if (lines != null) {
            lines.add(str);
          }
          out.println(str);
        }
      } catch (IOException e) {
        throw new AssertionError(e);
      }
    }
  }

  private static final String D8_ENVIRONMENT_VARIABLE = "D8_EXEC";

  private final SourceMapping appSourceMap;

  private static final String EOL = System.getProperty("line.separator");

  /**
   *
   */
  public V8Launcher(SourceMapping appSourceMap) {
    this.appSourceMap = appSourceMap;
  }

  @Override
  public void execute(String jsScript, String sourceName, String[] args, RunnerOptions options,
                      PrintStream stdout, PrintStream stderr)
      throws RunnerError {
    if (!isConfigured()) {
      throw new RunnerError("Please set the " + D8_ENVIRONMENT_VARIABLE + " environment variable.");
    }
    File sourceFile;
    try {
      sourceFile = writeTempFile(sourceName, jsScript);
    } catch (IOException e) {
      throw new RunnerError(e);
    }
    try {
      ArrayList<String> command = new ArrayList<String>();
      command.add(v8Executable().getAbsolutePath());
      command.add(sourceFile.getAbsolutePath());
      if (options.shouldProfile()) {
        command.add("--prof");
      }
      command.add("--");
      command.addAll(Arrays.asList(args));
      int exitValue;
      Process p = null;
      List<String> stdOutLines = Lists.newArrayList();
      Thread stdOutDrain = null;
      Thread stdErrDrain = null;
      try {
        p = Runtime.getRuntime().exec(command.toArray(new String[0]));
        // TODO(floitsch): we should handle timeouts (but how long should we wait?).
        stdOutDrain = new Thread(new Drainer(p.getInputStream(), stdout, stdOutLines));
        stdErrDrain = new Thread(new Drainer(p.getErrorStream(), stderr, null));
        stdOutDrain.start();
        stdErrDrain.start();
        try {
          exitValue = p.waitFor();
        } catch (InterruptedException e) {
          throw new RuntimeException(e);
        }
      } catch (IOException e) {
        throw new RunnerError(e);
      } finally {
        try {
          if (stdOutDrain != null) {
            stdOutDrain.join();
          }
          if (stdErrDrain != null) {
            stdErrDrain.join();
          }
        } catch (InterruptedException e) {
          throw new RuntimeException(e);
        }
        try {
          p.getInputStream().close();
          p.getOutputStream().close();
          p.getOutputStream().close();
        } catch (IOException e) {
          throw new RunnerError(e);
        }
        p.destroy();
      }
      if (exitValue != 0) {
        StringWriter stringWriter = new StringWriter();
        PrintWriter out = new PrintWriter(stringWriter);
        if (options.verbose()) {
          out.println(jsScript);
        }
        out.println("Execution failed.");

        String str = mapStackEntry(decodeStackTraceFromString(stdOutLines), appSourceMap);
        if (str != null) {
          out.println("Mapped stack trace:");
          out.println(str);
          out.println("");
        }
        out.println("V8 execution returned non-zero exit-code: " + p.exitValue());
        out.flush();
        throw new RunnerError(stringWriter.toString());
      }
    } finally {
      sourceFile.delete();
    }
  }

  private String mapStackEntry(List<StackEntry> entries, SourceMapping map) {
    if (entries != null) {
      StringBuilder sb = new StringBuilder();
      for (StackEntry entry : entries) {
        SourceMapping sm = getSourceMapForFile(entry.file, map);
        // TODO(johnlenz): Try to translate the method name.
        String method = (entry.method.isEmpty()) ? "" : " (" + entry.method + ")";
        if (sm != null) {
          OriginalMapping mapping = sm.getMappingForLine(entry.line, entry.column);
          if (mapping != null) {
            String file = mapping.getOriginalFile();
            int line = mapping.getLineNumber();
            int column = mapping.getColumnPosition();
            sb.append("    at MAPPED  : " + file + ":" + line + ":" + column + method + EOL);
            continue;
          }
        }
        sb.append("    at UNMAPPED: "
            + entry.file + ":" + entry.line + ":" + entry.column + method + EOL);
      }

      return sb.toString();
    }
    return null;
  }

  SourceMapping getSourceMapForFile(String file, SourceMapping map) {
    return map;
  }

  static class StackEntry {
    String method;
    String file;
    int line;
    int column;
  }

  private List<StackEntry> decodeStackTraceFromString(List<String> lines) {
    List<StackEntry> entries = Lists.newArrayList();

    boolean seenFirst = false;
    for (String str : lines) {
      StackEntry entry = decodeStackEntry(str);
      if (entry == null) {
        if (seenFirst) {
          break;
        } else {
          continue;
        }
      } else {
        seenFirst = true;
      }
      entries.add(entry);
    }

    return entries.isEmpty() ? null : entries;
  }

  private StackEntry decodeStackEntry(String str) {
    final String PREFIX = "    at ";
    if (str.startsWith(PREFIX)) {
      StackEntry entry = new StackEntry();
      int start = str.indexOf("(");
      int end = str.indexOf(")");
      entry.method = "";
      String location;
      if (start == -1) {
        location = str.substring(PREFIX.length());
      } else {
        entry.method = str.substring(7, start-1);
        location = str.substring(start+1, end);
      }
      return decodeLocation(entry, location);
    }
    return null;
  }

  private StackEntry decodeLocation(StackEntry entry, String location) {
    String[] parts = location.split(":");
    if (parts.length == 3) {
      entry.file = parts[0];
      entry.line = Integer.valueOf(parts[1]);
      entry.column = Integer.valueOf(parts[2]);
      return entry;
    }
    return null;
  }

  private File writeTempFile(String name, String content) throws IOException {
    // The first argument to createTempFile must be at least three characters long, and be a
    // valid file-name.
    name = name.replace('/', '_');
    File file = File.createTempFile("dart_" + name, ".js");
    FileWriter writer = new FileWriter(file);
    try {
      writer.write(content);
    } finally {
      writer.close();
    }
    return file;
  }

  private static File v8Executable() {
    String d8Path = System.getProperty("com.google.dart.runner.d8",
                                       System.getenv(D8_ENVIRONMENT_VARIABLE));
    if (d8Path == null) {
      String testSrcDir = System.getenv("TEST_SRCDIR");
      if (testSrcDir == null) {
        return null;
      }
      return new File(new File(new File(new File(testSrcDir, "google3"),
                                        "third_party"), "v8"), "d8");
    } else {
      return new File(d8Path);
    }
  }

  /**
   * @return true if the D8_EXEC environment variable is correctly set up.
   */
  public static boolean isConfigured() {
    File file = v8Executable();
    if (file == null) {
      return false;
    }
    return file.canExecute();
  }
}
