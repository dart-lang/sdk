// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';
import 'dart:collection' show Queue;

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:unittest/unittest.dart';

class ExpectClient extends MockClient {
  final Queue<MockClientHandler> _handlers;

  ExpectClient._(MockClientHandler fn)
    : _handlers = new Queue<MockClientHandler>(),
      super(fn);

  factory ExpectClient() {
    var client;
    client = new ExpectClient._((request) =>
        client._handleRequest(request));
    return client;
  }

  void expectRequest(MockClientHandler fn) {
    var completer = new Completer();
    expect(completer.future, completes);

    _handlers.add((request) {
      completer.complete(null);
      return fn(request);
    });
  }

  Future<http.Response> _handleRequest(http.Request request) {
    if (_handlers.isEmpty) {
      return new Future.value(new http.Response('not found', 404));
    } else {
      return _handlers.removeFirst()(request);
    }
  }
}

/// A matcher for AuthorizationExceptions.
const isAuthorizationException = const _AuthorizationException();

/// A matcher for functions that throw AuthorizationException.
const Matcher throwsAuthorizationException =
    const Throws(isAuthorizationException);

class _AuthorizationException extends TypeMatcher {
  const _AuthorizationException() : super("AuthorizationException");
  bool matches(item, MatchState matchState) =>
    item is oauth2.AuthorizationException;
}

/// A matcher for ExpirationExceptions.
const isExpirationException = const _ExpirationException();

/// A matcher for functions that throw ExpirationException.
const Matcher throwsExpirationException =
    const Throws(isExpirationException);

class _ExpirationException extends TypeMatcher {
  const _ExpirationException() : super("ExpirationException");
  bool matches(item, MatchState matchState) =>
    item is oauth2.ExpirationException;
}
