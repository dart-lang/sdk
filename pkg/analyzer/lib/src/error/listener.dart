// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show AstNode, ConstructorDeclaration;
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

/// Given an array of [arguments] that is expected to contain two or more
/// types, convert the types into strings by using the display names of the
/// types, unless there are two or more types with the same names, in which
/// case the extended display names of the types will be used in order to
/// clarify the message.
///
/// If [expectedTypes] is non-null, the length and types of [arguments] are
/// checked for type correctness.
List<DiagnosticMessage> convertTypeNames(
  List<Object?>? arguments, {
  List<ExpectedType>? expectedTypes,
}) {
  if (expectedTypes != null) _checkTypes(arguments ?? const [], expectedTypes);
  if (arguments == null) {
    return const [];
  }

  var typeGroups = <String, List<_ToConvert>>{};
  for (var i = 0; i < arguments.length; i++) {
    var argument = arguments[i];
    if (argument is TypeImpl) {
      var displayName = argument.getDisplayString(preferTypeAlias: true);
      var types = typeGroups.putIfAbsent(displayName, () => []);
      types.add(_TypeToConvert(i, argument, displayName));
    } else if (argument is Element) {
      var displayName = argument.displayString();
      var types = typeGroups.putIfAbsent(displayName, () => []);
      types.add(_ElementToConvert(i, argument, displayName));
    }
  }

  var messages = <DiagnosticMessage>[];
  for (var typeGroup in typeGroups.values) {
    if (typeGroup.length == 1) {
      var typeToConvert = typeGroup[0];
      // If the display name of a type is unambiguous, just replace the type
      // in the arguments list with its display name.
      arguments[typeToConvert.index] = typeToConvert.displayName;
      continue;
    }

    const unnamedExtension = '<unnamed extension>';
    const unnamed = '<unnamed>';
    var nameToElementMap = <String, Set<Element>>{};
    for (var typeToConvert in typeGroup) {
      for (var element in typeToConvert.allElements) {
        var name = element.name;
        name ??= element is ExtensionElement ? unnamedExtension : unnamed;

        var elements = nameToElementMap.putIfAbsent(name, () => {});
        elements.add(element);
      }
    }

    for (var typeToConvert in typeGroup) {
      // TODO(brianwilkerson): When clients do a better job of displaying
      // context messages, remove the extra text added to the buffer.
      StringBuffer? buffer;
      for (var element in typeToConvert.allElements) {
        var name = element.name;
        name ??= element is ExtensionElement ? unnamedExtension : unnamed;
        var sourcePath = element.firstFragment.libraryFragment!.source.fullName;
        if (nameToElementMap[name]!.length > 1) {
          if (buffer == null) {
            buffer = StringBuffer();
            buffer.write('where ');
          } else {
            buffer.write(', ');
          }
          buffer.write('$name is defined in $sourcePath');
        }
        messages.add(
          DiagnosticMessageImpl(
            filePath: sourcePath,
            length: element.name?.length ?? 0,
            message: '$name is defined in $sourcePath',
            offset: element.firstFragment.nameOffset ?? -1,
            url: null,
          ),
        );
      }

      arguments[typeToConvert.index] = buffer != null
          ? '${typeToConvert.displayName} ($buffer)'
          : typeToConvert.displayName;
    }
  }
  return messages;
}

/// Checks [arguments] for type correctness against [expectedTypes].
///
/// Throws a [StateError] if the types are incorrect.
void _checkTypes(List<Object?> arguments, List<ExpectedType> expectedTypes) {
  late var error = StateError('''
Unexpected types supplied during diagnostic message substitution.
Actual types: ${arguments.map((a) => a.runtimeType).toList()}
Expected types: $expectedTypes''');
  if (arguments.length != expectedTypes.length) {
    throw error;
  }
  for (var i = 0; i < arguments.length; i++) {
    var argument = arguments[i];
    var typeMatches = switch (expectedTypes[i]) {
      ExpectedType.element => argument is Element,
      ExpectedType.int => argument is int,
      ExpectedType.name => argument is String,
      ExpectedType.object => true,
      ExpectedType.string => argument is String,
      ExpectedType.token => argument is Token,
      ExpectedType.type => argument is DartType,
      ExpectedType.uri => argument is Uri,
    };
    if (!typeMatches) {
      throw error;
    }
  }
}

/// An object used to create diagnostics and report them to a diagnostic
/// listener.
@AnalyzerPublicApi(message: 'Exported by package:analyzer/error/listener.dart')
class DiagnosticReporter {
  /// The diagnostic listener to which diagnostics are reported.
  final DiagnosticOrErrorListener _diagnosticListener;

  /// The source to be used when reporting diagnostics.
  final Source _source;

