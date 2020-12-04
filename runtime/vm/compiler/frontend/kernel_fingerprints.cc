// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_fingerprints.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"

#define H (translation_helper_)
#define I Isolate::Current()

namespace dart {
namespace kernel {

class KernelFingerprintHelper : public KernelReaderHelper {
 public:
  KernelFingerprintHelper(Zone* zone,
                          TranslationHelper* translation_helper,
                          const Script& script,
                          const ExternalTypedData& data,
                          intptr_t data_program_offset)
      : KernelReaderHelper(zone,
                           translation_helper,
                           script,
                           data,
                           data_program_offset),
        hash_(0) {}

  virtual ~KernelFingerprintHelper() {}
  uint32_t CalculateFieldFingerprint();
  uint32_t CalculateFunctionFingerprint();

  static uint32_t CalculateHash(uint32_t current, uint32_t val) {
    return current * 31 + val;
  }

 private:
  void BuildHash(uint32_t val);
  void CalculateConstructorFingerprint();
  void CalculateArgumentsFingerprint();
  void CalculateVariableDeclarationFingerprint();
  void CalculateStatementListFingerprint();
  void CalculateListOfExpressionsFingerprint();
  void CalculateListOfDartTypesFingerprint();
  void CalculateListOfVariableDeclarationsFingerprint();
  void CalculateStringReferenceFingerprint();
  void CalculateListOfStringsFingerprint();
  void CalculateTypeParameterFingerprint();
  void CalculateTypeParametersListFingerprint();
  void CalculateCanonicalNameFingerprint();
  void CalculateInterfaceMemberNameFingerprint();
  void CalculateInitializerFingerprint();
  void CalculateDartTypeFingerprint();
  void CalculateOptionalDartTypeFingerprint();
  void CalculateInterfaceTypeFingerprint(bool simple);
  void CalculateFunctionTypeFingerprint(bool simple);
  void CalculateGetterNameFingerprint();
  void CalculateSetterNameFingerprint();
  void CalculateMethodNameFingerprint();
  void CalculateExpressionFingerprint();
  void CalculateStatementFingerprint();
  void CalculateFunctionNodeFingerprint();

  uint32_t hash_;

  DISALLOW_COPY_AND_ASSIGN(KernelFingerprintHelper);
};

void KernelFingerprintHelper::BuildHash(uint32_t val) {
  hash_ = CalculateHash(hash_, val);
}

void KernelFingerprintHelper::CalculateConstructorFingerprint() {
  ConstructorHelper helper(this);

  helper.ReadUntilExcluding(ConstructorHelper::kAnnotations);
  CalculateListOfExpressionsFingerprint();
  CalculateFunctionNodeFingerprint();
  intptr_t len = ReadListLength();
  for (intptr_t i = 0; i < len; ++i) {
    CalculateInitializerFingerprint();
  }
  helper.SetJustRead(ConstructorHelper::kInitializers);
  BuildHash(helper.flags_);
}

void KernelFingerprintHelper::CalculateArgumentsFingerprint() {
  BuildHash(ReadUInt());  // read argument count.

  CalculateListOfDartTypesFingerprint();    // read list of types.
  CalculateListOfExpressionsFingerprint();  // read positionals.

  // List of named.
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    CalculateStringReferenceFingerprint();  // read ith name index.
    CalculateExpressionFingerprint();       // read ith expression.
  }
}

void KernelFingerprintHelper::CalculateVariableDeclarationFingerprint() {
  VariableDeclarationHelper helper(this);

  helper.ReadUntilExcluding(VariableDeclarationHelper::kAnnotations);
  CalculateListOfExpressionsFingerprint();
  helper.SetJustRead(VariableDeclarationHelper::kAnnotations);

  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  // We don't need to use the helper after this point.
  CalculateDartTypeFingerprint();
  if (ReadTag() == kSomething) {
    CalculateExpressionFingerprint();
  }

  BuildHash(helper.flags_);
}

void KernelFingerprintHelper::CalculateStatementListFingerprint() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    CalculateStatementFingerprint();  // read ith expression.
  }
}

