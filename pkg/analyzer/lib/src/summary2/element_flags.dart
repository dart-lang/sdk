// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';

class ClassElementFlags {
  static const int _hasExtendsClause = 1 << 0;
  static const int _isAbstract = 1 << 1;
  static const int _isAugmentation = 1 << 2;
  static const int _isBase = 1 << 3;
  static const int _isFinal = 1 << 4;
  static const int _isInterface = 1 << 5;
  static const int _isMacro = 1 << 6;
  static const int _isMixinApplication = 1 << 7;
  static const int _isMixinClass = 1 << 8;
  static const int _isSealed = 1 << 9;
  static const int _isSimplyBounded = 1 << 10;

  static void read(
    SummaryDataReader reader,
    ClassElementImpl element,
  ) {
    var byte = reader.readUInt30();
    element.hasExtendsClause = (byte & _hasExtendsClause) != 0;
    element.isAbstract = (byte & _isAbstract) != 0;
    element.isAugmentation = (byte & _isAugmentation) != 0;
    element.isBase = (byte & _isBase) != 0;
    element.isFinal = (byte & _isFinal) != 0;
    element.isInterface = (byte & _isInterface) != 0;
    element.isMacro = (byte & _isMacro) != 0;
    element.isMixinApplication = (byte & _isMixinApplication) != 0;
    element.isMixinClass = (byte & _isMixinClass) != 0;
    element.isSealed = (byte & _isSealed) != 0;
    element.isSimplyBounded = (byte & _isSimplyBounded) != 0;
  }

  static void write(
    BufferedSink sink,
    ClassElementImpl element,
  ) {
    var result = 0;
    result |= element.hasExtendsClause ? _hasExtendsClause : 0;
    result |= element.isAbstract ? _isAbstract : 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isBase ? _isBase : 0;
    result |= element.isFinal ? _isFinal : 0;
    result |= element.isInterface ? _isInterface : 0;
    result |= element.isMacro ? _isMacro : 0;
    result |= element.isMixinApplication ? _isMixinApplication : 0;
    result |= element.isMixinClass ? _isMixinClass : 0;
    result |= element.isSealed ? _isSealed : 0;
    result |= element.isSimplyBounded ? _isSimplyBounded : 0;
    sink.writeUInt30(result);
  }
}

class ConstructorElementFlags {
  static const int _isAugmentation = 1 << 0;
  static const int _isConst = 1 << 1;
  static const int _isExternal = 1 << 2;
  static const int _isFactory = 1 << 3;
  static const int _isSynthetic = 1 << 4;

  static void read(SummaryDataReader reader, ConstructorElementImpl element) {
    var byte = reader.readByte();
    element.isAugmentation = (byte & _isAugmentation) != 0;
    element.isConst = (byte & _isConst) != 0;
    element.isExternal = (byte & _isExternal) != 0;
    element.isFactory = (byte & _isFactory) != 0;
    element.isSynthetic = (byte & _isSynthetic) != 0;
  }

  static void write(BufferedSink sink, ConstructorElementImpl element) {
    var result = 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isConst ? _isConst : 0;
    result |= element.isExternal ? _isExternal : 0;
    result |= element.isFactory ? _isFactory : 0;
    result |= element.isSynthetic ? _isSynthetic : 0;
    sink.writeByte(result);
  }
}

class EnumElementFlags {
  static const int _isSimplyBounded = 1 << 0;
  static const int _isAugmentation = 1 << 1;

  static void read(SummaryDataReader reader, EnumElementImpl element) {
    var byte = reader.readByte();
    element.isSimplyBounded = (byte & _isSimplyBounded) != 0;
    element.isAugmentation = (byte & _isAugmentation) != 0;
  }

  static void write(BufferedSink sink, EnumElementImpl element) {
    var result = 0;
    result |= element.isSimplyBounded ? _isSimplyBounded : 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    sink.writeByte(result);
  }
}

class ExtensionElementFlags {
  static const int _isAugmentation = 1 << 0;

