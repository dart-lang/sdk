// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:collection/collection.dart';

/// Helper for finding elements declared in the resolved [unit].
class FindElement2 extends _FindElementBase {
  final CompilationUnit unit;

  FindElement2(this.unit);

  @override
  LibraryFragment get libraryFragment => unit.declaredFragment!;

  LibraryExport export(String targetUri) {
    LibraryExport? result;

    for (var export in libraryFragment.libraryExports2) {
      var exportedUri = export.exportedLibrary2?.uri.toString();
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

  FieldFormalParameterElement2 fieldFormalParameter(String name) {
    return parameter(name) as FieldFormalParameterElement2;
  }

  TopLevelFunctionElement function(String name) {
    for (var function in libraryElement.functions) {
      if (function.name3 == name) {
        return function;
      }
    }
    throw StateError('Not found: $name');
  }

  LibraryImport import(String targetUri, {bool mustBeUnique = true}) {
    LibraryImport? importElement;

    for (var libraryFragment in libraryFragment.withEnclosing2) {
      for (var import in libraryFragment.libraryImports2) {
        var importedUri = import.importedLibrary2?.uri.toString();
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

  LabelElement2 label(String name) {
    LabelElement2? result;

    void updateResult(Element2 element) {
      if (element is LabelElement2 && element.name3 == name) {
        if (result != null) {
          throw StateError('Not unique: $name');
        }
        result = element;
      }
    }

    unit.accept(FunctionAstVisitor(
      label: (node) {
        updateResult(node.label.element!);
      },
    ));

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  LocalFunctionElement localFunction(String name) {
    LocalFunctionElement? result;

    unit.accept(FunctionAstVisitor(
      functionDeclarationStatement: (node) {
        var element = node.functionDeclaration.declaredFragment?.element;
        if (element is LocalFunctionElement && element.name3 == name) {
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

  LocalVariableElement2 localVar(String name) {
    LocalVariableElement2? result;

    void updateResult(Element2 element) {
      if (element is LocalVariableElement2 && element.name3 == name) {
        if (result != null) {
          throw StateError('Not unique: $name');
        }
        result = element;
      }
    }

    unit.accept(FunctionAstVisitor(
      catchClauseParameter: (node) {
        updateResult(node.declaredElement2!);
      },
      declaredIdentifier: (node) {
        updateResult(node.declaredElement2!);
      },
      declaredVariablePattern: (node) {
        updateResult(node.declaredElement2!);
      },
      variableDeclaration: (node) {
        updateResult(node.declaredElement2!);
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

    void findIn(List<FormalParameterElement> formalParameters) {
      for (var formalParameter in formalParameters) {
        if (formalParameter.name3 == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = formalParameter;
        }
      }
    }

    void findInExecutables(List<ExecutableElement2> executables) {
      for (var executable in executables) {
        findIn(executable.formalParameters);
      }
    }

    void findInClasses(List<InterfaceElement2> classes) {
      for (var class_ in classes) {
        findInExecutables(class_.getters2);
        findInExecutables(class_.setters2);
        findInExecutables(class_.constructors2);
        findInExecutables(class_.methods2);
      }
    }

    findInExecutables(libraryElement.getters);
    findInExecutables(libraryElement.setters);
    findInExecutables(libraryElement.functions);

    findInClasses(libraryElement.classes);
    findInClasses(libraryElement.enums);
    findInClasses(libraryElement.extensionTypes);
    findInClasses(libraryElement.mixins);

    for (var extension_ in libraryElement.extensions) {
      findInExecutables(extension_.getters2);
      findInExecutables(extension_.setters2);
      findInExecutables(extension_.methods2);
    }

    for (var alias in libraryElement.typeAliases) {
      var aliasedElement = alias.aliasedElement2;
      if (aliasedElement is GenericFunctionTypeElement2) {
        findIn(aliasedElement.formalParameters);
      }
    }

    unit.accept(
      FunctionAstVisitor(functionExpression: (node, local) {
        if (local) {
          var functionElement = node.declaredFragment!.element;
          findIn(functionElement.formalParameters);
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

    for (var partElement in libraryFragment.partIncludes) {
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
    for (var libraryFragment in libraryFragment.withEnclosing2) {
      for (var importPrefix in libraryFragment.prefixes) {
        if (importPrefix.name3 == name) {
          return importPrefix;
        }
      }
    }
    throw StateError('Not found: $name');
  }

  TypeParameterElement2 typeParameter(String name) {
    TypeParameterElement2? result;

    unit.accept(FunctionAstVisitor(
      typeParameter: (node) {
        var element = node.declaredFragment!.element;
        if (element.name3 == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = element;
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

  @override
  LibraryFragment get libraryFragment {
    return importedLibrary.firstFragment;
  }

  PrefixElement2? get prefix => import.prefix2?.element;
}

class PartFindElement extends _FindElementBase {
  @override
  final LibraryFragment libraryFragment;

  PartFindElement(this.libraryFragment);
}

abstract class _FindElementBase {
  LibraryElement2 get libraryElement => libraryFragment.element;

  LibraryFragment get libraryFragment;

  ClassElement2 class_(String name) {
    for (var class_ in libraryElement.classes) {
      if (class_.name3 == name) {
        return class_;
      }
    }
    throw StateError('Not found: $name');
  }

  InterfaceElement2 classOrMixin(String name) {
    for (var class_ in libraryElement.classes) {
      if (class_.name3 == name) {
        return class_;
      }
    }
    for (var mixin in libraryElement.mixins) {
      if (mixin.name3 == name) {
        return mixin;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement2 constructor(String name, {String? of}) {
    assert(name != '');

    ConstructorElement2? result;

    void findIn(List<ConstructorElement2> constructors) {
      for (var constructor in constructors) {
        if (constructor.name3 == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = constructor;
        }
      }
    }

    for (var class_ in libraryElement.classes) {
      if (of == null || class_.name3 == of) {
        findIn(class_.constructors2);
      }
    }

    for (var enum_ in libraryElement.enums) {
      if (of == null || enum_.name3 == of) {
        findIn(enum_.constructors2);
      }
    }

    for (var extensionType in libraryElement.extensionTypes) {
      if (of == null || extensionType.name3 == of) {
        findIn(extensionType.constructors2);
      }
    }

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }

  EnumElement2 enum_(String name) {
    for (var enum_ in libraryElement.enums) {
      if (enum_.name3 == name) {
        return enum_;
      }
    }
    throw StateError('Not found: $name');
  }

  ExtensionElement2 extension_(String name) {
    for (var extension_ in libraryElement.extensions) {
      if (extension_.name3 == name) {
        return extension_;
      }
    }
    throw StateError('Not found: $name');
  }

  ExtensionTypeElement2 extensionType(String name) {
    for (var element in libraryElement.extensionTypes) {
      if (element.name3 == name) {
        return element;
      }
    }
    throw StateError('Not found: $name');
  }

  FieldElement2 field(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.fields2.named(name),
      fromExtension: (element) => element.fields2.named(name),
    );
  }

  GetterElement getter(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.getters2.named(name),
      fromExtension: (element) => element.getters2.named(name),
    );
  }

  MethodElement2 method(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.methods2.named(name),
      fromExtension: (element) => element.methods2.named(name),
    );
  }

  MixinElement2 mixin(String name) {
    for (var mixin in libraryElement.mixins) {
      if (mixin.name3 == name) {
        return mixin;
      }
    }
    throw StateError('Not found: $name');
  }

  FormalParameterElement parameter(String name) {
    FormalParameterElement? result;

    for (var class_ in libraryElement.classes) {
      for (var constructor in class_.constructors2) {
        for (var formalParameter in constructor.formalParameters) {
          if (formalParameter.name3 == name) {
            if (result != null) {
              throw StateError('Not unique: $name');
            }
            result = formalParameter;
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
      fromClass: (element) => element.setters2.named(name),
      fromExtension: (element) => element.setters2.named(name),
    );
  }

  TopLevelFunctionElement topFunction(String name) {
    for (var function in libraryElement.functions) {
      if (function.name3 == name) {
        return function;
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
    for (var variable in libraryElement.topLevelVariables) {
      if (variable.name3 == name) {
        return variable;
      }
    }
    throw StateError('Not found: $name');
  }

  TypeAliasElement2 typeAlias(String name) {
    for (var element in libraryElement.typeAliases) {
      if (element.name3 == name) {
        return element;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement2 unnamedConstructor(String name) {
    return _findInClassesLike(
      className: name,
      fromClass: (e) => e.constructors2.firstWhereOrNull((element) {
        return element.name3 == 'new';
      }),
      fromExtension: (_) => null,
    );
  }

  T _findInClassesLike<T extends Element2>({
    required String? className,
    required T? Function(InterfaceElement2 element) fromClass,
    required T? Function(ExtensionElement2 element) fromExtension,
  }) {
    bool filter(InstanceElement2 element) {
      return className == null || element.name3 == className;
    }

    var classes = [
      ...libraryElement.classes,
      ...libraryElement.enums,
      ...libraryElement.extensionTypes,
      ...libraryElement.mixins,
    ];

    var results = [
      ...classes.where(filter).map(fromClass),
      ...libraryElement.extensions.where(filter).map(fromExtension),
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

extension<T extends Element2> on List<T> {
  T? named(String targetName) {
    for (var element in this) {
      if (element.name3 == targetName) {
        return element;
      }
    }
    return null;
  }
}

extension ExecutableElementExtensions on ExecutableElement2 {
  FormalParameterElement parameter(String name) {
    for (var formalParameter in formalParameters) {
      if (formalParameter.name3 == name) {
        return formalParameter;
      }
    }
    throw StateError('Not found: $name');
  }

  SuperFormalParameterElement2 superFormalParameter(String name) {
    for (var formalParameter in formalParameters) {
      if (formalParameter is SuperFormalParameterElement2 &&
          formalParameter.name3 == name) {
        return formalParameter;
      }
    }
    throw StateError('Not found: $name');
  }
}
