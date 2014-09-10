library pub.barback.web_socket_api;
import 'dart:async';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'asset_environment.dart';
class WebSocketApi {
  final AssetEnvironment _environment;
  final json_rpc.Server _server;
  bool _exitOnClose = false;
  WebSocketApi(CompatibleWebSocket socket, this._environment)
      : _server = new json_rpc.Server(socket) {
    _server.registerMethod("urlToAssetId", _urlToAssetId);
    _server.registerMethod("pathToUrls", _pathToUrls);
    _server.registerMethod("serveDirectory", _serveDirectory);
    _server.registerMethod("unserveDirectory", _unserveDirectory);
    _server.registerMethod("exitOnClose", () {
      _exitOnClose = true;
    });
  }
  Future listen() {
    return _server.listen().then((_) {
      if (!_exitOnClose) return;
      log.message("WebSocket connection closed, terminating.");
      flushThenExit(exit_codes.SUCCESS);
    });
  }
  Future<Map> _urlToAssetId(json_rpc.Parameters params) {
    var url = params["url"].asUri;
    var line = params["line"].asIntOr(null);
    return _environment.getAssetIdForUrl(url).then((id) {
      if (id == null) {
        throw new json_rpc.RpcException(
            _Error.NOT_SERVED,
            '"${url.host}:${url.port}" is not being served by pub.');
      }
      var result = {
        "package": id.package,
        "path": id.path
      };
      if (line != null) result["line"] = line;
      return result;
    });
  }
  Future<Map> _pathToUrls(json_rpc.Parameters params) {
    var assetPath = params["path"].asString;
    var line = params["line"].asIntOr(null);
    return _environment.getUrlsForAssetPath(assetPath).then((urls) {
      if (urls.isEmpty) {
        throw new json_rpc.RpcException(
            _Error.NOT_SERVED,
            'Asset path "$assetPath" is not currently being served.');
      }
      var result = {
        "urls": urls.map((url) => url.toString()).toList()
      };
      if (line != null) result["line"] = line;
      return result;
    });
  }
  Future<Map> _serveDirectory(json_rpc.Parameters params) {
    var rootDirectory = _validateRelativePath(params, "path");
    return _environment.serveDirectory(rootDirectory).then((server) {
      return {
        "url": server.url.toString()
      };
    }).catchError((error) {
      if (error is! OverlappingSourceDirectoryException) throw error;
      var dir = pluralize(
          "directory",
          error.overlappingDirectories.length,
          plural: "directories");
      var overlapping =
          toSentence(error.overlappingDirectories.map((dir) => '"$dir"'));
      print("data: ${error.overlappingDirectories}");
      throw new json_rpc.RpcException(
          _Error.OVERLAPPING,
          'Path "$rootDirectory" overlaps already served $dir $overlapping.',
          data: {
        "directories": error.overlappingDirectories
      });
    });
  }
  Future<Map> _unserveDirectory(json_rpc.Parameters params) {
    var rootDirectory = _validateRelativePath(params, "path");
    return _environment.unserveDirectory(rootDirectory).then((url) {
      if (url == null) {
        throw new json_rpc.RpcException(
            _Error.NOT_SERVED,
            'Directory "$rootDirectory" is not bound to a server.');
      }
      return {
        "url": url.toString()
      };
    });
  }
  String _validateRelativePath(json_rpc.Parameters params, String key) {
    var pathString = params[key].asString;
    if (!path.isRelative(pathString)) {
      throw new json_rpc.RpcException.invalidParams(
          '"$key" must be a relative path. Got "$pathString".');
    }
    if (!path.isWithin(".", pathString)) {
      throw new json_rpc.RpcException.invalidParams(
          '"$key" cannot reach out of its containing directory. ' 'Got "$pathString".');
    }
    return pathString;
  }
}
class _Error {
  static const NOT_SERVED = 1;
  static const OVERLAPPING = 2;
}
