// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.util;

import '../common.dart';
import '../constants/expressions.dart';
import '../elements/resolution_types.dart';
import '../diagnostics/messages.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart' show WrappedMessage;
import '../elements/names.dart';
import '../elements/operators.dart';
import '../resolution/access_semantics.dart';
import '../resolution/send_structure.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import 'keys.dart';
import 'serialization.dart';

/// Serialize [name] into [encoder].
void serializeName(Name name, ObjectEncoder encoder) {
  encoder.setString(Key.NAME, name.text);
  encoder.setBool(Key.IS_SETTER, name.isSetter);
  if (name.library != null) {
    LibraryElement library = name.library;
    encoder.setElement(Key.LIBRARY, library);
  }
}

/// Deserialize a [Name] from [decoder].
Name deserializeName(ObjectDecoder decoder) {
  String name = decoder.getString(Key.NAME);
  bool isSetter = decoder.getBool(Key.IS_SETTER);
  LibraryElement library = decoder.getElement(Key.LIBRARY, isOptional: true);
  return new Name(name, library, isSetter: isSetter);
}

/// Serialize [selector] into [encoder].
void serializeSelector(Selector selector, ObjectEncoder encoder) {
  encoder.setEnum(Key.KIND, selector.kind);

  encoder.setInt(Key.ARGUMENTS, selector.callStructure.argumentCount);
  encoder.setStrings(
      Key.NAMED_ARGUMENTS, selector.callStructure.namedArguments);
  serializeName(selector.memberName, encoder);
}

/// Deserialize a [Selector] from [decoder].
Selector deserializeSelector(ObjectDecoder decoder) {
  SelectorKind kind = decoder.getEnum(Key.KIND, SelectorKind.values);
  int argumentCount = decoder.getInt(Key.ARGUMENTS);
  List<String> namedArguments =
      decoder.getStrings(Key.NAMED_ARGUMENTS, isOptional: true);
  return new Selector(kind, deserializeName(decoder),
      new CallStructure(argumentCount, namedArguments));
}

/// Serialize [sendStructure] into [encoder].
void serializeSendStructure(
    SendStructure sendStructure, ObjectEncoder encoder) {
  encoder.setEnum(Key.KIND, sendStructure.kind);
  switch (sendStructure.kind) {
    case SendStructureKind.IF_NULL:
    case SendStructureKind.LOGICAL_AND:
    case SendStructureKind.LOGICAL_OR:
    case SendStructureKind.NOT:
    case SendStructureKind.INVALID_UNARY:
    case SendStructureKind.INVALID_BINARY:
      // No additional properties.
      break;
    case SendStructureKind.IS:
      IsStructure structure = sendStructure;
      encoder.setType(Key.TYPE, structure.type);
      break;
    case SendStructureKind.IS_NOT:
      IsNotStructure structure = sendStructure;
      encoder.setType(Key.TYPE, structure.type);
      break;
    case SendStructureKind.AS:
      AsStructure structure = sendStructure;
      encoder.setType(Key.TYPE, structure.type);
      break;
    case SendStructureKind.INVOKE:
      InvokeStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      serializeSelector(structure.selector, encoder.createObject(Key.SELECTOR));
      break;
    case SendStructureKind.INCOMPATIBLE_INVOKE:
      IncompatibleInvokeStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      serializeSelector(structure.selector, encoder.createObject(Key.SELECTOR));
      break;
    case SendStructureKind.GET:
      GetStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      break;
    case SendStructureKind.SET:
      SetStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      break;
    case SendStructureKind.UNARY:
      UnaryStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      encoder.setEnum(Key.OPERATOR, structure.operator.kind);
      break;
    case SendStructureKind.INDEX:
      IndexStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      break;
    case SendStructureKind.EQUALS:
      EqualsStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      break;
    case SendStructureKind.NOT_EQUALS:
      NotEqualsStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      break;
    case SendStructureKind.BINARY:
      BinaryStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      encoder.setEnum(Key.OPERATOR, structure.operator.kind);
      break;
    case SendStructureKind.INDEX_SET:
      IndexSetStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      break;
    case SendStructureKind.INDEX_PREFIX:
      IndexPrefixStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      encoder.setEnum(Key.OPERATOR, structure.operator.kind);
      break;
    case SendStructureKind.INDEX_POSTFIX:
      IndexPostfixStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      encoder.setEnum(Key.OPERATOR, structure.operator.kind);
      break;
    case SendStructureKind.COMPOUND:
      CompoundStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      encoder.setEnum(Key.OPERATOR, structure.operator.kind);
      break;
    case SendStructureKind.SET_IF_NULL:
      SetIfNullStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      break;
    case SendStructureKind.COMPOUND_INDEX_SET:
      CompoundIndexSetStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      encoder.setEnum(Key.OPERATOR, structure.operator.kind);
      break;
    case SendStructureKind.INDEX_SET_IF_NULL:
      IndexSetIfNullStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      break;
    case SendStructureKind.PREFIX:
      PrefixStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      encoder.setEnum(Key.OPERATOR, structure.operator.kind);
      break;
    case SendStructureKind.POSTFIX:
      PostfixStructure structure = sendStructure;
      serializeAccessSemantics(
          structure.semantics, encoder.createObject(Key.SEMANTICS));
      encoder.setEnum(Key.OPERATOR, structure.operator.kind);
      break;
    case SendStructureKind.DEFERRED_PREFIX:
      DeferredPrefixStructure structure = sendStructure;
      encoder.setElement(Key.PREFIX, structure.prefix);
      serializeSendStructure(
          structure.sendStructure, encoder.createObject(Key.SEND_STRUCTURE));
      break;
  }
}

