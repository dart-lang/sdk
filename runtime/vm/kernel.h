// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_H_
#define RUNTIME_VM_KERNEL_H_

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/token_position.h"


#define KERNEL_NODES_DO(M)                                                     \
  M(Name)                                                                      \
  M(DartType)                                                                  \
  M(InvalidType)                                                               \
  M(DynamicType)                                                               \
  M(VoidType)                                                                  \
  M(BottomType)                                                                \
  M(InterfaceType)                                                             \
  M(FunctionType)                                                              \
  M(TypeParameterType)                                                         \
  M(VectorType)                                                                \
  M(TypedefType)

#define KERNEL_TREE_NODES_DO(M)                                                \
  M(Library)                                                                   \
  M(Typedef)                                                                   \
  M(Class)                                                                     \
  M(NormalClass)                                                               \
  M(MixinClass)                                                                \
  M(Member)                                                                    \
  M(Field)                                                                     \
  M(Constructor)                                                               \
  M(Procedure)                                                                 \
  M(Initializer)                                                               \
  M(InvalidInitializer)                                                        \
  M(FieldInitializer)                                                          \
  M(SuperInitializer)                                                          \
  M(RedirectingInitializer)                                                    \
  M(LocalInitializer)                                                          \
  M(FunctionNode)                                                              \
  M(Expression)                                                                \
  M(InvalidExpression)                                                         \
  M(VariableGet)                                                               \
  M(VariableSet)                                                               \
  M(PropertyGet)                                                               \
  M(PropertySet)                                                               \
  M(DirectPropertyGet)                                                         \
  M(DirectPropertySet)                                                         \
  M(StaticGet)                                                                 \
  M(StaticSet)                                                                 \
  M(Arguments)                                                                 \
  M(NamedExpression)                                                           \
  M(MethodInvocation)                                                          \
  M(DirectMethodInvocation)                                                    \
  M(StaticInvocation)                                                          \
  M(ConstructorInvocation)                                                     \
  M(Not)                                                                       \
  M(LogicalExpression)                                                         \
  M(ConditionalExpression)                                                     \
  M(StringConcatenation)                                                       \
  M(IsExpression)                                                              \
  M(AsExpression)                                                              \
  M(BasicLiteral)                                                              \
  M(StringLiteral)                                                             \
  M(BigintLiteral)                                                             \
  M(IntLiteral)                                                                \
  M(DoubleLiteral)                                                             \
  M(BoolLiteral)                                                               \
  M(NullLiteral)                                                               \
  M(SymbolLiteral)                                                             \
  M(TypeLiteral)                                                               \
  M(ThisExpression)                                                            \
  M(Rethrow)                                                                   \
  M(Throw)                                                                     \
  M(ListLiteral)                                                               \
  M(MapLiteral)                                                                \
  M(MapEntry)                                                                  \
  M(AwaitExpression)                                                           \
  M(FunctionExpression)                                                        \
  M(Let)                                                                       \
  M(VectorCreation)                                                            \
  M(VectorGet)                                                                 \
  M(VectorSet)                                                                 \
  M(VectorCopy)                                                                \
  M(ClosureCreation)                                                           \
  M(Statement)                                                                 \
  M(InvalidStatement)                                                          \
  M(ExpressionStatement)                                                       \
  M(Block)                                                                     \
  M(EmptyStatement)                                                            \
  M(AssertStatement)                                                           \
  M(LabeledStatement)                                                          \
  M(BreakStatement)                                                            \
  M(WhileStatement)                                                            \
  M(DoStatement)                                                               \
  M(ForStatement)                                                              \
  M(ForInStatement)                                                            \
  M(SwitchStatement)                                                           \
  M(SwitchCase)                                                                \
  M(ContinueSwitchStatement)                                                   \
  M(IfStatement)                                                               \
  M(ReturnStatement)                                                           \
  M(TryCatch)                                                                  \
  M(Catch)                                                                     \
  M(TryFinally)                                                                \
  M(YieldStatement)                                                            \
  M(VariableDeclaration)                                                       \
  M(FunctionDeclaration)                                                       \
  M(TypeParameter)                                                             \
  M(Program)

#define KERNEL_ALL_NODES_DO(M)                                                 \
  M(Node)                                                                      \
  KERNEL_NODES_DO(M)                                                           \
  M(TreeNode)                                                                  \
  KERNEL_TREE_NODES_DO(M)

#define KERNEL_VISITORS_DO(M)                                                  \
  M(ExpressionVisitor)                                                         \
  M(StatementVisitor)                                                          \
  M(MemberVisitor)                                                             \
  M(ClassVisitor)                                                              \
  M(InitializerVisitor)                                                        \
  M(DartTypeVisitor)                                                           \
  M(TreeVisitor)                                                               \
  M(Visitor)

namespace dart {

class Field;
class ParsedFunction;
class Zone;

namespace kernel {


class Reader;
class TreeNode;
class TypeParameter;

// Boxes a value of type `T*` and `delete`s it on destruction.
template <typename T>
class Child {
 public:
  Child() : pointer_(NULL) {}
  explicit Child(T* value) : pointer_(value) {}

  ~Child() { delete pointer_; }

  // Support `Child<T> box = T* obj`.
  T*& operator=(T* value) {
    ASSERT(pointer_ == NULL);
    return pointer_ = value;
  }

  // Implicitly convert `Child<T>` to `T*`.
  operator T*&() { return pointer_; }

  T* operator->() { return pointer_; }

 private:
  T* pointer_;
};

// Boxes a value of type `T*` (only used to mark a member as a weak reference).
template <typename T>
class Ref {
 public:
  Ref() : pointer_(NULL) {}
  explicit Ref(T* value) : pointer_(value) {}

  // Support `Ref<T> box = T* obj`.
  T*& operator=(T* value) {
    ASSERT(pointer_ == NULL);
    return pointer_ = value;
  }

  // Implicitly convert `Ref<T>` to `T*`.
  operator T*&() { return pointer_; }

  T* operator->() { return pointer_; }

 private:
  T* pointer_;
};


// A list of pointers that are each deleted when the list is destroyed.
template <typename T>
class List {
 public:
  List() : array_(NULL), length_(0) {}
  ~List();

  template <typename IT>
  void ReadFrom(Reader* reader);

  template <typename IT>
  void ReadFrom(Reader* reader, TreeNode* parent);

  template <typename IT>
  void ReadFromStatic(Reader* reader);

  // Extends the array to at least be able to hold [length] elements.
  //
  // Free places will be filled with `NULL` values.
  void EnsureInitialized(int length);

  // Returns element at [index].
  //
  // If the array is not big enough, it will be grown via `EnsureInitialized`.
  // If the element doesn't exist, it will be created via `new IT()`.
  template <typename IT>
  IT* GetOrCreate(int index);

  template <typename IT, typename PT>
  IT* GetOrCreate(int index, PT* parent);

  // Returns element at [index].
  T*& operator[](int index) {
    ASSERT(index < length_);
    return array_[index];
  }

  int length() { return length_; }

  T** raw_array() { return array_; }

  bool CanStream() {
    for (intptr_t i = 0; i < length_; ++i) {
      if (!array_[i]->can_stream()) return false;
    }
    return true;
  }

 private:
  T** array_;
  int length_;

  DISALLOW_COPY_AND_ASSIGN(List);
};


// A list that cannot be resized and which, unlike List<T>, does not enforce
// its members to be pointers and does not `delete` its members on destruction.
template <typename T>
class RawList {
 public:
  RawList() : pointer_(NULL) {}

  ~RawList() {
    if (pointer_ != NULL) {
      delete[] pointer_;
    }
  }

  void Initialize(int length) {
    ASSERT(pointer_ == NULL);
    pointer_ = new T[length];
    length_ = length;
  }

  T& operator[](int index) { return pointer_[index]; }

  int length() { return length_; }

 private:
  int length_;
  T* pointer_;

  DISALLOW_COPY_AND_ASSIGN(RawList);
};


class TypeParameterList : public List<TypeParameter> {
 public:
  void ReadFrom(Reader* reader);
  TypeParameterList() : first_offset(-1) {}
  intptr_t first_offset;
};


class Source {
 public:
  ~Source();

 private:
  uint8_t* uri_;               // UTF-8 encoded.
  intptr_t uri_size_;          // In bytes.
  uint8_t* source_code_;       // UTF-8 encoded.
  intptr_t source_code_size_;  // In bytes.
  intptr_t* line_starts_;
  intptr_t line_count_;

  friend class SourceTable;
};


class SourceTable {
 public:
  ~SourceTable();

  void ReadFrom(Reader* reader);

  intptr_t size() { return size_; }

  uint8_t* UriFor(intptr_t i) { return sources_[i].uri_; }
  intptr_t UriSizeFor(intptr_t i) { return sources_[i].uri_size_; }

  uint8_t* SourceCodeFor(intptr_t i) { return sources_[i].source_code_; }
  intptr_t SourceCodeSizeFor(intptr_t i) {
    return sources_[i].source_code_size_;
  }

  intptr_t* LineStartsFor(intptr_t i) { return sources_[i].line_starts_; }
  intptr_t LineCountFor(intptr_t i) { return sources_[i].line_count_; }

 private:
  SourceTable() : size_(0), sources_(NULL) {}

  friend class Program;

  // The number of entries in the table.
  intptr_t size_;

  // An array of sources.
  Source* sources_;

  DISALLOW_COPY_AND_ASSIGN(SourceTable);
};


class StringIndex {
 public:
  StringIndex() : value_(-1) {}
  explicit StringIndex(int value) : value_(value) {}

  operator int() const { return value_; }

 private:
  int value_;
};


class NameIndex {
 public:
  NameIndex() : value_(-1) {}
  explicit NameIndex(int value) : value_(value) {}

  operator int() const { return value_; }