  static void read(
    SummaryDataReader reader,
    ExtensionElementImpl element,
  ) {
    var byte = reader.readByte();
    element.isAugmentation = (byte & _isAugmentation) != 0;
  }

  static void write(
    BufferedSink sink,
    ExtensionElementImpl element,
  ) {
    var result = 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    sink.writeByte(result);
  }
}

class ExtensionTypeElementFlags {
  static const int _hasRepresentationSelfReference = 1 << 0;
  static const int _hasImplementsSelfReference = 1 << 1;
  static const int _isAugmentation = 1 << 2;
  static const int _isAugmentationChainStart = 1 << 3;
  static const int _isSimplyBounded = 1 << 4;

  static void read(SummaryDataReader reader, ExtensionTypeElementImpl element) {
    var byte = reader.readByte();
    element.hasRepresentationSelfReference =
        (byte & _hasRepresentationSelfReference) != 0;
    element.hasImplementsSelfReference =
        (byte & _hasImplementsSelfReference) != 0;
    element.isAugmentation = (byte & _isAugmentation) != 0;
    element.isAugmentationChainStart = (byte & _isAugmentationChainStart) != 0;
    element.isSimplyBounded = (byte & _isSimplyBounded) != 0;
  }

  static void write(BufferedSink sink, ExtensionTypeElementImpl element) {
    var result = 0;
    result |= element.hasRepresentationSelfReference
        ? _hasRepresentationSelfReference
        : 0;
    result |=
        element.hasImplementsSelfReference ? _hasImplementsSelfReference : 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isAugmentationChainStart ? _isAugmentationChainStart : 0;
    result |= element.isSimplyBounded ? _isSimplyBounded : 0;
    sink.writeByte(result);
  }
}

class FieldElementFlags {
  static const int _hasImplicitType = 1 << 0;
  static const int _hasInitializer = 1 << 1;
  static const int _inheritsCovariant = 1 << 2;
  static const int _isAbstract = 1 << 3;
  static const int _isAugmentation = 1 << 4;
  static const int _isConst = 1 << 5;
  static const int _isCovariant = 1 << 6;
  static const int _isEnumConstant = 1 << 7;
  static const int _isExternal = 1 << 8;
  static const int _isFinal = 1 << 9;
  static const int _isLate = 1 << 10;
  static const int _isPromotable = 1 << 11;
  static const int _shouldUseTypeForInitializerInference = 1 << 12;
  static const int _isStatic = 1 << 13;
  static const int _isSynthetic = 1 << 14;

  static void read(SummaryDataReader reader, FieldElementImpl element) {
    var byte = reader.readUInt30();
    element.hasImplicitType = (byte & _hasImplicitType) != 0;
    element.hasInitializer = (byte & _hasInitializer) != 0;
    element.inheritsCovariant = (byte & _inheritsCovariant) != 0;
    element.isAbstract = (byte & _isAbstract) != 0;
    element.isAugmentation = (byte & _isAugmentation) != 0;
    element.isConst = (byte & _isConst) != 0;
    element.isCovariant = (byte & _isCovariant) != 0;
    element.isEnumConstant = (byte & _isEnumConstant) != 0;
    element.isExternal = (byte & _isExternal) != 0;
    element.isFinal = (byte & _isFinal) != 0;
    element.isLate = (byte & _isLate) != 0;
    element.isPromotable = (byte & _isPromotable) != 0;
    element.shouldUseTypeForInitializerInference =
        (byte & _shouldUseTypeForInitializerInference) != 0;
    element.isStatic = (byte & _isStatic) != 0;
    element.isSynthetic = (byte & _isSynthetic) != 0;
  }

