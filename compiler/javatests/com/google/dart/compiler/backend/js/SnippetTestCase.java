// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.base.Strings;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartCompilerListenerTest;
import com.google.dart.compiler.DartSourceTest;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.MockArtifactProvider;
import com.google.dart.compiler.MockLibrarySource;

import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

/**
 * Tests for binary expression optimizations.
 */
public class SnippetTestCase extends CompilerTestCase {

  private static final String MARKER = "_marker_";

  private MockArtifactProvider provider = new MockArtifactProvider();
  private JavascriptBackend jsBackend = new JavascriptBackend();
  protected AbstractJsBackend getBackend() {
    return jsBackend;
  }

  @Override
  protected void tearDown() throws Exception {
    provider = null;
    jsBackend = null;
    super.tearDown();
  }

  protected String compileSingleUnit(final String filePath) throws IOException {
    return compileSingleUnit(filePath, "Main");
  }

  protected String compileSingleUnit(final String filePath, final String part) throws IOException {
    URL url = inputUrlFor(getClass(), filePath + ".dart");
    String source = readUrl(url);
    MockLibrarySource lib = new MockLibrarySource();
    DartSourceTest src = new DartSourceTest(filePath, source, lib);
    lib.addSource(src);
    CompilerOptions options = new CompilerOptions();
    CompilerConfiguration config = new DefaultCompilerConfiguration(this.getBackend(), options);
    DartCompilerListener listener = new DartCompilerListenerTest(src.getName());
    DartCompiler.compileLib(lib, config, provider, listener);

    return provider.getArtifactString(src, part, JavascriptBackend.EXTENSION_JS);
  }

  protected List<String> findMarkerLines(String js) {
    assertNotNull(js);
    List<String> lines = new ArrayList<String>();

    int begin = 0;
    int end = 0;
    while (true) {
      begin = js.indexOf(MARKER, begin);
      if (begin < 0) {
        break;
      }
      end = js.indexOf(';', begin);
      if (end > begin) {
        lines.add(js.substring(begin + MARKER.length(), end));
      }
      begin = end;
    }

    return lines;
  }

  /**
   * Returns the specified occurence of the marker string inside of the JS code or null if there is
   * none. Note that this method may miss the text around the specified occurence of the marker.
   */
  protected String findMarkerAtOccurrence(String js, String marker, int occurrence) {
    int begin = 0;
    int end = 0;
    int nOccurrence = 0;
    while (true) {
      begin = js.indexOf(marker, begin);
      if (begin < 0) {
        break;
      }
      nOccurrence++;
      end = js.indexOf(';', begin);
      if (end > begin && occurrence == nOccurrence) {
        return js.substring(begin, end);
      }

      begin = end;
    }

    return null;
  }

  /**
   * Returns the specified occurrence of the marker string inside of the JS code by splitting the
   * string using the specified regex and then locating the occurrence. This method allows you to
   * control how much of the text around the marker occurence you are interested in.
   */
  protected String findMarkerAtOccurrence(String js, String marker, String regEx, int occurrence) {
    int iOccurrence = 0;
    String[] strings = js.split(regEx);
    for (int i = 0; i < strings.length; ++i) {
      if (strings[i].indexOf(marker) != -1) {
        if (++iOccurrence == occurrence) {
          return strings[i].trim();
        }
      }
    }
    return null;
  }

  protected String replaceTemps(String js) {
    return Strings.isNullOrEmpty(js) ? "" : js.replaceAll("tmp\\$[0-9]+", "tmp");
  }

  protected String[] getFunctionBody(String name, String corpus) {
    assertTrue(!Strings.isNullOrEmpty(name));
    int start = corpus.indexOf(name);
    if (start == -1) {
      return new String[0];
    }
    int len = corpus.length();
    while (start < len && corpus.charAt(start) != '{') {
      start++;
    }
    int end = start;
    int count = 0;
    while (end < len) {
      if (corpus.charAt(end) == '{')
        count++;
      if (corpus.charAt(end) == '}')
        count--;
      end++;
      if (count == 0)
        break;
    }
    assert end >= start;
    List<String> result = new ArrayList<String>();
    for (String s : corpus.substring(start, end).split("\\n")) {
      if (s.equals("{") || s.equals("}"))
        continue;
      result.add(s.trim());
    }
    return result.toArray(new String[0]);
  }
}
