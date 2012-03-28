// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:html", prefix:"html");
#import('../../../frog/leg/api.dart', prefix: "api_lib");
#import('../../../lib/uri/uri.dart', prefix:"uri_lib");

/**
 * This is the entrypoint for a version of the leg compiler that
 * runs in the browser.
 *
 * Because this is running in the browser, we do not access
 * the file system.  Instead, we assume that all necessary files
 * have been placed in inert <script> elements somewhere on the html page.
 *
 * (See legpad.py for more details on how the html page is constructed.)
 */
void main() {
  new Legpad().run();
}

class Legpad {
  // id of script element containing name of the main dart file
  // to compile
  static final String MAIN_ID = "main_id";

  Legpad() : warnings = new StringBuffer() {}

  // accumulates diagnostic messages emitted by the leg compiler
  StringBuffer warnings;

  // the generated javascript
  String output;

  String readAll(String filename) {
    String text = getText(idOfFilename(filename));
    print("read $filename (${text.length} bytes)");
    return text;
  }

  void diagnosticHandler(uri_lib.Uri uri, int begin, int end,
                                 String message, bool fatal) {
    // TODO(mattsh): format message with location info
    warnings.add(message).add("\n");
  }

  Future<String> readUriFromString(uri_lib.Uri uri) {
    Completer<String> completer = new Completer<String>();
    completer.complete(readAll(uri.toString()));
    return completer.future;
  }

  /**
   * Returns the id of the <script> element that contains
   * the contents of this file.  (Replace all slashes
   * and dots in the file name with underscores.)
   */
  String idOfFilename(String filename) {
    return filename.replaceAll("/", "_").replaceAll(".", "_");
  }

  void run() {
    String mainFile = getText(MAIN_ID);
    setText("input", readAll(mainFile));
    Stopwatch stopwatch = new Stopwatch.start();
    runLeg();
    int elapsedMillis = stopwatch.elapsedInMs();
    setText("output", output);
    setText("warnings", warnings);
    String timing = "generated ${output.length} characters in " +
        "${((elapsedMillis) / 1000).toStringAsPrecision(3)} seconds";
    setText("timing", timing);
  }

  void runLeg() {
    uri_lib.Uri mainUri = new uri_lib.Uri.fromString(getText(MAIN_ID));
    uri_lib.Uri libraryRoot =
        new uri_lib.Uri.fromString("dartdir/frog/leg/lib/");
    List<String> compilerArgs = [
      "--enable_type_checks",
      "--enable_asserts"
    ];

    // TODO(mattsh) - dart2js api should be synchronous
    Future<String> futureJavascript = api_lib.compile(mainUri,
         libraryRoot, readUriFromString, diagnosticHandler, compilerArgs);

    if (futureJavascript == null) {
      output = "throw 'legpad compilation error';\n";
      return;
    }
    output = futureJavascript.value;
  }

  void setText(String id, String text) {
    html.Element element = html.document.query("#$id");
    if (element === null) {
      throw new Exception("Can't find element $id");
    }
    element.innerHTML = htmlEscape(text);
  }

  String getText(String id) {
    html.Element element = html.document.query("#$id");
    if (element === null) {
      throw new Exception("Can't find element $id");
    }
    return element.text.trim();
  }

  // TODO(mattsh): should exist in standard lib somewhere
  static String htmlEscape(String text) {
    return text.replaceAll('&', '&amp;').replaceAll(
        '>', '&gt;').replaceAll('<', '&lt;');
  }
}