void KernelFingerprintHelper::CalculateListOfExpressionsFingerprint() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    CalculateExpressionFingerprint();  // read ith expression.
  }
}

void KernelFingerprintHelper::CalculateListOfDartTypesFingerprint() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    CalculateDartTypeFingerprint();  // read ith type.
  }
}

void KernelFingerprintHelper::CalculateStringReferenceFingerprint() {
  BuildHash(
      H.DartString(ReadStringReference()).Hash());  // read ith string index.
}

void KernelFingerprintHelper::CalculateListOfStringsFingerprint() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    CalculateStringReferenceFingerprint();  // read ith string index.
  }
}

void KernelFingerprintHelper::CalculateListOfVariableDeclarationsFingerprint() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    // read ith variable declaration.
    CalculateVariableDeclarationFingerprint();
  }
}

void KernelFingerprintHelper::CalculateTypeParameterFingerprint() {
  TypeParameterHelper helper(this);

  helper.ReadUntilExcluding(TypeParameterHelper::kAnnotations);
  CalculateListOfExpressionsFingerprint();
  helper.SetJustRead(TypeParameterHelper::kAnnotations);

  helper.ReadUntilExcluding(TypeParameterHelper::kVariance);
  Variance variance = ReadVariance();
  BuildHash(variance);
  helper.SetJustRead(TypeParameterHelper::kVariance);

  helper.ReadUntilExcluding(TypeParameterHelper::kBound);
  // The helper isn't needed after this point.
  CalculateDartTypeFingerprint();
  if (ReadTag() == kSomething) {
    CalculateDartTypeFingerprint();
  }
  BuildHash(helper.flags_);
}

void KernelFingerprintHelper::CalculateTypeParametersListFingerprint() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    CalculateTypeParameterFingerprint();
  }
}

void KernelFingerprintHelper::CalculateCanonicalNameFingerprint() {
  const StringIndex i = H.CanonicalNameString(ReadCanonicalNameReference());
  BuildHash(H.DartString(i).Hash());
}

void KernelFingerprintHelper::CalculateInterfaceMemberNameFingerprint() {
  CalculateCanonicalNameFingerprint();
  ReadCanonicalNameReference();  // read target_origin_reference
}

void KernelFingerprintHelper::CalculateInitializerFingerprint() {
  Tag tag = ReadTag();
  ReadByte();  // read isSynthetic flag.
  switch (tag) {
    case kInvalidInitializer:
      return;
    case kFieldInitializer:
      BuildHash(H.DartFieldName(ReadCanonicalNameReference()).Hash());
      CalculateExpressionFingerprint();  // read value.
      return;
    case kSuperInitializer:
      ReadPosition();                       // read position.
      CalculateCanonicalNameFingerprint();  // read target_reference
      CalculateArgumentsFingerprint();      // read arguments.
      return;
    case kRedirectingInitializer:
      ReadPosition();                       // read position.
      CalculateCanonicalNameFingerprint();  // read target_reference
      CalculateArgumentsFingerprint();      // read arguments.
      return;
    case kLocalInitializer:
      CalculateVariableDeclarationFingerprint();  // read variable.
      return;
    case kAssertInitializer:
      CalculateStatementFingerprint();
      return;
    default:
      ReportUnexpectedTag("initializer", tag);
      UNREACHABLE();
  }
}

