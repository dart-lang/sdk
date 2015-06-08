library input.transformer.instrumentation;

import 'dart:convert';

import 'package:logging/logging.dart';

import 'operation.dart';

final int COLON = ':'.codeUnitAt(0);

/**
 * [InstrumentationInputConverter] converts an instrumentation stream
 * into a series of operations to be sent to the analysis server.
 */
class InstrumentationInputConverter extends Converter<String, Operation> {
  final Logger logger = new Logger('InstrumentationInputConverter');
  final Set<String> _codesSeen = new Set<String>();
  final Set<String> _methodsSeen = new Set<String>();
  final Set<String> _eventsSeen = new Set<String>();

  @override
  Operation convert(String line) {
    try {
      List<String> fields = _parseFields(line);
      if (fields.length < 2) {
        //return new InfoOperation('Ignored line:\n  $line');
        return null;
      }
      // int timeStamp = int.parse(fields[0], onError: (_) => -1);
      String opCode = fields[1];
      if (opCode == 'Req') {
        return convertRequest(line, fields);
      }
      if (opCode == 'Noti') {
        return convertNotification(fields);
      }
      if (opCode == 'Ver') {
        // 1433195174666:Ver:1421765742287333878467:org.dartlang.dartplugin:0.0.0:1.7.0:1.11.0-edge.131698
        return new StartServerOperation();
      }
      if (_codesSeen.add(opCode)) {
        logger.log(Level.INFO, 'Ignored op code: $opCode\n  $line');
      }
      return null;
    } catch (e, s) {
      throw 'Failed to parse line\n  $line\n$e\n$s';
    }
  }

  /**
   * Return an operation for the notification defined by [line] and [fields]
   * or `null` if none.
   */
  Operation convertNotification(List<String> fields) {
    //1433344448533:Noti:{"event"::"server.status","params"::{"analysis"::{"isAnalyzing"::false}}}
    Map<String, dynamic> json = JSON.decode(fields[2]);
    String event = json['event'];
    if (event == 'server.status') {
      Map<String, dynamic> params = json['params'];
      if (params != null) {
        Map<String, dynamic> analysis = params['analysis'];
        if (analysis != null && analysis['isAnalyzing'] == false) {
          return new WaitForAnalysisCompleteOperation();
        }
      }
    }
    if (event == 'server.connected') {
      // Handled by the driver
      return null;
    }
    if (_eventsSeen.add(event)) {
      logger.log(Level.INFO, 'Ignored notification: $event');
    }
    return null;
  }

  /**
   * Return an operation for the request defined by [line] and [fields]
   * or `null` if none.
   */
  Operation convertRequest(String line, List<String> fields) {
    Map<String, dynamic> json = JSON.decode(fields[2]);
    String method = json['method'];
    if (method == 'analysis.setAnalysisRoots') {
      // 1433343174749:Req:{"id"::"3","method"::"analysis.setAnalysisRoots","params"::{"included"::["/usr/local/google/home/danrubel/work/git/dart_sdk/sdk/pkg/analysis_server","/usr/local/google/home/danrubel/work/git/dart_sdk/sdk/pkg/analyzer"],"excluded"::[],"packageRoots"::{}},"clientRequestTime"::1433343174702}
      return new RequestOperation(json);
    }
    if (method == 'server.setSubscriptions') {
      // 1433343174741:Req:{"id"::"1","method"::"server.setSubscriptions","params"::{"subscriptions"::["STATUS"]},"clientRequestTime"::1433343172679}
      return new RequestOperation(json);
    }
    if (_methodsSeen.add(method)) {
      logger.log(Level.INFO, 'Ignored request: $method\n  $line');
    }
    return null;
  }

  /**
   * Determine if the given line is from an instrumentation file.
   * For example:
   * `1433175833005:Ver:1421765742287333878467:org.dartlang.dartplugin:0.0.0:1.6.2:1.11.0-edge.131698`
   */
  static bool isFormat(String line) {
    List<String> fields = _parseFields(line);
    int timeStamp = int.parse(fields[0], onError: (_) => -1);
    String opCode = fields[1];
    return timeStamp > 0 && opCode == 'Ver';
  }

  /**
   * Extract fields from the given [line].
   */
  static List<String> _parseFields(String line) {
    List<String> fields = new List<String>();
    int index = 0;
    StringBuffer sb = new StringBuffer();
    while (index < line.length) {
      int code = line.codeUnitAt(index);
      if (code == COLON) {
        // Embedded colons are doubled
        int next = index + 1;
        if (next < line.length && line.codeUnitAt(next) == COLON) {
          sb.write(':');
          ++index;
        } else {
          fields.add(sb.toString());
          sb.clear();
        }
      } else {
        sb.writeCharCode(code);
      }
      ++index;
    }
    if (sb.isNotEmpty) {
      fields.add(sb.toString());
    }
    return fields;
  }
}
