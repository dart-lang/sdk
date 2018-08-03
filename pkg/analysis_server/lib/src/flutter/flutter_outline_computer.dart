// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';

/// Computer for Flutter specific outlines.
class FlutterOutlineComputer {
  static const CONSTRUCTOR_NAME = 'forDesignTime';

  /// Code to append to the instrumented library code.
  static const RENDER_APPEND = r'''

final flutterDesignerWidgets = <int, Widget>{};

T _registerWidgetInstance<T extends Widget>(int id, T widget) {
  flutterDesignerWidgets[id] = widget;
  return widget;
}
''';

  final String file;
  final String content;
  final LineInfo lineInfo;
  final CompilationUnit unit;
  final TypeProvider typeProvider;

  final List<protocol.FlutterOutline> _depthFirstOrder = [];

  int nextWidgetId = 0;

  /// This map is filled with information about widget classes that can be
  /// rendered. Its keys are class name offsets.
  final Map<int, _WidgetClass> widgets = {};

  final List<protocol.SourceEdit> instrumentationEdits = [];
  String instrumentedCode;

  FlutterOutlineComputer(this.file, this.content, this.lineInfo, this.unit)
      : typeProvider = unit.element.context.typeProvider;

  protocol.FlutterOutline compute() {
    protocol.Outline dartOutline = new DartUnitOutlineComputer(
            file, lineInfo, unit,
            withBasicFlutter: false)
        .compute();

    // Find widget classes.
    // IDEA plugin only supports rendering widgets in libraries.
    if (unit.element.source == unit.element.librarySource) {
      _findWidgets();
    }

    // Convert Dart outlines into Flutter outlines.
    var flutterDartOutline = _convert(dartOutline);

    // Create outlines for widgets.
    unit.accept(new _FlutterOutlineBuilder(this));

    // Compute instrumented code.
    if (widgets.values.any((w) => w.hasDesignTimeConstructor)) {
      _rewriteRelativeDirectives();
      instrumentationEdits.sort((a, b) => b.offset - a.offset);
      instrumentedCode =
          SourceEdit.applySequence(content, instrumentationEdits);
      instrumentedCode += RENDER_APPEND;
    }

    return flutterDartOutline;
  }

  /// If the given [argument] for the [parameter] can be represented as a
  /// Flutter attribute, add it to the [attributes].
  void _addAttribute(List<protocol.FlutterOutlineAttribute> attributes,
      Expression argument, ParameterElement parameter) {
    if (parameter == null) {
      return;
    }
    if (argument is NamedExpression) {
      argument = (argument as NamedExpression).expression;
    }

    String name = parameter.displayName;

    String label = content.substring(argument.offset, argument.end);
    if (label.contains('\n')) {
      label = '…';
    }

    if (argument is BooleanLiteral) {
      attributes.add(new protocol.FlutterOutlineAttribute(name, label,
          literalValueBoolean: argument.value));
    } else if (argument is IntegerLiteral) {
      attributes.add(new protocol.FlutterOutlineAttribute(name, label,
          literalValueInteger: argument.value));
    } else if (argument is StringLiteral) {
      attributes.add(new protocol.FlutterOutlineAttribute(name, label,
          literalValueString: argument.stringValue));
    } else {
      if (argument is FunctionExpression) {
        bool hasParameters = argument.parameters != null &&
            argument.parameters.parameters.isNotEmpty;
        if (argument.body is ExpressionFunctionBody) {
          label = hasParameters ? '(…) => …' : '() => …';
        } else {
          label = hasParameters ? '(…) { … }' : '() { … }';
        }
      } else if (argument is ListLiteral) {
        label = '[…]';
      } else if (argument is MapLiteral) {
        label = '{…}';
      }
      attributes.add(new protocol.FlutterOutlineAttribute(name, label));
    }
  }

  int _addInstrumentationEdits(Expression expression) {
    int id = nextWidgetId++;
    instrumentationEdits.add(new protocol.SourceEdit(
        expression.offset, 0, '_registerWidgetInstance($id, '));
    instrumentationEdits.add(new protocol.SourceEdit(expression.end, 0, ')'));
    return id;
  }

