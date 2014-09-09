library pub.barback.source_directory;
import 'dart:async';
import 'package:watcher/watcher.dart';
import 'asset_environment.dart';
import 'barback_server.dart';
class SourceDirectory {
  final AssetEnvironment _environment;
  final String directory;
  final String hostname;
  final int port;
  Future<BarbackServer> get server => _serverCompleter.future;
  final _serverCompleter = new Completer<BarbackServer>();
  StreamSubscription<WatchEvent> watchSubscription;
  SourceDirectory(this._environment, this.directory, this.hostname, this.port);
  Future<BarbackServer> serve() {
    return BarbackServer.bind(
        _environment,
        hostname,
        port,
        rootDirectory: directory).then((server) {
      _serverCompleter.complete(server);
      return server;
    });
  }
  Future close() {
    return server.then((server) {
      var futures = [server.close()];
      if (watchSubscription != null) {
        var cancel = watchSubscription.cancel();
        if (cancel != null) futures.add(cancel);
      }
      return Future.wait(futures);
    });
  }
}