  /// The lock level; if greater than zero, no diagnostic will be reported.
  ///
  /// This is used to prevent reporting diagnostics inside comments.
  @internal
  int lockLevel = 0;

  /// Initializes a newly created error reporter that will report diagnostics to the
  /// given [_diagnosticListener].
  ///
  /// Diagnostics are reported against the [_source] unless another source is
  /// provided later.
  DiagnosticReporter(this._diagnosticListener, this._source);

  Source get source => _source;

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The location of the diagnostic will be the name of the [node].
  ///
  /// The reported [Diagnostic] is returned so that the caller may attach
  /// additional information to it (for example, using an expando).
  Diagnostic atConstructorDeclaration(
    ConstructorDeclaration node,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    @Deprecated('Use an expando instead') Object? data,
  }) {
    // TODO(brianwilkerson): Consider extending this method to take any
    //  declaration and compute the correct range for the name of that
    //  declaration. This might make it easier to be consistent.
    if (node.name case var nameToken?) {
      var offset = node.returnType.offset;
      return atOffset(
        offset: offset,
        length: nameToken.end - offset,
        diagnosticCode: diagnosticCode,
        arguments: arguments,
      );
    } else {
      return atNode(node.returnType, diagnosticCode, arguments: arguments);
    }
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [element] is used to compute the location of the diagnostic.
  ///
  /// The reported [Diagnostic] is returned so that the caller may attach
  /// additional information to it (for example, using an expando).
  Diagnostic atElement2(
    Element element,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    @Deprecated('Use an expando instead') Object? data,
  }) {
    var nonSynthetic = element.nonSynthetic;
    return atOffset(
      diagnosticCode: diagnosticCode,
      offset: nonSynthetic.firstFragment.nameOffset ?? -1,
      length: nonSynthetic.name?.length ?? 0,
      arguments: arguments,
      contextMessages: contextMessages,
      // ignore: deprecated_member_use_from_same_package
      data: data,
    );
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [entity] is used to compute the location of the diagnostic.
  ///
  /// The reported [Diagnostic] is returned so that the caller may attach
  /// additional information to it (for example, using an expando).
  Diagnostic atEntity(
    SyntacticEntity entity,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    @Deprecated('Use an expando instead') Object? data,
  }) {
    return atOffset(
      diagnosticCode: diagnosticCode,
      offset: entity.offset,
      length: entity.length,
      arguments: arguments,
      contextMessages: contextMessages,
      // ignore: deprecated_member_use_from_same_package
      data: data,
    );
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [node] is used to compute the location of the diagnostic.
  ///
  /// The reported [Diagnostic] is returned so that the caller may attach
  /// additional information to it (for example, using an expando).
  Diagnostic atNode(
    AstNode node,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    @Deprecated('Use an expando instead') Object? data,
  }) {
    return atOffset(
      diagnosticCode: diagnosticCode,
      offset: node.offset,
      length: node.length,
      arguments: arguments,
      contextMessages: contextMessages,
      // ignore: deprecated_member_use_from_same_package
      data: data,
    );
  }

  /// Reports a diagnostic with the given [diagnosticCode] (or [errorCode],
  /// deprecated) and [arguments].
  ///
  /// The location of the diagnostic is specified by the given [offset] and
  /// [length].
  ///
  /// The reported [Diagnostic] is returned so that the caller may attach
  /// additional information to it (for example, using an expando).
  Diagnostic atOffset({
    required int offset,
    required int length,
    @Deprecated("Use 'diagnosticCode' instead") DiagnosticCode? errorCode,
    DiagnosticCode? diagnosticCode,
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    @Deprecated('Use an expando instead') Object? data,
  }) {
    if ((errorCode == null && diagnosticCode == null) ||
        (errorCode != null && diagnosticCode != null)) {
      throw ArgumentError(
        "Exactly one of 'errorCode' (deprecated) and 'diagnosticCode' should be given",
      );
    }

    diagnosticCode ??= errorCode!;

    if (arguments != null) {
      var invalid = arguments
          .whereNotType<String>()
          .whereNotType<DartType>()
          .whereNotType<Element>()
          .whereNotType<int>()
          .whereNotType<Uri>();
      if (invalid.isNotEmpty) {
        throw ArgumentError(
          'Tried to format a diagnostic using '
          '${invalid.map((e) => e.runtimeType).join(', ')}',
        );
      }
    }

    var diagnostic = _createDiagnostic(
      offset: offset,
      length: length,
      diagnosticCode: diagnosticCode,
      arguments: arguments ?? const [],
      contextMessages: contextMessages ?? [],
      // ignore: deprecated_member_use_from_same_package
      data: data,
    );
    reportError(diagnostic);
    return diagnostic;
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [span] is used to compute the location of the diagnostic.
  ///
  /// The reported [Diagnostic] is returned so that the caller may attach
  /// additional information to it (for example, using an expando).
  Diagnostic atSourceSpan(
    SourceSpan span,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    @Deprecated('Use an expando instead') Object? data,
  }) {
    return atOffset(
      diagnosticCode: diagnosticCode,
      offset: span.start.offset,
      length: span.length,
      arguments: arguments,
      contextMessages: contextMessages,
      // ignore: deprecated_member_use_from_same_package
      data: data,
    );
  }

  /// Reports a diagnostic with the given [diagnosticCode] and [arguments].
  ///
  /// The [token] is used to compute the location of the diagnostic.
  ///
  /// The reported [Diagnostic] is returned so that the caller may attach
  /// additional information to it (for example, using an expando).
  Diagnostic atToken(
    Token token,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    @Deprecated('Use an expando instead') Object? data,
  }) {
    return atOffset(
      diagnosticCode: diagnosticCode,
      offset: token.offset,
      length: token.length,
      arguments: arguments,
      contextMessages: contextMessages,
      // ignore: deprecated_member_use_from_same_package
      data: data,
    );
  }

  /// Report the given [diagnostic].
  void reportError(Diagnostic diagnostic) {
    if (lockLevel != 0) {
      return;
    }
    _diagnosticListener.onDiagnostic(diagnostic);
  }

  Diagnostic _createDiagnostic({
    required int offset,
    required int length,
    required DiagnosticCode diagnosticCode,
    required List<Object> arguments,
    required List<DiagnosticMessage> contextMessages,
    @Deprecated('Use an expando instead') Object? data,
  }) {
    contextMessages.addAll(
      convertTypeNames(
        arguments,
        expectedTypes: diagnosticCode is DiagnosticCodeWithExpectedTypes
            ? diagnosticCode.expectedTypes
            : null,
      ),
    );
    return Diagnostic.tmp(
      source: _source,
      offset: offset,
      length: length,
      diagnosticCode: diagnosticCode,
      arguments: arguments,
      contextMessages: contextMessages,
      // ignore: deprecated_member_use
      data: data,
    );
  }
}