  protocol.FlutterOutline _convert(protocol.Outline dartOutline) {
    protocol.FlutterOutline flutterOutline = new protocol.FlutterOutline(
        protocol.FlutterOutlineKind.DART_ELEMENT,
        dartOutline.offset,
        dartOutline.length,
        dartOutline.codeOffset,
        dartOutline.codeLength,
        dartElement: dartOutline.element);
    if (dartOutline.children != null) {
      flutterOutline.children = dartOutline.children.map(_convert).toList();
    }

    // Fill rendering information for widget classes.
    if (dartOutline.element.kind == protocol.ElementKind.CLASS) {
      var widget = widgets[dartOutline.element.location.offset];
      if (widget != null) {
        flutterOutline.isWidgetClass = true;
        if (widget.hasDesignTimeConstructor) {
          flutterOutline.renderConstructor = CONSTRUCTOR_NAME;
        }
        flutterOutline.stateClassName = widget.state?.name?.name;
        flutterOutline.stateOffset = widget.state?.offset;
        flutterOutline.stateLength = widget.state?.length;
      }
    }

    _depthFirstOrder.add(flutterOutline);
    return flutterOutline;
  }

  /// If the [node] is a supported Flutter widget creation, create a new
  /// outline item for it. If the node is not a widget creation, but its type
  /// is a Flutter Widget class subtype, and [withGeneric] is `true`, return
  /// a widget reference outline item.
  protocol.FlutterOutline _createOutline(Expression node, bool withGeneric) {
    DartType type = node.staticType;
    if (!isWidgetType(type)) {
      return null;
    }
    String className = type.element.displayName;

    if (node is InstanceCreationExpression) {
      int id = _addInstrumentationEdits(node);

      var attributes = <protocol.FlutterOutlineAttribute>[];
      var children = <protocol.FlutterOutline>[];
      for (var argument in node.argumentList.arguments) {
        bool isWidgetArgument = isWidgetType(argument.staticType);
        bool isWidgetListArgument = isListOfWidgetsType(argument.staticType);

        String parentAssociationLabel;
        Expression childrenExpression;

        if (argument is NamedExpression) {
          parentAssociationLabel = argument.name.label.name;
          childrenExpression = argument.expression;
        } else {
          childrenExpression = argument;
        }

        if (isWidgetArgument) {
          var child = _createOutline(childrenExpression, true);
          if (child != null) {
            child.parentAssociationLabel = parentAssociationLabel;
            children.add(child);
          }
        } else if (isWidgetListArgument) {
          if (childrenExpression is ListLiteral) {
            for (var element in childrenExpression.elements) {
              var child = _createOutline(element, true);
              if (child != null) {
                children.add(child);
              }
            }
          }
        } else {
          ParameterElement parameter = argument.staticParameterElement;
          _addAttribute(attributes, argument, parameter);
        }
      }

      return new protocol.FlutterOutline(
          protocol.FlutterOutlineKind.NEW_INSTANCE,
          node.offset,
          node.length,
          node.offset,
          node.length,
          className: className,
          attributes: attributes,
          children: children,
          id: id);
    }

    // A generic Widget typed expression.
    if (withGeneric) {
      var kind = protocol.FlutterOutlineKind.GENERIC;

      String variableName;
      if (node is SimpleIdentifier) {
        kind = protocol.FlutterOutlineKind.VARIABLE;
        variableName = node.name;
      }

      String label;
      if (kind == protocol.FlutterOutlineKind.GENERIC) {
        label = _getShortLabel(node);
      }

      int id = _addInstrumentationEdits(node);
      return new protocol.FlutterOutline(
          kind, node.offset, node.length, node.offset, node.length,
          className: className,
          variableName: variableName,
          label: label,
          id: id);
    }

    return null;
  }

