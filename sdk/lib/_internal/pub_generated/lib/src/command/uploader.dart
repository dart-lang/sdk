library pub.command.uploader;
import 'dart:async';
import 'package:path/path.dart' as path;
import '../command.dart';
import '../entrypoint.dart';
import '../exit_codes.dart' as exit_codes;
import '../http.dart';
import '../io.dart';
import '../log.dart' as log;
import '../oauth2.dart' as oauth2;
import '../source/hosted.dart';
import '../utils.dart';
class UploaderCommand extends PubCommand {
  String get description =>
      "Manage uploaders for a package on pub.dartlang.org.";
  String get usage => "pub uploader [options] {add/remove} <email>";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-uploader.html";
  bool get takesArguments => true;
  Uri get server => Uri.parse(commandOptions['server']);
  UploaderCommand() {
    commandParser.addOption(
        'server',
        defaultsTo: HostedSource.defaultUrl,
        help: 'The package server on which the package is hosted.');
    commandParser.addOption(
        'package',
        help: 'The package whose uploaders will be modified.\n'
            '(defaults to the current package)');
  }
  Future onRun() {
    if (commandOptions.rest.isEmpty) {
      log.error('No uploader command given.');
      this.printUsage();
      return flushThenExit(exit_codes.USAGE);
    }
    var rest = commandOptions.rest.toList();
    var command = rest.removeAt(0);
    if (!['add', 'remove'].contains(command)) {
      log.error('Unknown uploader command "$command".');
      this.printUsage();
      return flushThenExit(exit_codes.USAGE);
    } else if (rest.isEmpty) {
      log.error('No uploader given for "pub uploader $command".');
      this.printUsage();
      return flushThenExit(exit_codes.USAGE);
    }
    return syncFuture(() {
      var package = commandOptions['package'];
      if (package != null) return package;
      return new Entrypoint(path.current, cache).root.name;
    }).then((package) {
      var uploader = rest[0];
      return oauth2.withClient(cache, (client) {
        if (command == 'add') {
          var url =
              server.resolve("/api/packages/" "${Uri.encodeComponent(package)}/uploaders");
          return client.post(url, headers: PUB_API_HEADERS, body: {
            "email": uploader
          });
        } else {
          var url = server.resolve(
              "/api/packages/" "${Uri.encodeComponent(package)}/uploaders/"
                  "${Uri.encodeComponent(uploader)}");
          return client.delete(url, headers: PUB_API_HEADERS);
        }
      });
    }).then(
        handleJsonSuccess).catchError(
            (error) => handleJsonError(error.response),
            test: (e) => e is PubHttpException);
  }
}
