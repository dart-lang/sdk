// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/** Copy a file with path [sourceName] to destination [destName]. */
void copyFile(String sourceName, String destName) {
  var sourceFile = new File(sourceName);
  var destFile = new File(destName);
  var istream = sourceFile.openInputStream();
  var ostream = destFile.openOutputStream(FileMode.WRITE);
  istream.pipe(ostream);
  // TODO(gram) - make sure both streams are closed.
  // I think they are but the docs are not clear on this point.
}

/** Create a file [fileName] and populate it with [contents]. */
void createFile(String fileName, String contents) {
  var file = new File(fileName);
  var ostream = file.openOutputStream(FileMode.WRITE);
  ostream.writeString(contents);
  ostream.close();
}

/**
 * Given a file path [path], make it absolute if it is relative,
 * and return the result.
 */
String makePathAbsolute(String path) {
  var p = new Path(path).canonicalize();
  if (p.isAbsolute) {
    return p.toString();
  } else {
    var cwd = new Path((new Directory.current()).path);
    return cwd.join(p).toString();
  }
}

/**
 * Create the list of all the files in a set of directories
 * ([dirs]) whose names match [filePat]. If [recurse] is true
 * look at subdirectories too. Once they have all been enumerated,
 * call [onComplete].
 */
void buildFileList(List dirs, RegExp filePat, bool recurse,
                   Function onComplete) {
  var files = new List();
  var dirCount = 1;
  for (var i = 0; i < dirs.length; i++) {
    var path = dirs[i];
    // Is this a regular file?
    File f = new File(path);
    if (f.existsSync()) {
      if (filePat.hasMatch(path)) {
        files.add(path);
      }
    } else { // Try treat it as a directory.
      Directory d = new Directory(path);
      if (d.existsSync()) {
        ++dirCount;
        var lister = d.list(recursive: recurse);
        lister.onFile = (file) {
          if (filePat.hasMatch(file)) {
            files.add(file);
          }
        };
        lister.onDone = (complete) {
          if (complete && --dirCount == 0) {
            onComplete(files);
          }
        };
      } else { // Does not exist.
        print('$path does not exist.');
      }
    }
  }
  if (--dirCount == 0) {
    onComplete(files);
  }
}

/** Delete a file. */
bool deleteFile(String fname) {
  var f = new File(fname);
  try {
    f.deleteSync();
  } catch (e) {
    return false;
  }
  return true;
}

/**
 * Get the directory that testrunner lives in; we need it to import
 * support files into the generated scripts.
 */

String get runnerDirectory() {
  var libDirectory = makePathAbsolute(new Options().script);
  return libDirectory.substring(0,
      libDirectory.lastIndexOf(Platform.pathSeparator));
}

