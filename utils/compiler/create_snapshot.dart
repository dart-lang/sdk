// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

Future<String> getVersion(var rootPath) {
  var suffix = Platform.operatingSystem == 'windows' ? '.exe' : '';
  var printVersionScript = rootPath.resolve("tools/print_version.py");
  return Process.run("python$suffix",
                     [printVersionScript.toFilePath()]).then((result) {
    if (result.exitCode != 0) {
      throw "Could not generate version";
    }
    return result.stdout.trim();
  });
}

Future<String> getSnapshotGenerationFile(var args, var rootPath) {
  var dart2js = rootPath.resolve(args["dart2js_main"]);
  var dartdoc = rootPath.resolve(args["dartdoc_main"]);
  return getVersion(rootPath).then((version) {
    var snapshotGenerationText =
"""
import '${dart2js.toFilePath(windows: false)}' as dart2jsMain;
import '${dartdoc.toFilePath(windows: false)}' as dartdocMain;
import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length < 1) throw "No tool given as argument";
  String tool = arguments[0];
  if (tool == "dart2js") {
    dart2jsMain.BUILD_ID = "$version";
    dart2jsMain.main(arguments.skip(1).toList());
  } else if (tool == "dartdoc") {
    dartdocMain.main(arguments.skip(1).toList());
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

Future createSnapshot(var dart_file, var packageRoot) {
  return Process.run(Platform.executable,
                     ["--package-root=$packageRoot",
                      "--snapshot=$dart_file.snapshot",
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
void main(List<String> arguments) {
  var validArguments = ["--output_dir", "--dart2js_main", "--dartdoc_main",
                        "--package_root"];
  var args = {};
  for (var argument in arguments) {
    var argumentSplit = argument.split("=");
    if (argumentSplit.length != 2) throw "Invalid argument $argument, no =";
    if (!validArguments.contains(argumentSplit[0])) {
      throw "Invalid argument $argument";
    }
    args[argumentSplit[0].substring(2)] = argumentSplit[1];
  }
  if (!args.containsKey("dart2js_main")) throw "Please specify dart2js_main";
  if (!args.containsKey("dartdoc_main")) throw "Please specify dartdoc_main";
  if (!args.containsKey("output_dir")) throw "Please specify output_dir";
  if (!args.containsKey("package_root")) throw "Please specify package_root";

  var scriptFile = new Uri.file(new File(Platform.script).fullPathSync());
  var path = scriptFile.resolve(".");
  var rootPath = path.resolve("../..");
  getSnapshotGenerationFile(args, rootPath).then((result) {
    var wrapper = "${args['output_dir']}/utils_wrapper.dart";
    writeSnapshotFile(wrapper, result);
    createSnapshot(wrapper, args["package_root"]);
  });
}
