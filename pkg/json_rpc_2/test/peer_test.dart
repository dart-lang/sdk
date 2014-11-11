// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.test.client.client_test;

import 'dart:async';
import 'dart:convert';

import 'package:unittest/unittest.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

void main() {
  var incoming;
  var outgoing;
  var peer;
  setUp(() {
    var incomingController = new StreamController();
    incoming = incomingController.sink;
    var outgoingController = new StreamController();
    outgoing = outgoingController.stream;
    peer = new json_rpc.Peer.withoutJson(
        incomingController.stream, outgoingController);
  });

  group("like a client,", () {
    test("can send a message and receive a response", () {
      expect(outgoing.first.then((request) {
        expect(request, equals({
          "jsonrpc": "2.0",
          "method": "foo",
          "params": {"bar": "baz"},
          "id": 0
        }));
        incoming.add({
          "jsonrpc": "2.0",
          "result": "qux",
          "id": 0
        });
      }), completes);

      peer.listen();
      expect(peer.sendRequest("foo", {"bar": "baz"}),
          completion(equals("qux")));
    });

    test("can send a batch of messages and receive a batch of responses", () {
      expect(outgoing.first.then((request) {
        expect(request, equals([
          {
            "jsonrpc": "2.0",
            "method": "foo",
            "params": {"bar": "baz"},
            "id": 0
          },
          {
            "jsonrpc": "2.0",
            "method": "a",
            "params": {"b": "c"},
            "id": 1
          },
          {
            "jsonrpc": "2.0",
            "method": "w",
            "params": {"x": "y"},
            "id": 2
          }
        ]));

        incoming.add([
          {
            "jsonrpc": "2.0",
            "result": "qux",
            "id": 0
          },
          {
            "jsonrpc": "2.0",
            "result": "d",
            "id": 1
          },
          {
            "jsonrpc": "2.0",
            "result": "z",
            "id": 2
          }
        ]);
      }), completes);

      peer.listen();

      peer.withBatch(() {
        expect(peer.sendRequest("foo", {"bar": "baz"}),
            completion(equals("qux")));
        expect(peer.sendRequest("a", {"b": "c"}), completion(equals("d")));
        expect(peer.sendRequest("w", {"x": "y"}), completion(equals("z")));
      });
    });
  });

  group("like a server,", () {
    test("can receive a call and return a response", () {
      expect(outgoing.first, completion(equals({
        "jsonrpc": "2.0",
        "result": "qux",
        "id": 0
      })));

      peer.registerMethod("foo", (_) => "qux");
      peer.listen();

      incoming.add({
        "jsonrpc": "2.0",
        "method": "foo",
        "params": {"bar": "baz"},
        "id": 0
      });
    });

    test("can receive a batch of calls and return a batch of responses", () {
      expect(outgoing.first, completion(equals([
        {
          "jsonrpc": "2.0",
          "result": "qux",
          "id": 0
        },
        {
          "jsonrpc": "2.0",
          "result": "d",
          "id": 1
        },
        {
          "jsonrpc": "2.0",
          "result": "z",
          "id": 2
        }
      ])));

      peer.registerMethod("foo", (_) => "qux");
      peer.registerMethod("a", (_) => "d");
      peer.registerMethod("w", (_) => "z");
      peer.listen();

      incoming.add([
        {
          "jsonrpc": "2.0",
          "method": "foo",
          "params": {"bar": "baz"},
          "id": 0
        },
        {
          "jsonrpc": "2.0",
          "method": "a",
          "params": {"b": "c"},
          "id": 1
        },
        {
          "jsonrpc": "2.0",
          "method": "w",
          "params": {"x": "y"},
          "id": 2
        }
      ]);
    });

    test("returns a response for malformed JSON", () {
      var incomingController = new StreamController();
      var outgoingController = new StreamController();
      var jsonPeer = new json_rpc.Peer(
          incomingController.stream, outgoingController);

      expect(outgoingController.stream.first.then(JSON.decode), completion({
        "jsonrpc": "2.0",
        "error": {
          'code': error_code.PARSE_ERROR,
          "message": startsWith("Invalid JSON: "),
          "data": {'request': '{invalid'}
        },
        "id": null
      }));

      jsonPeer.listen();

      incomingController.add("{invalid");
    });

    test("returns a response for incorrectly-structured JSON", () {
      expect(outgoing.first, completion({
        "jsonrpc": "2.0",
        "error": {
          'code': error_code.INVALID_REQUEST,
          "message": 'Request must contain a "jsonrpc" key.',
          "data": {'request': {'completely': 'wrong'}}
        },
        "id": null
      }));

      peer.listen();

      incoming.add({
        "completely": "wrong"
      });
    });
  });
}
