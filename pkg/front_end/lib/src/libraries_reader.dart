import 'package:analyzer/src/summary/idl.dart';
import 'package:front_end/src/base/library_info.dart';

/// Decodes the contents of the SDK's "libraries.dart" file.
///
/// Caller should pass in the unlinked summary of the libraries.dart file.  This
/// function will materialize the "libraries" constant based on information in
/// the summary.
///
/// Note that this code is not intended to be fully general; it makes some
/// assumptions about the structure of the "libraries.dart" file (such as what
/// declarations are expected to be present in it, and the types of those
/// declarations).
Map<String, LibraryInfo> readLibraries(UnlinkedUnit librariesUnit) {
  var constContext = new _ConstContext(librariesUnit.references);
  for (var variable in librariesUnit.variables) {
    if (!variable.isConst) continue;
    constContext.topLevelConstants[variable.name] =
        new _ConstVariable(variable.initializer.bodyExpr, constContext);
  }
  for (var cls in librariesUnit.classes) {
    if (cls.name == 'Maturity') {
      for (var field in cls.fields) {
        if (!field.isConst) continue;
        constContext.maturityConstants[field.name] =
            new _ConstVariable(field.initializer.bodyExpr, constContext);
      }
    }
  }
  return constContext.topLevelConstants['libraries'].value;
}

/// Function type used to invoke a constructor based on dynamic information.
///
/// Caller supplies two callbacks ([positional] and [named]) which can be used
/// to query the arguments passed to the constructor.  These callbacks will
/// return the requested argument if it was provided; otherwise they will return
/// the supplied default value.
typedef dynamic _Constructor(dynamic positional(int i, [dynamic defaultValue]),
    dynamic named(String name, [dynamic defaultValue]));

/// Contextual information used to evaluate constants in the "libraries.dart"
/// file.
class _ConstContext {
  /// Top level constants in the "libraries.dart" file.
  final topLevelConstants = <String, _ConstVariable>{};

  /// Static constants in "libraries.dart"'s "Maturity" class.
  final maturityConstants = <String, _ConstVariable>{};

  /// References from the unlinked summary of the "libraries.dart" file.
  final List<UnlinkedReference> references;

  _ConstContext(this.references);
}

/// Information necessary to evaluate a single constant from the
/// "libraries.dart" file.
class _ConstVariable {
  /// The constant expression from the unlinked summary.
  final UnlinkedExpr expr;

  /// Contextual information necessary to evaluate the constant.
  final _ConstContext context;

  /// The evaluated value, or `null` if it hasn't been evaluated yet.
  dynamic _value;

  _ConstVariable(this.expr, this.context);

  /// Evaluate the constant (if necessary) and return it.
  dynamic get value => _value ??= _materialize();

  /// Find the constructor referred to by [entityRef] and return a function
  /// which may be used to invoke it.
  _Constructor _findConstructor(EntityRef entityRef) {
    // This method is not fully general; we only support the constructor
    // invocations that we expect to find in LibraryInfo.
    assert(entityRef.implicitFunctionTypeIndices.isEmpty);
    assert(entityRef.paramReference == 0);
    assert(entityRef.syntheticParams.isEmpty);
    assert(entityRef.syntheticReturnType == null);
    assert(entityRef.typeArguments.isEmpty);
    var reference = context.references[entityRef.reference];
    assert(reference.prefixReference == 0);
    switch (reference.name) {
      case 'LibraryInfo':
        return (dynamic positional(int i, [dynamic defaultValue]),
                dynamic named(String name, [dynamic defaultValue])) =>
            new LibraryInfo(positional(0),
                categories: named('categories', ''),
                dart2jsPath: named('dart2jsPath'),
                dart2jsPatchPath: named('dart2jsPatchPath'),
                implementation: named('implementation', false),
                documented: named('documented', true),
                maturity: named('maturity', Maturity.UNSPECIFIED),
                platforms: named('platforms', DART2JS_PLATFORM | VM_PLATFORM));
      case 'Maturity':
        return (dynamic positional(int i, [dynamic defaultValue]),
                dynamic named(String name, [dynamic defaultValue])) =>
            new Maturity(positional(0), positional(1), positional(2));
      default:
        throw new UnimplementedError(
            'Unexpected constructor reference: ${reference.name}');
    }
  }

