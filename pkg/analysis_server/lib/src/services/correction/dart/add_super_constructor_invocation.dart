// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddSuperConstructorInvocation extends MultiCorrectionProducer {
  AddSuperConstructorInvocation({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var node = this.node;
    if (node is PrimaryConstructorDeclaration) {
      var superType = _supertypeOfClass(node.parent);
      if (superType == null) return const [];

      var body = node.body;
      return _producersFromPrimary(superType, node, body);
    } else if (node is PrimaryConstructorBody) {
      var declaration = node.declaration;
      if (declaration == null) return const [];

      var superType = _supertypeOfClass(node.parent?.parent);
      if (superType == null) return const [];

      return _producersFromPrimary(superType, declaration, node);
    } else if (node is ConstructorDeclaration) {
      var superType = _supertypeOfClass(node.parent?.parent);
      if (superType == null) return const [];

      return _producersFromSecondary(superType, node);
    } else {
      var targetConstructor = node.parent;
      if (targetConstructor is! ConstructorDeclaration) return const [];

      var superType = _supertypeOfClass(targetConstructor.parent?.parent);
      if (superType == null) return const [];

      return _producersFromSecondary(superType, targetConstructor);
    }
  }

  List<ResolvedCorrectionProducer> _producersFromPrimary(
    InterfaceType superType,
    PrimaryConstructorDeclaration declaration,
    PrimaryConstructorBody? body,
  ) {
    SourceRange editRange;
    List<String> prefixParts = [];
    List<String> suffixParts = [];
    if (body == null) {
      var classDeclaration = declaration.parent;
      if (classDeclaration case ClassDeclaration(:var body)) {
        if (body is BlockClassBody) {
          editRange = range.startOffsetLength(body.leftBracket.end, 0);
          prefixParts = ['', '  this : '];
          if (body.leftBracket.end == body.rightBracket.offset) {
            suffixParts = [';', ''];
          } else {
            suffixParts = [';'];
          }
        } else {
          editRange = (body as EmptyClassBody).semicolon.sourceRange;
          prefixParts = [' {', '  this : '];
          suffixParts = [';', '}'];
        }
      } else if (classDeclaration case EnumDeclaration(:var body)) {
        if (body is BlockEnumBody) {
          editRange = range.startOffsetLength(body.leftBracket.end, 0);
          prefixParts = ['', '  this : '];
          suffixParts = [';'];
        } else {
          editRange = (body as EmptyEnumBody).semicolon.sourceRange;
          prefixParts = [' {', '  this : '];
          suffixParts = [';', '}'];
        }
      } else {
        return const [];
      }
    } else {
      var initializers = body.initializers;
      if (initializers.isEmpty) {
        var colon = body.colon;
        if (colon == null) {
          editRange = range.startOffsetLength(body.thisKeyword.end, 0);
          prefixParts = [' : '];
          suffixParts = [''];
        } else {
          editRange = range.startOffsetLength(colon.end, 0);
          prefixParts = [' '];
          suffixParts = [''];
        }
      } else {
        editRange = range.startOffsetLength(initializers.last.end, 0);
        prefixParts = [', '];
        suffixParts = [''];
      }
    }
    var producers = <ResolvedCorrectionProducer>[];
    for (var superConstructor in superType.constructors) {
      // Only propose public constructors.
      var name = superConstructor.name;
      if (name != null && !Identifier.isPrivateName(name)) {
        producers.add(
          _AddInvocation(
            context: context,
            constructor: superConstructor,
            editRange: editRange,
            prefixParts: prefixParts,
            suffixParts: suffixParts,
          ),
        );
      }
    }
    return producers;
  }

  List<ResolvedCorrectionProducer> _producersFromSecondary(
    InterfaceType superType,
    ConstructorDeclaration constructor,
  ) {
    var initializers = constructor.initializers;
    int insertOffset;
    String prefix;
    if (initializers.isEmpty) {
      insertOffset = constructor.parameters.end;
      prefix = ' : ';
    } else {
      var lastInitializer = initializers[initializers.length - 1];
      insertOffset = lastInitializer.end;
      prefix = ', ';
    }
    var producers = <ResolvedCorrectionProducer>[];
    for (var superConstructor in superType.constructors) {
      // Only propose public constructors.
      var name = superConstructor.name;
      if (name != null && !Identifier.isPrivateName(name)) {
        producers.add(
          _AddInvocation(
            context: context,
            constructor: superConstructor,
            editRange: range.startOffsetLength(insertOffset, 0),
            prefixParts: [prefix],
            suffixParts: [''],
          ),
        );
      }
    }
    return producers;
  }

  InterfaceType? _supertypeOfClass(AstNode? node) {
    if (node is! ClassDeclaration) {
      return null;
    }
    var targetClassElement = node.declaredFragment?.element;
    return targetClassElement?.supertype;
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [AddSuperConstructorInvocation] producer.
class _AddInvocation extends ResolvedCorrectionProducer {
  /// The constructor to be invoked.
  final ConstructorElement _constructor;

  /// The offset at which the initializer is to be inserted.
  final SourceRange _editRange;

  /// The prefix to be added before the actual invocation.
  final List<String> _prefixParts;

  /// The suffix to be added after the actual invocation.
  final List<String> _suffixParts;

  _AddInvocation({
    required super.context,
    required this._constructor,
    required this._editRange,
    required this._prefixParts,
    required this._suffixParts,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments {
    var buffer = StringBuffer();
    buffer.write('super');
    var constructorName = _constructor.name;
    if (constructorName != null && constructorName != 'new') {
      buffer.write('.');
      buffer.write(constructorName);
    }
    buffer.write('(...)');
    return [buffer.toString()];
  }

  @override
  FixKind get fixKind => DartFixKind.addSuperConstructorInvocation;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var constructorName = _constructor.name;
    if (constructorName == null ||
        _constructor.formalParameters.any((p) => p.name == null)) {
      return;
    }
    var currentConstructor = node
        .thisOrAncestorOfType<ConstructorDeclaration>();
    var positionalParameters = 0;
    var namedParameters = <String>{};
    if (currentConstructor case ConstructorDeclaration(:var parameters)) {
      for (var parameter in parameters.parameters) {
        if (parameter case SuperFormalParameter(
          :var isPositional,
        ) when isPositional) {
          positionalParameters++;
        } else if (parameter case SuperFormalParameter(
          :var isNamed,
        ) when isNamed) {
          namedParameters.add(parameter.name.lexeme);
        }
      }
    }
    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;
      builder.addReplacement(_editRange, (builder) {
        builder.write(_prefixParts.join(eol));
        // add super constructor name
        builder.write('super');
        if (constructorName != 'new') {
          builder.write('.');
          builder.addSimpleLinkedEdit('NAME', constructorName);
        }
        // add arguments
        builder.write('(');
        var firstParameter = true;
        for (var (index, parameter) in _constructor.formalParameters.indexed) {
          // skip non-required parameters
          if (parameter.isOptional) {
            break;
          }
          if (parameter.isNamed && namedParameters.contains(parameter.name)) {
            // skip already initialized named parameters
            continue;
          }
          if (parameter.isPositional && index < positionalParameters) {
            // skip already initialized positional parameters
            continue;
          }

          // comma
          if (firstParameter) {
            firstParameter = false;
          } else {
            builder.write(', ');
          }

          if (parameter.isNamed) {
            builder.write('${parameter.name}: ');
          }
          // A default value to pass as an argument.
          builder.addSimpleLinkedEdit(
            parameter.name!,
            parameter.type.defaultArgumentCode,
          );
        }
        builder.write(')');
        builder.write(_suffixParts.join(eol));
      });
    });
  }
}

extension on DartType {
  String get defaultArgumentCode {
    if (isDartCoreBool) {
      return 'false';
    }
    if (isDartCoreInt) {
      return '0';
    }
    if (isDartCoreDouble) {
      return '0.0';
    }
    if (isDartCoreString) {
      return "''";
    }
    // No better guess.
    return 'null';
  }
}