void KernelFingerprintHelper::CalculateDartTypeFingerprint() {
  Tag tag = ReadTag();
  BuildHash(tag);
  switch (tag) {
    case kInvalidType:
    case kDynamicType:
    case kVoidType:
    case kBottomType:
      // those contain nothing.
      break;
    case kNeverType:
      BuildHash(static_cast<uint32_t>(ReadNullability()));
      break;
    case kInterfaceType:
      CalculateInterfaceTypeFingerprint(false);
      break;
    case kSimpleInterfaceType:
      CalculateInterfaceTypeFingerprint(true);
      break;
    case kFunctionType:
      CalculateFunctionTypeFingerprint(false);
      break;
    case kSimpleFunctionType:
      CalculateFunctionTypeFingerprint(true);
      break;
    case kTypeParameterType: {
      Nullability nullability = ReadNullability();
      BuildHash(static_cast<uint32_t>(nullability));
      ReadUInt();                              // read index for parameter.
      CalculateOptionalDartTypeFingerprint();  // read bound bound.
      break;
    }
    default:
      ReportUnexpectedTag("type", tag);
      UNREACHABLE();
  }
}

void KernelFingerprintHelper::CalculateOptionalDartTypeFingerprint() {
  Tag tag = ReadTag();  // read tag.
  BuildHash(tag);
  if (tag == kNothing) {
    return;
  }
  ASSERT(tag == kSomething);
  CalculateDartTypeFingerprint();  // read type.
}

void KernelFingerprintHelper::CalculateInterfaceTypeFingerprint(bool simple) {
  Nullability nullability = ReadNullability();
  BuildHash(static_cast<uint32_t>(nullability));
  NameIndex kernel_class = ReadCanonicalNameReference();
  ASSERT(H.IsClass(kernel_class));
  const String& class_name = H.DartClassName(kernel_class);
  NameIndex kernel_library = H.CanonicalNameParent(kernel_class);
  const String& library_name =
      H.DartSymbolPlain(H.CanonicalNameString(kernel_library));
  BuildHash(class_name.Hash());
  BuildHash(library_name.Hash());
  if (!simple) {
    CalculateListOfDartTypesFingerprint();  // read list of types.
  }
}

void KernelFingerprintHelper::CalculateFunctionTypeFingerprint(bool simple) {
  Nullability nullability = ReadNullability();
  BuildHash(static_cast<uint32_t>(nullability));

  if (!simple) {
    CalculateTypeParametersListFingerprint();  // read type_parameters.
    BuildHash(ReadUInt());                     // read required parameter count.
    BuildHash(ReadUInt());                     // read total parameter count.
  }

  CalculateListOfDartTypesFingerprint();  // read positional_parameters types.

  if (!simple) {
    const intptr_t named_count =
        ReadListLength();  // read named_parameters list length.
    BuildHash(named_count);
    for (intptr_t i = 0; i < named_count; ++i) {
      // read string reference (i.e. named_parameters[i].name).
      CalculateStringReferenceFingerprint();
      CalculateDartTypeFingerprint();  // read named_parameters[i].type.
      BuildHash(ReadFlags());          // read flags.
    }
  }

  if (!simple) {
    // TODO(bkonyi): include in hash.
    SkipOptionalDartType();  // read typedef type.
  }

  CalculateDartTypeFingerprint();  // read return type.
}

void KernelFingerprintHelper::CalculateGetterNameFingerprint() {
  const NameIndex name = ReadCanonicalNameReference();
  if (!H.IsRoot(name) && (H.IsGetter(name) || H.IsField(name))) {
    BuildHash(H.DartGetterName(name).Hash());
  }
  ReadCanonicalNameReference();  // read interface_target_origin_reference
}

void KernelFingerprintHelper::CalculateSetterNameFingerprint() {
  const NameIndex name = ReadCanonicalNameReference();
  if (!H.IsRoot(name)) {
    BuildHash(H.DartSetterName(name).Hash());
  }
  ReadCanonicalNameReference();  // read interface_target_origin_reference
}

void KernelFingerprintHelper::CalculateMethodNameFingerprint() {
  const NameIndex name =
      ReadCanonicalNameReference();  // read interface_target_reference.
  if (!H.IsRoot(name) && !H.IsField(name)) {
    BuildHash(H.DartProcedureName(name).Hash());
  }
  ReadCanonicalNameReference();  // read interface_target_origin_reference
}

