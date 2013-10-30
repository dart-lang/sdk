// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of testrunner;

/** Create a file [fileName] and populate it with [contents]. */
void writeFile(String fileName, String contents) {
  var file = new File(fileName);
  file.writeAsStringSync(contents);
}

/**
 * Read the contents of a file [fileName] into a [List] of [String]s.
 * If the file does not exist and [errorIfNoFile] is true, throw an
 * exception, else return an empty list.
 */
List<String> getFileContents(String filename, bool errorIfNoFile) {
  File f = new File(filename);
  if (!f.existsSync()) {
    if (errorIfNoFile) {
      throw new Exception('Config file $filename not found.');
    } else {
      return new List();
    }
  }
  return f.readAsLinesSync();
}

/**
 * Given a file path [path], make it absolute if it is relative,
 * and return the result.
 */
String makePathAbsolute(String path) {
  var p = new Path(path).canonicalize();
  if (p.isAbsolute) {
    return p.toNativePath();
  } else {
    var cwd = new Path(Directory.current.path);
    return cwd.join(p).toNativePath();
  }
}

/**
 * Create the list of all the files in a set of directories
 * ([dirs]) whose names match [filePat]. If [recurse] is true
 * look at subdirectories too. An optional [excludePat] can be supplied
 * and files or directories that match that will be excluded.
 * [includeSymLinks] controls whether or not to include files that
 * have symlinks in the traversed tree.
 */
List buildFileList(List dirs, RegExp filePat, bool recurse,
                   [RegExp excludePat, bool includeSymLinks = false]) {
  var files = new List();
  for (var i = 0; i < dirs.length; i++) {
    var path = dirs[i];
    if (excludePat != null && excludePat.hasMatch(path)) {
      continue;
    }
    // Is this a regular file?
    File f = new File(path);
    if (f.existsSync()) {
      if (filePat.hasMatch(path)) {
        files.add(path);
      }
    } else { // Try treat it as a directory.
      path = makePathAbsolute(path);
      Directory d = new Directory(path);
      if (d.existsSync()) {
        var contents = d.listSync(recursive: recurse,
            followLinks: includeSymLinks);
        for (var entity in contents) {
          if (entity is File) {
            var file = entity.path;
            if (filePat.hasMatch(file)) {
              if (excludePat == null || !excludePat.hasMatch(file)) {
                files.add(file);
              }
            }
          }
        }
      } else { // Does not exist.
        print('$path does not exist.');
      }
    }
  }
  return files;
}

/**
 * Get the directory that testrunner lives in; we need it to import
 * support files into the generated scripts.
 */

String get runnerDirectory {
  var libDirectory = makePathAbsolute(new Platform.script);
  return libDirectory.substring(0,
      libDirectory.lastIndexOf(Platform.pathSeparator));
}

/*
 * Run an external process [cmd] with command line arguments [args].
 * Returns a [Future] for when the process terminates.
 */
Future _processHelper(String command, List<String> args,
    {String workingDir}) {
  var options = null;
  if (workingDir != null) {
    options = new ProcessOptions();
    options.workingDirectory = workingDir;
  }
  return Process.run(command, args, options)
      .then((result) => result.exitCode)
      .catchError((e) {
        print("$command ${args.join(' ')}: ${e.toString()}");
      });
}

