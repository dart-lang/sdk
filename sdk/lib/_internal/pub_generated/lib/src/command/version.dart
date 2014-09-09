library pub.command.version;
import 'dart:async';
import '../command.dart';
import '../log.dart' as log;
import '../sdk.dart' as sdk;
class VersionCommand extends PubCommand {
  String get description => "Print pub version.";
  String get usage => "pub version";
  Future onRun() {
    log.message("Pub ${sdk.version}");
    return null;
  }
}
