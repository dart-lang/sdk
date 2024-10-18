// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:collection/collection.dart';

/// Helper for finding elements declared in the resolved [unit].
class FindElement2 extends _FindElementBase {
  final CompilationUnit unit;

  FindElement2(this.unit);

  LibraryElement2 get libraryElement => unitElement.element;

  @override
  LibraryFragment get unitElement => unit.declaredFragment!;

  LibraryExport export(String targetUri) {
    LibraryExport? result;

    for (var export in unitElement.libraryExports2) {
      var exportedUri =
          export.exportedLibrary2?.firstFragment.source.uri.toString();
      if (exportedUri == targetUri) {
        if (result != null) {
          throw StateError('Not unique: $targetUri');
        }
        result = export;
      }
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $targetUri');
  }

  FieldFormalParameterElement fieldFormalParameter(String name) {
    return parameter(name) as FieldFormalParameterElement;
  }

  TopLevelFunctionElement function(String name) {
    for (var function in unitElement.functions2) {
      if (function.name2?.name == name) {
        return function.element;
      }
    }
    throw StateError('Not found: $name');
  }

  LibraryImport import(String targetUri, {bool mustBeUnique = true}) {
    LibraryImport? importElement;

    for (var libraryFragment in unitElement.withEnclosing2) {
      for (var import in libraryFragment.libraryImports2) {
        var importedUri =
            import.importedLibrary2?.firstFragment.source.uri.toString();
        if (importedUri == targetUri) {
          if (importElement == null) {
            importElement = import;
          } else if (mustBeUnique) {
            throw StateError('Not unique: $targetUri');
          }
        }
      }
    }

    if (importElement != null) {
      return importElement;
    }
    throw StateError('Not found: $targetUri');
  }

  ImportFindElement importFind(String targetUri, {bool mustBeUnique = true}) {
    var import = this.import(targetUri, mustBeUnique: mustBeUnique);
    return ImportFindElement(import);
  }

  LabelElement label(String name) {
    LabelElement? result;

    void updateResult(Element element) {
      if (element is LabelElement && element.name == name) {
        if (result != null) {
          throw StateError('Not unique: $name');
        }
        result = element;
      }
    }

    unit.accept(FunctionAstVisitor(
      label: (node) {
        updateResult(node.label.staticElement!);
      },
    ));

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  FunctionElement localFunction(String name) {
    FunctionElement? result;

    unit.accept(FunctionAstVisitor(
      functionDeclarationStatement: (node) {
        var element = node.functionDeclaration.declaredElement;
        if (element is FunctionElement && element.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = element;
        }
      },
    ));

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  LocalVariableElement localVar(String name) {
    LocalVariableElement? result;

    void updateResult(Element element) {
      if (element is LocalVariableElement && element.name == name) {
        if (result != null) {
          throw StateError('Not unique: $name');
        }
        result = element;
      }
    }

    unit.accept(FunctionAstVisitor(
      catchClauseParameter: (node) {
        updateResult(node.declaredElement!);
      },
      declaredIdentifier: (node) {
        updateResult(node.declaredElement!);
      },
      declaredVariablePattern: (node) {
        updateResult(node.declaredElement!);
      },
      variableDeclaration: (node) {
        updateResult(node.declaredElement!);
      },
    ));

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  @override
  FormalParameterElement parameter(String name) {
    FormalParameterElement? result;

    void findIn(List<FormalParameterFragment> parameters) {
      for (var parameter in parameters) {
        if (parameter.name2?.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = parameter.element;
        }
      }
    }

    void findInElements(List<FormalParameterElement> parameters) {
      for (var parameter in parameters) {
        if (parameter.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = parameter;
        }
      }
    }

    void findInExecutables(List<ExecutableFragment> executables) {
      for (var executable in executables) {
        findIn(executable.formalParameters);
      }
    }

    void findInClasses(List<InterfaceFragment> classes) {
      for (var class_ in classes) {
        findInExecutables(class_.getters);
        findInExecutables(class_.setters);
        findInExecutables(class_.constructors2);
        findInExecutables(class_.methods2);
      }
    }

    findInExecutables(unitElement.getters);
    findInExecutables(unitElement.setters);
    findInExecutables(unitElement.functions2);

    findInClasses(unitElement.classes2);
    findInClasses(unitElement.enums2);
    findInClasses(unitElement.extensionTypes2);
    findInClasses(unitElement.mixins2);

    for (var extension_ in unitElement.extensions2) {
      findInExecutables(extension_.getters);
      findInExecutables(extension_.setters);
      findInExecutables(extension_.methods2);
    }

    for (var alias in unitElement.typeAliases2) {
      var aliasedElement = alias.element.aliasedElement2;
      if (aliasedElement is GenericFunctionTypeElement2) {
        findInElements(aliasedElement.formalParameters);
      }
    }

    unit.accept(
      FunctionAstVisitor(functionExpression: (node, local) {
        if (local) {
          var functionElement = node.declaredElement2!;
          findInElements(functionElement.formalParameters);
        }
      }),
    );

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }

  LibraryFragment part(String targetUri) {
    LibraryFragment? result;

    for (var partElement in unitElement.fragmentIncludes) {
      var uri = partElement.uri;
      if (uri is DirectiveUriWithUnit) {
        var unitElement = uri.libraryFragment;
        if ('${unitElement.source.uri}' == targetUri) {
          if (result != null) {
            throw StateError('Not unique: $targetUri');
          }
          result = unitElement;
        }
      }
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $targetUri');
  }

  PartFindElement partFind(String targetUri) {
    var part = this.part(targetUri);
    return PartFindElement(part);
  }

  PrefixElement2 prefix(String name) {
    for (var libraryFragment in unitElement.withEnclosing2) {
      for (var import_ in libraryFragment.libraryImports2) {
        var prefix = import_.prefix2;
        if (prefix != null && prefix.name2?.name == name) {
          return prefix.element;
        }
      }
    }
    throw StateError('Not found: $name');
  }

  TypeParameterElement2 typeParameter(String name) {
    TypeParameterElement2? result;

    unit.accept(FunctionAstVisitor(
      typeParameter: (node) {
        var element = node.declaredFragment!;
        if (element.name2?.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = element.element;
        }
      },
    ));

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }
}

/// Helper for searching imported elements.
class ImportFindElement extends _FindElementBase {
  final LibraryImport import;

  ImportFindElement(this.import);

  LibraryElement2 get importedLibrary => import.importedLibrary2!;

  PrefixElement2? get prefix => import.prefix2?.element;

  @override
  LibraryFragment get unitElement {
    return importedLibrary.firstFragment;
  }
}

class PartFindElement extends _FindElementBase {
  @override
  final LibraryFragment unitElement;

  PartFindElement(this.unitElement);
}

abstract class _FindElementBase {
  LibraryFragment get unitElement;

  ClassElement2 class_(String name) {
    for (var class_ in unitElement.classes2) {
      if (class_.name2?.name == name) {
        return class_.element;
      }
    }
    throw StateError('Not found: $name');
  }

  InterfaceElement2 classOrMixin(String name) {
    for (var class_ in unitElement.classes2) {
      if (class_.name2?.name == name) {
        return class_.element;
      }
    }
    for (var mixin in unitElement.mixins2) {
      if (mixin.name2?.name == name) {
        return mixin.element;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement2 constructor(String name, {String? of}) {
    assert(name != '');

    ConstructorElement2? result;

    void findIn(List<ConstructorFragment> constructors) {
      for (var constructor in constructors) {
        if (constructor.name2?.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = constructor.element;
        }
      }
    }

    for (var class_ in unitElement.classes2) {
      if (of == null || class_.name2?.name == of) {
        findIn(class_.constructors2);
      }
    }

    for (var enum_ in unitElement.enums2) {
      if (of == null || enum_.name2?.name == of) {
        findIn(enum_.constructors2);
      }
    }

    for (var extensionType in unitElement.extensionTypes2) {
      if (of == null || extensionType.name2?.name == of) {
        findIn(extensionType.constructors2);
      }
    }

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }

  EnumElement2 enum_(String name) {
    for (var enum_ in unitElement.enums2) {
      if (enum_.name2?.name == name) {
        return enum_.element;
      }
    }
    throw StateError('Not found: $name');
  }

  ExtensionElement2 extension_(String name) {
    for (var extension_ in unitElement.extensions2) {
      if (extension_.name2?.name == name) {
        return extension_.element;
      }
    }
    throw StateError('Not found: $name');
  }

  ExtensionTypeElement2 extensionType(String name) {
    for (var element in unitElement.extensionTypes2) {
      if (element.name2?.name == name) {
        return element.element;
      }
    }
    throw StateError('Not found: $name');
  }

  FieldElement2 field(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.fields2.named(name)?.element,
      fromExtension: (element) => element.fields2.named(name)?.element,
    );
  }

  GetterElement getter(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) =>
          element.getters.named(name)?.element as GetterElement,
      fromExtension: (element) =>
          element.getters.named(name)?.element as GetterElement,
    );
  }

  MethodElement2 method(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.methods2.named(name)?.element,
      fromExtension: (element) => element.methods2.named(name)?.element,
    );
  }

  MixinElement2 mixin(String name) {
    for (var mixin in unitElement.mixins2) {
      if (mixin.name2?.name == name) {
        return mixin.element;
      }
    }
    throw StateError('Not found: $name');
  }

  FormalParameterElement parameter(String name) {
    FormalParameterElement? result;

    for (var class_ in unitElement.classes2) {
      for (var constructor in class_.constructors2) {
        for (var parameter in constructor.formalParameters) {
          if (parameter.name2?.name == name) {
            if (result != null) {
              throw StateError('Not unique: $name');
            }
            result = parameter.element;
          }
        }
      }
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }

  SetterElement setter(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) =>
          element.setters.named(name)?.element as SetterElement,
      fromExtension: (element) =>
          element.setters.named(name)?.element as SetterElement,
    );
  }

  TopLevelFunctionElement topFunction(String name) {
    for (var function in unitElement.functions2) {
      if (function.name2?.name == name) {
        return function.element;
      }
    }
    throw StateError('Not found: $name');
  }

  GetterElement topGet(String name) {
    return topVar(name).getter2!;
  }

  SetterElement topSet(String name) {
    return topVar(name).setter2!;
  }

  TopLevelVariableElement2 topVar(String name) {
    for (var variable in unitElement.topLevelVariables2) {
      if (variable.name2?.name == name) {
        return variable.element;
      }
    }
    throw StateError('Not found: $name');
  }

  TypeAliasElement2 typeAlias(String name) {
    for (var element in unitElement.typeAliases2) {
      if (element.name2?.name == name) {
        return element.element;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement2 unnamedConstructor(String name) {
    return _findInClassesLike(
      className: name,
      fromClass: (e) => e.constructors2
          .firstWhereOrNull((fragment) => fragment.name2 == null)
          ?.element,
      fromExtension: (_) => null,
    );
  }

  T _findInClassesLike<T extends Element2>({
    required String? className,
    required T? Function(InterfaceFragment element) fromClass,
    required T? Function(ExtensionFragment element) fromExtension,
  }) {
    bool filter(Fragment fragment) {
      return className == null || fragment.name2?.name == className;
    }

    var classes = [
      ...unitElement.classes2,
      ...unitElement.enums2,
      ...unitElement.extensionTypes2,
      ...unitElement.mixins2,
    ];

    var results = [
      ...classes.where(filter).map(fromClass),
      ...unitElement.extensions2.where(filter).map(fromExtension),
    ].nonNulls.toList();

    var result = results.singleOrNull;
    if (result != null) {
      return result;
    }

    if (results.isEmpty) {
      throw StateError('Not found');
    } else {
      throw StateError('Not unique');
    }
  }
}

extension<T extends Fragment> on List<T> {
  T? named(String targetName) {
    for (var element in this) {
      if (element.name2?.name == targetName) {
        return element;
      }
    }
    return null;
  }
}

extension ExecutableElementExtensions on ExecutableElement2 {
  FormalParameterElement parameter(String name) {
    for (var parameter in formalParameters) {
      if (parameter.name == name) {
        return parameter;
      }
    }
    throw StateError('Not found: $name');
  }

  SuperFormalParameterElement2 superFormalParameter(String name) {
    for (var parameter in formalParameters) {
      if (parameter is SuperFormalParameterElement2 && parameter.name == name) {
        return parameter;
      }
    }
    throw StateError('Not found: $name');
  }
}
