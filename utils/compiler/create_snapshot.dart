// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

Future<String> getVersion(var options, var rootPath) {
  var versionPath = rootPath.append("tools").append("version.dart");
  return Process.run(options.executable,
                     [versionPath.toNativePath()])
      .then((result) {
        if (result.exitCode != 0) {
          throw "Could not generate version";
        }
        return result.stdout.trim();
      });
}

Future<String> getSnapshotGenerationFile(var options, var args, var rootPath) {
  var dart2js = rootPath.append(args["dart2js_main"]);

  return getVersion(options, rootPath).then((version) {
    var snapshotGenerationText = 
"""
import '${dart2js}' as dart2jsMain;
import 'dart:io';

void main() {
  Options options = new Options();
  if (options.arguments.length < 1) throw "No tool given as argument";
  String tool = options.arguments.removeAt(0);
  if (tool == "dart2js") {
    dart2jsMain.BUILD_ID = "$version";
    dart2jsMain.mainWithErrorHandler(options);
  }
}

""";
    return snapshotGenerationText;
  });
}

void writeSnapshotFile(var path, var content) {
    File file = new File(path);
    var writer = file.openSync(mode: FileMode.WRITE);
    writer.writeStringSync(content);
    writer.close();
}

Future createSnapshot(var options, var dart_file) {
  return Process.run(options.executable,
                     ["--generate-script-snapshot=$dart_file.snapshot",
                      dart_file])
      .then((result) {
        if (result.exitCode != 0) {
          throw "Could not generate snapshot";
        }
      });
}

/**
 * Takes the following arguments:
 * --output_dir=val     The full path to the output_dir.
 * --dart2js_main=val   The path to the dart2js main script releative to root.
 */
void main() { 
  Options options = new Options();
  var validArguments = ["--output_dir", "--dart2js_main"];
  var args = {};
  for (var argument in options.arguments) {
    var argumentSplit = argument.split("=");
    if (argumentSplit.length != 2) throw "Invalid argument $argument, no =";
    if (!validArguments.contains(argumentSplit[0])) {
      throw "Invalid argument $argument";
    }
    args[argumentSplit[0].substring(2)] = argumentSplit[1];
  }
  if (!args.containsKey("dart2js_main")) throw "Please specify dart2js_main";
  if (!args.containsKey("output_dir")) throw "Please specify output_dir";

  var scriptFile = new File(options.script);
  var path = new Path(scriptFile.directorySync().path); 
  var rootPath = path.directoryPath.directoryPath;

  getSnapshotGenerationFile(options, args, rootPath).then((result) {
    var wrapper = "${args['output_dir']}/utils_wrapper.dart";
    writeSnapshotFile(wrapper, result);
    createSnapshot(options, wrapper);
  });
}
