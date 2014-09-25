library pub.command.lish;
import 'dart:async';
import 'package:http/http.dart' as http;
import '../command.dart';
import '../ascii_tree.dart' as tree;
import '../http.dart';
import '../io.dart';
import '../log.dart' as log;
import '../oauth2.dart' as oauth2;
import '../source/hosted.dart';
import '../utils.dart';
import '../validator.dart';
class LishCommand extends PubCommand {
  String get description => "Publish the current package to pub.dartlang.org.";
  String get usage => "pub publish [options]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-lish.html";
  List<String> get aliases => const ["lish", "lush"];
  Uri get server {
    if (commandOptions.wasParsed('server')) {
      return Uri.parse(commandOptions['server']);
    }
    if (entrypoint.root.pubspec.publishTo != null) {
      return Uri.parse(entrypoint.root.pubspec.publishTo);
    }
    return Uri.parse(HostedSource.defaultUrl);
  }
  bool get dryRun => commandOptions['dry-run'];
  bool get force => commandOptions['force'];
  LishCommand() {
    commandParser.addFlag(
        'dry-run',
        abbr: 'n',
        negatable: false,
        help: 'Validate but do not publish the package.');
    commandParser.addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Publish without confirmation if there are no errors.');
    commandParser.addOption(
        'server',
        defaultsTo: HostedSource.defaultUrl,
        help: 'The package server to which to upload this package.');
  }
  Future _publish(packageBytes) {
    var cloudStorageUrl;
    return oauth2.withClient(cache, (client) {
      return log.progress('Uploading', () {
        var newUri = server.resolve("/api/packages/versions/new");
        return client.get(newUri, headers: PUB_API_HEADERS).then((response) {
          var parameters = parseJsonResponse(response);
          var url = _expectField(parameters, 'url', response);
          if (url is! String) invalidServerResponse(response);
          cloudStorageUrl = Uri.parse(url);
          var request = new http.MultipartRequest('POST', cloudStorageUrl);
          request.headers['Pub-Request-Timeout'] = 'None';
          var fields = _expectField(parameters, 'fields', response);
          if (fields is! Map) invalidServerResponse(response);
          fields.forEach((key, value) {
            if (value is! String) invalidServerResponse(response);
            request.fields[key] = value;
          });
          request.followRedirects = false;
          request.files.add(
              new http.MultipartFile.fromBytes(
                  'file',
                  packageBytes,
                  filename: 'package.tar.gz'));
          return client.send(request);
        }).then(http.Response.fromStream).then((response) {
          var location = response.headers['location'];
          if (location == null) throw new PubHttpException(response);
          return location;
        }).then(
            (location) =>
                client.get(location, headers: PUB_API_HEADERS)).then(handleJsonSuccess);
      });
    }).catchError((error) {
      if (error is! PubHttpException) throw error;
      var url = error.response.request.url;
      if (urisEqual(url, cloudStorageUrl)) {
        fail('Failed to upload the package.');
      } else if (urisEqual(Uri.parse(url.origin), Uri.parse(server.origin))) {
        handleJsonError(error.response);
      } else {
        throw error;
      }
    });
  }
  Future onRun() {
    if (force && dryRun) {
      usageError('Cannot use both --force and --dry-run.');
    }
    if (entrypoint.root.pubspec.isPrivate) {
      dataError(
          'A private package cannot be published.\n'
              'You can enable this by changing the "publish_to" field in your ' 'pubspec.');
    }
    var files = entrypoint.root.listFiles(useGitIgnore: true);
    log.fine('Archiving and publishing ${entrypoint.root}.');
    var package = entrypoint.root;
    log.message(
        'Publishing ${package.name} ${package.version} to $server:\n'
            '${tree.fromFiles(files, baseDir: entrypoint.root.dir)}');
    var packageBytesFuture =
        createTarGz(files, baseDir: entrypoint.root.dir).toBytes();
    return _validate(
        packageBytesFuture.then((bytes) => bytes.length)).then((isValid) {
      if (isValid) return packageBytesFuture.then(_publish);
    });
  }
  _expectField(Map map, String key, http.Response response) {
    if (map.containsKey(key)) return map[key];
    invalidServerResponse(response);
  }
  Future<bool> _validate(Future<int> packageSize) {
    return Validator.runAll(entrypoint, packageSize).then((pair) {
      var errors = pair.first;
      var warnings = pair.last;
      if (!errors.isEmpty) {
        log.error(
            "Sorry, your package is missing "
                "${(errors.length > 1) ? 'some requirements' : 'a requirement'} "
                "and can't be published yet.\nFor more information, see: "
                "http://pub.dartlang.org/doc/pub-lish.html.\n");
        return false;
      }
      if (force) return true;
      if (dryRun) {
        var s = warnings.length == 1 ? '' : 's';
        log.warning("\nPackage has ${warnings.length} warning$s.");
        return false;
      }
      var message = '\nLooks great! Are you ready to upload your package';
      if (!warnings.isEmpty) {
        var s = warnings.length == 1 ? '' : 's';
        message = "\nPackage has ${warnings.length} warning$s. Upload anyway";
      }
      return confirm(message).then((confirmed) {
        if (!confirmed) {
          log.error("Package upload canceled.");
          return false;
        }
        return true;
      });
    });
  }
}