void KernelFingerprintHelper::CalculateExpressionFingerprint() {
  uint8_t payload = 0;
  Tag tag = ReadTag(&payload);
  BuildHash(tag);
  switch (tag) {
    case kInvalidExpression:
      ReadPosition();
      CalculateStringReferenceFingerprint();
      return;
    case kVariableGet:
      ReadPosition();                          // read position.
      ReadUInt();                              // read kernel position.
      ReadUInt();                              // read relative variable index.
      CalculateOptionalDartTypeFingerprint();  // read promoted type.
      return;
    case kSpecializedVariableGet:
      ReadPosition();  // read position.
      ReadUInt();      // read kernel position.
      return;
    case kVariableSet:
      ReadPosition();                    // read position.
      ReadUInt();                        // read kernel position.
      ReadUInt();                        // read relative variable index.
      CalculateExpressionFingerprint();  // read expression.
      return;
    case kSpecializedVariableSet:
      ReadPosition();                    // read position.
      ReadUInt();                        // read kernel position.
      CalculateExpressionFingerprint();  // read expression.
      return;
    case kPropertyGet:
      ReadPosition();                            // read position.
      CalculateExpressionFingerprint();          // read receiver.
      BuildHash(ReadNameAsGetterName().Hash());  // read name.
      CalculateGetterNameFingerprint();  // read interface_target_reference.
      return;
    case kPropertySet:
      ReadPosition();                            // read position.
      CalculateExpressionFingerprint();          // read receiver.
      BuildHash(ReadNameAsSetterName().Hash());  // read name.
      CalculateExpressionFingerprint();          // read value.
      CalculateSetterNameFingerprint();  // read interface_target_reference.
      return;
    case kSuperPropertyGet:
      ReadPosition();                            // read position.
      BuildHash(ReadNameAsGetterName().Hash());  // read name.
      CalculateGetterNameFingerprint();  // read interface_target_reference.
      return;
    case kSuperPropertySet:
      ReadPosition();                            // read position.
      BuildHash(ReadNameAsSetterName().Hash());  // read name.
      CalculateExpressionFingerprint();          // read value.
      CalculateSetterNameFingerprint();  // read interface_target_reference.
      return;
    case kStaticGet:
      ReadPosition();                       // read position.
      CalculateCanonicalNameFingerprint();  // read target_reference.
      return;
    case kStaticSet:
      ReadPosition();                       // read position.
      CalculateCanonicalNameFingerprint();  // read target_reference.
      CalculateExpressionFingerprint();     // read expression.
      return;
    case kMethodInvocation:
      ReadFlags();                               // read flags.
      ReadPosition();                            // read position.
      CalculateExpressionFingerprint();          // read receiver.
      BuildHash(ReadNameAsMethodName().Hash());  // read name.
      CalculateArgumentsFingerprint();           // read arguments.
      CalculateMethodNameFingerprint();  // read interface_target_reference.
      return;
    case kSuperMethodInvocation:
      ReadPosition();                            // read position.
      BuildHash(ReadNameAsMethodName().Hash());  // read name.
      CalculateArgumentsFingerprint();           // read arguments.
      CalculateInterfaceMemberNameFingerprint();  // read target_reference.
      return;
    case kStaticInvocation:
      ReadPosition();                       // read position.
      CalculateCanonicalNameFingerprint();  // read target_reference.
      CalculateArgumentsFingerprint();      // read arguments.
      return;
    case kConstructorInvocation:
      ReadPosition();                       // read position.
      CalculateCanonicalNameFingerprint();  // read target_reference.
      CalculateArgumentsFingerprint();      // read arguments.
      return;
    case kNot:
      CalculateExpressionFingerprint();  // read expression.
      return;
    case kNullCheck:
      ReadPosition();                    // read position.
      CalculateExpressionFingerprint();  // read expression.
      return;
    case kLogicalExpression:
      CalculateExpressionFingerprint();  // read left.
      SkipBytes(1);                      // read operator.
      CalculateExpressionFingerprint();  // read right.
      return;
    case kConditionalExpression:
      CalculateExpressionFingerprint();        // read condition.
      CalculateExpressionFingerprint();        // read then.
      CalculateExpressionFingerprint();        // read otherwise.
      CalculateOptionalDartTypeFingerprint();  // read unused static type.
      return;
    case kStringConcatenation:
      ReadPosition();                           // read position.
      CalculateListOfExpressionsFingerprint();  // read list of expressions.
      return;
    case kIsExpression:
      ReadPosition();                    // read position.
      if (translation_helper_.info().kernel_binary_version() >= 38) {
        BuildHash(ReadFlags());  // read flags.
      }
      CalculateExpressionFingerprint();  // read operand.
      CalculateDartTypeFingerprint();    // read type.
      return;
    case kAsExpression:
      ReadPosition();                    // read position.
      BuildHash(ReadFlags());            // read flags.
      CalculateExpressionFingerprint();  // read operand.
      CalculateDartTypeFingerprint();    // read type.
      return;
    case kTypeLiteral:
      CalculateDartTypeFingerprint();  // read type.
      return;
    case kThisExpression:
      return;
    case kRethrow:
      ReadPosition();  // read position.
      return;
    case kThrow:
      ReadPosition();                    // read position.
      CalculateExpressionFingerprint();  // read expression.
      return;
    case kListLiteral:
      ReadPosition();                           // read position.
      CalculateDartTypeFingerprint();           // read type.
      CalculateListOfExpressionsFingerprint();  // read list of expressions.
      return;
    case kSetLiteral:
      // Set literals are currently desugared in the frontend and will not
      // reach the VM. See http://dartbug.com/35124 for discussion.
      UNREACHABLE();
      return;
    case kMapLiteral: {
      ReadPosition();                           // read position.
      CalculateDartTypeFingerprint();           // read type.
      CalculateDartTypeFingerprint();           // read value type.
      intptr_t list_length = ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        CalculateExpressionFingerprint();  // read ith key.
        CalculateExpressionFingerprint();  // read ith value.
      }
      return;
    }
    case kFunctionExpression:
      ReadPosition();                      // read position.
      CalculateFunctionNodeFingerprint();  // read function node.
      return;
    case kLet:
      CalculateVariableDeclarationFingerprint();  // read variable declaration.
      CalculateExpressionFingerprint();           // read expression.
      return;
    case kBlockExpression:
      CalculateStatementListFingerprint();
      CalculateExpressionFingerprint();  // read expression.
      return;
    case kInstantiation:
      CalculateExpressionFingerprint();       // read expression.
      CalculateListOfDartTypesFingerprint();  // read type arguments.
      return;
    case kBigIntLiteral:
      CalculateStringReferenceFingerprint();  // read string reference.
      return;
    case kStringLiteral:
      CalculateStringReferenceFingerprint();  // read string reference.
      return;
    case kSpecializedIntLiteral:
      return;
    case kNegativeIntLiteral:
      BuildHash(ReadUInt());  // read value.
      return;
    case kPositiveIntLiteral:
      BuildHash(ReadUInt());  // read value.
      return;
    case kDoubleLiteral: {
      double value = ReadDouble();  // read value.
      uint64_t data = bit_cast<uint64_t>(value);
      BuildHash(static_cast<uint32_t>(data >> 32));
      BuildHash(static_cast<uint32_t>(data));
      return;
    }
    case kTrueLiteral:
      return;
    case kFalseLiteral:
      return;
    case kNullLiteral:
      return;
    case kConstantExpression:
      ReadPosition();
      SkipDartType();
      SkipConstantReference();
      return;
    case kLoadLibrary:
    case kCheckLibraryIsLoaded:
      ReadUInt();  // skip library index
      return;
    case kConstStaticInvocation:
    case kConstConstructorInvocation:
    case kConstListLiteral:
    case kConstSetLiteral:
    case kConstMapLiteral:
    case kSymbolLiteral:
      // Const invocations and const literals are removed by the
      // constant evaluator.
    case kListConcatenation:
    case kSetConcatenation:
    case kMapConcatenation:
    case kInstanceCreation:
    case kFileUriExpression:
      // Collection concatenation, instance creation operations and
      // in-expression URI changes are internal to the front end and
      // removed by the constant evaluator.
    default:
      ReportUnexpectedTag("expression", tag);
      UNREACHABLE();
  }
}

