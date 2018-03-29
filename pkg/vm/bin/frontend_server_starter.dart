library frontend_server;

import 'dart:async';
import 'dart:io';

import '../lib/frontend_server.dart';

Future<Null> main(List<String> args) async {
  exit(await starter(args));
}
