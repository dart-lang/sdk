// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Code transform for @observable. The core transformation is relatively
/// straightforward, and essentially like an editor refactoring.
library observe.transformer;

import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:barback/barback.dart';
import 'package:source_maps/refactor.dart';
import 'package:source_span/source_span.dart';

/// A [Transformer] that replaces observables based on dirty-checking with an
/// implementation based on change notifications.
///
/// The transformation adds hooks for field setters and notifies the observation
/// system of the change.
class ObservableTransformer extends Transformer {

  final List<String> _files;
  ObservableTransformer([List<String> files]) : _files = files;
  ObservableTransformer.asPlugin(BarbackSettings settings)
      : _files = _readFiles(settings.configuration['files']);

  static List<String> _readFiles(value) {
    if (value == null) return null;
    var files = [];
    bool error;
    if (value is List) {
      files = value;
      error = value.any((e) => e is! String);
    } else if (value is String) {
      files = [value];
      error = false;
    } else {
      error = true;
    }
    if (error) print('Invalid value for "files" in the observe transformer.');
    return files;
  }

  // TODO(nweiz): This should just take an AssetId when barback <0.13.0 support
  // is dropped.
  Future<bool> isPrimary(idOrAsset) {
    var id = idOrAsset is AssetId ? idOrAsset : idOrAsset.id;
    return new Future.value(id.extension == '.dart' &&
        (_files == null || _files.contains(id.path)));
  }

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((content) {
      // Do a quick string check to determine if this is this file even
      // plausibly might need to be transformed. If not, we can avoid an
      // expensive parse.
      if (!observableMatcher.hasMatch(content)) return;

      var id = transform.primaryInput.id;
      // TODO(sigmund): improve how we compute this url
      var url = id.path.startsWith('lib/')
            ? 'package:${id.package}/${id.path.substring(4)}' : id.path;
      var sourceFile = new SourceFile(content, url: url);
      var transaction = _transformCompilationUnit(
          content, sourceFile, transform.logger);
      if (!transaction.hasEdits) {
        transform.addOutput(transform.primaryInput);
        return;
      }
      var printer = transaction.commit();
      // TODO(sigmund): emit source maps when barback supports it (see
      // dartbug.com/12340)
      printer.build(url);
      transform.addOutput(new Asset.fromString(id, printer.text));
    });
  }
}

TextEditTransaction _transformCompilationUnit(
    String inputCode, SourceFile sourceFile, TransformLogger logger) {
  var unit = parseCompilationUnit(inputCode, suppressErrors: true);
  var code = new TextEditTransaction(inputCode, sourceFile);
  for (var directive in unit.directives) {
    if (directive is LibraryDirective && _hasObservable(directive)) {
      logger.warning('@observable on a library no longer has any effect. '
          'It should be placed on individual fields.',
          span: _getSpan(sourceFile, directive));
      break;
    }
  }

  for (var declaration in unit.declarations) {
    if (declaration is ClassDeclaration) {
      _transformClass(declaration, code, sourceFile, logger);
    } else if (declaration is TopLevelVariableDeclaration) {
      if (_hasObservable(declaration)) {
        logger.warning('Top-level fields can no longer be observable. '
            'Observable fields should be put in an observable objects.',
            span: _getSpan(sourceFile, declaration));
      }
    }
  }
  return code;
}

_getSpan(SourceFile file, AstNode node) => file.span(node.offset, node.end);

/// True if the node has the `@observable` or `@published` annotation.
// TODO(jmesserly): it is not good to be hard coding Polymer support here.
bool _hasObservable(AnnotatedNode node) =>
    node.metadata.any(_isObservableAnnotation);

// TODO(jmesserly): this isn't correct if the annotation has been imported
// with a prefix, or cases like that. We should technically be resolving, but
// that is expensive in analyzer, so it isn't feasible yet.
bool _isObservableAnnotation(Annotation node) =>
    _isAnnotationContant(node, 'observable') ||
    _isAnnotationContant(node, 'published') ||
    _isAnnotationType(node, 'ObservableProperty') ||
    _isAnnotationType(node, 'PublishedProperty');

bool _isAnnotationContant(Annotation m, String name) =>
    m.name.name == name && m.constructorName == null && m.arguments == null;

bool _isAnnotationType(Annotation m, String name) => m.name.name == name;

