// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

// (Same data as used in our other Json* benchmarks)
final data = '{"summary":{"turnover":0.3736,"correlation2":0.'
    '7147,"concentration":0.3652,"beta":0.8814,"totalValue":1.3'
    '091078259E8,"correlation":0.7217},"watchlist":[],"shortCash'
    '":-1611000,"holdings":[{"type":"LONG","commission":1040'
    ',"cost":9001920,"quantity":26000,"lots":[{"marketCap":"'
    'L","industry":"TECHNOLOGY","style":"G","buyDate":"20'
    '08-10-08 13:44:20.000","quantity":8000},{"marketCap":"L",'
    '"industry":"TECHNOLOGY","style":"G","buyDate":"2008-1'
    '0-15 13:28:02.000","quantity":18000}],"stock":"GOOG"},{"'
    'type":"LONG","commission":8000,"cost":4672000,"quantity'
    '":200000,"lots":[{"marketCap":"L","industry":"TECHNOLO'
    'GY","style":"G","buyDate":"2008-10-15 13:28:54.000","q'
    'uantity":200000}],"stock":"MSFT"},{"type":"LONG","comm'
    'ission":21877,"cost":1.001592313E7,"quantity":546919,"lots'
    '":[{"marketCap":"L","industry":"FINANCIAL","style":"'
    'G","buyDate":"2008-08-01 09:50:17.000","quantity":103092}'
    ',{"marketCap":"L","industry":"FINANCIAL","style":"G"'
    ',"buyDate":"2008-08-18 10:31:34.000","quantity":49950},{"'
    'marketCap":"L","industry":"FINANCIAL","style":"G","b'
    'uyDate":"2008-08-29 09:35:22.000","quantity":45045},{"mark'
    'etCap":"L","industry":"FINANCIAL","style":"G","buyDa'
    'te":"2008-09-15 09:40:32.000","quantity":48400},{"marketCa'
    'p":"L","industry":"FINANCIAL","style":"G","buyDate"'
    ':"2008-10-06 11:21:50.000","quantity":432},{"marketCap":"'
    'L","industry":"FINANCIAL","style":"G","buyDate":"200'
    '8-10-15 13:30:05.000","quantity":300000}],"stock":"UBS"},'
    '{"type":"LONG","commission":4000,"cost":6604849.1,"quan'
    'tity":122741,"lots":[{"marketCap":"L","industry":"SERV'
    'ICES","style":"V","buyDate":"2008-04-26 04:44:34.000",'
    '"quantity":22741},{"marketCap":"L","industry":"SERVICES'
    '","style":"V","buyDate":"2008-10-15 13:31:02.000","qua'
    'ntity":100000}],"stock":"V"},{"type":"LONG","commissio'
    'n":2805,"cost":5005558.25,"quantity":70121,"lots":[{"mar'
    'ketCap":"M","industry":"RETAIL","style":"G","buyDate'
    '":"2008-10-10 10:48:36.000","quantity":121},{"marketCap":'
    '"M","industry":"RETAIL","style":"G","buyDate":"2008'
    '-10-15 13:33:44.000","quantity":70000}],"stock":"LDG"},{'
    '"type":"LONG","commission":10000,"cost":5382500,"quanti'
    'ty":250000,"lots":[{"marketCap":"L","industry":"RETAIL'
    '","style":"V","buyDate":"2008-10-15 13:34:30.000","qua'
    'ntity":250000}],"stock":"SWY"},{"type":"LONG","commiss'
    'ion":1120,"cost":1240960,"quantity":28000,"lots":[{"mark'
    'etCap":"u","industry":"ETF","style":"B","buyDate":'
    '"2008-10-15 15:57:39.000","quantity":28000}],"stock":"OIL'
    '"},{"type":"LONG","commission":400,"cost":236800,"quan'
    'tity":10000,"lots":[{"marketCap":"M","industry":"UTILI'
    'TIES_AND_ENERGY","style":"G","buyDate":"2008-10-15 15:58'
    ':03.000","quantity":10000}],"stock":"COG"},{"type":"LO'
    'NG","commission":3200,"cost":1369600,"quantity":80000,"l'
    'ots":[{"marketCap":"S","industry":"UTILITIES_AND_ENERGY'
    '","style":"G","buyDate":"2008-10-15 15:58:32.000","qua'
    'ntity":80000}],"stock":"CRZO"},{"type":"LONG","commiss'
    'ion":429,"cost":108164.8,"quantity":10720,"lots":[{"mark'
    'etCap":"u","industry":"FINANCIAL","style":"V","buyDa'
    'te":"2008-10-16 09:37:06.000","quantity":10720}],"stock":'
    '"FGI"},{"type":"LONG","commission":1080,"cost":494910,'
    '"quantity":27000,"lots":[{"marketCap":"L","industry":'
    '"RETAIL","style":"V","buyDate":"2008-10-16 09:37:06.000'
    '","quantity":27000}],"stock":"LOW"},{"type":"LONG","'
    'commission":4080,"cost":4867440,"quantity":102000,"lots":'
    '[{"marketCap":"L","industry":"HEALTHCARE","style":"V'
    '","buyDate":"2008-10-16 09:37:06.000","quantity":102000}]'
    ',"stock":"AMGN"},{"type":"SHORT","commission":4000,"'
    'cost":-1159000,"quantity":-100000,"lots":[{"marketCap":'
    '"L","industry":"TECHNOLOGY","style":"V","buyDate":'
    '"2008-10-16 09:37:06.000","quantity":-100000}],"stock":"'
    'AMAT"},{"type":"LONG","commission":2,"cost":5640002,"'
    'quantity":50,"lots":[{"marketCap":"L","industry":"FIN'
    'ANCIAL","style":"B","buyDate":"2008-10-16 09:37:06.000'
    '","quantity":50}],"stock":"BRKA"},{"type":"SHORT","'
    'commission":4000,"cost":-436000,"quantity":-100000,"lots'
    '":[{"marketCap":"M","industry":"TRANSPORTATION","styl'
    'e":"G","buyDate":"2008-10-16 09:37:06.000","quantity":-'
    '100000}],"stock":"JBLU"},{"type":"LONG","commission":8'
    '000,"cost":1.1534E7,"quantity":200000,"lots":[{"marketCap'
    '":"S","industry":"FINANCIAL","style":"G","buyDate":'
    '"2008-10-16 14:35:24.000","quantity":200000}],"stock":"US'
    'O"},{"type":"LONG","commission":4000,"cost":1.0129E7,"'
    'quantity":100000,"lots":[{"marketCap":"L","industry":"'
    'TECHNOLOGY","style":"G","buyDate":"2008-10-15 13:28:26.0'
    '00","quantity":50000},{"marketCap":"L","industry":"TEC'
    'HNOLOGY","style":"G","buyDate":"2008-10-17 09:33:09.000'
    '","quantity":50000}],"stock":"AAPL"},{"type":"LONG",'
    '"commission":1868,"cost":9971367.2,"quantity":54280,"lots'
    '":[{"marketCap":"L","industry":"SERVICES","style":"G'
    '","buyDate":"2008-04-26 04:44:34.000","quantity":7580},{'
    '"marketCap":"L","industry":"SERVICES","style":"G","'
    'buyDate":"2008-05-29 09:50:28.000","quantity":7500},{"mark'
    'etCap":"L","industry":"SERVICES","style":"G","buyDat'
    'e":"2008-10-15 13:30:38.000","quantity":33000},{"marketCap'
    '":"L","industry":"SERVICES","style":"G","buyDate":'
    '"2008-10-17 09:33:09.000","quantity":6200}],"stock":"MA"'
    '}],"longCash":4.600368106E7,"ownerId":8,"pendingOrders":[{'
    '"total":487000,"type":"cover","subtotal":483000,"price'
    '":4.83,"commission":4000,"date":"2008-10-17 23:56:06.000"'
    ',"quantity":100000,"expires":"2008-10-20 16:00:00.000","s'
    'tock":"JBLU","id":182375},{"total":6271600,"type":"buy'
    '","subtotal":6270000,"price":156.75,"commission":1600,"d'
    'ate":"2008-10-17 23:56:40.000","quantity":40000,"expires"'
    ':"2008-10-20 16:00:00.000","stock":"MA","id":182376}],"'
    'inceptionDate":"2008-04-26 04:44:29.000","withdrawals":0,"'
    'id":219948,"deposits":0}';

