import 'dart:io';

import 'compare_failures.dart' as compare_failures;
import 'current_summary.dart' as current_summary;
import 'status_summary.dart' as status_summary;

void help(List<String> args) {
  if (args.length == 1 && args[0] == "--help") {
    print("This help");
    return;
  }

  print("A script that combines multiple commands:\n");

  commands.forEach((command, fun) {
    print("$command:");
    fun(["--help"]);
    print("");
  });
}

const commands = const {
  "help": help,
  "compare-failures": compare_failures.main,
  "current-summary": current_summary.main,
  "status-summary": status_summary.main,
};

void main(List<String> args) {
  if (args.isEmpty) {
    help([]);
    exit(-1);
  }
  var command = commands[args[0]];
  if (command == null) {
    help([]);
    exit(-1);
  }
  command(args.sublist(1));
}
