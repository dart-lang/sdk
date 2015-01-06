// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observatory_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

final Logger logger = new Logger('ObsServe');

class ObservatoryServer {
  static const _CHROME_PREFIX = '/crdptargets/';

  // Is logging enabled?
  bool log;

  // Host to listen on.
  String host;
  // Port to listen on.
  int port;

  // Host that pub is listening on.
  String pubHost;
  // Port that pub is listening on.
  int pubPort;

  HttpServer _server;
  final HttpClient _client = new HttpClient();

  ObservatoryServer(List<String> args) {
    var parser = new ArgParser();
    parser.addFlag('log', help: 'Log activity.', defaultsTo: true);
    parser.addOption('port', help: 'Specify port listen on',
                     defaultsTo: '9090');
    parser.addOption('host',
                     help: 'Specify host to listen on',
                     defaultsTo: '127.0.0.1');
    parser.addOption('pub-port', help: 'Specify port that pub is listening on',
                     defaultsTo: '9191');
    parser.addOption('pub-host', help: 'Specify host that pub is listening on',
                     defaultsTo: '127.0.0.1');
    var results = parser.parse(args);
    host = results['host'];
    port = int.parse(results['port']);
    log = results['log'];
    pubHost = results['pub-host'];
    pubPort = int.parse(results['pub-port']);
  }

  List<Map> _makeTargetList(List<Map> tabs) {
    var r = <Map>[];
    tabs.forEach((tab) {
      var uri = Uri.parse(tab['url']);
      if (uri.host == 'devtools') {
        // Ignore.
        return;
      }
      var target = {
        'lastConnectionTime': 0,
        'chrome': true,
        'name': tab['title'],
        'networkAddress': tab['webSocketDebuggerUrl'],
      };
      r.add(target);
    });
    return r;
  }

  void _getChromeTabs(HttpRequest request) {
    var path = request.uri.path;
    var method = request.method;
    if (method != 'GET') {
      return;
    }
    assert(path.startsWith(_CHROME_PREFIX));
    var networkAddress = path.substring(_CHROME_PREFIX.length);
    if ((networkAddress == '') || (networkAddress == null)) {
      request.response.write('[]');
      request.response.close();
      return;
    }
    networkAddress = Uri.decodeComponent(networkAddress);
    var chunks = networkAddress.split(':');
    var chromeAddress = chunks[0];
    var chromePort =
        (chunks[1] == null) || (chunks[1] == '') ? 9222 : int.parse(chunks[1]);
    logger.info('tabs from $chromeAddress:$chromePort');
    _client.open(method, chromeAddress, chromePort, 'json')
        .then((HttpClientRequest pubRequest) {
          // Calling .close() on an HttpClientRequest sends the request to the
          // server. The future completes to an HttpClientResponse when the
          // server has responded.
          return pubRequest.close();
        }).then((HttpClientResponse response) {
          var respond = (contents) {
            var tabs = JSON.decode(contents);
            var targets = _makeTargetList(tabs);
            request.response.write(JSON.encode(targets));
            request.response.close().catchError((e) {
              logger.severe('tabs from $chromeAddress:$chromePort failed');
              logger.severe(e.toString());
            });
          };
          response.transform(UTF8.decoder).listen(respond);
        }).catchError((e) {
          logger.severe('tabs from $chromeAddress:$chromePort failed');
          logger.severe(e.toString());
        });
  }

  /// Forward [request] to pub.
  void _forwardToPub(HttpRequest request) {
    var path = request.uri.path;
    var method = request.method;
    logger.info('pub $method $path');
    _client.open(method, pubHost, pubPort, path)
        .then((HttpClientRequest pubRequest) {
          return pubRequest.close();
        }).then((HttpClientResponse response) {
          return request.response.addStream(response);
        }).then((_) => request.response.close())
        .catchError((e) {
          logger.severe('pub $method $path failed.');
          logger.severe(e.toString());
        });
  }

  void _onHttpRequest(HttpRequest request) {
    // Allow cross origin requests.
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    if (request.uri.path.startsWith(_CHROME_PREFIX)) {
      _getChromeTabs(request);
    } else {
      _forwardToPub(request);
    }
  }

  /// Future completes to [this] on successful startup.
  Future start() {
    return HttpServer.bind(host,  port).then((s) {
      _server = s;
      _server.listen(_onHttpRequest);
      print('ObsServe is running on ${_server.address}:${_server.port}');
    });
  }
}

main(List<String> args) {
  hierarchicalLoggingEnabled = true;
  logger.level = Level.ALL;
  logger.onRecord.listen(print);
  new ObservatoryServer(args)..start();
}

