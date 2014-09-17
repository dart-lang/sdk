library pub.command.run;
import 'dart:async';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;
import '../command.dart';
import '../executable.dart';
import '../io.dart';
import '../utils.dart';
class RunCommand extends PubCommand {
  bool get takesArguments => true;
  bool get allowTrailingOptions => false;
  String get description =>
      "Run an executable from a package.\n"
          "NOTE: We are currently optimizing this command's startup time.";
  String get usage => "pub run <executable> [args...]";
  RunCommand() {
    commandParser.addOption(
        "mode",
        help: 'Mode to run transformers in.\n'
            '(defaults to "release" for dependencies, "debug" for entrypoint)');
  }
  Future onRun() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        join0() {
          var package = entrypoint.root.name;
          var executable = commandOptions.rest[0];
          var args = commandOptions.rest.skip(1).toList();
          join1() {
            var mode;
            join2() {
              runExecutable(
                  entrypoint,
                  package,
                  executable,
                  args,
                  mode: mode).then((x0) {
                try {
                  var exitCode = x0;
                  flushThenExit(exitCode).then((x1) {
                    try {
                      x1;
                      completer0.complete(null);
                    } catch (e1) {
                      completer0.completeError(e1);
                    }
                  }, onError: (e2) {
                    completer0.completeError(e2);
                  });
                } catch (e0) {
                  completer0.completeError(e0);
                }
              }, onError: (e3) {
                completer0.completeError(e3);
              });
            }
            if (commandOptions['mode'] != null) {
              mode = new BarbackMode(commandOptions['mode']);
              join2();
            } else {
              join3() {
                join2();
              }
              if (package == entrypoint.root.name) {
                mode = BarbackMode.DEBUG;
                join3();
              } else {
                mode = BarbackMode.RELEASE;
                join3();
              }
            }
          }
          if (executable.contains(":")) {
            var components = split1(executable, ":");
            package = components[0];
            executable = components[1];
            join4() {
              join1();
            }
            if (p.split(executable).length > 1) {
              usageError(
                  "Cannot run an executable in a subdirectory of a " + "dependency.");
              join4();
            } else {
              join4();
            }
          } else {
            join1();
          }
        }
        if (commandOptions.rest.isEmpty) {
          usageError("Must specify an executable to run.");
          join0();
        } else {
          join0();
        }
      } catch (e4) {
        completer0.completeError(e4);
      }
    });
    return completer0.future;
  }
}
