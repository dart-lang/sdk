// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_server.virtual_host;

import 'dart:async';
import 'dart:io';

/**
 * The [VirtualHost] class is a utility class for handling multiple hosts on
 * multiple sources, by using a named-based approach.
 */
abstract class VirtualHost {
  /**
   * Get the [Stream] of [HttpRequest]s, not matching any hosts. If unused, the
   * default implementation will result in a [HttpHeaders.FORBIDDEN] response.
   */
  Stream<HttpRequest> get unhandled;

  /**
   * Construct a new [VirtualHost].
   *
   * The optional [source] is a shortcut for calling [addSource].
   *
   * Example of usage:
   *
   *   HttpServer.bind(..., 80).then((server) {
   *     var virtualHost = new VirtualHost(server);
   *     virtualServer.addHost('static.myserver.com')
   *         .listen(...);
   *     virtualServer.addHost('cache.myserver.com')
   *         .listen(...);
   *   })
   */
  factory VirtualHost([Stream<HttpRequest> source]) => new _VirtualHost(source);

  /**
   * Provide another source of [HttpRequest]s in the form of a [Stream].
   */
  void addSource(Stream<HttpRequest> source);


  /**
   * Add a host to the [VirtualHost] instance. The host can be either a specific
   * domain (`my.domain.name`) or a wildcard-based domain name
   * (`*.domain.name`). The former will only match the specific domain name
   * while the latter will match any series of sub-domains.
   *
   * If both `my.domain.name` and `*.domain.name` is specified, the most
   * qualified will take precedence, `my.domain.name` in this case.
   */
  Stream<HttpRequest> addHost(String host);
}


class _VirtualHostDomain {
  StreamController<HttpRequest> any;
  StreamController<HttpRequest> exact;
  Map<String, _VirtualHostDomain> subDomains = {};
}


class _VirtualHost implements VirtualHost {
  final _VirtualHostDomain _topDomain = new _VirtualHostDomain();
  StreamController<HttpRequest> _unhandledController;

  Stream<HttpRequest> get unhandled {
    if (_unhandledController == null) {
      _unhandledController = new StreamController<HttpRequest>();
    }
    return _unhandledController.stream;
  }

  _VirtualHost([Stream<HttpRequest> source]) {
    if (source != null) addSource(source);
  }

  void addSource(Stream<HttpRequest> source) {
    source.listen((request) {
      var host = request.headers.host;
      if (host == null) {
        _unhandled(request);
        return;
      }
      var domains = host.split('.');
      var current = _topDomain;
      var any;
      for (var i = domains.length - 1; i >= 0; i--) {
        if (current.any != null) any = current.any;
        if (i == 0) {
          var last = current.subDomains[domains[i]];
          if (last != null && last.exact != null) {
            last.exact.add(request);
            return;
          }
        } else {
          if (!current.subDomains.containsKey(domains[i])) {
            break;
          }
          current = current.subDomains[domains[i]];
        }
      }
      if (any != null) {
        any.add(request);
        return;
      }
      _unhandled(request);
    });
  }

  Stream<HttpRequest> addHost(String host) {
    if (host.lastIndexOf('*') > 0) {
      throw new ArgumentError(
          'Wildcards are only allowed in the beginning of a host');
    }
    var controller = new StreamController<HttpRequest>();
    var domains = host.split('.');
    var current = _topDomain;
    for (var i = domains.length - 1; i >= 0; i--) {
      if (domains[i] == '*') {
        if (current.any != null) {
          throw new ArgumentError('Host is already provided');
        }
        current.any = controller;
      } else {
        if (!current.subDomains.containsKey(domains[i])) {
          current.subDomains[domains[i]] = new _VirtualHostDomain();
        }
        if (i > 0) {
          current = current.subDomains[domains[i]];
        } else {
          if (current.subDomains[domains[i]].exact != null) {
            throw new ArgumentError('Host is already provided');
          }
          current.subDomains[domains[i]].exact = controller;
        }
      }
    }
    return controller.stream;
  }

  void _unhandled(HttpRequest request) {
    if (_unhandledController != null) {
      _unhandledController.add(request);
      return;
    }
    request.response.statusCode = HttpStatus.FORBIDDEN;
    request.response.close();
  }
}
