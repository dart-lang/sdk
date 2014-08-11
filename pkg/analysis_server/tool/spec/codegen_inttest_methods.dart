// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code generation for the file "integration_test_methods.dart".
 */
library codegenInttestMethods;

import 'dart:convert';
import 'dart:io';

import 'api.dart';
import 'codegen_tools.dart';
import 'from_html.dart';
import 'to_html.dart';

/**
 * Visitor that generates the code for integration_test_methods.dart
 */
class CodegenInttestMethodsVisitor extends HierarchicalApiVisitor with
    CodeGenerator {
  /**
   * Visitor used to produce doc comments.
   */
  final ToHtmlVisitor toHtmlVisitor;

  /**
   * Code snippets concatenated to initialize all of the class fields.
   */
  List<String> fieldInitializationCode = <String>[];

  /**
   * Code snippets concatenated to produce the contents of the switch statement
   * for dispatching notifications.
   */
  List<String> notificationSwitchContents = <String>[];

  CodegenInttestMethodsVisitor(Api api)
      : super(api),
        toHtmlVisitor = new ToHtmlVisitor(api);

  @override
  visitApi() {
    outputHeader();
    writeln('/**');
    writeln(' * Convenience methods for running integration tests');
    writeln(' */');
    writeln('library test.integration.methods;');
    writeln();
    writeln("import 'dart:async';");
    writeln();
    writeln("import 'package:unittest/unittest.dart';");
    writeln();
    writeln("import 'integration_tests.dart';");
    writeln("import 'protocol_matchers.dart';");
    writeln();
    writeln();
    writeln('/**');
    writeln(' * Convenience methods for running integration tests');
    writeln(' */');
    writeln('abstract class InttestMixin {');
    indent(() {
      writeln('Server get server;');
      super.visitApi();
      writeln();
      docComment(toHtmlVisitor.collectHtml(() {
        toHtmlVisitor.writeln('Initialize the fields in InttestMixin, and');
        toHtmlVisitor.writeln('ensure that notifications will be handled.');
      }), false);
      writeln('void initializeInttestMixin() {');
      indent(() {
        write(fieldInitializationCode.join());
      });
      writeln('}');
      writeln();
      docComment(toHtmlVisitor.collectHtml(() {
        toHtmlVisitor.writeln('Dispatch the notification named [event], and');
        toHtmlVisitor.writeln('containing parameters [params], to the');
        toHtmlVisitor.writeln('appropriate stream.');
      }), false);
      writeln('void dispatchNotification(String event, params) {');
      indent(() {
        writeln('switch (event) {');
        indent(() {
          write(notificationSwitchContents.join());
          writeln('default:');
          indent(() {
            writeln("fail('Unexpected notification: \$event');");
            writeln('break;');
          });
        });
        writeln('}');
      });
      writeln('}');
    });
    writeln('}');
  }

  @override
  visitNotification(Notification notification) {
    String streamName = camelJoin(['on', notification.domainName, notification.event]);
    writeln();
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.translateHtml(notification.html);
      toHtmlVisitor.describePayload(notification.params, 'Parameters');
    }), false);
    writeln('Stream $streamName;');
    writeln();
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.write('Stream controller for [$streamName].');
    }), false);
    writeln('StreamController _$streamName;');
    fieldInitializationCode.add(collectCode(() {
      writeln('_$streamName = new StreamController(sync: true);');
      writeln('$streamName = _$streamName.stream.asBroadcastStream();');
    }));
    notificationSwitchContents.add(collectCode(() {
      writeln('case ${JSON.encode(notification.longEvent)}:');
      indent(() {
        String paramsValidator = camelJoin(['is', notification.domainName,
            notification.event, 'params']);
        writeln('expect(params, $paramsValidator);');
        writeln('_$streamName.add(params);');
        writeln('break;');
      });
    }));
  }

  @override
  visitRequest(Request request) {
    String methodName = camelJoin(['send', request.domainName, request.method]);
    List<String> args = <String>[];
    List<String> optionalArgs = <String>[];
    if (request.params != null) {
      for (TypeObjectField field in request.params.fields) {
        if (field.optional) {
          optionalArgs.add(formatArgument(field));
        } else {
          args.add(formatArgument(field));
        }
      }
    }
    optionalArgs.add('bool checkTypes: true');
    args.add('{${optionalArgs.join(', ')}}');
    writeln();
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.translateHtml(request.html);
      toHtmlVisitor.describePayload(request.params, 'Parameters');
      toHtmlVisitor.describePayload(request.result, 'Returns');
    }), false);
    writeln('Future $methodName(${args.join(', ')}) {');
    indent(() {
      String paramsValidator = camelJoin(['is', request.domainName,
          request.method, 'params']);
      String resultValidator = camelJoin(['is', request.domainName,
          request.method, 'result']);
      String paramsVar = 'null';
      if (request.params != null) {
        paramsVar = 'params';
        writeln('Map<String, dynamic> params = {};');
        for (TypeObjectField field in request.params.fields) {
          if (field.optional) {
            writeln('if (${field.name} != null) {');
            indent(() {
              populateField(field);
            });
            writeln('}');
          } else {
            populateField(field);
          }
        }
        writeln('if (checkTypes) {');
        indent(() {
          writeln('expect(params, $paramsValidator);');
        });
        writeln('}');
      }
      writeln(
          'return server.send(${JSON.encode(request.longMethod)}, $paramsVar)');
      indent(() {
        writeln('  .then((result) {');
        writeln('if (checkTypes) {');
        indent(() {
          writeln('expect(result, $resultValidator);');
        });
        writeln('}');
        writeln('return result;');
      });
      writeln('});');
    });
    writeln('}');
  }

  /**
   * Generate a function argument for the given parameter field.
   */
  String formatArgument(TypeObjectField field) =>
      '${jsonType(field.type)} ${field.name}';

  /**
   * Generate code that populates the given parameter field based on the
   * function argument from [formatArgument].
   */
  void populateField(TypeObjectField field) {
    writeln('params[${JSON.encode(field.name)}] = ${field.name};');
  }

  /**
   * Figure out the appropriate Dart type for data having the given API
   * protocol [type].
   */
  String jsonType(TypeDecl type) {
    type = resolveTypeReferenceChain(type);
    if (type is TypeEnum) {
      return 'String';
    } else if (type is TypeList) {
      return 'List<${jsonType(type.itemType)}>';
    } else if (type is TypeMap) {
      return 'Map<String, ${jsonType(type.valueType)}>';
    } else if (type is TypeObject) {
      return 'Map<String, dynamic>';
    } else if (type is TypeReference) {
      switch (type.typeName) {
        case 'String':
        case 'int':
        case 'bool':
          // These types correspond exactly to Dart types
          return type.typeName;
        case 'object':
          return 'Map<String, dynamic>';
        default:
          throw new Exception(type.typeName);
      }
    } else {
      throw new Exception('Unexpected kind of TypeDecl');
    }
  }
}

/**
 * Translate spec_input.html into protocol_matchers.dart.
 */
main() {
  CodegenInttestMethodsVisitor visitor = new CodegenInttestMethodsVisitor(
      readApi());
  String code = visitor.collectCode(visitor.visitApi);
  File outputFile = new File(
      '../../test/integration/integration_test_methods.dart');
  outputFile.writeAsStringSync(code);
}
