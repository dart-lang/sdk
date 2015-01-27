// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental.options;

class Options {
  final List<String> arguments;
  final Uri packageRoot;
  final String host;
  final int port;

  Options({this.arguments, this.packageRoot, this.host, this.port});

  static String extractArgument(String option, String short, {String long}) {
    if (option.startsWith(short)) {
      return option.substring(short.length);
    }
    if (long != null && option.startsWith(long)) {
      return option.substring(long.length);
    }
    return null;
  }

  static Options parse(List<String> commandLine) {
    Iterator<String> iterator = commandLine.iterator;
    List<String> arguments = <String>[];
    Uri packageRoot;
    String host = "127.0.0.1";
    int port = 0;
    bool showHelp = false;
    List<String> unknownOptions = <String>[];

    LOOP: while (iterator.moveNext()) {
      String option = iterator.current;
      switch (option) {
        case "-p":
          iterator.moveNext();
          packageRoot = Uri.base.resolve(iterator.current);
          continue;

        case "-h":
          iterator.moveNext();
          host = iterator.current;
          continue;

        case "-n":
          iterator.moveNext();
          port = int.parse(iterator.current);
          continue;

        case "--help":
          showHelp = true;
          continue;

        case "--":
          break LOOP;

        default:
          String argument;

          argument = extractArgument(option, "-p", long: "--package-root");
          if (argument != null) {
            packageRoot = Uri.base.resolve(argument);
            continue;
          }

          argument = extractArgument(option, "-h", long: "--host");
          if (argument != null) {
            host = argument;
            continue;
          }

          argument = extractArgument(option, "-n", long: "--port");
          if (argument != null) {
            port = int.parse(option);
            continue;
          }

          if (option.startsWith("-")) {
            unknownOptions.add(option);
            continue;
          }

          arguments.add(option);
          break;
      }
    }
    if (showHelp) {
      print(USAGE);
    }
    if (!unknownOptions.isEmpty) {
      print(USAGE);
      print("Unknown options: '${unknownOptions.join('\', \'')}'");
      return null;
    }
    while (iterator.moveNext()) {
      arguments.add(iterator.current);
    }
    if (arguments.length > 1) {
      print(USAGE);
      print("Extra arguments: '${arguments.skip(1).join('\', \'')}'");
      return null;
    }
    if (packageRoot == null) {
      packageRoot = Uri.base.resolve('packages/');
    }
    return new Options(
        arguments: arguments, packageRoot: packageRoot, host: host, port: port);
  }
}

const String USAGE = """
Usage: server.dart [options] [--] documentroot

Development web server which serves files relative to [documentroot]. If a file
is missing, and the requested file name ends with '.dart.js', the server will
look for a file with the same name save '.js', compile it to JavaScript, and
serve that file instead.

Supported options:

  -p<path>, --package-root=<path>
    Where to find packages, that is, "package:..." imports.

  -h<name>, --host=<name>
    Host name to bind the web server to (default 127.0.0.1).

  -n<port>, --port=<port>
    Port number to bind the web server to.

  --help
    Show this message.
""";
