// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Post results from Dart continuous integration testers to Cloud Pub/Sub.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

void usage(ArgParser parser) {
  print('''
Usage: post_results_to_pubsub.dart [OPTIONS]
Posts Dart CI results as messages to Google cloud pubsub

The options are as follows:

${parser.usage}''');
  exit(1);
}

// Pubsub messages must be < 10MB long.  Because the JSON we send is
// Base64 encoded, and we add a final record after checking the size,
// the limit must be less than 3/4 of 10MB.
const messageLengthLimit = 7000000;
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

  final options = parser.parse(args);
  if (options['help']) {
    usage(parser);
  }

  var client = http.Client();

  var lines = await File(options['result_file']).readAsLines();
  var token = await File(options['auth_token']).readAsString();
  // Construct pubsub messages.
  var line = 0;
  while (line < lines.length) {
    var message = StringBuffer();
    message.write('[');
    message.write(lines[line++]);
    var messageLines = 1;
    while (message.length < messageLengthLimit && line < lines.length) {
      message.write(',\n');
      message.write(lines[line++]);
      messageLines++;
    }
    message.write(']');
    var base64data = base64Encode(utf8.encode(message.toString()));
    var jsonMessage =
        '{"messages": [{"attributes": {}, "data": "$base64data"}]}';
    var headers = {'Authorization': 'Bearer $token'};
    var response =
        await client.post(postUrl, headers: headers, body: jsonMessage);
    print('Sent pubsub message containing ${messageLines} results');
    print('Status ${response.statusCode}');
    print('Response: ${response.body}');
  }
  client.close();
}