class SendPortBenchmark {
  final BenchmarkConfig config;
  late ReceivePort port;
  late StreamIterator it;

  double usPerSend = 0.0;
  double usPerReceive = 0.0;

  SendPortBenchmark(this.config);

  // Runs warmup phase, runs benchmark and reports result.
  Future report() async {
    port = ReceivePort();
    it = StreamIterator(port);

    // Warmup for 100 ms.
    await measureFor(const Duration(milliseconds: 200));

    // Run benchmark for 2 seconds.
    //
    // Sets [usPerSend] and [usPerReceive] as side-effect.
    await measureFor(const Duration(seconds: 2));

    // Report result.
    print('SendPort.Send.${config.name}(RunTimeRaw): $usPerSend us.');
    print('SendPort.Receive.${config.name}(RunTimeRaw): $usPerReceive us.');

    await it.cancel();
    port.close();
  }

  Future measureFor(Duration duration) async {
    final durationInMicroseconds = duration.inMicroseconds;

    int sumSendUs = 0;
    int sumReceiveUs = 0;

    final sw = Stopwatch()..start();

    int numberOfSendReceives = 0;
    int lastUs = 0;
    int currentUs = 0;
    do {
      // Send & measure time
      port.sendPort.send(config.data);
      currentUs = sw.elapsedMicroseconds;
      sumSendUs += currentUs - lastUs;
      lastUs = currentUs;

      // Receive & measure time
      await it.moveNext();
      it.current;
      currentUs = sw.elapsedMicroseconds;
      sumReceiveUs += currentUs - lastUs;
      lastUs = currentUs;

      numberOfSendReceives++;
    } while (lastUs < durationInMicroseconds);

    usPerSend = sumSendUs / numberOfSendReceives;
    usPerReceive = sumReceiveUs / numberOfSendReceives;
  }
}

