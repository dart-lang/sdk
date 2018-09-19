// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/diagnostics/source_span.dart';
import 'package:compiler/src/library_loader.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../helpers/memory_compiler.dart';

// TODO(johnniwinther): Update allowed-listing to mention specific properties.
run(Uri entryPoint,
    {Map<String, String> memorySourceFiles = const {},
    Map<String, List<String>> allowedList,
    bool verbose = false}) {
  asyncTest(() async {
    Compiler compiler = await compilerFor(memorySourceFiles: memorySourceFiles);
    LoadedLibraries loadedLibraries =
        await compiler.libraryLoader.loadLibraries(entryPoint);
    new DynamicVisitor(
            compiler.reporter, loadedLibraries.component, allowedList)
        .run(verbose: verbose);
  });
}

// TODO(johnniwinther): Add improved type promotion to handle negative
// reasoning.
// TODO(johnniwinther): Use this visitor in kernel impact computation.
abstract class StaticTypeVisitor extends ir.Visitor<ir.DartType> {
  ir.Component get component;
  ir.TypeEnvironment _typeEnvironment;
  bool _isStaticTypePrepared = false;

  @override
  ir.DartType defaultNode(ir.Node node) {
    node.visitChildren(this);
    return null;
  }

  @override
  ir.DartType defaultExpression(ir.Expression node) {
    defaultNode(node);
    return getStaticType(node);
  }

  ir.DartType getStaticType(ir.Expression node) {
    if (!_isStaticTypePrepared) {
      _isStaticTypePrepared = true;
      try {
        _typeEnvironment ??= new ir.TypeEnvironment(
            new ir.CoreTypes(component), new ir.ClassHierarchy(component));
      } catch (e) {}
    }
    if (_typeEnvironment == null) {
      // The class hierarchy crashes on multiple inheritance. Use `dynamic`
      // as static type.
      return const ir.DynamicType();
    }
    ir.TreeNode enclosingClass = node;
    while (enclosingClass != null && enclosingClass is! ir.Class) {
      enclosingClass = enclosingClass.parent;
    }
    try {
      _typeEnvironment.thisType =
          enclosingClass is ir.Class ? enclosingClass.thisType : null;
      return node.getStaticType(_typeEnvironment);
    } catch (e) {
      // The static type computation crashes on type errors. Use `dynamic`
      // as static type.
      return const ir.DynamicType();
    }
  }
}

// TODO(johnniwinther): Handle dynamic access of Object properties/methods
// separately.
class DynamicVisitor extends StaticTypeVisitor {
  final DiagnosticReporter reporter;
  final ir.Component component;
  final Map<String, List<String>> allowedList;
  int _errorCount = 0;
  Map<String, Set<String>> _encounteredAllowedListedErrors =
      <String, Set<String>>{};
  Map<Uri, List<DiagnosticMessage>> _allowedListedErrors =
      <Uri, List<DiagnosticMessage>>{};

  DynamicVisitor(this.reporter, this.component, this.allowedList);

  void run({bool verbose = false}) {
    component.accept(this);
    bool failed = false;
    if (_errorCount != 0) {
      print('$_errorCount error(s) found.');
      failed = true;
    }
    allowedList.forEach((String file, List<String> messageParts) {
      Set<String> encounteredParts = _encounteredAllowedListedErrors[file];
      if (encounteredParts == null) {
        print("Allowed-listing of path '$file' isn't used. "
            "Remove it from the allowed-list.");
        failed = true;
      } else if (messageParts != null) {
        for (String messagePart in messageParts) {
          if (!encounteredParts.contains(messagePart)) {
            print("Allowed-listing of message '$messagePart' in path '$file' "
                "isn't used. Remove it from the allowed-list.");
          }
          failed = true;
        }
      }
    });
    Expect.isFalse(failed, "Errors occurred.");
    if (verbose) {
      _allowedListedErrors.forEach((Uri uri, List<DiagnosticMessage> messages) {
        for (DiagnosticMessage message in messages) {
          reporter.reportError(message);
        }
      });
    } else {
      int total = 0;
      _allowedListedErrors.forEach((Uri uri, List<DiagnosticMessage> messages) {
        print('${messages.length} error(s) allowed in $uri');
        total += messages.length;
      });
      if (total > 0) {
        print('${total} error(s) allowed in total.');
      }
    }
  }

  @override
  ir.DartType visitPropertyGet(ir.PropertyGet node) {
    ir.DartType result = super.visitPropertyGet(node);
    ir.DartType type = node.receiver.accept(this);
    if (type is ir.DynamicType) {
      reportError(node, "Dynamic access of '${node.name}'.");
    }
    return result;
  }

  @override
  ir.DartType visitPropertySet(ir.PropertySet node) {
    ir.DartType result = super.visitPropertySet(node);
    ir.DartType type = node.receiver.accept(this);
    if (type is ir.DynamicType) {
      reportError(node, "Dynamic update to '${node.name}'.");
    }
    return result;
  }

  @override
  ir.DartType visitMethodInvocation(ir.MethodInvocation node) {
    ir.DartType result = super.visitMethodInvocation(node);
    if (node.name.name == '==' &&
        node.arguments.positional.single is ir.NullLiteral) {
      return result;
    }
    ir.DartType type = node.receiver.accept(this);
    if (type is ir.DynamicType) {
      reportError(node, "Dynamic invocation of '${node.name}'.");
    }
    return result;
  }

  void reportError(ir.Node node, String message) {
    SourceSpan span = computeSourceSpanFromTreeNode(node);
    Uri uri = span.uri;
    if (uri.scheme == 'org-dartlang-sdk') {
      uri = Uri.base.resolve(uri.path.substring(1));
      span = new SourceSpan(uri, span.begin, span.end);
    }
    bool whiteListed = false;
    allowedList.forEach((String file, List<String> messageParts) {
      if (uri.path.endsWith(file)) {
        if (messageParts == null) {
          // All errors are whitelisted.
          whiteListed = true;
          message += ' (white-listed)';
          _encounteredAllowedListedErrors.putIfAbsent(
              file, () => new Set<String>());
        } else {
          for (String messagePart in messageParts) {
            if (message.contains(messagePart)) {
              _encounteredAllowedListedErrors
                  .putIfAbsent(file, () => new Set<String>())
                  .add(messagePart);
              message += ' (allowed)';
              whiteListed = true;
            }
          }
        }
      }
    });
    DiagnosticMessage diagnosticMessage =
        reporter.createMessage(span, MessageKind.GENERIC, {'text': message});
    if (whiteListed) {
      _allowedListedErrors
          .putIfAbsent(uri, () => <DiagnosticMessage>[])
          .add(diagnosticMessage);
    } else {
      reporter.reportError(diagnosticMessage);
      _errorCount++;
    }
  }
}