/// Deserialize a [SendStructure] from [decoder].
// ignore: MISSING_RETURN
SendStructure deserializeSendStructure(ObjectDecoder decoder) {
  SendStructureKind kind = decoder.getEnum(Key.KIND, SendStructureKind.values);
  switch (kind) {
    case SendStructureKind.IF_NULL:
      return const IfNullStructure();
    case SendStructureKind.LOGICAL_AND:
      return const LogicalAndStructure();
    case SendStructureKind.LOGICAL_OR:
      return const LogicalOrStructure();
    case SendStructureKind.IS:
      return new IsStructure(decoder.getType(Key.TYPE));
    case SendStructureKind.IS_NOT:
      return new IsNotStructure(decoder.getType(Key.TYPE));
    case SendStructureKind.AS:
      return new AsStructure(decoder.getType(Key.TYPE));
    case SendStructureKind.INVOKE:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      Selector selector = deserializeSelector(decoder.getObject(Key.SELECTOR));
      return new InvokeStructure(semantics, selector);
    case SendStructureKind.INCOMPATIBLE_INVOKE:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      Selector selector = deserializeSelector(decoder.getObject(Key.SELECTOR));
      return new IncompatibleInvokeStructure(semantics, selector);
    case SendStructureKind.GET:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new GetStructure(semantics);
    case SendStructureKind.SET:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new SetStructure(semantics);
    case SendStructureKind.NOT:
      return const NotStructure();
    case SendStructureKind.UNARY:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new UnaryStructure(
          semantics,
          UnaryOperator.fromKind(
              decoder.getEnum(Key.OPERATOR, UnaryOperatorKind.values)));
    case SendStructureKind.INVALID_UNARY:
      return new InvalidUnaryStructure();
    case SendStructureKind.INDEX:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new IndexStructure(semantics);
    case SendStructureKind.EQUALS:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new EqualsStructure(semantics);
    case SendStructureKind.NOT_EQUALS:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new NotEqualsStructure(semantics);
    case SendStructureKind.BINARY:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new BinaryStructure(
          semantics,
          BinaryOperator.fromKind(
              decoder.getEnum(Key.OPERATOR, BinaryOperatorKind.values)));
    case SendStructureKind.INVALID_BINARY:
      return const InvalidBinaryStructure();
    case SendStructureKind.INDEX_SET:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new IndexSetStructure(semantics);
    case SendStructureKind.INDEX_PREFIX:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new IndexPrefixStructure(
          semantics,
          IncDecOperator.fromKind(
              decoder.getEnum(Key.OPERATOR, IncDecOperatorKind.values)));
    case SendStructureKind.INDEX_POSTFIX:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new IndexPostfixStructure(
          semantics,
          IncDecOperator.fromKind(
              decoder.getEnum(Key.OPERATOR, IncDecOperatorKind.values)));
    case SendStructureKind.COMPOUND:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new CompoundStructure(
          semantics,
          AssignmentOperator.fromKind(
              decoder.getEnum(Key.OPERATOR, AssignmentOperatorKind.values)));
    case SendStructureKind.SET_IF_NULL:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new SetIfNullStructure(semantics);
    case SendStructureKind.COMPOUND_INDEX_SET:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new CompoundIndexSetStructure(
          semantics,
          AssignmentOperator.fromKind(
              decoder.getEnum(Key.OPERATOR, AssignmentOperatorKind.values)));
    case SendStructureKind.INDEX_SET_IF_NULL:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new IndexSetIfNullStructure(semantics);
    case SendStructureKind.PREFIX:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new PrefixStructure(
          semantics,
          IncDecOperator.fromKind(
              decoder.getEnum(Key.OPERATOR, IncDecOperatorKind.values)));
    case SendStructureKind.POSTFIX:
      AccessSemantics semantics =
          deserializeAccessSemantics(decoder.getObject(Key.SEMANTICS));
      return new PostfixStructure(
          semantics,
          IncDecOperator.fromKind(
              decoder.getEnum(Key.OPERATOR, IncDecOperatorKind.values)));
    case SendStructureKind.DEFERRED_PREFIX:
      PrefixElement prefix = decoder.getElement(Key.PREFIX);
      SendStructure sendStructure =
          deserializeSendStructure(decoder.getObject(Key.SEND_STRUCTURE));
      return new DeferredPrefixStructure(prefix, sendStructure);
  }
}

