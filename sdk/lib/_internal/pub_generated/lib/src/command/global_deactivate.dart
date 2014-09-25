library pub.command.global_deactivate;
import 'dart:async';
import '../command.dart';
import '../log.dart' as log;
import '../utils.dart';
class GlobalDeactivateCommand extends PubCommand {
  String get description => "Remove a previously activated package.";
  String get usage => "pub global deactivate <package>";
  bool get takesArguments => true;
  Future onRun() {
    if (commandOptions.rest.isEmpty) {
      usageError("No package to deactivate given.");
    }
    if (commandOptions.rest.length > 1) {
      var unexpected = commandOptions.rest.skip(1).map((arg) => '"$arg"');
      var arguments = pluralize("argument", unexpected.length);
      usageError("Unexpected $arguments ${toSentence(unexpected)}.");
    }
    if (!globals.deactivate(commandOptions.rest.first)) {
      dataError("No active package ${log.bold(commandOptions.rest.first)}.");
    }
    return null;
  }
}
