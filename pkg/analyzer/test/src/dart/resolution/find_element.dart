import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';

import 'function_ast_visitor.dart';

class FindElement {
  final CompilationUnit unit;

  FindElement(this.unit);

  CompilationUnitElement get unitElement => unit.declaredElement;

  ClassElement class_(String name) {
    for (var class_ in unitElement.types) {
      if (class_.name == name) {
        return class_;
      }
    }
    fail('Not found class: $name');
  }

  ConstructorElement constructor(String name, {String className}) {
    assert(name != '');
    ConstructorElement result;
    for (var class_ in unitElement.types) {
      if (className == null || class_.name == className) {
        for (var constructor in class_.constructors) {
          if (constructor.name == name) {
            if (result != null) {
              throw new StateError('Not constructor name: $name');
            }
            result = constructor;
          }
        }
      }
    }
    if (result != null) {
      return result;
    }
    fail('Not found constructor: $name');
  }

  ClassElement enum_(String name) {
    for (var enum_ in unitElement.enums) {
      if (enum_.name == name) {
        return enum_;
      }
    }
    fail('Not found enum: $name');
  }

  ExportElement export(String targetUri) {
    ExportElement exportElement;
    for (var export in unitElement.library.exports) {
      var exportedUri = export.exportedLibrary.source.uri.toString();
      if (exportedUri == targetUri) {
        if (exportElement != null) {
          throw new StateError('Not unique $targetUri export.');
        }
        exportElement = export;
      }
    }
    if (exportElement != null) {
      return exportElement;
    }
    fail('Not found export: $targetUri');
  }

  FieldElement field(String name) {
    for (var type in unitElement.mixins) {
      for (var field in type.fields) {
        if (field.name == name) {
          return field;
        }
      }
    }
    for (var type in unitElement.types) {
      for (var field in type.fields) {
        if (field.name == name) {
          return field;
        }
      }
    }
    fail('Not found class field: $name');
  }

  FunctionElement function(String name) {
    for (var function in unitElement.functions) {
      if (function.name == name) {
        return function;
      }
    }
    fail('Not found top-level function: $name');
  }

  PropertyAccessorElement getter(String name) {
    for (var class_ in unitElement.types) {
      for (var accessor in class_.accessors) {
        if (accessor.isGetter && accessor.displayName == name) {
          return accessor;
        }
      }
    }
    fail('Not found class accessor: $name');
  }

  ImportElement import(String targetUri) {
    ImportElement importElement;
    for (var import in unitElement.library.imports) {
      var importedUri = import.importedLibrary.source.uri.toString();
      if (importedUri == targetUri) {
        if (importElement != null) {
          throw new StateError('Not unique $targetUri import.');
        }
        importElement = import;
      }
    }
    if (importElement != null) {
      return importElement;
    }
    fail('Not found import: $targetUri');
  }

  InterfaceType interfaceType(String name) {
    return class_(name).type;
  }

  LocalVariableElement localVar(String name) {
    LocalVariableElement result;
    unit.accept(new FunctionAstVisitor(
      variableDeclaration: (node) {
        var element = node.declaredElement;
        if (element is LocalVariableElement) {
          if (result != null) {
            throw new StateError('Local variable name $name is not unique.');
          }
          result = element;
        }
      },
    ));
    if (result == null) {
      fail('Not found local variable: $name');
    }
    return result;
  }

  MethodElement method(String name) {
    for (var type in unitElement.types) {
      for (var method in type.methods) {
        if (method.name == name) {
          return method;
        }
      }
    }
    fail('Not found class method: $name');
  }

  ClassElement mixin(String name) {
    for (var mixin in unitElement.mixins) {
      if (mixin.name == name) {
        return mixin;
      }
    }
    fail('Not found mixin: $name');
  }

  ParameterElement parameter(String name) {
    ParameterElement parameterElement;
    void considerParameter(ParameterElement parameter) {
      if (parameter.name == name) {
        if (parameterElement != null) {
          throw new StateError('Parameter name $name is not unique.');
        }
        parameterElement = parameter;
      }
    }

    for (var accessor in unitElement.accessors) {
      accessor.parameters.forEach(considerParameter);
    }
    for (var function in unitElement.functions) {
      function.parameters.forEach(considerParameter);
    }
    for (var function in unitElement.functionTypeAliases) {
      function.parameters.forEach(considerParameter);
    }
    for (var class_ in unitElement.types) {
      for (var constructor in class_.constructors) {
        constructor.parameters.forEach(considerParameter);
      }
      for (var method in class_.methods) {
        method.parameters.forEach(considerParameter);
      }
    }
    if (parameterElement != null) {
      return parameterElement;
    }
    fail('No parameter found with name $name');
  }

  PrefixElement prefix(String name) {
    for (var import_ in unitElement.library.imports) {
      var prefix = import_.prefix;
      if (prefix != null && prefix.name == name) {
        return prefix;
      }
    }
    fail('Prefix not found: $name');
  }

  PropertyAccessorElement setter(String name, {String inClass}) {
    PropertyAccessorElement result;
    for (var class_ in unitElement.types) {
      if (inClass != null && class_.name != inClass) {
        continue;
      }
      for (var accessor in class_.accessors) {
        if (accessor.isSetter && accessor.displayName == name) {
          if (result == null) {
            result = accessor;
          } else {
            throw new StateError('Class setter $name is not unique.');
          }
        }
      }
    }
    if (result == null) {
      fail('Not found class setter: $name');
    }
    return result;
  }

  FunctionElement topFunction(String name) {
    for (var function in unitElement.functions) {
      if (function.name == name) {
        return function;
      }
    }
    fail('Not found top-level function: $name');
  }

  PropertyAccessorElement topGet(String name) {
    return topVar(name).getter;
  }

  PropertyAccessorElement topSet(String name) {
    return topVar(name).setter;
  }

  TopLevelVariableElement topVar(String name) {
    for (var variable in unitElement.topLevelVariables) {
      if (variable.name == name) {
        return variable;
      }
    }
    fail('Not found top-level variable: $name');
  }

  TypeParameterElement typeParameter(String name) {
    TypeParameterElement result;

    void consider(TypeParameterElement candidate) {
      if (candidate.name == name) {
        if (result != null) {
          throw new StateError('Type parameter $name is not unique.');
        }
        result = candidate;
      }
    }

    for (var type in unitElement.functionTypeAliases) {
      type.typeParameters.forEach(consider);
    }
    for (var type in unitElement.types) {
      type.typeParameters.forEach(consider);
    }
    if (result != null) {
      return result;
    }
    fail('Not found type parameter: $name');
  }

  ConstructorElement unnamedConstructor(String name) {
    return class_(name).unnamedConstructor;
  }
}