/// Serialize [newStructure] into [encoder].
void serializeNewStructure(NewStructure newStructure, ObjectEncoder encoder) {
  encoder.setEnum(Key.KIND, newStructure.kind);
  switch (newStructure.kind) {
    case NewStructureKind.NEW_INVOKE:
      NewInvokeStructure structure = newStructure;
      encoder.setEnum(Key.SUB_KIND, structure.semantics.kind);
      encoder.setElement(Key.ELEMENT, structure.semantics.element);
      encoder.setType(Key.TYPE, structure.semantics.type);
      serializeSelector(structure.selector, encoder.createObject(Key.SELECTOR));
      break;
    case NewStructureKind.CONST_INVOKE:
      ConstInvokeStructure structure = newStructure;
      encoder.setEnum(Key.SUB_KIND, structure.constantInvokeKind);
      encoder.setConstant(Key.CONSTANT, structure.constant);
      break;
    case NewStructureKind.LATE_CONST:
      throw new UnsupportedError(
          'Unsupported NewStructure kind ${newStructure.kind}.');
  }
}

/// Deserialize a [NewStructure] from [decoder].
// ignore: MISSING_RETURN
NewStructure deserializeNewStructure(ObjectDecoder decoder) {
  NewStructureKind kind = decoder.getEnum(Key.KIND, NewStructureKind.values);
  switch (kind) {
    case NewStructureKind.NEW_INVOKE:
      ConstructorAccessKind constructorAccessKind =
          decoder.getEnum(Key.SUB_KIND, ConstructorAccessKind.values);
      Element element = decoder.getElement(Key.ELEMENT);
      ResolutionDartType type = decoder.getType(Key.TYPE);
      ConstructorAccessSemantics semantics =
          new ConstructorAccessSemantics(constructorAccessKind, element, type);
      Selector selector = deserializeSelector(decoder.getObject(Key.SELECTOR));
      return new NewInvokeStructure(semantics, selector);

    case NewStructureKind.CONST_INVOKE:
      ConstantInvokeKind constantInvokeKind =
          decoder.getEnum(Key.SUB_KIND, ConstantInvokeKind.values);
      ConstantExpression constant = decoder.getConstant(Key.CONSTANT);
      return new ConstInvokeStructure(constantInvokeKind, constant);
    case NewStructureKind.LATE_CONST:
      throw new UnsupportedError('Unsupported NewStructure kind $kind.');
  }
}