/// Used by [DiagnosticReporter._convertTypeNames] to keep track of an error
/// argument that is an [Element], that is being converted to a display string.
class _ElementToConvert implements _ToConvert {
  @override
  final int index;

  @override
  final String displayName;

  @override
  final Iterable<Element> allElements;

  _ElementToConvert(this.index, Element element, this.displayName)
    : allElements = [element];
}

/// Used by [DiagnosticReporter._convertTypeNames] to keep track of an argument
/// that is being converted to a display string.
abstract class _ToConvert {
  /// A list of all elements involved in the [DartType] or [Element]'s display
  /// string.
  Iterable<Element> get allElements;

  /// The argument's display string, to replace the argument in the argument
  /// list.
  String get displayName;

  /// The index of the argument in the argument list.
  int get index;
}

/// Used by [DiagnosticReporter._convertTypeNames] to keep track of an error
/// argument that is a [DartType], that is being converted to a display string.
class _TypeToConvert implements _ToConvert {
  @override
  final int index;

  final DartType _type;

  @override
  final String displayName;

  @override
  late final Iterable<Element> allElements = () {
    var elements = <Element>{};

    void addElementsFrom(DartType type) {
      if (type is FunctionType) {
        addElementsFrom(type.returnType);
        for (var parameter in type.formalParameters) {
          addElementsFrom(parameter.type);
        }
      } else if (type is RecordType) {
        for (var parameter in type.fields) {
          addElementsFrom(parameter.type);
        }
      } else if (type is InterfaceType) {
        if (elements.add(type.element)) {
          for (var typeArgument in type.typeArguments) {
            addElementsFrom(typeArgument);
          }
        }
      }
    }

    addElementsFrom(_type);
    return elements.where((element) {
      var name = element.name;
      return name != null && name.isNotEmpty;
    });
  }();

  _TypeToConvert(this.index, this._type, this.displayName);
}

/// Code that will be added to [DiagnosticReporter] when the new literate API
/// for diagnostic reporting is exposed publicly.
extension LiterateDiagnosticReporter on DiagnosticReporter {
  /// Reports the given [diagnostic].
  void report(LocatedDiagnostic diagnostic) {
    var locatableDiagnostic = diagnostic.locatableDiagnostic;
    reportError(
      _createDiagnostic(
        offset: diagnostic.offset,
        length: diagnostic.length,
        diagnosticCode: locatableDiagnostic.code,
        arguments: locatableDiagnostic.arguments,
        contextMessages: locatableDiagnostic.contextMessages.toList(),
      ),
    );
  }
}