void KernelFingerprintHelper::CalculateStatementFingerprint() {
  Tag tag = ReadTag();  // read tag.
  BuildHash(tag);
  switch (tag) {
    case kExpressionStatement:
      CalculateExpressionFingerprint();  // read expression.
      return;
    case kBlock:
      ReadPosition();  // read file offset.
      ReadPosition();  // read file end offset.
      CalculateStatementListFingerprint();
      return;
    case kEmptyStatement:
      return;
    case kAssertBlock:
      CalculateStatementListFingerprint();
      return;
    case kAssertStatement:
      CalculateExpressionFingerprint();  // Read condition.
      ReadPosition();                    // read condition start offset.
      ReadPosition();                    // read condition end offset.
      if (ReadTag() == kSomething) {
        CalculateExpressionFingerprint();  // read (rest of) message.
      }
      return;
    case kLabeledStatement:
      CalculateStatementFingerprint();  // read body.
      return;
    case kBreakStatement:
      ReadPosition();  // read position.
      ReadUInt();      // read target_index.
      return;
    case kWhileStatement:
      ReadPosition();                    // read position.
      CalculateExpressionFingerprint();  // read condition.
      CalculateStatementFingerprint();   // read body.
      return;
    case kDoStatement:
      ReadPosition();                    // read position.
      CalculateStatementFingerprint();   // read body.
      CalculateExpressionFingerprint();  // read condition.
      return;
    case kForStatement: {
      ReadPosition();                                    // read position.
      CalculateListOfVariableDeclarationsFingerprint();  // read variables.
      Tag tag = ReadTag();  // Read first part of condition.
      if (tag == kSomething) {
        CalculateExpressionFingerprint();  // read rest of condition.
      }
      CalculateListOfExpressionsFingerprint();  // read updates.
      CalculateStatementFingerprint();          // read body.
      return;
    }
    case kForInStatement:
    case kAsyncForInStatement:
      ReadPosition();                             // read position.
      ReadPosition();                             // read body position.
      CalculateVariableDeclarationFingerprint();  // read variable.
      CalculateExpressionFingerprint();           // read iterable.
      CalculateStatementFingerprint();            // read body.
      return;
    case kSwitchStatement: {
      ReadPosition();                     // read position.
      CalculateExpressionFingerprint();   // read condition.
      int case_count = ReadListLength();  // read number of cases.
      for (intptr_t i = 0; i < case_count; ++i) {
        int expression_count = ReadListLength();  // read number of expressions.
        for (intptr_t j = 0; j < expression_count; ++j) {
          ReadPosition();                    // read jth position.
          CalculateExpressionFingerprint();  // read jth expression.
        }
        BuildHash(static_cast<uint32_t>(ReadBool()));  // read is_default.
        CalculateStatementFingerprint();  // read body.
      }
      return;
    }
    case kContinueSwitchStatement:
      ReadPosition();  // read position.
      ReadUInt();      // read target_index.
      return;
    case kIfStatement:
      ReadPosition();                    // read position.
      CalculateExpressionFingerprint();  // read condition.
      CalculateStatementFingerprint();   // read then.
      CalculateStatementFingerprint();   // read otherwise.
      return;
    case kReturnStatement: {
      ReadPosition();       // read position
      Tag tag = ReadTag();  // read (first part of) expression.
      BuildHash(tag);
      if (tag == kSomething) {
        CalculateExpressionFingerprint();  // read (rest of) expression.
      }
      return;
    }
    case kTryCatch: {
      CalculateStatementFingerprint();          // read body.
      BuildHash(ReadByte());                    // read flags
      intptr_t catch_count = ReadListLength();  // read number of catches.
      for (intptr_t i = 0; i < catch_count; ++i) {
        ReadPosition();                  // read position.
        CalculateDartTypeFingerprint();  // read guard.
        tag = ReadTag();                 // read first part of exception.
        BuildHash(tag);
        if (tag == kSomething) {
          CalculateVariableDeclarationFingerprint();  // read exception.
        }
        tag = ReadTag();  // read first part of stack trace.
        BuildHash(tag);
        if (tag == kSomething) {
          CalculateVariableDeclarationFingerprint();  // read stack trace.
        }
        CalculateStatementFingerprint();  // read body.
      }
      return;
    }
    case kTryFinally:
      CalculateStatementFingerprint();  // read body.
      CalculateStatementFingerprint();  // read finalizer.
      return;
    case kYieldStatement: {
      ReadPosition();                    // read position.
      BuildHash(ReadByte());             // read flags.
      CalculateExpressionFingerprint();  // read expression.
      return;
    }
    case kVariableDeclaration:
      CalculateVariableDeclarationFingerprint();  // read variable declaration.
      return;
    case kFunctionDeclaration:
      ReadPosition();                             // read position.
      CalculateVariableDeclarationFingerprint();  // read variable.
      CalculateFunctionNodeFingerprint();         // read function node.
      return;
    default:
      ReportUnexpectedTag("statement", tag);
      UNREACHABLE();
  }
}