  static void write(BufferedSink sink, FieldElementImpl element) {
    var result = 0;
    result |= element.hasImplicitType ? _hasImplicitType : 0;
    result |= element.hasInitializer ? _hasInitializer : 0;
    result |= element.inheritsCovariant ? _inheritsCovariant : 0;
    result |= element.isAbstract ? _isAbstract : 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isConst ? _isConst : 0;
    result |= element.isCovariant ? _isCovariant : 0;
    result |= element.isEnumConstant ? _isEnumConstant : 0;
    result |= element.isExternal ? _isExternal : 0;
    result |= element.isFinal ? _isFinal : 0;
    result |= element.isLate ? _isLate : 0;
    result |= element.isPromotable ? _isPromotable : 0;
    result |= element.shouldUseTypeForInitializerInference
        ? _shouldUseTypeForInitializerInference
        : 0;
    result |= element.isStatic ? _isStatic : 0;
    result |= element.isSynthetic ? _isSynthetic : 0;
    sink.writeUInt30(result);
  }
}

class FunctionElementFlags {
  static const int _hasImplicitReturnType = 1 << 0;
  static const int _isAsynchronous = 1 << 1;
  static const int _isAugmentation = 1 << 2;
  static const int _isExternal = 1 << 3;
  static const int _isGenerator = 1 << 4;
  static const int _isStatic = 1 << 5;

  static void read(SummaryDataReader reader, FunctionElementImpl element) {
    var byte = reader.readByte();
    element.hasImplicitReturnType = (byte & _hasImplicitReturnType) != 0;
    element.isAsynchronous = (byte & _isAsynchronous) != 0;
    element.isAugmentation = (byte & _isAugmentation) != 0;
    element.isExternal = (byte & _isExternal) != 0;
    element.isGenerator = (byte & _isGenerator) != 0;
    element.isStatic = (byte & _isStatic) != 0;
  }

  static void write(BufferedSink sink, FunctionElementImpl element) {
    var result = 0;
    result |= element.hasImplicitReturnType ? _hasImplicitReturnType : 0;
    result |= element.isAsynchronous ? _isAsynchronous : 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isExternal ? _isExternal : 0;
    result |= element.isGenerator ? _isGenerator : 0;
    result |= element.isStatic ? _isStatic : 0;
    sink.writeByte(result);
  }
}

class LibraryElementFlags {
  static const int _hasPartOfDirective = 1 << 0;
  static const int _isSynthetic = 1 << 1;

  static void read(SummaryDataReader reader, LibraryElementImpl element) {
    var byte = reader.readByte();
    element.hasPartOfDirective = (byte & _hasPartOfDirective) != 0;
    element.isSynthetic = (byte & _isSynthetic) != 0;
  }

  static void write(BufferedSink sink, LibraryElementImpl element) {
    var result = 0;
    result |= element.hasPartOfDirective ? _hasPartOfDirective : 0;
    result |= element.isSynthetic ? _isSynthetic : 0;
    sink.writeByte(result);
  }
}

class LibraryImportElementFlags {
  static const int _isSynthetic = 1 << 0;

  static void read(SummaryDataReader reader, LibraryImportElementImpl element) {
    var byte = reader.readByte();
    element.isSynthetic = (byte & _isSynthetic) != 0;
  }

  static void write(BufferedSink sink, LibraryImportElementImpl element) {
    var result = 0;
    result |= element.isSynthetic ? _isSynthetic : 0;
    sink.writeByte(result);
  }
}

class MethodElementFlags {
  static const int _hasImplicitReturnType = 1 << 0;
  static const int _invokesSuperSelf = 1 << 1;
  static const int _isAbstract = 1 << 2;
  static const int _isAsynchronous = 1 << 3;
  static const int _isAugmentation = 1 << 4;
  static const int _isExtensionTypeMember = 1 << 5;
  static const int _isExternal = 1 << 6;
  static const int _isGenerator = 1 << 7;
  static const int _isStatic = 1 << 8;
  static const int _isSynthetic = 1 << 9;

