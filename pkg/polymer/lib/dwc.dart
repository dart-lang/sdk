// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point to the compiler. Used to implement `bin/dwc.dart`. */
library dwc;

import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart' show Level;

import 'src/compiler.dart';
import 'src/file_system.dart';
import 'src/file_system/console.dart';
import 'src/files.dart';
import 'src/messages.dart';
import 'src/compiler_options.dart';
import 'src/utils.dart';

FileSystem _fileSystem;

void main() {
  run(new Options().arguments).then((result) {
    exit(result.success ? 0 : 1);
  });
}

/** Contains the result of a compiler run. */
class CompilerResult {
  final bool success;

  /** Map of output path to source, if there is one */
  final Map<String, String> outputs;

  /** List of files read during compilation */
  final List<String> inputs;

  final List<String> messages;
  String bootstrapFile;

  CompilerResult([this.success = true,
                  this.outputs,
                  this.inputs,
                  this.messages = const [],
                  this.bootstrapFile]);

  factory CompilerResult._(bool success,
      List<String> messages, List<OutputFile> outputs, List<SourceFile> files) {
    var file;
    var outs = new Map<String, String>();
    for (var out in outputs) {
      if (path.basename(out.path).endsWith('_bootstrap.dart')) {
        file = out.path;
      }
      outs[out.path] = out.source;
    }
    var inputs = files.map((f) => f.path).toList();
    return new CompilerResult(success, outs, inputs, messages, file);
  }
}

/**
 * Runs the web components compiler with the command-line options in [args].
 * See [CompilerOptions] for the definition of valid arguments.
 */
// TODO(jmesserly): fix this to return a proper exit code
// TODO(justinfagnani): return messages in the result
Future<CompilerResult> run(List<String> args, {bool printTime,
    bool shouldPrint: true}) {
  var options = CompilerOptions.parse(args);
  if (options == null) return new Future.value(new CompilerResult());
  if (printTime == null) printTime = options.verbose;

  _fileSystem = new ConsoleFileSystem();
  var messages = new Messages(options: options, shouldPrint: shouldPrint);

  return asyncTime('Total time spent on ${options.inputFile}', () {
    var compiler = new Compiler(_fileSystem, options, messages);
    var res;
    return compiler.run()
      .then((_) {
        var success = messages.messages.every((m) => m.level != Level.SEVERE);
        var msgs = options.jsonFormat
            ? messages.messages.map((m) => m.toJson())
            : messages.messages.map((m) => m.toString());
        res = new CompilerResult._(success, msgs.toList(),
            compiler.output, compiler.files);
      })
      .then((_) => _symlinkPubPackages(res, options, messages))
      .then((_) => _emitFiles(compiler.output, options.clean))
      .then((_) => res);
  }, printTime: printTime, useColors: options.useColors);
}

Future _emitFiles(List<OutputFile> outputs, bool clean) {
  outputs.forEach((f) => _writeFile(f.path, f.contents, clean));
  return _fileSystem.flush();
}

void _writeFile(String filePath, String contents, bool clean) {
  if (clean) {
    File fileOut = new File(filePath);
    if (fileOut.existsSync()) {
      fileOut.deleteSync();
    }
  } else {
    _createIfNeeded(path.dirname(filePath));
    _fileSystem.writeString(filePath, contents);
  }
}

void _createIfNeeded(String outdir) {
  if (outdir.isEmpty) return;
  var outDirectory = new Directory(outdir);
  if (!outDirectory.existsSync()) {
    _createIfNeeded(path.dirname(outdir));
    outDirectory.createSync();
  }
}

/**
 * Creates a symlink to the pub packages directory in the output location. The
 * returned future completes when the symlink was created (or immediately if it
 * already exists).
 */
Future _symlinkPubPackages(CompilerResult result, CompilerOptions options,
    Messages messages) {
  if (options.outputDir == null || result.bootstrapFile == null
      || options.packageRoot != null) {
    // We don't need to copy the packages directory if the output was generated
    // in-place where the input lives, if the compiler was called without an
    // entry-point file, or if the compiler was called with a package-root
    // option.
    return new Future.value(null);
  }

  var linkDir = path.dirname(result.bootstrapFile);
  _createIfNeeded(linkDir);
  var linkPath = path.join(linkDir, 'packages');
  // A resolved symlink works like a directory
  // TODO(sigmund): replace this with something smarter once we have good
  // symlink support in dart:io
  if (new Directory(linkPath).existsSync()) {
    // Packages directory already exists.
    return new Future.value(null);
  }

  // A broken symlink works like a file
  var toFile = new File(linkPath);
  if (toFile.existsSync()) {
    toFile.deleteSync();
  }

  var targetPath = path.join(path.dirname(options.inputFile), 'packages');
  // [fullPathSync] will canonicalize the path, resolving any symlinks.
  // TODO(sigmund): once it's possible in dart:io, we just want to use a full
  // path, but not necessarily resolve symlinks.
  var target = new File(targetPath).fullPathSync().toString();
  return createSymlink(target, linkPath, messages: messages);
}


// TODO(jmesserly): this code was taken from Pub's io library.
// Added error handling and don't return the file result, to match the code
// we had previously. Also "target" and "link" only accept strings. And inlined
// the relevant parts of runProcess. Note that it uses "cmd" to get the path
// on Windows.
/**
 * Creates a new symlink that creates an alias of [target] at [link], both of
 * which can be a [String], [File], or [Directory]. Returns a [Future] which
 * completes to the symlink file (i.e. [link]).
 */
Future createSymlink(String target, String link, {Messages messages: null}) {
  messages = messages == null? new Messages.silent() : messages;
  var command = 'ln';
  var args = ['-s', target, link];

  if (Platform.operatingSystem == 'windows') {
    // Call mklink on Windows to create an NTFS junction point. Only works on
    // Vista or later. (Junction points are available earlier, but the "mklink"
    // command is not.) I'm using a junction point (/j) here instead of a soft
    // link (/d) because the latter requires some privilege shenanigans that
    // I'm not sure how to specify from the command line.
    command = 'cmd';
    args = ['/c', 'mklink', '/j', link, target];
  }

  return Process.run(command, args).then((result) {
    if (result.exitCode != 0) {
      var details = 'subprocess stdout:\n${result.stdout}\n'
                    'subprocess stderr:\n${result.stderr}';
      messages.error(
        'unable to create symlink\n target: $target\n link:$link\n$details',
        null);
    }
    return null;
  });
}
