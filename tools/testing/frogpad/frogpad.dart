// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is the entrypoint for a version of the frog compiler that
 * can run in the browser.
 * Because this is running in the browser, frog cannot access
 * the file system.  Instead, we assume the all necessary files
 * have been placed in inert <script> elements somewhere on the page.
 * (See frogpad.py for more details on how the html page is constructed.)
 */

#import("dart:html", prefix:"html");
#import("../../../frog/lang.dart");
#import("../../../frog/file_system.dart");

// id of script element containing name of the main dart file
// to compile.
final String MAIN_ID = "main_id";

// id of script element containing name of the frog directory
final String FROGDIR_ID = "frogdir_id";

void main() {
  StringBuffer warnings = new StringBuffer();
  HtmlFileSystem fs = new HtmlFileSystem();
  String frogDir = getText(FROGDIR_ID);
  String mainFile = getText(MAIN_ID);
  setText("input", fs.readAll(mainFile));

  int time1 = new Date.now().value;
  List<String> args = [
      "dummy_arg1",
      "dummy_arg2",
      "--enable_type_checks",
      "--enable_asserts",
    mainFile];
  parseOptions(frogDir, args, fs);

  options.useColors = false;

  initializeWorld(fs);
  world.messageHandler = void _(
      String prefix, String message, SourceSpan span) {
    String location = "";
    if (span !== null) {
      location = span.locationText;
    }
    warnings.add('$prefix$message$location\n');
  };
  bool success = world.compile();
  int time2 = new Date.now().value;
  String output = "throw 'frogpad compilation error';\n";
  if (success) {
    output = world.getGeneratedCode();
  }
  setText("output", output);
  setText("warnings", warnings.toString());

  String timing = "generated ${output.length} characters in "
      "${((time2 - time1) / 1000).toStringAsPrecision(3)} seconds";
  setText("timing", timing);
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

// TODO(rnystrom): should exist in standard lib somewhere
String htmlEscape(String text) {
  return text.replaceAll('&', '&amp;')
             .replaceAll('>', '&gt;')
             .replaceAll('<', '&lt;');
}

class HtmlFileSystem implements FileSystem {

  HtmlFileSystem() {}

  String readAll(String filename) {
    String text = getText(idOfFilename(filename));
    print("read $filename (${text.length} bytes)");
    return text;
  }

  /**
   * Returns the id of the <script> element that contains
   * the contents of this file.
   * The id is constructed by taking the filename and replacing
   * all slashes and dots with underscores.  For example, the file name:
   *
   *   "/usr/local/src/dart/frog/lang.dart"
   *
   * becomes:
   *
   *   "_usr_local_src_dart_frog_lang_dart"
   *
   * And, so this file's contents will be found in a <script>
   * element that looks like this:
   *
   *   <script type=application/inert id="_usr_local_src_dart_frog_lang_dart">
   *      ... contents of file lang.dart placed here ...
   *   etc.
   */
  String idOfFilename(String filename) {
    return filename.replaceAll("/", "_").replaceAll(".", "_");
  }

  void writeString(String outfile, String text) {
    throw new UnsupportedOperationException("");
  }

  bool fileExists(String filename) {
    // frog calls this to check if files exist before reading them.  We return
    // true here for all files, and let it fail later if frog attempts to read
    // the contents of a non-existent file.
    return true;
  }

  void createDirectory(String path, [bool recursive]) {
    throw new UnsupportedOperationException("");
  }

  void removeDirectory(String path, [bool recursive]) {
    throw new UnsupportedOperationException("");
  }
}
