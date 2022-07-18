// @dart = 2.9
library frontend_server;

import 'dart:async';
import 'dart:io';

import 'package:frontend_server/frontend_server.dart';

Future<Null> main(List<String> args) async {
  exitCode = await starter(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