  static void read(SummaryDataReader reader, MethodElementImpl element) {
    var bits = reader.readUInt30();
    element.hasImplicitReturnType = (bits & _hasImplicitReturnType) != 0;
    element.invokesSuperSelf = (bits & _invokesSuperSelf) != 0;
    element.isAbstract = (bits & _isAbstract) != 0;
    element.isAsynchronous = (bits & _isAsynchronous) != 0;
    element.isAugmentation = (bits & _isAugmentation) != 0;
    element.isExtensionTypeMember = (bits & _isExtensionTypeMember) != 0;
    element.isExternal = (bits & _isExternal) != 0;
    element.isGenerator = (bits & _isGenerator) != 0;
    element.isStatic = (bits & _isStatic) != 0;
    element.isSynthetic = (bits & _isSynthetic) != 0;
  }

  static void write(BufferedSink sink, MethodElementImpl element) {
    var result = 0;
    result |= element.hasImplicitReturnType ? _hasImplicitReturnType : 0;
    result |= element.invokesSuperSelf ? _invokesSuperSelf : 0;
    result |= element.isAbstract ? _isAbstract : 0;
    result |= element.isAsynchronous ? _isAsynchronous : 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isExtensionTypeMember ? _isExtensionTypeMember : 0;
    result |= element.isExternal ? _isExternal : 0;
    result |= element.isGenerator ? _isGenerator : 0;
    result |= element.isStatic ? _isStatic : 0;
    result |= element.isSynthetic ? _isSynthetic : 0;
    sink.writeUInt30(result);
  }
}

class MixinElementFlags {
  static const int _isAugmentation = 1 << 0;
  static const int _isBase = 1 << 1;
  static const int _isSimplyBounded = 1 << 2;

  static void read(
    SummaryDataReader reader,
    MixinElementImpl element,
  ) {
    var byte = reader.readByte();
    element.isAugmentation = (byte & _isAugmentation) != 0;
    element.isBase = (byte & _isBase) != 0;
    element.isSimplyBounded = (byte & _isSimplyBounded) != 0;
  }

  static void write(BufferedSink sink, MixinElementImpl element) {
    var result = 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isBase ? _isBase : 0;
    result |= element.isSimplyBounded ? _isSimplyBounded : 0;
    sink.writeByte(result);
  }
}

class ParameterElementFlags {
  static const int _hasImplicitType = 1 << 0;
  static const int _inheritsCovariant = 1 << 1;
  static const int _isExplicitlyCovariant = 1 << 2;
  static const int _isFinal = 1 << 3;

  static void read(SummaryDataReader reader, ParameterElementImpl element) {
    var byte = reader.readByte();
    element.hasImplicitType = (byte & _hasImplicitType) != 0;
    element.inheritsCovariant = (byte & _inheritsCovariant) != 0;
    element.isExplicitlyCovariant = (byte & _isExplicitlyCovariant) != 0;
    element.isFinal = (byte & _isFinal) != 0;
  }

  static void write(BufferedSink sink, ParameterElementImpl element) {
    var result = 0;
    result |= element.hasImplicitType ? _hasImplicitType : 0;
    result |= element.inheritsCovariant ? _inheritsCovariant : 0;
    result |= element.isExplicitlyCovariant ? _isExplicitlyCovariant : 0;
    result |= element.isFinal ? _isFinal : 0;
    sink.writeByte(result);
  }
}

class PropertyAccessorElementFlags {
  static const int _invokesSuperSelf = 1 << 0;
  static const int _isAugmentation = 1 << 1;
  static const int _isGetter = 1 << 2;
  static const int _isSetter = 1 << 3;
  static const int _hasImplicitReturnType = 1 << 4;
  static const int _isAbstract = 1 << 5;
  static const int _isAsynchronous = 1 << 6;
  static const int _isExtensionTypeMember = 1 << 7;
  static const int _isExternal = 1 << 8;
  static const int _isGenerator = 1 << 9;
  static const int _isStatic = 1 << 10;