  /// Return the `State` declaration for the given `StatefulWidget` declaration.
  /// Return `null` if cannot be found.
  ClassDeclaration _findState(ClassDeclaration widget) {
    MethodDeclaration createStateMethod = widget.members.firstWhere(
        (method) =>
            method is MethodDeclaration &&
            method.name.name == 'createState' &&
            method.body != null,
        orElse: () => null);
    if (createStateMethod == null) {
      return null;
    }

    DartType stateType;
    {
      FunctionBody buildBody = createStateMethod.body;
      if (buildBody is ExpressionFunctionBody) {
        stateType = buildBody.expression.staticType;
      } else if (buildBody is BlockFunctionBody) {
        List<Statement> statements = buildBody.block.statements;
        if (statements.isNotEmpty) {
          Statement lastStatement = statements.last;
          if (lastStatement is ReturnStatement) {
            stateType = lastStatement.expression?.staticType;
          }
        }
      }
    }
    if (stateType == null) {
      return null;
    }

    ClassElement stateElement;
    if (stateType is InterfaceType && isState(stateType.element)) {
      stateElement = stateType.element;
    } else {
      return null;
    }

    for (var stateNode in unit.declarations) {
      if (stateNode is ClassDeclaration && stateNode.element == stateElement) {
        return stateNode;
      }
    }

    return null;
  }

  /// Fill [widgets] with information about classes that can be rendered.
  void _findWidgets() {
    for (var widget in unit.declarations) {
      if (widget is ClassDeclaration) {
        int nameOffset = widget.name.offset;

        var designTimeConstructor = widget.getConstructor(CONSTRUCTOR_NAME);
        bool hasDesignTimeConstructor = designTimeConstructor != null;

        InterfaceType superType = widget.element.supertype;
        if (isExactlyStatelessWidgetType(superType)) {
          widgets[nameOffset] =
              new _WidgetClass(nameOffset, hasDesignTimeConstructor);
        } else if (isExactlyStatefulWidgetType(superType)) {
          ClassDeclaration state = _findState(widget);
          if (state != null) {
            widgets[nameOffset] =
                new _WidgetClass(nameOffset, hasDesignTimeConstructor, state);
          }
        }
      }
    }
  }

  String _getShortLabel(AstNode node) {
    if (node is MethodInvocation) {
      var buffer = new StringBuffer();

      if (node.target != null) {
        buffer.write(_getShortLabel(node.target));
        buffer.write('.');
      }

      buffer.write(node.methodName.name);

      if (node.argumentList == null || node.argumentList.arguments.isEmpty) {
        buffer.write('()');
      } else {
        buffer.write('(…)');
      }

      return buffer.toString();
    }
    return node.toString();
  }

  /// The instrumented code is put into a temporary directory for Dart VM to
  /// run. So, any relative URIs must be changed to corresponding absolute URIs.
  void _rewriteRelativeDirectives() {
    for (var directive in unit.directives) {
      if (directive is UriBasedDirective) {
        String uriContent = directive.uriContent;
        Source source = directive.uriSource;
        if (uriContent != null && source != null) {
          try {
            if (!Uri.parse(uriContent).isAbsolute) {
              instrumentationEdits.add(new SourceEdit(directive.uri.offset,
                  directive.uri.length, "'${source.uri}'"));
            }
          } on FormatException {}
        }
      }
    }
  }
}

class _FlutterOutlineBuilder extends GeneralizingAstVisitor<void> {
  final FlutterOutlineComputer computer;

  _FlutterOutlineBuilder(this.computer);

  @override
  void visitExpression(Expression node) {
    var outline = computer._createOutline(node, false);
    if (outline != null) {
      for (var parent in computer._depthFirstOrder) {
        if (parent.offset < outline.offset &&
            outline.offset + outline.length < parent.offset + parent.length) {
          parent.children ??= <protocol.FlutterOutline>[];
          parent.children.add(outline);
          return;
        }
      }
    } else {
      super.visitExpression(node);
    }
  }
}

/// Information about a Widget class that can be rendered.
class _WidgetClass {
  final int nameOffset;

  /// Is `true` if has `forDesignTime` constructor, so can be rendered.
  final bool hasDesignTimeConstructor;

  /// If a `StatefulWidget` with the `State` in the same file.
  final ClassDeclaration state;

  _WidgetClass(this.nameOffset, this.hasDesignTimeConstructor, [this.state]);
}