void _transformClass(ClassDeclaration cls, TextEditTransaction code,
    SourceFile file, TransformLogger logger) {

  if (_hasObservable(cls)) {
    logger.warning('@observable on a class no longer has any effect. '
        'It should be placed on individual fields.',
        span: _getSpan(file, cls));
  }

  // We'd like to track whether observable was declared explicitly, otherwise
  // report a warning later below. Because we don't have type analysis (only
  // syntactic understanding of the code), we only report warnings that are
  // known to be true.
  var explicitObservable = false;
  var implicitObservable = false;
  if (cls.extendsClause != null) {
    var id = _getSimpleIdentifier(cls.extendsClause.superclass.name);
    if (id.name == 'Observable') {
      code.edit(id.offset, id.end, 'ChangeNotifier');
      explicitObservable = true;
    } else if (id.name == 'ChangeNotifier') {
      explicitObservable = true;
    } else if (id.name != 'HtmlElement' && id.name != 'CustomElement'
        && id.name != 'Object') {
      // TODO(sigmund): this is conservative, consider using type-resolution to
      // improve this check.
      implicitObservable = true;
    }
  }

  if (cls.withClause != null) {
    for (var type in cls.withClause.mixinTypes) {
      var id = _getSimpleIdentifier(type.name);
      if (id.name == 'Observable') {
        code.edit(id.offset, id.end, 'ChangeNotifier');
        explicitObservable = true;
        break;
      } else if (id.name == 'ChangeNotifier') {
        explicitObservable = true;
        break;
      } else {
        // TODO(sigmund): this is conservative, consider using type-resolution
        // to improve this check.
        implicitObservable = true;
      }
    }
  }

  if (cls.implementsClause != null) {
    // TODO(sigmund): consider adding type-resolution to give a more precise
    // answer.
    implicitObservable = true;
  }

  var declaresObservable = explicitObservable || implicitObservable;

  // Track fields that were transformed.
  var instanceFields = new Set<String>();
  var getters = new List<String>();
  var setters = new List<String>();

  for (var member in cls.members) {
    if (member is FieldDeclaration) {
      if (member.isStatic) {
        if (_hasObservable(member)){
          logger.warning('Static fields can no longer be observable. '
              'Observable fields should be put in an observable objects.',
              span: _getSpan(file, member));
        }
        continue;
      }
      if (_hasObservable(member)) {
        if (!declaresObservable) {
          logger.warning('Observable fields should be put in an observable '
              'objects. Please declare that this class extends from '
              'Observable, includes Observable, or implements '
              'Observable.',
              span: _getSpan(file, member));
        }
        _transformFields(file, member, code, logger);

        var names = member.fields.variables.map((v) => v.name.name);

        getters.addAll(names);
        if (!_isReadOnly(member.fields)) {
          setters.addAll(names);
          instanceFields.addAll(names);
        }
      }
    }
    // TODO(jmesserly): this is a temporary workaround until we can remove
    // getValueWorkaround and setValueWorkaround.
    if (member is MethodDeclaration) {
      if (_hasKeyword(member.propertyKeyword, Keyword.GET)) {
        getters.add(member.name.name);
      } else if (_hasKeyword(member.propertyKeyword, Keyword.SET)) {
        setters.add(member.name.name);
      }
    }
  }

  // If nothing was @observable, bail.
  if (instanceFields.length == 0) return;

  if (!explicitObservable) _mixinObservable(cls, code);

  // Fix initializers, because they aren't allowed to call the setter.
  for (var member in cls.members) {
    if (member is ConstructorDeclaration) {
      _fixConstructor(member, code, instanceFields);
    }
  }
}

/// Adds "with ChangeNotifier" and associated implementation.
void _mixinObservable(ClassDeclaration cls, TextEditTransaction code) {
  // Note: we need to be careful to put the with clause after extends, but
  // before implements clause.
  if (cls.withClause != null) {
    var pos = cls.withClause.end;
    code.edit(pos, pos, ', ChangeNotifier');
  } else if (cls.extendsClause != null) {
    var pos = cls.extendsClause.end;
    code.edit(pos, pos, ' with ChangeNotifier ');
  } else {
    var params = cls.typeParameters;
    var pos =  params != null ? params.end : cls.name.end;
    code.edit(pos, pos, ' extends ChangeNotifier ');
  }
}

SimpleIdentifier _getSimpleIdentifier(Identifier id) =>
    id is PrefixedIdentifier ? id.identifier : id;


bool _hasKeyword(Token token, Keyword keyword) =>
    token is KeywordToken && token.keyword == keyword;

String _getOriginalCode(TextEditTransaction code, AstNode node) =>
    code.original.substring(node.offset, node.end);

