library pub.command.global_list;
import 'dart:async';
import '../command.dart';
class GlobalListCommand extends PubCommand {
  bool get allowTrailingOptions => false;
  String get description => 'List globally activated packages.';
  String get usage => 'pub global list';
  Future onRun() {
    globals.listActivePackages();
    return null;
  }
}
