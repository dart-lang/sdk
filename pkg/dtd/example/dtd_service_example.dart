// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';

//Extension side
class Bar extends DTDResponse {
  late String baz;
  late int bazCount;
  late String bazDescription;

  // ignore: use_super_parameters
  Bar.fromDTDResponse(DTDResponse response) : super.fromDTDResponse(response) {
    baz = result['baz'] as String;
    bazCount = result['bazCount'] as int;
    bazDescription = result['bazDescription'] as String;
  }

  @override
  String toString() {
    return 'Bar(baz:$baz, bazCount:$bazCount, bazDescription:$bazDescription)';
  }
}

extension FooServiceExtension on DTDConnection {
  Future<Bar> barExtension() async {
    final result = await call(
      'Foo',
      'bar',
      params: {
        'baz': 'the baz',
        'bazCount': 1,
        'bazDescription': 'there is one baz',
      },
    );
    return Bar.fromDTDResponse(result);
  }
}

void main(List<String> args) async {
  final url = args[0]; // pass the url as a param to the example
  print('Connecting to DTD at $url');

  final fooService = await DartToolingDaemon.connect(Uri.parse('ws://$url'));
  final client = await DartToolingDaemon.connect(Uri.parse('ws://$url'));

  await fooService.registerService(
    'Foo',
    'bar',
    (params) async {
      final baz = params['baz'].value;
      final bazCount = params['bazCount'].value;
      final bazDescription = params['bazDescription'].value;
      final result = {
        'type': 'Bar',
        'baz': baz,
        'bazCount': bazCount,
        'bazDescription': bazDescription,
      };
      return result;
    },
  );
  final response = await client.barExtension();
  final bar = Bar.fromDTDResponse(response);

  print('Got a bar response: $bar');
}