  /// Compute the value referred to by [entityRef].
  dynamic _findReference(EntityRef entityRef) {
    // This method is not fully general; we only support the references that we
    // expect to find in LibraryInfo.
    assert(entityRef.implicitFunctionTypeIndices.isEmpty);
    assert(entityRef.paramReference == 0);
    assert(entityRef.syntheticParams.isEmpty);
    assert(entityRef.syntheticReturnType == null);
    assert(entityRef.typeArguments.isEmpty);
    var reference = context.references[entityRef.reference];
    if (reference.prefixReference == 0) {
      return context.topLevelConstants[reference.name].value;
    } else {
      assert(reference.prefixReference != 0);
      var prefixReference = context.references[reference.prefixReference];
      assert(prefixReference.name == 'Maturity');
      assert(prefixReference.prefixReference == 0);
      return context.maturityConstants[reference.name].value;
    }
  }

  /// Compute the value of the constant.
  dynamic _materialize() {
    var stack = [];
    var stringIndex = 0;
    var intIndex = 0;
    var referenceIndex = 0;
    List popItems(int count) {
      var items = stack.sublist(stack.length - count, stack.length);
      stack.length -= count;
      return items;
    }

    for (var operation in expr.operations) {
      switch (operation) {
        case UnlinkedExprOperation.pushString:
          stack.add(expr.strings[stringIndex++]);
          break;
        case UnlinkedExprOperation.invokeConstructor:
          var namedArgumentList = popItems(expr.ints[intIndex++]);
          var namedArguments = <String, dynamic>{};
          for (var namedArgument in namedArgumentList) {
            namedArguments[expr.strings[stringIndex++]] = namedArgument;
          }
          var positionalArguments = popItems(expr.ints[intIndex++]);
          stack.add(_findConstructor(expr.references[referenceIndex++])(
              (i, [defaultValue]) => i < positionalArguments.length
                  ? positionalArguments[i]
                  : defaultValue,
              (name, [defaultValue]) => namedArguments.containsKey(name)
                  ? namedArguments[name]
                  : defaultValue));
          break;
        case UnlinkedExprOperation.makeUntypedMap:
          var map = {};
          var numKeyValuePairs = expr.ints[intIndex++];
          var keyValueList = popItems(numKeyValuePairs * 2);
          for (var i = 0; i < numKeyValuePairs; i++) {
            map[keyValueList[2 * i]] = keyValueList[2 * i + 1];
          }
          stack.add(map);
          break;
        case UnlinkedExprOperation.pushReference:
          stack.add(_findReference(expr.references[referenceIndex++]));
          break;
        case UnlinkedExprOperation.pushInt:
          stack.add(expr.ints[intIndex++]);
          break;
        case UnlinkedExprOperation.pushFalse:
          stack.add(false);
          break;
        case UnlinkedExprOperation.pushTrue:
          stack.add(true);
          break;
        case UnlinkedExprOperation.bitOr:
          var y = stack.removeLast();
          var x = stack.removeLast();
          stack.add(x | y);
          break;
        default:
          throw new UnimplementedError(
              'Unexpected expression in libraries.dart: $operation');
      }
    }
    assert(stringIndex == expr.strings.length);
    assert(intIndex == expr.ints.length);
    assert(referenceIndex == expr.references.length);
    assert(stack.length == 1);
    if (stack[0] == null) {
      throw new StateError('Unexpected null constant in libraries.dart');
    }
    return stack[0];
  }
}