class TreeNode {
  @pragma('vm:entry-point') // Prevent tree shaking of this field.
  final TreeNode? left;
  @pragma('vm:entry-point') // Prevent tree shaking of this field.
  final TreeNode? right;
  @pragma('vm:entry-point') // Prevent tree shaking of this field.
  final int value;

  TreeNode(this.left, this.right, this.value);
}

TreeNode generateBinaryTreeOfDepth(int depth) {
  int i = 0;

  TreeNode gen(int depth) {
    if (depth == 0) return TreeNode(null, null, i++);
    return TreeNode(gen(depth - 1), gen(depth - 1), i++);
  }

  return gen(depth);
}

class BenchmarkConfig {
  final String name;
  final dynamic data;

  BenchmarkConfig(this.name, this.data);
}

Future<void> main(args) async {
  final String json5KB = data;
  final json5KBDecoded = json.decode(json5KB);
  assert(json5KB.length == 5534);

  final json400B = json.encode(json5KBDecoded['pendingOrders']);
  final json400BDecoded = json.decode(json400B);
  assert(json400B.length == 390);

  final String json50KB = json.encode({
    '1': [json5KBDecoded, json5KBDecoded, json5KBDecoded, json5KBDecoded],
    '2': [json5KBDecoded, json5KBDecoded, json5KBDecoded, json5KBDecoded],
    '3': json5KBDecoded,
  });
  final json50KBDecoded = json.decode(json50KB);
  assert(json50KB.length == 49814);

  final String json500KB = json.encode({
    '1': [json50KBDecoded, json50KBDecoded, json50KBDecoded, json50KBDecoded],
    '2': [json50KBDecoded, json50KBDecoded, json50KBDecoded, json50KBDecoded],
    '3': [json50KBDecoded, json50KBDecoded],
  });
  final json500KBDecoded = json.decode(json500KB);
  assert(json500KB.length == 498169);

  final String json5MB = json.encode({
    '1': [
      json500KBDecoded,
      json500KBDecoded,
      json500KBDecoded,
    ],
    '2': [json500KBDecoded, json500KBDecoded, json500KBDecoded],
    '3': [json500KBDecoded, json500KBDecoded, json500KBDecoded],
    '4': json500KBDecoded,
  });
  final json5MBDecoded = json.decode(json5MB);
  assert(json5MB.length == 4981723);

  final configs = <BenchmarkConfig>[
    BenchmarkConfig('Nop', 1),
    BenchmarkConfig('Json.400B', json400BDecoded),
    BenchmarkConfig('Json.5KB', json5KBDecoded),
    BenchmarkConfig('Json.50KB', json50KBDecoded),
    BenchmarkConfig('Json.500KB', json500KBDecoded),
    BenchmarkConfig('Json.5MB', json5MBDecoded),
    BenchmarkConfig('BinaryTree.2', generateBinaryTreeOfDepth(2)),
    BenchmarkConfig('BinaryTree.4', generateBinaryTreeOfDepth(4)),
    BenchmarkConfig('BinaryTree.6', generateBinaryTreeOfDepth(6)),
    BenchmarkConfig('BinaryTree.8', generateBinaryTreeOfDepth(8)),
    BenchmarkConfig('BinaryTree.10', generateBinaryTreeOfDepth(10)),
    BenchmarkConfig('BinaryTree.12', generateBinaryTreeOfDepth(12)),
    BenchmarkConfig('BinaryTree.14', generateBinaryTreeOfDepth(14)),
  ];

  for (final config in configs) {
    await SendPortBenchmark(config).report();
  }
}
