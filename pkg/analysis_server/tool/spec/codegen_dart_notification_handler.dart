// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/tools.dart';
import 'package:html/dom.dart';

import 'api.dart';
import 'codegen_dart.dart';
import 'codegen_protocol_constants.dart' show generateConstName;
import 'from_html.dart';

GeneratedFile clientTarget() {
  return GeneratedFile(
      '../analysis_server_client/lib/handler/notification_handler.dart',
      (String pkgPath) async {
    var visitor = CodegenNotificationHandlerVisitor(readApi(pkgPath));
    return visitor.collectCode(visitor.visitApi);
  });
}

String _capitalize(String name) =>
    '${name.substring(0, 1).toUpperCase()}${name.substring(1)}';

List<String> _generateDartDoc(Element html) => html.children
    .where((Element elem) => elem.localName == 'p')
    .map<String>((Element elem) => elem.text.trim())
    .toList();

String _generateNotificationMethodName(String domainName, String event) =>
    'on${_capitalize(domainName)}${_capitalize(event)}';

String _generateParamTypeName(String domainName, String event) =>
    '${_capitalize(domainName)}${_capitalize(event)}Params';

/// Visitor which produces Dart code representing the API.
class CodegenNotificationHandlerVisitor extends DartCodegenVisitor
    with CodeGenerator {
  CodegenNotificationHandlerVisitor(Api api) : super(api) {
    codeGeneratorSettings.commentLineLength = 79;
    codeGeneratorSettings.docCommentStartMarker = null;
    codeGeneratorSettings.docCommentLineLeader = '/// ';
    codeGeneratorSettings.docCommentEndMarker = null;
    codeGeneratorSettings.languageName = 'dart';
  }

  void emitDartdoc(List<String> dartdoc) {
    var first = true;
    for (var paragraph in dartdoc) {
      if (first) {
        first = false;
      } else {
        writeln('  ///');
      }
      for (var line in paragraph.split(RegExp('\r?\n'))) {
        writeln('  /// ${line.trim()}');
      }
    }
  }

  void emitImports() {
    writeln("import 'package:analysis_server_client/protocol.dart';");
  }

  void emitNotificationHandler() {
    var visitor = _NotificationVisitor(api)..visitApi();
    final notifications = visitor.notificationConstants;
    notifications.sort((n1, n2) => n1.constName.compareTo(n2.constName));

    writeln('''
/// [NotificationHandler] processes analysis server notifications
/// and dispatches those notifications to different methods based upon
/// the type of notification. Clients may override
/// any of the "on<EventName>" methods that are of interest.
///
/// Clients may mix-in this class, but may not implement it.
mixin NotificationHandler {
  void handleEvent(Notification notification) {
    var params = notification.params;
    var decoder = ResponseDecoder(null);
    switch (notification.event) {
''');
    for (var notification in notifications) {
      writeln('      case ${notification.constName}:');
      writeln('        ${notification.methodName}(');
      writeln('          ${notification.paramsTypeName}');
      writeln("            .fromJson(decoder, 'params', params));");
      writeln('        break;');
    }
    writeln('      default:');
    writeln('        onUnknownNotification(notification.event, params);');
    writeln('        break;');
    writeln('    }');
    writeln('  }');
    for (var notification in notifications) {
      writeln();
      emitDartdoc(notification.dartdoc);
      writeln('  void ${notification.methodName}(');
      writeln('    ${notification.paramsTypeName} params) {');
      writeln('  }');
    }
    writeln();
    writeln('  /// Reports a notification that is not processed');
    writeln('  /// by any other notification handlers.');
    writeln('  void onUnknownNotification(String event, params) {}');
    writeln('}');
  }

  @override
  void visitApi() {
    outputHeader(year: '2018');
    writeln();
    emitImports();
    emitNotificationHandler();
  }
}

class _Notification {
  final String constName;
  final String methodName;
  final String paramsTypeName;
  final List<String> dartdoc;

  _Notification(
      this.constName, this.methodName, this.paramsTypeName, this.dartdoc);
}

class _NotificationVisitor extends HierarchicalApiVisitor {
  final notificationConstants = <_Notification>[];

  _NotificationVisitor(Api api) : super(api);

  @override
  void visitNotification(Notification notification) {
    notificationConstants.add(_Notification(
        generateConstName(
            notification.domainName, 'notification', notification.event),
        _generateNotificationMethodName(
            notification.domainName, notification.event),
        _generateParamTypeName(notification.domainName, notification.event),
        _generateDartDoc(notification.html)));
  }
}