 private:
  int value_;
};


// Forward declare all classes.
#define DO(name) class name;
KERNEL_ALL_NODES_DO(DO)
KERNEL_VISITORS_DO(DO)
#undef DO


#define DEFINE_CASTING_OPERATIONS(klass)                                       \
  virtual bool Is##klass() { return true; }                                    \
                                                                               \
  static klass* Cast(Node* node) {                                             \
    ASSERT(node == NULL || node->Is##klass());                                 \
    return static_cast<klass*>(node);                                          \
  }                                                                            \
                                                                               \
  virtual Node::NodeType Type() { return Node::kType##klass; }

#define DEFINE_IS_OPERATION(klass)                                             \
  virtual bool Is##klass() { return false; }

#define DEFINE_ALL_IS_OPERATIONS()                                             \
  KERNEL_NODES_DO(DEFINE_IS_OPERATION)                                         \
  DEFINE_IS_OPERATION(TreeNode)                                                \
  KERNEL_TREE_NODES_DO(DEFINE_IS_OPERATION)

class Typedef;
class Class;
class Constructor;
class Field;
class Library;
class LibraryDependency;
class Combinator;
class LinkedNode;
class Member;
class Procedure;

class Node {
 public:
  virtual ~Node();

  enum NodeType {
#define DO(name) kType##name,
    KERNEL_ALL_NODES_DO(DO)
#undef DO

        kNumTypes
  };

  DEFINE_ALL_IS_OPERATIONS();
  DEFINE_CASTING_OPERATIONS(Node);

  virtual void AcceptVisitor(Visitor* visitor) = 0;
  virtual void VisitChildren(Visitor* visitor) = 0;

 protected:
  Node() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(Node);
};


class TreeNode : public Node {
 public:
  virtual ~TreeNode();

  DEFINE_CASTING_OPERATIONS(TreeNode);

  virtual void AcceptVisitor(Visitor* visitor);
  virtual void AcceptTreeVisitor(TreeVisitor* visitor) = 0;
  intptr_t kernel_offset() const { return kernel_offset_; }
  bool can_stream() { return can_stream_; }

 protected:
  TreeNode() : kernel_offset_(-1), can_stream_(true) {}

  // Offset for this node in the kernel-binary. If this node has a tag the
  // offset includes the tag. Can be -1 to indicate "unknown" or invalid offset.
  intptr_t kernel_offset_;

  bool can_stream_;

 private:
  DISALLOW_COPY_AND_ASSIGN(TreeNode);
};


class LinkedNode : public TreeNode {
 public:
  virtual ~LinkedNode();

  NameIndex canonical_name() { return canonical_name_; }

 protected:
  LinkedNode() {}

  NameIndex canonical_name_;

 private:
  DISALLOW_COPY_AND_ASSIGN(LinkedNode);
};


class Library : public LinkedNode {
 public:
  Library* ReadFrom(Reader* reader);

  virtual ~Library();

  DEFINE_CASTING_OPERATIONS(Library);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  StringIndex import_uri() { return import_uri_index_; }
  intptr_t source_uri_index() { return source_uri_index_; }
  StringIndex name() { return name_index_; }
  List<Expression>& annotations() { return annotations_; }
  List<LibraryDependency>& dependencies() { return dependency_; }
  List<Typedef>& typedefs() { return typedefs_; }
  List<Class>& classes() { return classes_; }
  List<Field>& fields() { return fields_; }
  List<Procedure>& procedures() { return procedures_; }

  const uint8_t* kernel_data() { return kernel_data_; }
  intptr_t kernel_data_size() { return kernel_data_size_; }

 private:
  Library() : kernel_data_(NULL), kernel_data_size_(-1) {}

  template <typename T>
  friend class List;

  StringIndex name_index_;
  StringIndex import_uri_index_;
  intptr_t source_uri_index_;
  List<Expression> annotations_;
  List<LibraryDependency> dependency_;
  List<Typedef> typedefs_;
  List<Class> classes_;
  List<Field> fields_;
  List<Procedure> procedures_;
  const uint8_t* kernel_data_;
  intptr_t kernel_data_size_;

  DISALLOW_COPY_AND_ASSIGN(Library);
};


class LibraryDependency {
 public:
  enum Flags {
    kFlagExport = 1 << 0,
    kFlagDeferred = 1 << 1,
  };

  static LibraryDependency* ReadFrom(Reader* reader);

  virtual ~LibraryDependency();

  bool is_export() { return (flags_ & kFlagExport) != 0; }
  bool is_import() { return (flags_ & kFlagExport) == 0; }
  bool is_deferred() { return (flags_ & kFlagDeferred) != 0; }
  List<Expression>& annotations() { return annotations_; }
  NameIndex target() { return target_reference_; }
  StringIndex name() { return name_index_; }

 private:
  LibraryDependency() {}

  word flags_;
  List<Expression> annotations_;
  NameIndex target_reference_;
  StringIndex name_index_;
  List<Combinator> combinators_;

  DISALLOW_COPY_AND_ASSIGN(LibraryDependency);
};


class Combinator {
 public:
  static Combinator* ReadFrom(Reader* reader);

  virtual ~Combinator();

  bool is_show() { return is_show_; }
  RawList<intptr_t>& names() { return name_indices_; }

 private:
  Combinator() {}

  bool is_show_;
  RawList<intptr_t> name_indices_;

  DISALLOW_COPY_AND_ASSIGN(Combinator);
};


class Typedef : public LinkedNode {
 public:
  Typedef* ReadFrom(Reader* reader);

  virtual ~Typedef();

  DEFINE_CASTING_OPERATIONS(Typedef);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Library* parent() { return parent_; }
  StringIndex name() { return name_index_; }
  intptr_t source_uri_index() { return source_uri_index_; }
  TokenPosition position() { return position_; }
  TypeParameterList& type_parameters() { return type_parameters_; }
  DartType* type() { return type_; }

 protected:
  Typedef() : position_(TokenPosition::kNoSource) {}

 private:
  template <typename T>
  friend class List;

  StringIndex name_index_;
  Ref<Library> parent_;
  intptr_t source_uri_index_;
  TokenPosition position_;
  TypeParameterList type_parameters_;
  Child<DartType> type_;
};


class Class : public LinkedNode {
 public:
  Class* ReadFrom(Reader* reader);

  virtual ~Class();

  DEFINE_CASTING_OPERATIONS(Class);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void AcceptClassVisitor(ClassVisitor* visitor) = 0;

  Library* parent() { return parent_; }
  StringIndex name() { return name_index_; }
  intptr_t source_uri_index() { return source_uri_index_; }
  bool is_abstract() { return is_abstract_; }
  List<Expression>& annotations() { return annotations_; }
  TokenPosition position() { return position_; }

  virtual List<TypeParameter>& type_parameters() = 0;
  virtual List<InterfaceType>& implemented_classes() = 0;
  virtual List<Field>& fields() = 0;
  virtual List<Constructor>& constructors() = 0;
  virtual List<Procedure>& procedures() = 0;

 protected:
  Class() : is_abstract_(false), position_(TokenPosition::kNoSource) {}

 private:
  template <typename T>
  friend class List;

  StringIndex name_index_;
  Ref<Library> parent_;
  intptr_t source_uri_index_;
  bool is_abstract_;
  List<Expression> annotations_;
  TokenPosition position_;

  DISALLOW_COPY_AND_ASSIGN(Class);
};


class NormalClass : public Class {
 public:
  NormalClass* ReadFrom(Reader* reader);

  virtual ~NormalClass();

  DEFINE_CASTING_OPERATIONS(NormalClass);

  virtual void AcceptClassVisitor(ClassVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  virtual TypeParameterList& type_parameters() { return type_parameters_; }
  InterfaceType* super_class() { return super_class_; }
  virtual List<InterfaceType>& implemented_classes() {
    return implemented_classes_;
  }
  virtual List<Constructor>& constructors() { return constructors_; }
  virtual List<Procedure>& procedures() { return procedures_; }
  virtual List<Field>& fields() { return fields_; }

 private:
  NormalClass() {}

  template <typename T>
  friend class List;

  TypeParameterList type_parameters_;
  Child<InterfaceType> super_class_;
  List<InterfaceType> implemented_classes_;
  List<Constructor> constructors_;
  List<Procedure> procedures_;
  List<Field> fields_;

  DISALLOW_COPY_AND_ASSIGN(NormalClass);
};


class MixinClass : public Class {
 public:
  MixinClass* ReadFrom(Reader* reader);

  virtual ~MixinClass();

  DEFINE_CASTING_OPERATIONS(MixinClass);

  virtual void AcceptClassVisitor(ClassVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  virtual TypeParameterList& type_parameters() { return type_parameters_; }
  InterfaceType* first() { return first_; }
  InterfaceType* second() { return second_; }
  virtual List<InterfaceType>& implemented_classes() {
    return implemented_classes_;
  }
  virtual List<Constructor>& constructors() { return constructors_; }
  virtual List<Field>& fields() { return fields_; }
  virtual List<Procedure>& procedures() { return procedures_; }

 private:
  MixinClass() {}

  template <typename T>
  friend class List;

  TypeParameterList type_parameters_;
  Child<InterfaceType> first_;
  Child<InterfaceType> second_;
  List<InterfaceType> implemented_classes_;
  List<Constructor> constructors_;

  // Dummy instances which are empty lists.
  List<Field> fields_;
  List<Procedure> procedures_;

  DISALLOW_COPY_AND_ASSIGN(MixinClass);
};


class Member : public LinkedNode {
 public:
  virtual ~Member();

  DEFINE_CASTING_OPERATIONS(Member);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void AcceptMemberVisitor(MemberVisitor* visitor) = 0;

  TreeNode* parent() { return parent_; }
  Name* name() { return name_; }
  List<Expression>& annotations() { return annotations_; }
  TokenPosition position() { return position_; }
  TokenPosition end_position() { return end_position_; }

 protected:
  Member()
      : position_(TokenPosition::kNoSource),
        end_position_(TokenPosition::kNoSource) {}

  template <typename T>
  friend class List;

  Ref<TreeNode> parent_;
  Child<Name> name_;
  List<Expression> annotations_;
  TokenPosition position_;
  TokenPosition end_position_;

 private:
  DISALLOW_COPY_AND_ASSIGN(Member);
};


class Field : public Member {
 public:
  enum Flags {
    kFlagFinal = 1 << 0,
    kFlagConst = 1 << 1,
    kFlagStatic = 1 << 2,
  };

  Field* ReadFrom(Reader* reader);

  virtual ~Field();

  DEFINE_CASTING_OPERATIONS(Field);

  virtual void AcceptMemberVisitor(MemberVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  bool IsConst() { return (flags_ & kFlagConst) == kFlagConst; }
  bool IsFinal() { return (flags_ & kFlagFinal) == kFlagFinal; }
  bool IsStatic() { return (flags_ & kFlagStatic) == kFlagStatic; }
  intptr_t source_uri_index() { return source_uri_index_; }

  DartType* type() { return type_; }
  Expression* initializer() { return initializer_; }

 private:
  Field() {}

  template <typename T>
  friend class List;

  word flags_;
  intptr_t source_uri_index_;
  Child<DartType> type_;
  Child<Expression> initializer_;

  DISALLOW_COPY_AND_ASSIGN(Field);
};


class Constructor : public Member {
 public:
  enum Flags {
    kFlagConst = 1 << 0,
    kFlagExternal = 1 << 1,
  };

  Constructor* ReadFrom(Reader* reader);

  virtual ~Constructor();

  DEFINE_CASTING_OPERATIONS(Constructor);

  virtual void AcceptMemberVisitor(MemberVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  bool IsExternal() { return (flags_ & kFlagExternal) == kFlagExternal; }
  bool IsConst() { return (flags_ & kFlagConst) == kFlagConst; }

  FunctionNode* function() { return function_; }
  List<Initializer>& initializers() { return initializers_; }

 private:
  template <typename T>
  friend class List;

  Constructor() {}

  uint8_t flags_;
  Child<FunctionNode> function_;
  List<Initializer> initializers_;

  DISALLOW_COPY_AND_ASSIGN(Constructor);
};


class Procedure : public Member {
 public:
  enum Flags {
    kFlagStatic = 1 << 0,
    kFlagAbstract = 1 << 1,
    kFlagExternal = 1 << 2,
    kFlagConst = 1 << 3,  // Only for external const factories.
  };

  // Keep in sync with package:dynamo/lib/ast.dart:ProcedureKind
  enum ProcedureKind {
    kMethod,
    kGetter,
    kSetter,
    kOperator,
    kFactory,

    kIncompleteProcedure = 255
  };

  Procedure* ReadFrom(Reader* reader);

  virtual ~Procedure();

  DEFINE_CASTING_OPERATIONS(Procedure);

  virtual void AcceptMemberVisitor(MemberVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  ProcedureKind kind() { return kind_; }
  FunctionNode* function() { return function_; }

  bool IsStatic() { return (flags_ & kFlagStatic) == kFlagStatic; }
  bool IsAbstract() { return (flags_ & kFlagAbstract) == kFlagAbstract; }
  bool IsExternal() { return (flags_ & kFlagExternal) == kFlagExternal; }
  bool IsConst() { return (flags_ & kFlagConst) == kFlagConst; }
  intptr_t source_uri_index() { return source_uri_index_; }

 private:
  Procedure() : kind_(kIncompleteProcedure), flags_(0), function_(NULL) {}

  template <typename T>
  friend class List;

  ProcedureKind kind_;
  word flags_;
  intptr_t source_uri_index_;
  Child<FunctionNode> function_;

  DISALLOW_COPY_AND_ASSIGN(Procedure);
};


class Initializer : public TreeNode {
 public:
  static Initializer* ReadFrom(Reader* reader);

  virtual ~Initializer();

  DEFINE_CASTING_OPERATIONS(Initializer);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void AcceptInitializerVisitor(InitializerVisitor* visitor) = 0;

 protected:
  Initializer() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(Initializer);
};


class InvalidInitializer : public Initializer {
 public:
  static InvalidInitializer* ReadFromImpl(Reader* reader);

  virtual ~InvalidInitializer();

  DEFINE_CASTING_OPERATIONS(InvalidInitializer);
  virtual void AcceptInitializerVisitor(InitializerVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  InvalidInitializer() {}

  DISALLOW_COPY_AND_ASSIGN(InvalidInitializer);
};


class FieldInitializer : public Initializer {
 public:
  static FieldInitializer* ReadFromImpl(Reader* reader);

  virtual ~FieldInitializer();

  DEFINE_CASTING_OPERATIONS(FieldInitializer);

  virtual void AcceptInitializerVisitor(InitializerVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex field() { return field_reference_; }
  Expression* value() { return value_; }

 private:
  FieldInitializer() {}

  NameIndex field_reference_;  // Field canonical name.
  Child<Expression> value_;

  DISALLOW_COPY_AND_ASSIGN(FieldInitializer);
};


class SuperInitializer : public Initializer {
 public:
  static SuperInitializer* ReadFromImpl(Reader* reader);

  virtual ~SuperInitializer();

  DEFINE_CASTING_OPERATIONS(SuperInitializer);

  virtual void AcceptInitializerVisitor(InitializerVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex target() { return target_reference_; }
  Arguments* arguments() { return arguments_; }

 private:
  SuperInitializer() {}

  NameIndex target_reference_;  // Constructor canonical name.
  Child<Arguments> arguments_;

  DISALLOW_COPY_AND_ASSIGN(SuperInitializer);
};


class RedirectingInitializer : public Initializer {
 public:
  static RedirectingInitializer* ReadFromImpl(Reader* reader);

  virtual ~RedirectingInitializer();

  DEFINE_CASTING_OPERATIONS(RedirectingInitializer);

  virtual void AcceptInitializerVisitor(InitializerVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex target() { return target_reference_; }
  Arguments* arguments() { return arguments_; }

 private:
  RedirectingInitializer() {}

  NameIndex target_reference_;  // Constructor canonical name.
  Child<Arguments> arguments_;

  DISALLOW_COPY_AND_ASSIGN(RedirectingInitializer);
};


class LocalInitializer : public Initializer {
 public:
  static LocalInitializer* ReadFromImpl(Reader* reader);

  virtual ~LocalInitializer();

  DEFINE_CASTING_OPERATIONS(LocalInitializer);

  virtual void AcceptInitializerVisitor(InitializerVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  VariableDeclaration* variable() { return variable_; }

 private:
  LocalInitializer() {}

  Child<VariableDeclaration> variable_;

  DISALLOW_COPY_AND_ASSIGN(LocalInitializer);
};


class FunctionNode : public TreeNode {
 public:
  enum AsyncMarker {
    kSync = 0,
    kSyncStar = 1,
    kAsync = 2,
    kAsyncStar = 3,
    kSyncYielding = 4,
  };

  static FunctionNode* ReadFrom(Reader* reader);

  virtual ~FunctionNode();

  DEFINE_CASTING_OPERATIONS(FunctionNode);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  AsyncMarker async_marker() { return async_marker_; }
  AsyncMarker dart_async_marker() { return dart_async_marker_; }
  TypeParameterList& type_parameters() { return type_parameters_; }
  int required_parameter_count() { return required_parameter_count_; }
  List<VariableDeclaration>& positional_parameters() {
    return positional_parameters_;
  }
  List<VariableDeclaration>& named_parameters() { return named_parameters_; }
  DartType* return_type() { return return_type_; }

  Statement* body() { return body_; }
  void ReplaceBody(Statement* body);

  TokenPosition position() { return position_; }
  TokenPosition end_position() { return end_position_; }

 private:
  FunctionNode()
      : position_(TokenPosition::kNoSource),
        end_position_(TokenPosition::kNoSource) {}

  AsyncMarker async_marker_;
  AsyncMarker dart_async_marker_;
  TypeParameterList type_parameters_;
  int required_parameter_count_;
  List<VariableDeclaration> positional_parameters_;
  List<VariableDeclaration> named_parameters_;
  Child<DartType> return_type_;
  Child<Statement> body_;
  TokenPosition position_;
  TokenPosition end_position_;

  DISALLOW_COPY_AND_ASSIGN(FunctionNode);
};


class Expression : public TreeNode {
 public:
  static Expression* ReadFrom(Reader* reader);

  virtual ~Expression();

  DEFINE_CASTING_OPERATIONS(Expression);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor) = 0;
  TokenPosition position() { return position_; }
  void set_position(TokenPosition position) { position_ = position; }

 protected:
  Expression() : position_(TokenPosition::kNoSource) {}
  TokenPosition position_;

 private:
  DISALLOW_COPY_AND_ASSIGN(Expression);
};


class InvalidExpression : public Expression {
 public:
  static InvalidExpression* ReadFrom(Reader* reader);

  virtual ~InvalidExpression();
  virtual void VisitChildren(Visitor* visitor);

  DEFINE_CASTING_OPERATIONS(InvalidExpression);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);

 private:
  InvalidExpression() {}

  DISALLOW_COPY_AND_ASSIGN(InvalidExpression);
};


class VariableGet : public Expression {
 public:
  static VariableGet* ReadFrom(Reader* reader);
  static VariableGet* ReadFrom(Reader* reader, uint8_t payload);

  virtual ~VariableGet();

  DEFINE_CASTING_OPERATIONS(VariableGet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  VariableDeclaration* variable() { return variable_; }

 private:
  VariableGet() {}

  Ref<VariableDeclaration> variable_;
  intptr_t variable_kernel_offset_;

  DISALLOW_COPY_AND_ASSIGN(VariableGet);
};


class VariableSet : public Expression {
 public:
  static VariableSet* ReadFrom(Reader* reader);
  static VariableSet* ReadFrom(Reader* reader, uint8_t payload);

  virtual ~VariableSet();

  DEFINE_CASTING_OPERATIONS(VariableSet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  VariableDeclaration* variable() { return variable_; }
  Expression* expression() { return expression_; }

 private:
  VariableSet() {}

  Ref<VariableDeclaration> variable_;
  intptr_t variable_kernel_offset_;
  Child<Expression> expression_;

  DISALLOW_COPY_AND_ASSIGN(VariableSet);
};


class PropertyGet : public Expression {
 public:
  static PropertyGet* ReadFrom(Reader* reader);

  virtual ~PropertyGet();

  DEFINE_CASTING_OPERATIONS(PropertyGet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* receiver() { return receiver_; }
  Name* name() { return name_; }

 private:
  PropertyGet() {}

  NameIndex interface_target_reference_;
  Child<Expression> receiver_;
  Child<Name> name_;

  DISALLOW_COPY_AND_ASSIGN(PropertyGet);
};


class PropertySet : public Expression {
 public:
  static PropertySet* ReadFrom(Reader* reader);

  virtual ~PropertySet();

  DEFINE_CASTING_OPERATIONS(PropertySet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* receiver() { return receiver_; }
  Name* name() { return name_; }
  Expression* value() { return value_; }

 private:
  PropertySet() {}

  NameIndex interface_target_reference_;
  Child<Expression> receiver_;
  Child<Name> name_;
  Child<Expression> value_;

  DISALLOW_COPY_AND_ASSIGN(PropertySet);
};


class DirectPropertyGet : public Expression {
 public:
  static DirectPropertyGet* ReadFrom(Reader* reader);

  virtual ~DirectPropertyGet();

  DEFINE_CASTING_OPERATIONS(DirectPropertyGet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* receiver() { return receiver_; }
  NameIndex target() { return target_reference_; }

 private:
  DirectPropertyGet() {}

  NameIndex target_reference_;  // Member canonical name.
  Child<Expression> receiver_;

  DISALLOW_COPY_AND_ASSIGN(DirectPropertyGet);
};


class DirectPropertySet : public Expression {
 public:
  static DirectPropertySet* ReadFrom(Reader* reader);

  virtual ~DirectPropertySet();

  DEFINE_CASTING_OPERATIONS(DirectPropertySet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex target() { return target_reference_; }
  Expression* receiver() { return receiver_; }
  Expression* value() { return value_; }

 private:
  DirectPropertySet() {}

  NameIndex target_reference_;  // Member canonical name.
  Child<Expression> receiver_;
  Child<Expression> value_;

  DISALLOW_COPY_AND_ASSIGN(DirectPropertySet);
};


class StaticGet : public Expression {
 public:
  StaticGet(NameIndex target, bool can_stream) : target_reference_(target) {
    can_stream_ = can_stream;
  }

  static StaticGet* ReadFrom(Reader* reader);

  virtual ~StaticGet();

  DEFINE_CASTING_OPERATIONS(StaticGet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex target() { return target_reference_; }

 private:
  StaticGet() {}

  NameIndex target_reference_;  // Member canonical name.

  DISALLOW_COPY_AND_ASSIGN(StaticGet);
};


class StaticSet : public Expression {
 public:
  static StaticSet* ReadFrom(Reader* reader);

  virtual ~StaticSet();

  DEFINE_CASTING_OPERATIONS(StaticSet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex target() { return target_reference_; }
  Expression* expression() { return expression_; }

 private:
  StaticSet() {}

  NameIndex target_reference_;  // Member canonical name.
  Child<Expression> expression_;

  DISALLOW_COPY_AND_ASSIGN(StaticSet);
};


class Arguments : public TreeNode {
 public:
  static Arguments* ReadFrom(Reader* reader);

  virtual ~Arguments();

  DEFINE_CASTING_OPERATIONS(Arguments);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  // TODO(regis): Support type arguments of generic functions.
  List<DartType>& types() { return types_; }
  List<Expression>& positional() { return positional_; }
  List<NamedExpression>& named() { return named_; }

  int count() { return positional_.length() + named_.length(); }

 private:
  Arguments() {}

  List<DartType> types_;
  List<Expression> positional_;
  List<NamedExpression> named_;

  DISALLOW_COPY_AND_ASSIGN(Arguments);
};


class NamedExpression : public TreeNode {
 public:
  static NamedExpression* ReadFrom(Reader* reader);

  NamedExpression(StringIndex name_index, Expression* expr)
      : name_index_(name_index), expression_(expr) {}
  virtual ~NamedExpression();

  DEFINE_CASTING_OPERATIONS(NamedExpression);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  StringIndex name() { return name_index_; }
  Expression* expression() { return expression_; }

 private:
  NamedExpression() {}

  StringIndex name_index_;
  Child<Expression> expression_;

  DISALLOW_COPY_AND_ASSIGN(NamedExpression);
};


class MethodInvocation : public Expression {
 public:
  static MethodInvocation* ReadFrom(Reader* reader);

  virtual ~MethodInvocation();

  DEFINE_CASTING_OPERATIONS(MethodInvocation);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* receiver() { return receiver_; }
  Name* name() { return name_; }
  Arguments* arguments() { return arguments_; }

 private:
  MethodInvocation() {}

  NameIndex interface_target_reference_;
  Child<Expression> receiver_;
  Child<Name> name_;
  Child<Arguments> arguments_;

  DISALLOW_COPY_AND_ASSIGN(MethodInvocation);
};


class DirectMethodInvocation : public Expression {
 public:
  static DirectMethodInvocation* ReadFrom(Reader* reader);

  virtual ~DirectMethodInvocation();

  DEFINE_CASTING_OPERATIONS(DirectMethodInvocation);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* receiver() { return receiver_; }
  NameIndex target() { return target_reference_; }
  Arguments* arguments() { return arguments_; }

 private:
  DirectMethodInvocation() {}

  NameIndex target_reference_;  // Procedure canonical name.
  Child<Expression> receiver_;
  Child<Arguments> arguments_;

  DISALLOW_COPY_AND_ASSIGN(DirectMethodInvocation);
};


class StaticInvocation : public Expression {
 public:
  static StaticInvocation* ReadFrom(Reader* reader, bool is_const);
  ~StaticInvocation();

  DEFINE_CASTING_OPERATIONS(StaticInvocation);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex procedure() { return procedure_reference_; }
  Arguments* arguments() { return arguments_; }
  bool is_const() { return is_const_; }

 private:
  StaticInvocation() {}

  NameIndex procedure_reference_;  // Procedure canonical name.
  bool is_const_;
  Child<Arguments> arguments_;

  DISALLOW_COPY_AND_ASSIGN(StaticInvocation);
};


class ConstructorInvocation : public Expression {
 public:
  static ConstructorInvocation* ReadFrom(Reader* reader, bool is_const);

  virtual ~ConstructorInvocation();

  DEFINE_CASTING_OPERATIONS(ConstructorInvocation);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  bool is_const() { return is_const_; }
  NameIndex target() { return target_reference_; }
  Arguments* arguments() { return arguments_; }

 private:
  ConstructorInvocation() {}

  bool is_const_;
  NameIndex target_reference_;  // Constructor canonical name.
  Child<Arguments> arguments_;

  DISALLOW_COPY_AND_ASSIGN(ConstructorInvocation);
};


class Not : public Expression {
 public:
  static Not* ReadFrom(Reader* reader);

  virtual ~Not();

  DEFINE_CASTING_OPERATIONS(Not);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* expression() { return expression_; }

 private:
  Not() {}

  Child<Expression> expression_;

  DISALLOW_COPY_AND_ASSIGN(Not);
};


class LogicalExpression : public Expression {
 public:
  enum Operator { kAnd, kOr };

  static LogicalExpression* ReadFrom(Reader* reader);

  virtual ~LogicalExpression();

  DEFINE_CASTING_OPERATIONS(LogicalExpression);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* left() { return left_; }
  Operator op() { return operator_; }
  Expression* right() { return right_; }

 private:
  LogicalExpression() {}

  Child<Expression> left_;
  Operator operator_;
  Child<Expression> right_;

  DISALLOW_COPY_AND_ASSIGN(LogicalExpression);
};


class ConditionalExpression : public Expression {
 public:
  static ConditionalExpression* ReadFrom(Reader* reader);

  virtual ~ConditionalExpression();

  DEFINE_CASTING_OPERATIONS(ConditionalExpression);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* condition() { return condition_; }
  Expression* then() { return then_; }
  Expression* otherwise() { return otherwise_; }

 private:
  ConditionalExpression() {}

  Child<Expression> condition_;
  Child<Expression> then_;
  Child<Expression> otherwise_;

  DISALLOW_COPY_AND_ASSIGN(ConditionalExpression);
};


class StringConcatenation : public Expression {
 public:
  static StringConcatenation* ReadFrom(Reader* reader);

  virtual ~StringConcatenation();

  DEFINE_CASTING_OPERATIONS(StringConcatenation);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  List<Expression>& expressions() { return expressions_; }

 private:
  StringConcatenation() {}

  List<Expression> expressions_;

  DISALLOW_COPY_AND_ASSIGN(StringConcatenation);
};


class IsExpression : public Expression {
 public:
  static IsExpression* ReadFrom(Reader* reader);

  virtual ~IsExpression();

  DEFINE_CASTING_OPERATIONS(IsExpression);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* operand() { return operand_; }
  DartType* type() { return type_; }

 private:
  IsExpression() {}

  Child<Expression> operand_;
  Child<DartType> type_;

  DISALLOW_COPY_AND_ASSIGN(IsExpression);
};


class AsExpression : public Expression {
 public:
  static AsExpression* ReadFrom(Reader* reader);

  virtual ~AsExpression();

  DEFINE_CASTING_OPERATIONS(AsExpression);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* operand() { return operand_; }
  DartType* type() { return type_; }

 private:
  AsExpression() {}

  Child<Expression> operand_;
  Child<DartType> type_;

  DISALLOW_COPY_AND_ASSIGN(AsExpression);
};


class BasicLiteral : public Expression {
 public:
  virtual ~BasicLiteral();

  DEFINE_CASTING_OPERATIONS(BasicLiteral);

  virtual void VisitChildren(Visitor* visitor);
};


class StringLiteral : public BasicLiteral {
 public:
  static StringLiteral* ReadFrom(Reader* reader);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);

  explicit StringLiteral(StringIndex string_index)
      : value_index_(string_index) {}
  virtual ~StringLiteral();

  DEFINE_CASTING_OPERATIONS(StringLiteral);

  StringIndex value() { return value_index_; }

 protected:
  StringLiteral() {}

  StringIndex value_index_;

 private:
  DISALLOW_COPY_AND_ASSIGN(StringLiteral);
};


class BigintLiteral : public StringLiteral {
 public:
  static BigintLiteral* ReadFrom(Reader* reader);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);

  explicit BigintLiteral(StringIndex string_index)
      : StringLiteral(string_index) {}
  virtual ~BigintLiteral();

  DEFINE_CASTING_OPERATIONS(BigintLiteral);

 private:
  BigintLiteral() {}

  DISALLOW_COPY_AND_ASSIGN(BigintLiteral);
};


class IntLiteral : public BasicLiteral {
 public:
  static IntLiteral* ReadFrom(Reader* reader, bool is_negative);
  static IntLiteral* ReadFrom(Reader* reader, uint8_t payload);

  virtual ~IntLiteral();

  DEFINE_CASTING_OPERATIONS(IntLiteral);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);

  int64_t value() { return value_; }

 private:
  IntLiteral() {}

  int64_t value_;

  DISALLOW_COPY_AND_ASSIGN(IntLiteral);
};


class DoubleLiteral : public BasicLiteral {
 public:
  static DoubleLiteral* ReadFrom(Reader* reader);

  virtual ~DoubleLiteral();

  DEFINE_CASTING_OPERATIONS(DoubleLiteral);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);

  StringIndex value() { return value_index_; }

 private:
  DoubleLiteral() {}

  StringIndex value_index_;

  DISALLOW_COPY_AND_ASSIGN(DoubleLiteral);
};


class BoolLiteral : public BasicLiteral {
 public:
  static BoolLiteral* ReadFrom(Reader* reader, bool value);

  virtual ~BoolLiteral();

  DEFINE_CASTING_OPERATIONS(BoolLiteral);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);

  bool value() { return value_; }

 private:
  BoolLiteral() {}

  bool value_;

  DISALLOW_COPY_AND_ASSIGN(BoolLiteral);
};


class NullLiteral : public BasicLiteral {
 public:
  static NullLiteral* ReadFrom(Reader* reader);

  virtual ~NullLiteral();

  DEFINE_CASTING_OPERATIONS(NullLiteral);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);

 private:
  NullLiteral() {}

  DISALLOW_COPY_AND_ASSIGN(NullLiteral);
};


class SymbolLiteral : public Expression {
 public:
  static SymbolLiteral* ReadFrom(Reader* reader);

  virtual ~SymbolLiteral();

  DEFINE_CASTING_OPERATIONS(SymbolLiteral);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  StringIndex value() { return value_index_; }

 private:
  SymbolLiteral() {}

  StringIndex value_index_;

  DISALLOW_COPY_AND_ASSIGN(SymbolLiteral);
};


class TypeLiteral : public Expression {
 public:
  static TypeLiteral* ReadFrom(Reader* reader);

  virtual ~TypeLiteral();

  DEFINE_CASTING_OPERATIONS(TypeLiteral);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  DartType* type() { return type_; }

 private:
  TypeLiteral() {}

  Child<DartType> type_;

  DISALLOW_COPY_AND_ASSIGN(TypeLiteral);
};


class ThisExpression : public Expression {
 public:
  static ThisExpression* ReadFrom(Reader* reader);

  virtual ~ThisExpression();

  DEFINE_CASTING_OPERATIONS(ThisExpression);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  ThisExpression() {}

  DISALLOW_COPY_AND_ASSIGN(ThisExpression);
};


class Rethrow : public Expression {
 public:
  static Rethrow* ReadFrom(Reader* reader);

  virtual ~Rethrow();

  DEFINE_CASTING_OPERATIONS(Rethrow);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  Rethrow() {}

  DISALLOW_COPY_AND_ASSIGN(Rethrow);
};


class Throw : public Expression {
 public:
  static Throw* ReadFrom(Reader* reader);

  virtual ~Throw();

  DEFINE_CASTING_OPERATIONS(Throw);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* expression() { return expression_; }

 private:
  Throw() {}

  Child<Expression> expression_;

  DISALLOW_COPY_AND_ASSIGN(Throw);
};


class ListLiteral : public Expression {
 public:
  static ListLiteral* ReadFrom(Reader* reader, bool is_const);

  virtual ~ListLiteral();

  DEFINE_CASTING_OPERATIONS(ListLiteral);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  bool is_const() { return is_const_; }
  DartType* type() { return type_; }
  List<Expression>& expressions() { return expressions_; }

 private:
  ListLiteral() {}

  bool is_const_;
  Child<DartType> type_;
  List<Expression> expressions_;

  DISALLOW_COPY_AND_ASSIGN(ListLiteral);
};


class MapLiteral : public Expression {
 public:
  static MapLiteral* ReadFrom(Reader* reader, bool is_const);

  virtual ~MapLiteral();

  DEFINE_CASTING_OPERATIONS(MapLiteral);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  bool is_const() { return is_const_; }
  DartType* key_type() { return key_type_; }
  DartType* value_type() { return value_type_; }
  List<MapEntry>& entries() { return entries_; }

 private:
  MapLiteral() {}

  bool is_const_;
  Child<DartType> key_type_;
  Child<DartType> value_type_;
  List<MapEntry> entries_;

  DISALLOW_COPY_AND_ASSIGN(MapLiteral);
};


class MapEntry : public TreeNode {
 public:
  static MapEntry* ReadFrom(Reader* reader);

  virtual ~MapEntry();

  DEFINE_CASTING_OPERATIONS(MapEntry);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* key() { return key_; }
  Expression* value() { return value_; }

 private:
  MapEntry() {}

  template <typename T>
  friend class List;

  Child<Expression> key_;
  Child<Expression> value_;

  DISALLOW_COPY_AND_ASSIGN(MapEntry);
};


class AwaitExpression : public Expression {
 public:
  static AwaitExpression* ReadFrom(Reader* reader);

  virtual ~AwaitExpression();

  DEFINE_CASTING_OPERATIONS(AwaitExpression);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* operand() { return operand_; }

 private:
  AwaitExpression() {}

  Child<Expression> operand_;

  DISALLOW_COPY_AND_ASSIGN(AwaitExpression);
};


class FunctionExpression : public Expression {
 public:
  static FunctionExpression* ReadFrom(Reader* reader);

  virtual ~FunctionExpression();

  DEFINE_CASTING_OPERATIONS(FunctionExpression);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  FunctionNode* function() { return function_; }

 private:
  FunctionExpression() {}

  Child<FunctionNode> function_;

  DISALLOW_COPY_AND_ASSIGN(FunctionExpression);
};


class Let : public Expression {
 public:
  static Let* ReadFrom(Reader* reader);

  virtual ~Let();

  DEFINE_CASTING_OPERATIONS(Let);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  VariableDeclaration* variable() { return variable_; }
  Expression* body() { return body_; }
  TokenPosition position() { return position_; }
  TokenPosition end_position() { return end_position_; }

 private:
  Let()
      : position_(TokenPosition::kNoSource),
        end_position_(TokenPosition::kNoSource) {}

  Child<VariableDeclaration> variable_;
  Child<Expression> body_;
  TokenPosition position_;
  TokenPosition end_position_;

  DISALLOW_COPY_AND_ASSIGN(Let);
};


class VectorCreation : public Expression {
 public:
  static VectorCreation* ReadFrom(Reader* reader);

  virtual ~VectorCreation();

  DEFINE_CASTING_OPERATIONS(VectorCreation);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  intptr_t value() { return value_; }

 private:
  VectorCreation() {}

  intptr_t value_;

  DISALLOW_COPY_AND_ASSIGN(VectorCreation);
};


class VectorGet : public Expression {
 public:
  static VectorGet* ReadFrom(Reader* reader);

  virtual ~VectorGet();

  DEFINE_CASTING_OPERATIONS(VectorGet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* vector_expression() { return vector_expression_; }
  intptr_t index() { return index_; }

 private:
  VectorGet() {}

  Child<Expression> vector_expression_;
  intptr_t index_;

  DISALLOW_COPY_AND_ASSIGN(VectorGet);
};


class VectorSet : public Expression {
 public:
  static VectorSet* ReadFrom(Reader* reader);

  virtual ~VectorSet();

  DEFINE_CASTING_OPERATIONS(VectorSet);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* vector_expression() { return vector_expression_; }
  intptr_t index() { return index_; }
  Expression* value() { return value_; }

 private:
  VectorSet() {}

  Child<Expression> vector_expression_;
  intptr_t index_;
  Child<Expression> value_;

  DISALLOW_COPY_AND_ASSIGN(VectorSet);
};


class VectorCopy : public Expression {
 public:
  static VectorCopy* ReadFrom(Reader* reader);

  virtual ~VectorCopy();

  DEFINE_CASTING_OPERATIONS(VectorCopy);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* vector_expression() { return vector_expression_; }

 private:
  VectorCopy() {}

  Child<Expression> vector_expression_;

  DISALLOW_COPY_AND_ASSIGN(VectorCopy);
};


class ClosureCreation : public Expression {
 public:
  static ClosureCreation* ReadFrom(Reader* reader);

  virtual ~ClosureCreation();

  DEFINE_CASTING_OPERATIONS(ClosureCreation);

  virtual void AcceptExpressionVisitor(ExpressionVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex top_level_function() { return top_level_function_reference_; }
  Expression* context_vector() { return context_vector_; }
  FunctionType* function_type() { return function_type_; }

 private:
  ClosureCreation() {}

  NameIndex top_level_function_reference_;  // Procedure canonical name.
  Child<Expression> context_vector_;
  Child<FunctionType> function_type_;

  DISALLOW_COPY_AND_ASSIGN(ClosureCreation);
};


class Statement : public TreeNode {
 public:
  static Statement* ReadFrom(Reader* reader);

  virtual ~Statement();

  DEFINE_CASTING_OPERATIONS(Statement);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void AcceptStatementVisitor(StatementVisitor* visitor) = 0;
  TokenPosition position() { return position_; }

 protected:
  Statement() : position_(TokenPosition::kNoSource) {}
  TokenPosition position_;

 private:
  DISALLOW_COPY_AND_ASSIGN(Statement);
};


class InvalidStatement : public Statement {
 public:
  static InvalidStatement* ReadFrom(Reader* reader);

  virtual ~InvalidStatement();

  DEFINE_CASTING_OPERATIONS(InvalidStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  InvalidStatement() {}

  DISALLOW_COPY_AND_ASSIGN(InvalidStatement);
};


class ExpressionStatement : public Statement {
 public:
  static ExpressionStatement* ReadFrom(Reader* reader);

  explicit ExpressionStatement(Expression* exp) : expression_(exp) {}
  virtual ~ExpressionStatement();

  DEFINE_CASTING_OPERATIONS(ExpressionStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* expression() { return expression_; }

 private:
  ExpressionStatement() {}

  Child<Expression> expression_;

  DISALLOW_COPY_AND_ASSIGN(ExpressionStatement);
};


class Block : public Statement {
 public:
  static Block* ReadFromImpl(Reader* reader);

  virtual ~Block();

  DEFINE_CASTING_OPERATIONS(Block);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  List<Statement>& statements() { return statements_; }
  TokenPosition end_position() { return end_position_; }

 private:
  Block() : end_position_(TokenPosition::kNoSource) {}

  List<Statement> statements_;
  TokenPosition end_position_;

  DISALLOW_COPY_AND_ASSIGN(Block);
};


class EmptyStatement : public Statement {
 public:
  static EmptyStatement* ReadFrom(Reader* reader);

  virtual ~EmptyStatement();

  DEFINE_CASTING_OPERATIONS(EmptyStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  EmptyStatement() {}

  DISALLOW_COPY_AND_ASSIGN(EmptyStatement);
};


class AssertStatement : public Statement {
 public:
  static AssertStatement* ReadFrom(Reader* reader);

  virtual ~AssertStatement();

  DEFINE_CASTING_OPERATIONS(AssertStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* condition() { return condition_; }
  Expression* message() { return message_; }

 private:
  AssertStatement() {}

  Child<Expression> condition_;
  Child<Expression> message_;

  DISALLOW_COPY_AND_ASSIGN(AssertStatement);
};


class LabeledStatement : public Statement {
 public:
  static LabeledStatement* ReadFrom(Reader* reader);

  virtual ~LabeledStatement();

  DEFINE_CASTING_OPERATIONS(LabeledStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Statement* body() { return body_; }

 private:
  LabeledStatement() {}

  Child<Statement> body_;

  DISALLOW_COPY_AND_ASSIGN(LabeledStatement);
};


class BreakStatement : public Statement {
 public:
  static BreakStatement* ReadFrom(Reader* reader);

  virtual ~BreakStatement();

  DEFINE_CASTING_OPERATIONS(BreakStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  intptr_t target_index() { return target_index_; }

 private:
  BreakStatement() {}

  intptr_t target_index_;

  DISALLOW_COPY_AND_ASSIGN(BreakStatement);
};


class WhileStatement : public Statement {
 public:
  static WhileStatement* ReadFrom(Reader* reader);

  virtual ~WhileStatement();

  DEFINE_CASTING_OPERATIONS(WhileStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* condition() { return condition_; }
  Statement* body() { return body_; }

 private:
  WhileStatement() {}

  Child<Expression> condition_;
  Child<Statement> body_;

  DISALLOW_COPY_AND_ASSIGN(WhileStatement);
};


class DoStatement : public Statement {
 public:
  static DoStatement* ReadFrom(Reader* reader);

  virtual ~DoStatement();

  DEFINE_CASTING_OPERATIONS(DoStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* condition() { return condition_; }
  Statement* body() { return body_; }

 private:
  DoStatement() {}

  Child<Expression> condition_;
  Child<Statement> body_;

  DISALLOW_COPY_AND_ASSIGN(DoStatement);
};


class ForStatement : public Statement {
 public:
  static ForStatement* ReadFrom(Reader* reader);

  virtual ~ForStatement();

  DEFINE_CASTING_OPERATIONS(ForStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  List<VariableDeclaration>& variables() { return variables_; }
  Expression* condition() { return condition_; }
  List<Expression>& updates() { return updates_; }
  Statement* body() { return body_; }
  TokenPosition position() { return position_; }
  TokenPosition end_position() { return end_position_; }

 private:
  ForStatement()
      : position_(TokenPosition::kNoSource),
        end_position_(TokenPosition::kNoSource) {}

  List<VariableDeclaration> variables_;
  Child<Expression> condition_;
  List<Expression> updates_;
  Child<Statement> body_;
  TokenPosition position_;
  TokenPosition end_position_;

  DISALLOW_COPY_AND_ASSIGN(ForStatement);
};


class ForInStatement : public Statement {
 public:
  static ForInStatement* ReadFrom(Reader* reader, bool is_async);

  virtual ~ForInStatement();

  DEFINE_CASTING_OPERATIONS(ForInStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  VariableDeclaration* variable() { return variable_; }
  Expression* iterable() { return iterable_; }
  Statement* body() { return body_; }
  bool is_async() { return is_async_; }
  TokenPosition position() { return position_; }
  TokenPosition end_position() { return end_position_; }

 private:
  ForInStatement()
      : position_(TokenPosition::kNoSource),
        end_position_(TokenPosition::kNoSource) {}

  Child<VariableDeclaration> variable_;
  Child<Expression> iterable_;
  Child<Statement> body_;
  bool is_async_;
  TokenPosition position_;
  TokenPosition end_position_;

  DISALLOW_COPY_AND_ASSIGN(ForInStatement);
};


class SwitchStatement : public Statement {
 public:
  static SwitchStatement* ReadFrom(Reader* reader);

  virtual ~SwitchStatement();

  DEFINE_CASTING_OPERATIONS(SwitchStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* condition() { return condition_; }
  List<SwitchCase>& cases() { return cases_; }

 private:
  SwitchStatement() {}

  Child<Expression> condition_;
  List<SwitchCase> cases_;

  DISALLOW_COPY_AND_ASSIGN(SwitchStatement);
};


class SwitchCase : public TreeNode {
 public:
  SwitchCase* ReadFrom(Reader* reader);

  virtual ~SwitchCase();

  DEFINE_CASTING_OPERATIONS(SwitchCase);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  List<Expression>& expressions() { return expressions_; }
  bool is_default() { return is_default_; }
  Statement* body() { return body_; }

 private:
  SwitchCase() {}

  template <typename T>
  friend class List;

  List<Expression> expressions_;
  bool is_default_;
  Child<Statement> body_;

  DISALLOW_COPY_AND_ASSIGN(SwitchCase);
};


class ContinueSwitchStatement : public Statement {
 public:
  static ContinueSwitchStatement* ReadFrom(Reader* reader);

  virtual ~ContinueSwitchStatement();

  DEFINE_CASTING_OPERATIONS(ContinueSwitchStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  intptr_t target_index() { return target_index_; }

 private:
  ContinueSwitchStatement() {}

  intptr_t target_index_;

  DISALLOW_COPY_AND_ASSIGN(ContinueSwitchStatement);
};


class IfStatement : public Statement {
 public:
  static IfStatement* ReadFrom(Reader* reader);

  virtual ~IfStatement();

  DEFINE_CASTING_OPERATIONS(IfStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* condition() { return condition_; }
  Statement* then() { return then_; }
  Statement* otherwise() { return otherwise_; }

 private:
  IfStatement() {}

  Child<Expression> condition_;
  Child<Statement> then_;
  Child<Statement> otherwise_;

  DISALLOW_COPY_AND_ASSIGN(IfStatement);
};


class ReturnStatement : public Statement {
 public:
  ReturnStatement(Expression* expression, bool can_stream)
      : expression_(expression) {
    can_stream_ = can_stream;
  }

  static ReturnStatement* ReadFrom(Reader* reader);

  virtual ~ReturnStatement();

  DEFINE_CASTING_OPERATIONS(ReturnStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Expression* expression() { return expression_; }

 private:
  ReturnStatement() {}

  Child<Expression> expression_;

  DISALLOW_COPY_AND_ASSIGN(ReturnStatement);
};


class TryCatch : public Statement {
 public:
  static TryCatch* ReadFrom(Reader* reader);

  virtual ~TryCatch();

  DEFINE_CASTING_OPERATIONS(TryCatch);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Statement* body() { return body_; }
  List<Catch>& catches() { return catches_; }

 private:
  TryCatch() {}

  Child<Statement> body_;
  List<Catch> catches_;

  DISALLOW_COPY_AND_ASSIGN(TryCatch);
};


class Catch : public TreeNode {
 public:
  static Catch* ReadFrom(Reader* reader);

  virtual ~Catch();

  DEFINE_CASTING_OPERATIONS(Catch);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  DartType* guard() { return guard_; }
  VariableDeclaration* exception() { return exception_; }
  VariableDeclaration* stack_trace() { return stack_trace_; }
  Statement* body() { return body_; }
  TokenPosition position() { return position_; }
  TokenPosition end_position() { return end_position_; }

 private:
  Catch()
      : position_(TokenPosition::kNoSource),
        end_position_(TokenPosition::kNoSource) {}

  template <typename T>
  friend class List;

  Child<DartType> guard_;
  Child<VariableDeclaration> exception_;
  Child<VariableDeclaration> stack_trace_;
  Child<Statement> body_;
  TokenPosition position_;
  TokenPosition end_position_;

  DISALLOW_COPY_AND_ASSIGN(Catch);
};


class TryFinally : public Statement {
 public:
  static TryFinally* ReadFrom(Reader* reader);

  virtual ~TryFinally();

  DEFINE_CASTING_OPERATIONS(TryFinally);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  Statement* body() { return body_; }
  Statement* finalizer() { return finalizer_; }

 private:
  TryFinally() {}

  Child<Statement> body_;
  Child<Statement> finalizer_;

  DISALLOW_COPY_AND_ASSIGN(TryFinally);
};


class YieldStatement : public Statement {
 public:
  enum {
    kFlagYieldStar = 1 << 0,
    kFlagNative = 1 << 1,
  };
  static YieldStatement* ReadFrom(Reader* reader);

  virtual ~YieldStatement();

  DEFINE_CASTING_OPERATIONS(YieldStatement);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  bool is_yield_start() { return (flags_ & kFlagYieldStar) == kFlagYieldStar; }
  bool is_native() { return (flags_ & kFlagNative) == kFlagNative; }
  Expression* expression() { return expression_; }

 private:
  YieldStatement() {}

  word flags_;
  Child<Expression> expression_;

  DISALLOW_COPY_AND_ASSIGN(YieldStatement);
};


class VariableDeclaration : public Statement {
 public:
  enum Flags {
    kFlagFinal = 1 << 0,
    kFlagConst = 1 << 1,
  };

  static VariableDeclaration* ReadFrom(Reader* reader);
  static VariableDeclaration* ReadFromImpl(Reader* reader, bool read_tag);

  virtual ~VariableDeclaration();

  DEFINE_CASTING_OPERATIONS(VariableDeclaration);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  bool IsConst() { return (flags_ & kFlagConst) == kFlagConst; }
  bool IsFinal() { return (flags_ & kFlagFinal) == kFlagFinal; }

  StringIndex name() { return name_index_; }
  DartType* type() { return type_; }
  Expression* initializer() { return initializer_; }
  TokenPosition equals_position() { return equals_position_; }
  TokenPosition end_position() { return end_position_; }
  void set_end_position(TokenPosition position) { end_position_ = position; }
  intptr_t kernel_offset_no_tag() const { return kernel_offset_no_tag_; }

 private:
  VariableDeclaration()
      : equals_position_(TokenPosition::kNoSourcePos),
        end_position_(TokenPosition::kNoSource),
        kernel_offset_no_tag_(-1) {}

  template <typename T>
  friend class List;

  StringIndex name_index_;
  word flags_;
  Child<DartType> type_;
  Child<Expression> initializer_;
  TokenPosition equals_position_;
  TokenPosition end_position_;

  // Offset for this node in the kernel-binary. Always without the tag.
  // Can be -1 to indicate "unknown" or invalid offset.
  intptr_t kernel_offset_no_tag_;

  DISALLOW_COPY_AND_ASSIGN(VariableDeclaration);
};


class FunctionDeclaration : public Statement {
 public:
  static FunctionDeclaration* ReadFrom(Reader* reader);

  virtual ~FunctionDeclaration();

  DEFINE_CASTING_OPERATIONS(FunctionDeclaration);

  virtual void AcceptStatementVisitor(StatementVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  VariableDeclaration* variable() { return variable_; }
  FunctionNode* function() { return function_; }

 private:
  FunctionDeclaration() {}

  Child<VariableDeclaration> variable_;
  Child<FunctionNode> function_;

  DISALLOW_COPY_AND_ASSIGN(FunctionDeclaration);
};


class Name : public Node {
 public:
  static Name* ReadFrom(Reader* reader);

  virtual ~Name();

  DEFINE_CASTING_OPERATIONS(Name);

  virtual void AcceptVisitor(Visitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  StringIndex string_index() { return string_index_; }
  NameIndex library() { return library_reference_; }

 private:
  Name(intptr_t string_index, intptr_t library_reference)
      : string_index_(string_index),
        library_reference_(library_reference) {}  // NOLINT

  StringIndex string_index_;
  NameIndex library_reference_;  // Library canonical name.

  DISALLOW_COPY_AND_ASSIGN(Name);
};


class DartType : public Node {
 public:
  static DartType* ReadFrom(Reader* reader);

  virtual ~DartType();

  DEFINE_CASTING_OPERATIONS(DartType);

  virtual void AcceptVisitor(Visitor* visitor);
  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor) = 0;

 protected:
  DartType() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(DartType);
};


class InvalidType : public DartType {
 public:
  static InvalidType* ReadFrom(Reader* reader);

  virtual ~InvalidType();

  DEFINE_CASTING_OPERATIONS(InvalidType);

  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  InvalidType() {}

  DISALLOW_COPY_AND_ASSIGN(InvalidType);
};


class DynamicType : public DartType {
 public:
  static DynamicType* ReadFrom(Reader* reader);

  virtual ~DynamicType();

  DEFINE_CASTING_OPERATIONS(DynamicType);

  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  DynamicType() {}

  DISALLOW_COPY_AND_ASSIGN(DynamicType);
};


class VoidType : public DartType {
 public:
  static VoidType* ReadFrom(Reader* reader);

  virtual ~VoidType();

  DEFINE_CASTING_OPERATIONS(VoidType);

  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  VoidType() {}

  DISALLOW_COPY_AND_ASSIGN(VoidType);
};


class BottomType : public DartType {
 public:
  static BottomType* ReadFrom(Reader* reader);

  virtual ~BottomType();

  DEFINE_CASTING_OPERATIONS(BottomType);

  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  BottomType() {}

  DISALLOW_COPY_AND_ASSIGN(BottomType);
};


class InterfaceType : public DartType {
 public:
  static InterfaceType* ReadFrom(Reader* reader);
  static InterfaceType* ReadFrom(Reader* reader, bool _without_type_arguments_);

  explicit InterfaceType(NameIndex class_reference)
      : class_reference_(class_reference) {}
  virtual ~InterfaceType();

  DEFINE_CASTING_OPERATIONS(InterfaceType);

  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex klass() { return class_reference_; }
  List<DartType>& type_arguments() { return type_arguments_; }

 private:
  InterfaceType() {}

  NameIndex class_reference_;  // Class canonical name.
  List<DartType> type_arguments_;

  DISALLOW_COPY_AND_ASSIGN(InterfaceType);
};


class TypedefType : public DartType {
 public:
  static TypedefType* ReadFrom(Reader* reader);

  explicit TypedefType(NameIndex class_reference)
      : typedef_reference_(class_reference) {}
  virtual ~TypedefType();

  DEFINE_CASTING_OPERATIONS(TypedefType);

  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  NameIndex typedef_reference() { return typedef_reference_; }
  List<DartType>& type_arguments() { return type_arguments_; }

 private:
  TypedefType() {}

  NameIndex typedef_reference_;  // Typedef canonical name.
  List<DartType> type_arguments_;

  DISALLOW_COPY_AND_ASSIGN(TypedefType);
};


class NamedParameter {
 public:
  static NamedParameter* ReadFrom(Reader* reader);

  NamedParameter(StringIndex name_index, DartType* type)
      : name_index_(name_index), type_(type) {}

  StringIndex name() { return name_index_; }
  DartType* type() { return type_; }

 private:
  NamedParameter() {}

  StringIndex name_index_;
  Child<DartType> type_;

  DISALLOW_COPY_AND_ASSIGN(NamedParameter);
};


class FunctionType : public DartType {
 public:
  static FunctionType* ReadFrom(Reader* reader);
  static FunctionType* ReadFrom(Reader* reader, bool _without_type_arguments_);

  virtual ~FunctionType();

  DEFINE_CASTING_OPERATIONS(FunctionType);

  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  TypeParameterList& type_parameters() { return type_parameters_; }
  int required_parameter_count() { return required_parameter_count_; }
  List<DartType>& positional_parameters() { return positional_parameters_; }
  List<NamedParameter>& named_parameters() { return named_parameters_; }
  DartType* return_type() { return return_type_; }

 private:
  FunctionType() {}

  TypeParameterList type_parameters_;
  int required_parameter_count_;
  List<DartType> positional_parameters_;
  List<NamedParameter> named_parameters_;
  Child<DartType> return_type_;

  DISALLOW_COPY_AND_ASSIGN(FunctionType);
};


class TypeParameterType : public DartType {
 public:
  static TypeParameterType* ReadFrom(Reader* reader);

  virtual ~TypeParameterType();

  DEFINE_CASTING_OPERATIONS(TypeParameterType);

  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  TypeParameter* parameter() { return parameter_; }

 private:
  TypeParameterType() {}

  Ref<TypeParameter> parameter_;

  DISALLOW_COPY_AND_ASSIGN(TypeParameterType);
};


class VectorType : public DartType {
 public:
  static VectorType* ReadFrom(Reader* reader);

  virtual ~VectorType();

  DEFINE_CASTING_OPERATIONS(VectorType);

  virtual void AcceptDartTypeVisitor(DartTypeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

 private:
  VectorType() {}

  DISALLOW_COPY_AND_ASSIGN(VectorType);
};


class TypeParameter : public TreeNode {
 public:
  TypeParameter* ReadFrom(Reader* reader);

  virtual ~TypeParameter();

  DEFINE_CASTING_OPERATIONS(TypeParameter);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  StringIndex name() { return name_index_; }
  DartType* bound() { return bound_; }

 private:
  TypeParameter() {}

  template <typename T>
  friend class List;
  friend class TypeParameterList;

  StringIndex name_index_;
  Child<DartType> bound_;

  DISALLOW_COPY_AND_ASSIGN(TypeParameter);
};


class Program : public TreeNode {
 public:
  static Program* ReadFrom(Reader* reader);

  virtual ~Program();

  DEFINE_CASTING_OPERATIONS(Program);

  virtual void AcceptTreeVisitor(TreeVisitor* visitor);
  virtual void VisitChildren(Visitor* visitor);

  SourceTable& source_table() { return source_table_; }
  List<Library>& libraries() { return libraries_; }
  NameIndex main_method() { return main_method_reference_; }
  MallocGrowableArray<MallocGrowableArray<intptr_t>*> valid_token_positions;
  MallocGrowableArray<MallocGrowableArray<intptr_t>*> yield_token_positions;
  intptr_t string_table_offset() { return string_table_offset_; }
  intptr_t name_table_offset() { return name_table_offset_; }

 private:
  Program() {}

  NameIndex main_method_reference_;  // Procedure.
  List<Library> libraries_;
  SourceTable source_table_;

  // The offset from the start of the binary to the start of the string table.
  intptr_t string_table_offset_;

  // The offset from the start of the binary to the canonical name table.
  intptr_t name_table_offset_;

  DISALLOW_COPY_AND_ASSIGN(Program);
};


class Reference : public AllStatic {
 public:
  // Read canonical name references.
  static NameIndex ReadMemberFrom(Reader* reader, bool allow_null = false);
  static NameIndex ReadClassFrom(Reader* reader, bool allow_null = false);
  static NameIndex ReadTypedefFrom(Reader* reader);
  static NameIndex ReadLibraryFrom(Reader* reader);
};


class ExpressionVisitor {
 public:
  virtual ~ExpressionVisitor() {}

  virtual void VisitDefaultExpression(Expression* node) = 0;
  virtual void VisitDefaultBasicLiteral(BasicLiteral* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitInvalidExpression(InvalidExpression* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitVariableGet(VariableGet* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitVariableSet(VariableSet* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitPropertyGet(PropertyGet* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitPropertySet(PropertySet* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitDirectPropertyGet(DirectPropertyGet* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitDirectPropertySet(DirectPropertySet* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitStaticGet(StaticGet* node) { VisitDefaultExpression(node); }
  virtual void VisitStaticSet(StaticSet* node) { VisitDefaultExpression(node); }
  virtual void VisitMethodInvocation(MethodInvocation* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitDirectMethodInvocation(DirectMethodInvocation* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitStaticInvocation(StaticInvocation* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitConstructorInvocation(ConstructorInvocation* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitNot(Not* node) { VisitDefaultExpression(node); }
  virtual void VisitLogicalExpression(LogicalExpression* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitConditionalExpression(ConditionalExpression* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitStringConcatenation(StringConcatenation* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitIsExpression(IsExpression* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitAsExpression(AsExpression* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitSymbolLiteral(SymbolLiteral* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitTypeLiteral(TypeLiteral* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitThisExpression(ThisExpression* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitRethrow(Rethrow* node) { VisitDefaultExpression(node); }
  virtual void VisitThrow(Throw* node) { VisitDefaultExpression(node); }
  virtual void VisitListLiteral(ListLiteral* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitMapLiteral(MapLiteral* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitAwaitExpression(AwaitExpression* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitFunctionExpression(FunctionExpression* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitStringLiteral(StringLiteral* node) {
    VisitDefaultBasicLiteral(node);
  }
  virtual void VisitBigintLiteral(BigintLiteral* node) {
    VisitDefaultBasicLiteral(node);
  }
  virtual void VisitIntLiteral(IntLiteral* node) {
    VisitDefaultBasicLiteral(node);
  }
  virtual void VisitDoubleLiteral(DoubleLiteral* node) {
    VisitDefaultBasicLiteral(node);
  }
  virtual void VisitBoolLiteral(BoolLiteral* node) {
    VisitDefaultBasicLiteral(node);
  }
  virtual void VisitNullLiteral(NullLiteral* node) {
    VisitDefaultBasicLiteral(node);
  }
  virtual void VisitLet(Let* node) { VisitDefaultExpression(node); }
  virtual void VisitVectorCreation(VectorCreation* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitVectorGet(VectorGet* node) { VisitDefaultExpression(node); }
  virtual void VisitVectorSet(VectorSet* node) { VisitDefaultExpression(node); }
  virtual void VisitVectorCopy(VectorCopy* node) {
    VisitDefaultExpression(node);
  }
  virtual void VisitClosureCreation(ClosureCreation* node) {
    VisitDefaultExpression(node);
  }
};


class StatementVisitor {
 public:
  virtual ~StatementVisitor() {}

  virtual void VisitDefaultStatement(Statement* node) = 0;
  virtual void VisitInvalidStatement(InvalidStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitExpressionStatement(ExpressionStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitBlock(Block* node) { VisitDefaultStatement(node); }
  virtual void VisitEmptyStatement(EmptyStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitAssertStatement(AssertStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitLabeledStatement(LabeledStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitBreakStatement(BreakStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitWhileStatement(WhileStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitDoStatement(DoStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitForStatement(ForStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitForInStatement(ForInStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitSwitchStatement(SwitchStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitContinueSwitchStatement(ContinueSwitchStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitIfStatement(IfStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitReturnStatement(ReturnStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitTryCatch(TryCatch* node) { VisitDefaultStatement(node); }
  virtual void VisitTryFinally(TryFinally* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitYieldStatement(YieldStatement* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitVariableDeclaration(VariableDeclaration* node) {
    VisitDefaultStatement(node);
  }
  virtual void VisitFunctionDeclaration(FunctionDeclaration* node) {
    VisitDefaultStatement(node);
  }
};


class MemberVisitor {
 public:
  virtual ~MemberVisitor() {}

  virtual void VisitDefaultMember(Member* node) = 0;
  virtual void VisitConstructor(Constructor* node) { VisitDefaultMember(node); }
  virtual void VisitProcedure(Procedure* node) { VisitDefaultMember(node); }
  virtual void VisitField(Field* node) { VisitDefaultMember(node); }
};


class ClassVisitor {
 public:
  virtual ~ClassVisitor() {}

  virtual void VisitDefaultClass(Class* node) = 0;
  virtual void VisitNormalClass(NormalClass* node) { VisitDefaultClass(node); }
  virtual void VisitMixinClass(MixinClass* node) { VisitDefaultClass(node); }
};


class InitializerVisitor {
 public:
  virtual ~InitializerVisitor() {}

  virtual void VisitDefaultInitializer(Initializer* node) = 0;
  virtual void VisitInvalidInitializer(InvalidInitializer* node) {
    VisitDefaultInitializer(node);
  }
  virtual void VisitFieldInitializer(FieldInitializer* node) {
    VisitDefaultInitializer(node);
  }
  virtual void VisitSuperInitializer(SuperInitializer* node) {
    VisitDefaultInitializer(node);
  }
  virtual void VisitRedirectingInitializer(RedirectingInitializer* node) {
    VisitDefaultInitializer(node);
  }
  virtual void VisitLocalInitializer(LocalInitializer* node) {
    VisitDefaultInitializer(node);
  }
};


class DartTypeVisitor {
 public:
  virtual ~DartTypeVisitor() {}

  virtual void VisitDefaultDartType(DartType* node) = 0;
  virtual void VisitInvalidType(InvalidType* node) {
    VisitDefaultDartType(node);
  }
  virtual void VisitDynamicType(DynamicType* node) {
    VisitDefaultDartType(node);
  }
  virtual void VisitVoidType(VoidType* node) { VisitDefaultDartType(node); }
  virtual void VisitBottomType(BottomType* node) { VisitDefaultDartType(node); }
  virtual void VisitInterfaceType(InterfaceType* node) {
    VisitDefaultDartType(node);
  }
  virtual void VisitFunctionType(FunctionType* node) {
    VisitDefaultDartType(node);
  }
  virtual void VisitTypeParameterType(TypeParameterType* node) {
    VisitDefaultDartType(node);
  }
  virtual void VisitVectorType(VectorType* node) { VisitDefaultDartType(node); }
  virtual void VisitTypedefType(TypedefType* node) {
    VisitDefaultDartType(node);
  }
};


class TreeVisitor : public ExpressionVisitor,
                    public StatementVisitor,
                    public MemberVisitor,
                    public ClassVisitor,
                    public InitializerVisitor {
 public:
  virtual ~TreeVisitor() {}

  virtual void VisitDefaultTreeNode(TreeNode* node) = 0;
  virtual void VisitDefaultStatement(Statement* node) {
    VisitDefaultTreeNode(node);
  }
  virtual void VisitDefaultExpression(Expression* node) {
    VisitDefaultTreeNode(node);
  }
  virtual void VisitDefaultMember(Member* node) { VisitDefaultTreeNode(node); }
  virtual void VisitDefaultClass(Class* node) { VisitDefaultTreeNode(node); }
  virtual void VisitDefaultInitializer(Initializer* node) {
    VisitDefaultTreeNode(node);
  }

  virtual void VisitLibrary(Library* node) { VisitDefaultTreeNode(node); }
  virtual void VisitTypeParameter(TypeParameter* node) {
    VisitDefaultTreeNode(node);
  }
  virtual void VisitFunctionNode(FunctionNode* node) {
    VisitDefaultTreeNode(node);
  }
  virtual void VisitArguments(Arguments* node) { VisitDefaultTreeNode(node); }
  virtual void VisitNamedExpression(NamedExpression* node) {
    VisitDefaultTreeNode(node);
  }
  virtual void VisitSwitchCase(SwitchCase* node) { VisitDefaultTreeNode(node); }
  virtual void VisitCatch(Catch* node) { VisitDefaultTreeNode(node); }
  virtual void VisitMapEntry(MapEntry* node) { VisitDefaultTreeNode(node); }
  virtual void VisitProgram(Program* node) { VisitDefaultTreeNode(node); }
  virtual void VisitTypedef(Typedef* node) { VisitDefaultTreeNode(node); }
};


class Visitor : public TreeVisitor, public DartTypeVisitor {
 public:
  virtual ~Visitor() {}

  virtual void VisitDefaultNode(Node* node) = 0;
  virtual void VisitDefaultTreeNode(TreeNode* node) { VisitDefaultNode(node); }
  virtual void VisitDefaultDartType(DartType* node) { VisitDefaultNode(node); }
  virtual void VisitName(Name* node) { VisitDefaultNode(node); }
  virtual void VisitDefaultClassReference(Class* node) {
    VisitDefaultNode(node);
  }
  virtual void VisitDefaultMemberReference(Member* node) {
    VisitDefaultNode(node);
  }
};


class RecursiveVisitor : public Visitor {
 public:
  virtual ~RecursiveVisitor() {}

  virtual void VisitDefaultNode(Node* node) { node->VisitChildren(this); }

  virtual void VisitDefaultClassReference(Class* node) {}
  virtual void VisitDefaultMemberReference(Member* node) {}
};


template <typename T>
List<T>::~List() {
  for (int i = 0; i < length_; i++) {
    delete array_[i];
  }
  delete[] array_;
}


template <typename T>
void List<T>::EnsureInitialized(int length) {
  if (length < length_) return;

  T** old_array = array_;
  int old_length = length_;

  // TODO(27590) Maybe we should use double-growth instead to avoid running
  // into the quadratic case.
  length_ = length;
  array_ = new T*[length_];

  // Move old elements at the start (if necessary).
  int offset = 0;
  if (old_array != NULL) {
    for (; offset < old_length; offset++) {
      array_[offset] = old_array[offset];
    }
  }

  // Set the rest to NULL.
  for (; offset < length_; offset++) {
    array_[offset] = NULL;
  }

  delete[] old_array;
}


template <typename T>
template <typename IT>
IT* List<T>::GetOrCreate(int index) {
  EnsureInitialized(index + 1);

  T* member = array_[index];
  if (member == NULL) {
    member = array_[index] = new IT();
  }
  return IT::Cast(member);
}


template <typename T>
template <typename IT, typename PT>
IT* List<T>::GetOrCreate(int index, PT* parent) {
  EnsureInitialized(index + 1);

  T* member = array_[index];
  if (member == NULL) {
    member = array_[index] = new IT();
    member->parent_ = parent;
  } else {
    ASSERT(member->parent_ == parent);
  }
  return IT::Cast(member);
}

ParsedFunction* ParseStaticFieldInitializer(Zone* zone,
                                            const dart::Field& field);

}  // namespace kernel

kernel::Program* ReadPrecompiledKernelFromBuffer(const uint8_t* buffer,
                                                 intptr_t buffer_length);


}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_H_
