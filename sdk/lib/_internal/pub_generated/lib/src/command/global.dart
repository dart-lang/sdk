library pub.command.global;
import '../command.dart';
import 'global_activate.dart';
import 'global_deactivate.dart';
import 'global_list.dart';
import 'global_run.dart';
class GlobalCommand extends PubCommand {
  String get description => "Work with global packages.";
  String get usage => "pub global <subcommand>";
  final subcommands = {
    "activate": new GlobalActivateCommand(),
    "deactivate": new GlobalDeactivateCommand(),
    "list": new GlobalListCommand(),
    "run": new GlobalRunCommand()
  };
}