uint32_t KernelFingerprintHelper::CalculateFieldFingerprint() {
  hash_ = 0;
  FieldHelper field_helper(this);

  field_helper.ReadUntilExcluding(FieldHelper::kName);
  const String& name = ReadNameAsFieldName();  // read name.
  field_helper.SetJustRead(FieldHelper::kName);

  field_helper.ReadUntilExcluding(FieldHelper::kType);
  CalculateDartTypeFingerprint();  // read type.
  field_helper.SetJustRead(FieldHelper::kType);

  if (ReadTag() == kSomething) {
    if (PeekTag() == kFunctionExpression) {
      AlternativeReadingScope alt(&reader_);
      CalculateExpressionFingerprint();
    }
    SkipExpression();
  }

  BuildHash(name.Hash());
  BuildHash(field_helper.flags_);
  BuildHash(field_helper.annotation_count_);
  return hash_;
}

void KernelFingerprintHelper::CalculateFunctionNodeFingerprint() {
  FunctionNodeHelper function_node_helper(this);

  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);
  CalculateTypeParametersListFingerprint();
  function_node_helper.SetJustRead(FunctionNodeHelper::kTypeParameters);

  function_node_helper.ReadUntilExcluding(
      FunctionNodeHelper::kPositionalParameters);
  CalculateListOfVariableDeclarationsFingerprint();  // read positionals
  CalculateListOfVariableDeclarationsFingerprint();  // read named
  CalculateDartTypeFingerprint();                    // read return type.

  if (ReadTag() == kSomething) {
    CalculateStatementFingerprint();  // Read body.
  }
  BuildHash(function_node_helper.total_parameter_count_);
  BuildHash(function_node_helper.required_parameter_count_);
}

