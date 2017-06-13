// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code generation for the file "integration_test_methods.dart".
 */
import 'dart:convert';

import 'package:analyzer/src/codegen/tools.dart';
import 'package:front_end/src/codegen/tools.dart';
import 'package:path/path.dart' as path;

import 'api.dart';
import 'codegen_dart.dart';
import 'from_html.dart';
import 'to_html.dart';

final GeneratedFile target = new GeneratedFile(
    'test/integration/support/integration_test_methods.dart', (String pkgPath) {
  CodegenInttestMethodsVisitor visitor = new CodegenInttestMethodsVisitor(
      path.basename(pkgPath), readApi(pkgPath));
  return visitor.collectCode(visitor.visitApi);
});

/**
 * Visitor that generates the code for integration_test_methods.dart
 */
class CodegenInttestMethodsVisitor extends DartCodegenVisitor
    with CodeGenerator {
  /**
   * The name of the package into which code is being generated.
   */
  final String packageName;

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

  CodegenInttestMethodsVisitor(this.packageName, Api api)
      : toHtmlVisitor = new ToHtmlVisitor(api),
        super(api) {
    codeGeneratorSettings.commentLineLength = 79;
    codeGeneratorSettings.languageName = 'dart';
  }

  /**
   * Generate a function argument for the given parameter field.
   */
  String formatArgument(TypeObjectField field) =>
      '${dartType(field.type)} ${field.name}';

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
    } else if (type is TypeUnion) {
      return 'Object';
    } else {
      throw new Exception('Unexpected kind of TypeDecl');
    }
  }

  @override
  visitApi() {
    outputHeader(year: '2017');
    writeln();
    writeln('/**');
    writeln(' * Convenience methods for running integration tests');
    writeln(' */');
    writeln("import 'dart:async';");
    writeln();
    writeln("import 'package:$packageName/protocol/protocol_generated.dart';");
    writeln(
        "import 'package:$packageName/src/protocol/protocol_internal.dart';");
    writeln("import 'package:test/test.dart';");
    writeln();
    writeln("import 'integration_tests.dart';");
    writeln("import 'protocol_matchers.dart';");
    for (String uri in api.types.importUris) {
      write("import '");
      write(uri);
      writeln("';");
    }
    writeln();
    writeln('/**');
    writeln(' * Convenience methods for running integration tests');
    writeln(' */');
    writeln('abstract class IntegrationTestMixin {');
    indent(() {
      writeln('Server get server;');
      super.visitApi();
      writeln();
      docComment(toHtmlVisitor.collectHtml(() {
        toHtmlVisitor.writeln('Initialize the fields in InttestMixin, and');
        toHtmlVisitor.writeln('ensure that notifications will be handled.');
      }));
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
      }));
      writeln('void dispatchNotification(String event, params) {');
      indent(() {
        writeln('ResponseDecoder decoder = new ResponseDecoder(null);');
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
    String streamName =
        camelJoin(['on', notification.domainName, notification.event]);
    String className = camelJoin(
        [notification.domainName, notification.event, 'params'],
        doCapitalize: true);
    writeln();
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.translateHtml(notification.html);
      toHtmlVisitor.describePayload(notification.params, 'Parameters');
    }));
    writeln('Stream<$className> $streamName;');
    writeln();
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.write('Stream controller for [$streamName].');
    }));
    writeln('StreamController<$className> _$streamName;');
    fieldInitializationCode.add(collectCode(() {
      writeln('_$streamName = new StreamController<$className>(sync: true);');
      writeln('$streamName = _$streamName.stream.asBroadcastStream();');
    }));
    notificationSwitchContents.add(collectCode(() {
      writeln('case ${JSON.encode(notification.longEvent)}:');
      indent(() {
        String paramsValidator = camelJoin(
            ['is', notification.domainName, notification.event, 'params']);
        writeln('outOfTestExpect(params, $paramsValidator);');
        String constructorCall;
        if (notification.params == null) {
          constructorCall = 'new $className()';
        } else {
          constructorCall =
              "new $className.fromJson(decoder, 'params', params)";
        }
        writeln('_$streamName.add($constructorCall);');
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
    if (optionalArgs.isNotEmpty) {
      args.add('{${optionalArgs.join(', ')}}');
    }
    writeln();
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.translateHtml(request.html);
      toHtmlVisitor.describePayload(request.params, 'Parameters');
      toHtmlVisitor.describePayload(request.result, 'Returns');
    }));
    if (request.deprecated) {
      writeln('@deprecated');
    }
    String resultClass;
    String futureClass;
    if (request.result == null) {
      futureClass = 'Future';
    } else {
      resultClass = camelJoin([request.domainName, request.method, 'result'],
          doCapitalize: true);
      futureClass = 'Future<$resultClass>';
    }
    writeln('$futureClass $methodName(${args.join(', ')}) async {');
    indent(() {
      String requestClass = camelJoin(
          [request.domainName, request.method, 'params'],
          doCapitalize: true);
      String paramsVar = 'null';
      if (request.params != null) {
        paramsVar = 'params';
        List<String> args = <String>[];
        List<String> optionalArgs = <String>[];
        for (TypeObjectField field in request.params.fields) {
          if (field.optional) {
            optionalArgs.add('${field.name}: ${field.name}');
          } else {
            args.add(field.name);
          }
        }
        args.addAll(optionalArgs);
        writeln('var params = new $requestClass(${args.join(', ')}).toJson();');
      }
      String methodJson = JSON.encode(request.longMethod);
      writeln('var result = await server.send($methodJson, $paramsVar);');
      if (request.result != null) {
        String kind = 'null';
        if (requestClass == 'EditGetRefactoringParams') {
          kind = 'kind';
        }
        writeln('ResponseDecoder decoder = new ResponseDecoder($kind);');
        writeln("return new $resultClass.fromJson(decoder, 'result', result);");
      } else {
        writeln('outOfTestExpect(result, isNull);');
        writeln('return null;');
      }
    });
    writeln('}');
  }
}