/// Serialize [semantics] into [encoder].
void serializeAccessSemantics(
    AccessSemantics semantics, ObjectEncoder encoder) {
  encoder.setEnum(Key.KIND, semantics.kind);
  switch (semantics.kind) {
    case AccessKind.EXPRESSION:
    case AccessKind.THIS:
      // No additional properties.
      break;
    case AccessKind.THIS_PROPERTY:
    case AccessKind.DYNAMIC_PROPERTY:
    case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
      serializeName(semantics.name, encoder);
      break;
    case AccessKind.CLASS_TYPE_LITERAL:
    case AccessKind.TYPEDEF_TYPE_LITERAL:
    case AccessKind.DYNAMIC_TYPE_LITERAL:
      encoder.setConstant(Key.CONSTANT, semantics.constant);
      break;
    case AccessKind.LOCAL_FUNCTION:
    case AccessKind.LOCAL_VARIABLE:
    case AccessKind.FINAL_LOCAL_VARIABLE:
    case AccessKind.PARAMETER:
    case AccessKind.FINAL_PARAMETER:
    case AccessKind.STATIC_FIELD:
    case AccessKind.FINAL_STATIC_FIELD:
    case AccessKind.STATIC_METHOD:
    case AccessKind.STATIC_GETTER:
    case AccessKind.STATIC_SETTER:
    case AccessKind.TOPLEVEL_FIELD:
    case AccessKind.FINAL_TOPLEVEL_FIELD:
    case AccessKind.TOPLEVEL_METHOD:
    case AccessKind.TOPLEVEL_GETTER:
    case AccessKind.TOPLEVEL_SETTER:
    case AccessKind.SUPER_FIELD:
    case AccessKind.SUPER_FINAL_FIELD:
    case AccessKind.SUPER_METHOD:
    case AccessKind.SUPER_GETTER:
    case AccessKind.SUPER_SETTER:
    case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
    case AccessKind.UNRESOLVED:
    case AccessKind.UNRESOLVED_SUPER:
    case AccessKind.INVALID:
      encoder.setElement(Key.ELEMENT, semantics.element);
      break;
    case AccessKind.COMPOUND:
      CompoundAccessSemantics compoundAccess = semantics;
      encoder.setEnum(Key.SUB_KIND, compoundAccess.compoundAccessKind);
      encoder.setElement(Key.GETTER, semantics.getter);
      encoder.setElement(Key.SETTER, semantics.setter);
      break;
    case AccessKind.CONSTANT:
      throw new UnsupportedError('Unsupported access kind: ${semantics.kind}');
  }
}

/// Deserialize a [AccessSemantics] from [decoder].
// ignore: MISSING_RETURN
AccessSemantics deserializeAccessSemantics(ObjectDecoder decoder) {
  AccessKind kind = decoder.getEnum(Key.KIND, AccessKind.values);
  switch (kind) {
    case AccessKind.EXPRESSION:
      return const DynamicAccess.expression();
    case AccessKind.THIS:
      return const DynamicAccess.thisAccess();
    case AccessKind.THIS_PROPERTY:
      return new DynamicAccess.thisProperty(deserializeName(decoder));
    case AccessKind.DYNAMIC_PROPERTY:
      return new DynamicAccess.dynamicProperty(deserializeName(decoder));
    case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
      return new DynamicAccess.ifNotNullProperty(deserializeName(decoder));
    case AccessKind.CLASS_TYPE_LITERAL:
    case AccessKind.TYPEDEF_TYPE_LITERAL:
    case AccessKind.DYNAMIC_TYPE_LITERAL:
      return new ConstantAccess(kind, decoder.getConstant(Key.CONSTANT));

    case AccessKind.LOCAL_FUNCTION:
    case AccessKind.LOCAL_VARIABLE:
    case AccessKind.FINAL_LOCAL_VARIABLE:
    case AccessKind.PARAMETER:
    case AccessKind.FINAL_PARAMETER:
    case AccessKind.STATIC_FIELD:
    case AccessKind.FINAL_STATIC_FIELD:
    case AccessKind.STATIC_METHOD:
    case AccessKind.STATIC_GETTER:
    case AccessKind.STATIC_SETTER:
    case AccessKind.TOPLEVEL_FIELD:
    case AccessKind.FINAL_TOPLEVEL_FIELD:
    case AccessKind.TOPLEVEL_METHOD:
    case AccessKind.TOPLEVEL_GETTER:
    case AccessKind.TOPLEVEL_SETTER:
    case AccessKind.SUPER_FIELD:
    case AccessKind.SUPER_FINAL_FIELD:
    case AccessKind.SUPER_METHOD:
    case AccessKind.SUPER_GETTER:
    case AccessKind.SUPER_SETTER:
    case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
    case AccessKind.UNRESOLVED:
    case AccessKind.UNRESOLVED_SUPER:
    case AccessKind.INVALID:
      return new StaticAccess.internal(kind, decoder.getElement(Key.ELEMENT));

    case AccessKind.COMPOUND:
      CompoundAccessKind compoundAccessKind =
          decoder.getEnum(Key.SUB_KIND, CompoundAccessKind.values);
      Element getter = decoder.getElement(Key.GETTER);
      Element setter = decoder.getElement(Key.SETTER);
      return new CompoundAccessSemantics(compoundAccessKind, getter, setter);
    case AccessKind.CONSTANT:
      throw new UnsupportedError('Unsupported access kind: $kind');
  }
}

