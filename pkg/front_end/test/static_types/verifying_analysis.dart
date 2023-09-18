// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' as json;
import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/fasta/command_line_reporting.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/testing/analysis_helper.dart';
import 'package:kernel/ast.dart';

/// [AnalysisVisitor] that supports tracking error/problem occurrences in an
/// allowed list file.
class VerifyingAnalysis extends AnalysisVisitor {
  final String? _allowedListPath;

  Map _expectedJson = {};

  VerifyingAnalysis(DiagnosticMessageHandler onDiagnostic, Component component,
      this._allowedListPath, UriFilter? analyzedUrisFilter)
      : super(onDiagnostic, component, analyzedUrisFilter);

  void run({bool verbose = false, bool generate = false}) {
    if (!generate && _allowedListPath != null) {
      File file = new File(_allowedListPath);
      if (file.existsSync()) {
        try {
          _expectedJson = json.jsonDecode(file.readAsStringSync());
        } catch (e) {
          Expect.fail('Error reading allowed list from $_allowedListPath: $e');
        }
      }
    }
    component.accept(this);
    if (generate && _allowedListPath != null) {
      Map<String, Map<String, int>> actualJson = {};
      forEachMessage(
          (String uri, Map<String, List<FormattedMessage>> actualMessagesMap) {
        Map<String, int> map = {};
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
          map[message] = actualMessages.length;
        });
        actualJson[uri] = map;
      });

      new File(_allowedListPath).writeAsStringSync(
          new json.JsonEncoder.withIndent('  ').convert(actualJson));
      return;
    }

    int errorCount = 0;
    _expectedJson.forEach((uri, expectedMessages) {
      Map<String, List<FormattedMessage>>? actualMessagesMap =
          getMessagesForUri(uri);
      if (actualMessagesMap == null) {
        print("Error: Allowed-listing of uri '$uri' isn't used. "
            "Remove it from the allowed-list.");
        errorCount++;
      } else {
        expectedMessages.forEach((expectedMessage, expectedCount) {
          List<FormattedMessage>? actualMessages =
              actualMessagesMap[expectedMessage];
          if (actualMessages == null) {
            print("Error: Allowed-listing of message '$expectedMessage' "
                "in uri '$uri' isn't used. Remove it from the allowed-list.");
            errorCount++;
          } else {
            int actualCount = actualMessages.length;
            if (actualCount != expectedCount) {
              print("Error: Unexpected count of allowed message "
                  "'$expectedMessage' in uri '$uri'. "
                  "Expected $expectedCount, actual $actualCount:");
              print(
                  '----------------------------------------------------------');
              for (FormattedMessage message in actualMessages) {
                onDiagnostic(message);
              }
              print(
                  '----------------------------------------------------------');
              errorCount++;
            }
          }
        });
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
          if (!expectedMessages.containsKey(message)) {
            for (FormattedMessage message in actualMessages) {
              onDiagnostic(message);
              errorCount++;
            }
          }
        });
      }
    });
    forEachMessage(
        (String uri, Map<String, List<FormattedMessage>> actualMessagesMap) {
      if (!_expectedJson.containsKey(uri)) {
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
          for (FormattedMessage message in actualMessages) {
            onDiagnostic(message);
            errorCount++;
          }
        });
      }
    });
    if (errorCount != 0) {
      print('$errorCount error(s) found.');
      print("""

********************************************************************************
*  Unexpected code patterns found by test:
*
*    ${relativizeUri(Platform.script)}
*
*  Please address the reported errors, or, if the errors are as expected, run
*
*    dart ${relativizeUri(Platform.script)} -g
*
*  to update the expectation file.
********************************************************************************
""");
      exit(-1);
    }
    if (verbose) {
      forEachMessage(
          (String uri, Map<String, List<FormattedMessage>> actualMessagesMap) {
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
          for (FormattedMessage message in actualMessages) {
            // TODO(johnniwinther): It is unnecessarily complicated to just
            // add ' (allowed)' to an existing message!
            LocatedMessage locatedMessage = message.locatedMessage;
            String newMessageText =
                '${locatedMessage.messageObject.problemMessage} (allowed)';
            message = locatedMessage.withFormatting(
                format(
                    new LocatedMessage(
                        locatedMessage.uri,
                        locatedMessage.charOffset,
                        locatedMessage.length,
                        new Message(locatedMessage.messageObject.code,
                            problemMessage: newMessageText,
                            correctionMessage:
                                locatedMessage.messageObject.correctionMessage,
                            arguments: locatedMessage.messageObject.arguments)),
                    Severity.warning,
                    location: new Location(
                        message.uri!, message.line, message.column),
                    uriToSource: component.uriToSource),
                message.line,
                message.column,
                Severity.warning,
                []);
            onDiagnostic(message);
          }
        });
      });
    } else {
      int total = 0;
      forEachMessage(
          (String uri, Map<String, List<FormattedMessage>> actualMessagesMap) {
        int count = 0;
        actualMessagesMap
            .forEach((String message, List<FormattedMessage> actualMessages) {
          count += actualMessages.length;
        });

        print('${count} error(s) allowed in $uri');
        total += count;
      });
      if (total > 0) {
        print('${total} error(s) allowed in total.');
      }
    }
  }

  void registerError(TreeNode node, String message) {
    registerMessage(node, message);
  }
}
