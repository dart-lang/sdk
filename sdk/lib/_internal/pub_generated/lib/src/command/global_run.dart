library pub.command.global_run;
import 'dart:async';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;
import '../command.dart';
import '../io.dart';
import '../utils.dart';
class GlobalRunCommand extends PubCommand {
  bool get takesArguments => true;
  bool get allowTrailingOptions => false;
  String get description =>
      "Run an executable from a globally activated package.\n"
          "NOTE: We are currently optimizing this command's startup time.";
  String get usage => "pub global run <package>:<executable> [args...]";
  BarbackMode get mode => new BarbackMode(commandOptions["mode"]);
  GlobalRunCommand() {
    commandParser.addOption(
        "mode",
        defaultsTo: "release",
        help: 'Mode to run transformers in.');
  }
  Future onRun() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        join0() {
          var package;
          var executable = commandOptions.rest[0];
          join1() {
            var args = commandOptions.rest.skip(1).toList();
            join2() {
              globals.runExecutable(
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
            if (p.split(executable).length > 1) {
              usageError(
                  'Cannot run an executable in a subdirectory of a global ' + 'package.');
              join2();
            } else {
              join2();
            }
          }
          if (executable.contains(":")) {
            var parts = split1(executable, ":");
            package = parts[0];
            executable = parts[1];
            join1();
          } else {
            package = executable;
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
