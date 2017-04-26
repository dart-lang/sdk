import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:front_end/src/base/instrumentation.dart'
    show Instrumentation, InstrumentationValue;

/**
 * Instance of [InstrumentationValue] describing a [DartType].
 */
class InstrumentationValueForType extends InstrumentationValue {
  final DartType type;

  InstrumentationValueForType(this.type);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    _appendType(buffer, type);
    return buffer.toString();
  }

  void _appendElementName(StringBuffer buffer, Element element) {
    String name = element.name;
    String libraryName = element.library.name;
    if (libraryName == '') {
      throw new StateError('The element $name must be in a named library.');
    }
    if (libraryName != 'dart.core' &&
        libraryName != 'dart.async' &&
        libraryName != 'test') {
      buffer.write('$libraryName::$name');
    } else {
      buffer.write('$name');
    }
  }

  void _appendList<T>(StringBuffer buffer, String open, String close,
      List<T> items, String separator, writeItem(T item),
      {bool includeEmpty: false}) {
    if (!includeEmpty && items.isEmpty) {
      return;
    }
    buffer.write(open);
    bool first = true;
    for (T item in items) {
      if (!first) {
        buffer.write(separator);
      }
      writeItem(item);
      first = false;
    }
    buffer.write(close);
  }

  void _appendParameters(
      StringBuffer buffer, List<ParameterElement> parameters) {
    _appendList<ParameterElement>(buffer, '(', ')', parameters, ', ',
        (parameter) {
      _appendType(buffer, type);
      buffer.write(' ');
      buffer.write(parameter.name);
    }, includeEmpty: true);
  }

  void _appendType(StringBuffer buffer, DartType type) {
    if (type == null) {
      buffer.write('none');
    } else if (type is FunctionType) {
      Element element = type.element;
      _appendElementName(buffer, element);
      _appendTypeArguments(buffer, type.typeArguments);
      _appendParameters(buffer, type.parameters);
      buffer.write(' → ');
      _appendType(buffer, type.returnType);
    } else if (type is InterfaceType) {
      ClassElement element = type.element;
      _appendElementName(buffer, element);
      _appendTypeArguments(buffer, type.typeArguments);
    } else {
      buffer.write(type.toString());
    }
  }

  void _appendTypeArguments(StringBuffer buffer, List<DartType> typeArguments) {
    _appendList<DartType>(buffer, '<', '>', typeArguments, ', ',
        (type) => _appendType(buffer, type));
  }
}

/**
 * Wrapper around [Instrumentation] for writing analyzer specific values
 * for a single URI.
 */
class UriInstrumentation {
  final Instrumentation _instrumentation;
  final Uri _uri;

  UriInstrumentation(this._instrumentation, this._uri);

  void recordInference(int offset, DartType type) {
    _instrumentation.record(
        _uri, offset, 'type', new InstrumentationValueForType(type));
  }

  void recordPromotion(int offset, DartType type) {
    _instrumentation.record(
        _uri, offset, 'promotedType', new InstrumentationValueForType(type));
  }

  void recordTopType(int offset, DartType type) {
    _instrumentation.record(
        _uri, offset, 'topType', new InstrumentationValueForType(type));
  }
}