void _fixConstructor(ConstructorDeclaration ctor, TextEditTransaction code,
    Set<String> changedFields) {

  // Fix normal initializers
  for (var initializer in ctor.initializers) {
    if (initializer is ConstructorFieldInitializer) {
      var field = initializer.fieldName;
      if (changedFields.contains(field.name)) {
        code.edit(field.offset, field.end, '__\$${field.name}');
      }
    }
  }

  // Fix "this." initializer in parameter list. These are tricky:
  // we need to preserve the name and add an initializer.
  // Preserving the name is important for named args, and for dartdoc.
  // BEFORE: Foo(this.bar, this.baz) { ... }
  // AFTER:  Foo(bar, baz) : __$bar = bar, __$baz = baz { ... }

  var thisInit = [];
  for (var param in ctor.parameters.parameters) {
    if (param is DefaultFormalParameter) {
      param = param.parameter;
    }
    if (param is FieldFormalParameter) {
      var name = param.identifier.name;
      if (changedFields.contains(name)) {
        thisInit.add(name);
        // Remove "this." but keep everything else.
        code.edit(param.thisToken.offset, param.period.end, '');
      }
    }
  }

  if (thisInit.length == 0) return;

  // TODO(jmesserly): smarter formatting with indent, etc.
  var inserted = thisInit.map((i) => '__\$$i = $i').join(', ');

  int offset;
  if (ctor.separator != null) {
    offset = ctor.separator.end;
    inserted = ' $inserted,';
  } else {
    offset = ctor.parameters.end;
    inserted = ' : $inserted';
  }

  code.edit(offset, offset, inserted);
}

bool _isReadOnly(VariableDeclarationList fields) {
  return _hasKeyword(fields.keyword, Keyword.CONST) ||
      _hasKeyword(fields.keyword, Keyword.FINAL);
}

void _transformFields(SourceFile file, FieldDeclaration member,
    TextEditTransaction code, TransformLogger logger) {

  final fields = member.fields;
  if (_isReadOnly(fields)) return;

  // Private fields aren't supported:
  for (var field in fields.variables) {
    final name = field.name.name;
    if (Identifier.isPrivateName(name)) {
      logger.warning('Cannot make private field $name observable.',
          span: _getSpan(file, field));
      return;
    }
  }

  // Unfortunately "var" doesn't work in all positions where type annotations
  // are allowed, such as "var get name". So we use "dynamic" instead.
  var type = 'dynamic';
  if (fields.type != null) {
    type = _getOriginalCode(code, fields.type);
  } else if (_hasKeyword(fields.keyword, Keyword.VAR)) {
    // Replace 'var' with 'dynamic'
    code.edit(fields.keyword.offset, fields.keyword.end, type);
  }

  // Note: the replacements here are a bit subtle. It needs to support multiple
  // fields declared via the same @observable, as well as preserving newlines.
  // (Preserving newlines is important because it allows the generated code to
  // be debugged without needing a source map.)
  //
  // For example:
  //
  //     @observable
  //     @otherMetaData
  //         Foo
  //             foo = 1, bar = 2,
  //             baz;
  //
  // Will be transformed into something like:
  //
  //     @reflectable @observable
  //     @OtherMetaData()
  //         Foo
  //             get foo => __foo; Foo __foo = 1; @reflectable set foo ...; ...
  //             @observable @OtherMetaData() Foo get baz => __baz; Foo baz; ...
  //
  // Metadata is moved to the getter.

  String metadata = '';
  if (fields.variables.length > 1) {
    metadata = member.metadata
      .map((m) => _getOriginalCode(code, m))
      .join(' ');
    metadata = '@reflectable $metadata';
  }

  for (int i = 0; i < fields.variables.length; i++) {
    final field = fields.variables[i];
    final name = field.name.name;

    var beforeInit = 'get $name => __\$$name; $type __\$$name';

    // The first field is expanded differently from subsequent fields, because
    // we can reuse the metadata and type annotation.
    if (i == 0) {
      final begin = member.metadata.first.offset;
      code.edit(begin, begin, '@reflectable ');
    } else {
      beforeInit = '$metadata $type $beforeInit';
    }

    code.edit(field.name.offset, field.name.end, beforeInit);

    // Replace comma with semicolon
    final end = _findFieldSeperator(field.endToken.next);
    if (end.type == TokenType.COMMA) code.edit(end.offset, end.end, ';');

    code.edit(end.end, end.end, ' @reflectable set $name($type value) { '
        '__\$$name = notifyPropertyChange(#$name, __\$$name, value); }');
  }
}

Token _findFieldSeperator(Token token) {
  while (token != null) {
    if (token.type == TokenType.COMMA || token.type == TokenType.SEMICOLON) {
      break;
    }
    token = token.next;
  }
  return token;
}

// TODO(sigmund): remove hard coded Polymer support (@published). The proper way
// to do this would be to switch to use the analyzer to resolve whether
// annotations are subtypes of ObservableProperty.
final observableMatcher =
    new RegExp("@(published|observable|PublishedProperty|ObservableProperty)");
