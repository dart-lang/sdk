library pub.barback.server;
import 'dart:async';
import 'dart:io';
import 'package:barback/barback.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:stack_trace/stack_trace.dart';
import '../barback.dart';
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'base_server.dart';
import 'asset_environment.dart';
typedef bool AllowAsset(AssetId id);
class BarbackServer extends BaseServer<BarbackServerResult> {
  final String package;
  final String rootDirectory;
  AllowAsset allowAsset;
  static Future<BarbackServer> bind(AssetEnvironment environment, String host,
      int port, {String package, String rootDirectory}) {
    if (package == null) package = environment.rootPackage.name;
    return Chain.track(bindServer(host, port)).then((server) {
      if (rootDirectory == null) {
        log.fine('Serving packages on $host:$port.');
      } else {
        log.fine('Bound "$rootDirectory" to $host:$port.');
      }
      return new BarbackServer._(environment, server, package, rootDirectory);
    });
  }
  BarbackServer._(AssetEnvironment environment, HttpServer server, this.package,
      this.rootDirectory)
      : super(environment, server);
  AssetId urlToId(Uri url) {
    var id = packagesUrlToId(url);
    if (id != null) return id;
    if (rootDirectory == null) {
      throw new FormatException(
          "This server cannot serve out of the root directory. Got $url.");
    }
    var parts = path.url.split(url.path);
    if (parts.isNotEmpty && parts.first == "/") parts = parts.skip(1);
    var relativePath = path.url.join(rootDirectory, path.url.joinAll(parts));
    return new AssetId(package, relativePath);
  }
  handleRequest(shelf.Request request) {
    if (request.method != "GET" && request.method != "HEAD") {
      return methodNotAllowed(request);
    }
    var id;
    try {
      id = urlToId(request.url);
    } on FormatException catch (ex) {
      return notFound(request, error: ex.message);
    }
    if (allowAsset != null && !allowAsset(id)) {
      return notFound(
          request,
          error: "Asset $id is not available in this configuration.",
          asset: id);
    }
    return environment.barback.getAssetById(id).then((result) {
      return result;
    }).then((asset) => _serveAsset(request, asset)).catchError((error, trace) {
      if (error is! AssetNotFoundException) throw error;
      return environment.barback.getAssetById(
          id.addExtension("/index.html")).then((asset) {
        if (request.url.path.endsWith('/')) return _serveAsset(request, asset);
        logRequest(request, "302 Redirect to ${request.url}/");
        return new shelf.Response.found('${request.url}/');
      }).catchError((newError, newTrace) {
        throw newError is AssetNotFoundException ? error : newError;
      });
    }).catchError((error, trace) {
      if (error is! AssetNotFoundException) {
        trace = new Chain.forTrace(trace);
        logRequest(request, "$error\n$trace");
        addError(error, trace);
        close();
        return new shelf.Response.internalServerError();
      }
      addResult(new BarbackServerResult._failure(request.url, id, error));
      return notFound(request, asset: id);
    });
  }
  Future<shelf.Response> _serveAsset(shelf.Request request, Asset asset) {
    return validateStream(asset.read()).then((stream) {
      addResult(new BarbackServerResult._success(request.url, asset.id));
      var headers = {};
      var mimeType = lookupMimeType(asset.id.path);
      if (mimeType != null) headers['Content-Type'] = mimeType;
      return new shelf.Response.ok(stream, headers: headers);
    }).catchError((error, trace) {
      addResult(new BarbackServerResult._failure(request.url, asset.id, error));
      if (error is FileSystemException) {
        return notFound(request, error: error.toString(), asset: asset.id);
      }
      trace = new Chain.forTrace(trace);
      logRequest(request, "$error\n$trace");
      return new shelf.Response.internalServerError(body: error.toString());
    });
  }
}
class BarbackServerResult {
  final Uri url;
  final AssetId id;
  final error;
  bool get isSuccess => error == null;
  bool get isFailure => !isSuccess;
  BarbackServerResult._success(this.url, this.id) : error = null;
  BarbackServerResult._failure(this.url, this.id, this.error);
}