/// Serialize a reference from [context] to an [element] which might be a member
/// of an unnamed mixin application. If it is, [element] is by serialized
/// indirectly by name in the [nameKey] of [encoder], otherwise [element] is
/// serialized directly in [elementKey] in [encoder].
void serializeElementReference(Element context, Key elementKey, Key nameKey,
    ObjectEncoder encoder, Element element) {
  if (element.isGenerativeConstructor &&
      element.enclosingClass.isUnnamedMixinApplication) {
    assert(invariant(element, element.isConstructor,
        message: "Unexpected reference of forwarding constructor "
            "${element} from $context."));
    encoder.setString(nameKey, element.name);
  } else {
    encoder.setElement(elementKey, element);
  }
}

/// Deserialize a reference from [context] to an [Element] which might be a
/// member of an unnamed mixin application. If it is, the [Element] is by
/// deserialized indirectly by name from [nameKey] in [decoder], otherwise
/// the [Element] is deserialized directly from [elementKey] in [encoder].
Element deserializeElementReference(
    Element context, Key elementKey, Key nameKey, ObjectDecoder decoder,
    {bool isOptional: false}) {
  Element element = decoder.getElement(elementKey, isOptional: true);
  if (element == null) {
    String elementName = decoder.getString(nameKey, isOptional: isOptional);
    if (elementName == null) {
      return null;
    }
    ClassElement cls;
    if (context is ClassElement) {
      assert(invariant(NO_LOCATION_SPANNABLE, context.isNamedMixinApplication,
          message: "Unexpected reference of forwarding constructor "
              "'${elementName}' from $context."));
      cls = context;
    } else {
      assert(invariant(NO_LOCATION_SPANNABLE, context.isConstructor,
          message: "Unexpected reference of forwarding constructor "
              "'${elementName}' from $context."));
      cls = context.enclosingClass;
    }
    ClassElement superclass = cls.superclass;
    element = superclass.lookupConstructor(elementName);
    assert(invariant(NO_LOCATION_SPANNABLE, element != null,
        message: "Unresolved reference of forwarding constructor "
            "'${elementName}' from $context."));
  }
  return element;
}

void serializeMessageArguments(
    ObjectEncoder encoder, Key key, Map<String, dynamic> messageArguments) {
  if (messageArguments.isNotEmpty) {
    MapEncoder mapEncoder = encoder.createMap(Key.ARGUMENTS);
    messageArguments.forEach((String key, var value) {
      mapEncoder.setString(key, Message.convertToString(value));
    });
  }
}

Map<String, String> deserializeMessageArguments(
    ObjectDecoder decoder, Key key) {
  Map<String, String> arguments = <String, String>{};
  MapDecoder mapDecoder = decoder.getMap(key, isOptional: true);
  if (mapDecoder != null) {
    mapDecoder.forEachKey((String key) {
      arguments[key] = mapDecoder.getString(key);
    });
  }
  return arguments;
}

void serializeSourceSpan(ObjectEncoder encoder, SourceSpan sourceSpan) {
  encoder.setUri(Key.URI, sourceSpan.uri, sourceSpan.uri);
  encoder.setInt(Key.OFFSET, sourceSpan.begin);
  encoder.setInt(Key.LENGTH, sourceSpan.end - sourceSpan.begin);
}

SourceSpan deserializeSourceSpan(ObjectDecoder decoder) {
  Uri uri = decoder.getUri(Key.URI);
  int offset = decoder.getInt(Key.OFFSET);
  int length = decoder.getInt(Key.LENGTH);
  return new SourceSpan(uri, offset, offset + length);
}

void serializeWrappedMessage(
    ObjectEncoder encoder, Key key, WrappedMessage message) {
  ObjectEncoder object = encoder.createObject(key);
  if (message.sourceSpan != null) {
    serializeSourceSpan(
        object.createObject(Key.SOURCE_SPAN), message.sourceSpan);
  }
  object.setEnum(Key.KIND, message.messageKind);
  serializeMessageArguments(object, Key.ARGUMENTS, message.messageArguments);
}

WrappedMessage deserializeWrappedMessage(ObjectDecoder decoder, Key key) {
  ObjectDecoder object = decoder.getObject(key);
  SourceSpan sourceSpan;
  ObjectDecoder sourceSpanDecoder =
      object.getObject(Key.SOURCE_SPAN, isOptional: true);
  if (sourceSpanDecoder != null) {
    sourceSpan = deserializeSourceSpan(sourceSpanDecoder);
  }
  MessageKind messageKind = object.getEnum(Key.KIND, MessageKind.values);
  Map<String, dynamic> messageArguments =
      deserializeMessageArguments(object, Key.ARGUMENTS);
  return new WrappedMessage(sourceSpan, messageKind, messageArguments);
}
