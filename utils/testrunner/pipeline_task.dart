// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A test execution pipeline is made up of a list of tasks. Each task is a
 * subclass of [PipelineTask].
 */
abstract class PipelineTask {

  abstract void execute(Path testfile, List stdout, List stderr,
                       bool logging, Function exitHandler);

  void cleanup(Path testfile, List stdout, List stderr,
               bool verboseLogging, bool keepTestFiles) {
  }

  void deleteFiles(List templates, Path testfile, bool logging, bool keepFiles,
                   List stdout) {
    if (!keepFiles) {
      for (var template in templates) {
        var fname = expandMacros(template, testfile);
        deleteFile(fname);
        if (logging) {
          stdout.add('Removing $fname');
        }
      }
    }
  }

  String flattenPath(String path) {
    return makePathAbsolute(path).
        replaceAll(Platform.pathSeparator, "_").
        replaceAll(":","");
  }

  // This takes a string used in a template and does macro expansion for
  // a specific test file.
  String expandMacros(String template, Path testfile) {
    String path = makePathAbsolute(testfile.directoryPath.toString());
    return template.
        replaceAll(Macros.fullFilePath, testfile.toNativePath()).
        replaceAll(Macros.filenameNoExtension,
            testfile.filenameWithoutExtension).
        replaceAll(Macros.filename, testfile.filename).
        replaceAll(Macros.directory, path).
        replaceAll(Macros.flattenedDirectory, flattenPath(path));
  }
}


