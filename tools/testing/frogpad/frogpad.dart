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

void main() {
  String warnings = "";
  HtmlFileSystem fs = new HtmlFileSystem();
  String mainFile = getText(MAIN_ID); 
  setText("input", fs.readAll(mainFile));

  int time1 = new Date.now().value;
  List<String> args = ["dummy_arg1", "dummy_arg2", mainFile];
  parseOptions("dummy_home_dir", args, fs);

  options.useColors = false;

  initializeWorld(fs);
  world.messageHandler = void _(
      String prefix, String message, SourceSpan span) {
    String location = "";
    if (span !== null) {
      location = span.locationText;
    }
    warnings += prefix + message + location + "\n";
  };
  bool success = world.compile();
  int time2 = new Date.now().value;
  String output = world.getGeneratedCode();
  if (success) {
    setText("output", output);
  }
  setText("warnings", warnings);

  ((time2 - time1) / 1000).toStringAsPrecision(3);
  String timing = "generated ${output.length} characters in " + 
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
  return text.replaceAll('&', '&amp;').replaceAll(
      '>', '&gt;').replaceAll('<', '&lt;');
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
   * The id is constructed by taking the last directory
   * of the path, plus the file name, and using _ as a 
   * separator.  So, for example, the file name:
   *  
   *   "/usr/local/src/dart/frog/lang.dart" 
   * 
   * becomes:
   * 
   *   "frog_lang_dart"
   *  
   * And, so this file's contents will be found in a <script>
   * element that looks like this:
   *
   *   <script type=application/inert id="frog_lang_dart">
   *      ... contents of file lang.dart placed here ...
   *   etc.
   */    
  String idOfFilename(String filename) {
    List<String> components = filename.split("/");
    if (components.isEmpty()) {
      throw new Exception("bad filename");
    }
    // Grab the last two components (the directory name and file name).
    int startIndex = Math.max(0, components.length - 2);
    int length = components.length - startIndex;;
    components = components.getRange(startIndex, length);
    
    // Join components with underscore, and replace dots with underscore.
    return Strings.join(components, "_").replaceAll(".", "_");    
  }

  void writeString(String outfile, String text) {
    throw new UnsupportedOperationException("");
  }

  bool fileExists(String filename) {
    // frog calls this to check if files exist before reading them.  We return 
    // true here for all files, and let it fail later if frog attempts to read 
    // the contents of a non-existant file.
    return true;
  }

  void createDirectory(String path, [bool recursive]) {
    throw new UnsupportedOperationException("");
  }
  
  void removeDirectory(String path, [bool recursive]) {
    throw new UnsupportedOperationException("");
  }
}