uint32_t KernelFingerprintHelper::CalculateFunctionFingerprint() {
  hash_ = 0;
  Tag tag = PeekTag();
  if (tag == kField) {
    return CalculateFieldFingerprint();
  } else if (tag == kConstructor) {
    CalculateConstructorFingerprint();
    return hash_;
  }
  ProcedureHelper procedure_helper(this);
  procedure_helper.ReadUntilExcluding(ProcedureHelper::kName);
  const String& name = ReadNameAsMethodName();  // Read name.
  procedure_helper.SetJustRead(ProcedureHelper::kName);

  procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);
  if (ReadTag() == kSomething) {
    CalculateFunctionNodeFingerprint();
  }

  BuildHash(procedure_helper.kind_);
  BuildHash(procedure_helper.flags_);
  BuildHash(procedure_helper.annotation_count_);
  BuildHash(procedure_helper.stub_kind_);
  BuildHash(name.Hash());
  return hash_;
}

uint32_t KernelSourceFingerprintHelper::CalculateClassFingerprint(
    const Class& klass) {
  Zone* zone = Thread::Current()->zone();

  // Handle typedefs.
  if (klass.IsTypedefClass()) {
    const Function& func = Function::Handle(zone, klass.signature_function());
    return CalculateFunctionFingerprint(func);
  }

  String& name = String::Handle(zone, klass.Name());
  const Array& fields = Array::Handle(zone, klass.fields());
  const Array& functions = Array::Handle(zone, klass.current_functions());
  const Array& interfaces = Array::Handle(zone, klass.interfaces());
  AbstractType& type = AbstractType::Handle(zone);

  uint32_t hash = 0;
  hash = KernelFingerprintHelper::CalculateHash(hash, name.Hash());

  type = klass.super_type();
  if (!type.IsNull()) {
    name = type.Name();
    hash = KernelFingerprintHelper::CalculateHash(hash, name.Hash());
  }

  Field& field = Field::Handle(zone);
  // Calculate fingerprint for the class fields.
  for (intptr_t i = 0; i < fields.Length(); ++i) {
    field ^= fields.At(i);
    uint32_t fingerprint = CalculateFieldFingerprint(field);
    hash = KernelFingerprintHelper::CalculateHash(hash, fingerprint);
  }

  // Calculate fingerprint for the class functions.
  Function& func = Function::Handle(zone);
  for (intptr_t i = 0; i < functions.Length(); ++i) {
    func ^= functions.At(i);
    uint32_t fingerprint = CalculateFunctionFingerprint(func);
    hash = KernelFingerprintHelper::CalculateHash(hash, fingerprint);
  }

  // Calculate fingerprint for the interfaces.
  for (intptr_t i = 0; i < interfaces.Length(); ++i) {
    type ^= interfaces.At(i);
    name = type.Name();
    hash = KernelFingerprintHelper::CalculateHash(hash, name.Hash());
  }

  return hash;
}

uint32_t KernelSourceFingerprintHelper::CalculateFieldFingerprint(
    const Field& field) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Script& script = Script::Handle(zone, field.Script());

  TranslationHelper translation_helper(thread);
  translation_helper.InitFromScript(script);

  KernelFingerprintHelper helper(
      zone, &translation_helper, script,
      ExternalTypedData::Handle(zone, field.KernelData()),
      field.KernelDataProgramOffset());
  helper.SetOffset(field.kernel_offset());
  return helper.CalculateFieldFingerprint();
}

uint32_t KernelSourceFingerprintHelper::CalculateFunctionFingerprint(
    const Function& func) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Script& script = Script::Handle(zone, func.script());

  TranslationHelper translation_helper(thread);
  translation_helper.InitFromScript(script);

  KernelFingerprintHelper helper(
      zone, &translation_helper, script,
      ExternalTypedData::Handle(zone, func.KernelData()),
      func.KernelDataProgramOffset());
  helper.SetOffset(func.kernel_offset());
  return helper.CalculateFunctionFingerprint();
}

}  // namespace kernel
}  // namespace dart
