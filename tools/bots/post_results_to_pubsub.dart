// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Post results from Dart tryjobs and CI builders to Cloud Pub/Sub.
//
// Reads a results.json input file, sends only the changed results from
// that file to the Pub/Sub channel 'results' in the 'dart-ci' project.
// Multiple messages are sent if there are more than 100 changed results,
// so the cloud function only needs to process 100 records within its time
// limit of 60s. Because of this, we never approach the limit of 10 MB
// base64-encoded data bytes per message.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

void usage(ArgParser parser) {
  print('''
Usage: post_results_to_pubsub.dart [OPTIONS]
Posts Dart CI results as messages to Google Cloud Pub/Sub

The options are as follows:

${parser.usage}''');
  exit(1);
}

const resultsPerMessage = 100;
const postUrl =
    'https://pubsub.googleapis.com/v1/projects/dart-ci/topics/results:publish';

main(List<String> args) async {
  final parser = new ArgParser();
  parser.addFlag('help', help: 'Show the program usage.', negatable: false);
  parser.addOption('auth_token',
      abbr: 'a',
      help: 'Authorization token with a scope including pubsub publish.');
  parser.addOption('result_file',
      abbr: 'f', help: 'File containing the results to send');
  parser.addOption('id', abbr: 'i', help: 'Buildbucket ID of this build');
  parser.addOption('base_revision', help: 'A try build\'s patch base');

  final options = parser.parse(args);
  if (options['help']) {
    usage(parser);
  }

  final client = http.Client();

  final lines = await File(options['result_file']).readAsLines();
  final token = await File(options['auth_token']).readAsString();
  final buildbucketID = options['id'];
  final baseRevision = options['base_revision'];
  if (lines.isEmpty) {
    print('No results in input file');
    return;
  }

  final changedPattern = '"changed":true';
  List<String> changedResults =
      lines.where((change) => change.contains(changedPattern)).toList();
  // We need to send at least one result, to save build metadata to Firestore.
  // Send an unchanged result - the cloud function filters these out.
  if (changedResults.isEmpty) changedResults = lines.sublist(0, 1);

  final chunks = <List<String>>[];
  var position = 0;
  final lastFullChunkStart = changedResults.length - resultsPerMessage;
  while (position <= lastFullChunkStart) {
    chunks.add(changedResults.sublist(position, position += resultsPerMessage));
  }
  if (position < changedResults.length)
    chunks.add(changedResults.sublist(position));

  // Send pubsub messages.
  for (final chunk in chunks) {
    // Space messages out to reduce scaling problems
    const chunkDelay = Duration(seconds: 2);
    if (chunk != chunks.first) {
      await Future.delayed(chunkDelay);
    }
    final message = '[\n${chunk.join(",\n")}\n]';
    final base64data = base64Encode(utf8.encode(message.toString()));
    final attributes = {
      if (chunk == chunks.last) 'num_chunks': chunks.length.toString(),
      if (buildbucketID != null) 'buildbucket_id': buildbucketID,
      if (baseRevision != null) 'base_revision': baseRevision,
    };
    final jsonMessage = jsonEncode({
      'messages': [
        {'attributes': attributes, 'data': base64data}
      ]
    });
    final headers = {'Authorization': 'Bearer $token'};
    final response =
        await client.post(postUrl, headers: headers, body: jsonMessage);

    print('Sent pubsub message containing ${chunk.length} results');
    print('Status ${response.statusCode}');
    print('Response: ${response.body}');
  }
  print('Number of Pub/Sub messages sent: ${chunks.length}');
  client.close();
}
