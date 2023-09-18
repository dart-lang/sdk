// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'ast_model.dart';
import 'visitor_generator.dart';

Uri computeCoverageUri(Uri repoDir) {
  return repoDir.resolve('pkg/kernel/lib/src/coverage.dart');
}

Future<void> main(List<String> args) async {
  Uri output = args.isEmpty
      ? computeCoverageUri(Uri.base)
      : new File(args[0]).absolute.uri;
  String result = await generateAstCoverage(Uri.base);
  new File.fromUri(output).writeAsStringSync(result);
}

Future<String> generateAstCoverage(Uri repoDir, [AstModel? astModel]) async {
  astModel ??= await deriveAstModel(repoDir);
  return generateVisitor(astModel, new CoverageVisitorStrategy());
}

class CoverageVisitorStrategy extends Visitor0Strategy {
  Map<String, Set<String>> nestedClassNames = {};

  @override
  String get generatorCommand =>
      'dart pkg/front_end/tool/generate_ast_coverage.dart';

  @override
  String get returnType => 'void';

  @override
  String get visitorName => 'CoverageVisitor';

  @override
  String get visitorComment => '''
/// Recursive visitor that collects kinds for all visited nodes.
///
/// This can be used to verify that tests have the intended coverage.''';

  @override
  void handleVisit(AstModel astModel, AstClass astClass, StringBuffer sb) {
    if (astClass.kind == AstClassKind.auxiliary) {
      sb.writeln('''
        throw new UnsupportedError(
            "Unsupported auxiliary node \$node (\${node.runtimeType}).");''');
    } else {
      AstClass? superAstClass = astClass.superclass;
      while (superAstClass != null && !superAstClass.isInterchangeable) {
        superAstClass = superAstClass.superclass;
      }
      String innerName = superAstClass?.name ?? 'Node';
      (nestedClassNames[innerName] ??= {}).add(astClass.name);
      sb.writeln('''
    visited.add(${innerName}Kind.${astClass.name});
    node.visitChildren(this);''');
    }
  }

  @override
  void handleVisitReference(
      AstModel astModel, AstClass astClass, StringBuffer sb) {
    if (astClass.kind == AstClassKind.auxiliary) {
      sb.writeln('''
        throw new UnsupportedError(
            "Unsupported auxiliary node \$node (\${node.runtimeType}).");''');
    } else {
      AstClass? superAstClass = astClass.superclass;
      while (superAstClass != null && !superAstClass.isInterchangeable) {
        superAstClass = superAstClass.superclass;
      }
      if (superAstClass == astModel.constantClass) {
        // Constants are only visited as references.
        String innerName = superAstClass!.name;
        (nestedClassNames[innerName] ??= {}).add(astClass.name);
        sb.writeln('''
        visited.add(${innerName}Kind.${astClass.name});
        node.visitChildren(this);''');
      }
    }
  }

  @override
  void generateHeader(AstModel astModel, StringBuffer sb) {
    super.generateHeader(astModel, sb);
    sb.writeln('''
    Set<Object> visited = {};''');
  }

  @override
  void generateFooter(AstModel astModel, StringBuffer sb) {
    super.generateFooter(astModel, sb);
    nestedClassNames.forEach((String innerName, Set<String> classNames) {
      sb.writeln('''

enum ${innerName}Kind {''');
      for (String className in classNames.toList()..sort()) {
        sb.writeln('''
  $className,''');
      }
      sb.writeln('''
}''');
    });
    sb.writeln('''

/// Returns the set of node kinds that were not visited by [visitor].
Set<Object> missingNodes($visitorName visitor) {
  Set<Object> all = {''');
    nestedClassNames.forEach((String innerName, Set<String> classNames) {
      sb.writeln('''
    ...${innerName}Kind.values,''');
    });
    sb.writeln('''
  };
  all.removeAll(visitor.visited);
  return all;
}''');
    nestedClassNames.forEach((String innerName, Set<String> classNames) {
      if (innerName == 'Node') return;
      sb.writeln('''
/// Returns the set of [${innerName}Kind]s that were not visited by [visitor].
Set<${innerName}Kind> missing${innerName}s($visitorName visitor) {
  Set<${innerName}Kind> all = 
    new Set<${innerName}Kind>.of(${innerName}Kind.values);
  all.removeAll(visitor.visited);
  return all;
}''');
    });
  }
}
