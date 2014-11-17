// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code generation for the file "AnalysisServer.java".
 */
library java.generator.server;

import 'api.dart';
import 'codegen_java.dart';
import 'codegen_tools.dart';

final GeneratedFile target = javaGeneratedFile(
    '../../../../editor/tools/plugins/com.google.dart.server/src/com/google/dart/server/AnalysisServer.java',
    (Api api) => new CodegenAnalysisServer(api));

/**
 * Translate spec_input.html into AnalysisServer.java.
 */
main() {
  target.generate();
}

class CodegenAnalysisServer extends CodegenJavaVisitor {
  CodegenAnalysisServer(Api api) : super(api);

  /**
   * Get the name of the consumer class for responses to this request.
   */
  String consumerName(Request request) {
    return camelJoin([request.method, 'consumer'], doCapitalize: true);
  }

  @override
  void visitApi() {
    outputHeader(javaStyle: true);
    writeln('package com.google.dart.server;');
    writeln();
    writeln('import com.google.dart.server.generated.types.*;');
    writeln();
    writeln('import java.util.List;');
    writeln('import java.util.Map;');
    writeln();
    writeln('''/**
 * The interface {@code AnalysisServer} defines the behavior of objects that interface to an
 * analysis server.
 * 
 * @coverage dart.server
 */''');
    makeClass('public interface AnalysisServer', () {
      //
      // addAnalysisServerListener(..)
      //
      publicMethod('addAnalysisServerListener', () {
        writeln('''/**
 * Add the given listener to the list of listeners that will receive notification when new
 * analysis results become available.
 * 
 * @param listener the listener to be added
 */''');
        writeln(
            'public void addAnalysisServerListener(AnalysisServerListener listener);');
      });

      //
      // removeAnalysisServerListener(..)
      //
      publicMethod('removeAnalysisServerListener', () {
        writeln('''/**
 * Remove the given listener from the list of listeners that will receive notification when new
   * analysis results become available.
 * 
 * @param listener the listener to be removed
 */''');
        writeln(
            'public void removeAnalysisServerListener(AnalysisServerListener listener);');
      });

      //
      // start(..)
      //
      publicMethod('start', () {
        writeln('''/**
 * Start the analysis server.
 */''');
        writeln('public void start() throws Exception;');
      });
      super.visitApi();
    });
  }

  @override
  void visitRequest(Request request) {
    String methodName = '${request.domainName}_${request.method}';
    publicMethod(methodName, () {
      docComment(toHtmlVisitor.collectHtml(() {
        toHtmlVisitor.write('{@code ${request.longMethod }}');
        toHtmlVisitor.translateHtml(request.html);
        toHtmlVisitor.javadocParams(request.params);
      }), width: 99, javadocStyle: true);
      write('public void $methodName(');
      List<String> arguments = [];
      if (request.params != null) {
        for (TypeObjectField field in request.params.fields) {
          arguments.add('${javaType(field.type)} ${javaName(field.name)}');
        }
      }
      if (request.result != null) {
        arguments.add('${consumerName(request)} consumer');
      }
      write(arguments.join(', '));
      writeln(');');
    });
  }
}