  static void read(
    SummaryDataReader reader,
    PropertyAccessorElementImpl element,
  ) {
    var byte = reader.readUInt30();
    element.invokesSuperSelf = (byte & _invokesSuperSelf) != 0;
    element.isAugmentation = (byte & _isAugmentation) != 0;
    element.isGetter = (byte & _isGetter) != 0;
    element.isSetter = (byte & _isSetter) != 0;
    element.hasImplicitReturnType = (byte & _hasImplicitReturnType) != 0;
    element.isAbstract = (byte & _isAbstract) != 0;
    element.isAsynchronous = (byte & _isAsynchronous) != 0;
    element.isExtensionTypeMember = (byte & _isExtensionTypeMember) != 0;
    element.isExternal = (byte & _isExternal) != 0;
    element.isGenerator = (byte & _isGenerator) != 0;
    element.isStatic = (byte & _isStatic) != 0;
  }

  static void write(BufferedSink sink, PropertyAccessorElementImpl element) {
    var result = 0;
    result |= element.invokesSuperSelf ? _invokesSuperSelf : 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isGetter ? _isGetter : 0;
    result |= element.isSetter ? _isSetter : 0;
    result |= element.hasImplicitReturnType ? _hasImplicitReturnType : 0;
    result |= element.isAbstract ? _isAbstract : 0;
    result |= element.isAsynchronous ? _isAsynchronous : 0;
    result |= element.isExtensionTypeMember ? _isExtensionTypeMember : 0;
    result |= element.isExternal ? _isExternal : 0;
    result |= element.isGenerator ? _isGenerator : 0;
    result |= element.isStatic ? _isStatic : 0;
    sink.writeUInt30(result);
  }
}

class TopLevelVariableElementFlags {
  static const int _hasImplicitType = 1 << 0;
  static const int _hasInitializer = 1 << 1;
  static const int _isAugmentation = 1 << 2;
  static const int _isExternal = 1 << 3;
  static const int _isFinal = 1 << 4;
  static const int _isLate = 1 << 5;
  static const int _shouldUseTypeForInitializerInference = 1 << 6;

  static void read(
    SummaryDataReader reader,
    TopLevelVariableElementImpl element,
  ) {
    var byte = reader.readByte();
    element.hasImplicitType = (byte & _hasImplicitType) != 0;
    element.hasInitializer = (byte & _hasInitializer) != 0;
    element.isAugmentation = (byte & _isAugmentation) != 0;
    element.isExternal = (byte & _isExternal) != 0;
    element.isFinal = (byte & _isFinal) != 0;
    element.isLate = (byte & _isLate) != 0;
    element.shouldUseTypeForInitializerInference =
        (byte & _shouldUseTypeForInitializerInference) != 0;
  }

  static void write(BufferedSink sink, TopLevelVariableElementImpl element) {
    var result = 0;
    result |= element.hasImplicitType ? _hasImplicitType : 0;
    result |= element.hasInitializer ? _hasInitializer : 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isExternal ? _isExternal : 0;
    result |= element.isFinal ? _isFinal : 0;
    result |= element.isLate ? _isLate : 0;
    result |= element.shouldUseTypeForInitializerInference
        ? _shouldUseTypeForInitializerInference
        : 0;
    sink.writeByte(result);
  }
}

class TypeAliasElementFlags {
  static const int _hasSelfReference = 1 << 1;
  static const int _isAugmentation = 1 << 2;
  static const int _isSimplyBounded = 1 << 3;

  static void read(SummaryDataReader reader, TypeAliasElementImpl element) {
    var byte = reader.readByte();
    element.hasSelfReference = (byte & _hasSelfReference) != 0;
    element.isAugmentation = (byte & _isAugmentation) != 0;
    element.isSimplyBounded = (byte & _isSimplyBounded) != 0;
  }

  static void write(BufferedSink sink, TypeAliasElementImpl element) {
    var result = 0;
    result |= element.hasSelfReference ? _hasSelfReference : 0;
    result |= element.isAugmentation ? _isAugmentation : 0;
    result |= element.isSimplyBounded ? _isSimplyBounded : 0;
    sink.writeByte(result);
  }
}
