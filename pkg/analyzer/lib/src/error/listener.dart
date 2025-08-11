// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';

/// Given an array of [arguments] that is expected to contain two or more
/// types, convert the types into strings by using the display names of the
/// types, unless there are two or more types with the same names, in which
/// case the extended display names of the types will be used in order to
/// clarify the message.
List<DiagnosticMessage> convertTypeNames(List<Object?>? arguments) {
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
            offset: element.firstFragment.nameOffset2 ?? -1,
            url: null,
          ),
        );
      }

      arguments[typeToConvert.index] =
          buffer != null
              ? '${typeToConvert.displayName} ($buffer)'
              : typeToConvert.displayName;
    }
  }
  return messages;
}

/// Used by [ErrorReporter._convertTypeNames] to keep track of an error argument
/// that is an [Element], that is being converted to a display string.
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

/// Used by [ErrorReporter._convertTypeNames] to keep track of an argument that
/// is being converted to a display string.
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

/// Used by [ErrorReporter._convertTypeNames] to keep track of an error argument
/// that is a [DartType], that is being converted to a display string.
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
