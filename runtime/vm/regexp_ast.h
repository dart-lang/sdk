// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REGEXP_AST_H_
#define RUNTIME_VM_REGEXP_AST_H_

#include "platform/globals.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/regexp.h"

namespace dart {

class RegExpAlternative;
class RegExpAssertion;
class RegExpAtom;
class RegExpBackReference;
class RegExpCapture;
class RegExpCharacterClass;
class RegExpCompiler;
class RegExpDisjunction;
class RegExpEmpty;
class RegExpLookaround;
class RegExpQuantifier;
class RegExpText;

class RegExpVisitor : public ValueObject {
 public:
  virtual ~RegExpVisitor() {}
#define MAKE_CASE(Name)                                                        \
  virtual void* Visit##Name(RegExp##Name*, void* data) = 0;
  FOR_EACH_REG_EXP_TREE_TYPE(MAKE_CASE)
#undef MAKE_CASE
};

class RegExpTree : public ZoneAllocated {
 public:
  static const intptr_t kInfinity = kMaxInt32;
  virtual ~RegExpTree() {}
  virtual void* Accept(RegExpVisitor* visitor, void* data) = 0;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) = 0;
  virtual bool IsTextElement() const { return false; }
  virtual bool IsAnchoredAtStart() const { return false; }
  virtual bool IsAnchoredAtEnd() const { return false; }
  virtual intptr_t min_match() const = 0;
  virtual intptr_t max_match() const = 0;
  // Returns the interval of registers used for captures within this
  // expression.
  virtual Interval CaptureRegisters() const { return Interval::Empty(); }
  virtual void AppendToText(RegExpText* text);
  void Print();
#define MAKE_ASTYPE(Name)                                                      \
  virtual RegExp##Name* As##Name();                                            \
  virtual bool Is##Name() const;
  FOR_EACH_REG_EXP_TREE_TYPE(MAKE_ASTYPE)
#undef MAKE_ASTYPE
};

class RegExpDisjunction : public RegExpTree {
 public:
  explicit RegExpDisjunction(ZoneGrowableArray<RegExpTree*>* alternatives);
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  virtual RegExpDisjunction* AsDisjunction();
  virtual Interval CaptureRegisters() const;
  virtual bool IsDisjunction() const;
  virtual bool IsAnchoredAtStart() const;
  virtual bool IsAnchoredAtEnd() const;
  virtual intptr_t min_match() const { return min_match_; }
  virtual intptr_t max_match() const { return max_match_; }
  ZoneGrowableArray<RegExpTree*>* alternatives() const { return alternatives_; }

 private:
  ZoneGrowableArray<RegExpTree*>* alternatives_;
  intptr_t min_match_;
  intptr_t max_match_;
};

class RegExpAlternative : public RegExpTree {
 public:
  explicit RegExpAlternative(ZoneGrowableArray<RegExpTree*>* nodes);
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  virtual RegExpAlternative* AsAlternative();
  virtual Interval CaptureRegisters() const;
  virtual bool IsAlternative() const;
  virtual bool IsAnchoredAtStart() const;
  virtual bool IsAnchoredAtEnd() const;
  virtual intptr_t min_match() const { return min_match_; }
  virtual intptr_t max_match() const { return max_match_; }
  ZoneGrowableArray<RegExpTree*>* nodes() const { return nodes_; }

 private:
  ZoneGrowableArray<RegExpTree*>* nodes_;
  intptr_t min_match_;
  intptr_t max_match_;
};

class RegExpAssertion : public RegExpTree {
 public:
  enum AssertionType {
    START_OF_LINE,
    START_OF_INPUT,
    END_OF_LINE,
    END_OF_INPUT,
    BOUNDARY,
    NON_BOUNDARY
  };
  RegExpAssertion(AssertionType type, RegExpFlags flags)
      : assertion_type_(type), flags_(flags) {}
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  virtual RegExpAssertion* AsAssertion();
  virtual bool IsAssertion() const;
  virtual bool IsAnchoredAtStart() const;
  virtual bool IsAnchoredAtEnd() const;
  virtual intptr_t min_match() const { return 0; }
  virtual intptr_t max_match() const { return 0; }
  AssertionType assertion_type() const { return assertion_type_; }

 private:
  AssertionType assertion_type_;
  RegExpFlags flags_;
};

class CharacterSet : public ValueObject {
 public:
  explicit CharacterSet(uint16_t standard_set_type)
      : ranges_(NULL), standard_set_type_(standard_set_type) {}
  explicit CharacterSet(ZoneGrowableArray<CharacterRange>* ranges)
      : ranges_(ranges), standard_set_type_(0) {}
  CharacterSet(const CharacterSet& that)
      : ValueObject(),
        ranges_(that.ranges_),
        standard_set_type_(that.standard_set_type_) {}
  ZoneGrowableArray<CharacterRange>* ranges();
  uint16_t standard_set_type() const { return standard_set_type_; }
  void set_standard_set_type(uint16_t special_set_type) {
    standard_set_type_ = special_set_type;
  }
  bool is_standard() { return standard_set_type_ != 0; }
  void Canonicalize();

 private:
  ZoneGrowableArray<CharacterRange>* ranges_;
  // If non-zero, the value represents a standard set (e.g., all whitespace
  // characters) without having to expand the ranges.
  uint16_t standard_set_type_;
};

class RegExpCharacterClass : public RegExpTree {
 public:
  enum Flag {
    // The character class is negated and should match everything but the
    // specified ranges.
    NEGATED = 1 << 0,
    // The character class contains part of a split surrogate and should not
    // be unicode-desugared.
    CONTAINS_SPLIT_SURROGATE = 1 << 1,
  };
  using CharacterClassFlags = intptr_t;
  static inline CharacterClassFlags DefaultFlags() { return 0; }

  RegExpCharacterClass(
      ZoneGrowableArray<CharacterRange>* ranges,
      RegExpFlags flags,
      CharacterClassFlags character_class_flags = DefaultFlags())
      : set_(ranges),
        flags_(flags),
        character_class_flags_(character_class_flags) {
    // Convert the empty set of ranges to the negated Everything() range.
    if (ranges->is_empty()) {
      ranges->Add(CharacterRange::Everything());
      character_class_flags_ ^= NEGATED;
    }
  }
  RegExpCharacterClass(uint16_t type, RegExpFlags flags)
      : set_(type), flags_(flags), character_class_flags_(0) {}
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  virtual RegExpCharacterClass* AsCharacterClass();
  virtual bool IsCharacterClass() const;
  virtual bool IsTextElement() const { return true; }
  virtual intptr_t min_match() const { return 1; }
  // The character class may match two code units for unicode regexps.
  virtual intptr_t max_match() const { return 2; }
  virtual void AppendToText(RegExpText* text);
  CharacterSet character_set() const { return set_; }
  // TODO(lrn): Remove need for complex version if is_standard that
  // recognizes a mangled standard set and just do { return set_.is_special(); }
  bool is_standard();
  // Returns a value representing the standard character set if is_standard()
  // returns true.
  // Currently used values are:
  // s : unicode whitespace
  // S : unicode non-whitespace
  // w : ASCII word character (digit, letter, underscore)
  // W : non-ASCII word character
  // d : ASCII digit
  // D : non-ASCII digit
  // . : non-unicode non-newline
  // * : All characters
  uint16_t standard_type() const { return set_.standard_set_type(); }
  ZoneGrowableArray<CharacterRange>* ranges() { return set_.ranges(); }
  bool is_negated() const { return (character_class_flags_ & NEGATED) != 0; }
  RegExpFlags flags() const { return flags_; }
  bool contains_split_surrogate() const {
    return (character_class_flags_ & CONTAINS_SPLIT_SURROGATE) != 0;
  }

 private:
  CharacterSet set_;
  RegExpFlags flags_;
  CharacterClassFlags character_class_flags_;
};

class RegExpAtom : public RegExpTree {
 public:
  RegExpAtom(ZoneGrowableArray<uint16_t>* data, RegExpFlags flags)
      : data_(data), flags_(flags) {}
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  virtual RegExpAtom* AsAtom();
  virtual bool IsAtom() const;
  virtual bool IsTextElement() const { return true; }
  virtual intptr_t min_match() const { return data_->length(); }
  virtual intptr_t max_match() const { return data_->length(); }
  virtual void AppendToText(RegExpText* text);
  ZoneGrowableArray<uint16_t>* data() const { return data_; }
  intptr_t length() const { return data_->length(); }
  RegExpFlags flags() const { return flags_; }
  bool ignore_case() const { return flags_.IgnoreCase(); }

 private:
  ZoneGrowableArray<uint16_t>* data_;
  const RegExpFlags flags_;
};

class RegExpText : public RegExpTree {
 public:
  RegExpText() : elements_(2), length_(0) {}
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  virtual RegExpText* AsText();
  virtual bool IsText() const;
  virtual bool IsTextElement() const { return true; }
  virtual intptr_t min_match() const { return length_; }
  virtual intptr_t max_match() const { return length_; }
  virtual void AppendToText(RegExpText* text);
  void AddElement(TextElement elm) {
    elements_.Add(elm);
    length_ += elm.length();
  }
  GrowableArray<TextElement>* elements() { return &elements_; }

 private:
  GrowableArray<TextElement> elements_;
  intptr_t length_;
};

class RegExpQuantifier : public RegExpTree {
 public:
  enum QuantifierType { GREEDY, NON_GREEDY, POSSESSIVE };
  RegExpQuantifier(intptr_t min,
                   intptr_t max,
                   QuantifierType type,
                   RegExpTree* body)
      : body_(body),
        min_(min),
        max_(max),
        min_match_(min * body->min_match()),
        quantifier_type_(type) {
    if (max > 0 && body->max_match() > kInfinity / max) {
      max_match_ = kInfinity;
    } else {
      max_match_ = max * body->max_match();
    }
  }
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  static RegExpNode* ToNode(intptr_t min,
                            intptr_t max,
                            bool is_greedy,
                            RegExpTree* body,
                            RegExpCompiler* compiler,
                            RegExpNode* on_success,
                            bool not_at_start = false);
  virtual RegExpQuantifier* AsQuantifier();
  virtual Interval CaptureRegisters() const;
  virtual bool IsQuantifier() const;
  virtual intptr_t min_match() const { return min_match_; }
  virtual intptr_t max_match() const { return max_match_; }
  intptr_t min() const { return min_; }
  intptr_t max() const { return max_; }
  bool is_possessive() const { return quantifier_type_ == POSSESSIVE; }
  bool is_non_greedy() const { return quantifier_type_ == NON_GREEDY; }
  bool is_greedy() const { return quantifier_type_ == GREEDY; }
  RegExpTree* body() const { return body_; }

 private:
  RegExpTree* body_;
  intptr_t min_;
  intptr_t max_;
  intptr_t min_match_;
  intptr_t max_match_;
  QuantifierType quantifier_type_;
};

class RegExpCapture : public RegExpTree {
 public:
  explicit RegExpCapture(intptr_t index)
      : body_(nullptr), index_(index), name_(nullptr) {}
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  static RegExpNode* ToNode(RegExpTree* body,
                            intptr_t index,
                            RegExpCompiler* compiler,
                            RegExpNode* on_success);
  virtual RegExpCapture* AsCapture();
  virtual bool IsAnchoredAtStart() const;
  virtual bool IsAnchoredAtEnd() const;
  virtual Interval CaptureRegisters() const;
  virtual bool IsCapture() const;
  virtual intptr_t min_match() const { return body_->min_match(); }
  virtual intptr_t max_match() const { return body_->max_match(); }
  RegExpTree* body() const { return body_; }
  // When a backreference is parsed before the corresponding capture group,
  // which can happen because of lookbehind, we create the capture object when
  // we create the backreference, and fill in the body later when the actual
  // capture group is parsed.
  void set_body(RegExpTree* body) { body_ = body; }
  intptr_t index() const { return index_; }
  const ZoneGrowableArray<uint16_t>* name() { return name_; }
  void set_name(const ZoneGrowableArray<uint16_t>* name) { name_ = name; }
  static intptr_t StartRegister(intptr_t index) { return index * 2; }
  static intptr_t EndRegister(intptr_t index) { return index * 2 + 1; }

 private:
  RegExpTree* body_;
  intptr_t index_;
  const ZoneGrowableArray<uint16_t>* name_;
};

class RegExpLookaround : public RegExpTree {
 public:
  enum Type { LOOKAHEAD, LOOKBEHIND };
  RegExpLookaround(RegExpTree* body,
                   bool is_positive,
                   intptr_t capture_count,
                   intptr_t capture_from,
                   Type type)
      : body_(body),
        is_positive_(is_positive),
        capture_count_(capture_count),
        capture_from_(capture_from),
        type_(type) {}

  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  virtual RegExpLookaround* AsLookaround();
  virtual Interval CaptureRegisters() const;
  virtual bool IsLookaround() const;
  virtual bool IsAnchoredAtStart() const;
  virtual intptr_t min_match() const { return 0; }
  virtual intptr_t max_match() const { return 0; }
  RegExpTree* body() const { return body_; }
  bool is_positive() const { return is_positive_; }
  intptr_t capture_count() const { return capture_count_; }
  intptr_t capture_from() const { return capture_from_; }
  Type type() const { return type_; }

  // The RegExpLookaround::Builder class abstracts out the process of building
  // the compiling a RegExpLookaround object by splitting it into two phases,
  // represented by the provided methods.
  class Builder : public ValueObject {
   public:
    Builder(bool is_positive,
            RegExpNode* on_success,
            intptr_t stack_pointer_register,
            intptr_t position_register,
            intptr_t capture_register_count = 0,
            intptr_t capture_register_start = 0);
    RegExpNode* on_match_success() { return on_match_success_; }
    RegExpNode* ForMatch(RegExpNode* match);

   private:
    bool is_positive_;
    RegExpNode* on_match_success_;
    RegExpNode* on_success_;
    intptr_t stack_pointer_register_;
    intptr_t position_register_;
  };

 private:
  RegExpTree* body_;
  bool is_positive_;
  intptr_t capture_count_;
  intptr_t capture_from_;
  Type type_;
};

class RegExpBackReference : public RegExpTree {
 public:
  explicit RegExpBackReference(RegExpFlags flags)
      : capture_(nullptr), name_(nullptr), flags_(flags) {}
  RegExpBackReference(RegExpCapture* capture, RegExpFlags flags)
      : capture_(capture), name_(nullptr), flags_(flags) {}
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  virtual RegExpBackReference* AsBackReference();
  virtual bool IsBackReference() const;
  virtual intptr_t min_match() const { return 0; }
  // The back reference may be recursive, e.g. /(\2)(\1)/. To avoid infinite
  // recursion, we give up and just assume arbitrary length, which matches v8's
  // behavior.
  virtual intptr_t max_match() const { return kInfinity; }
  intptr_t index() const { return capture_->index(); }
  RegExpCapture* capture() const { return capture_; }
  void set_capture(RegExpCapture* capture) { capture_ = capture; }
  const ZoneGrowableArray<uint16_t>* name() { return name_; }
  void set_name(const ZoneGrowableArray<uint16_t>* name) { name_ = name; }

 private:
  RegExpCapture* capture_;
  const ZoneGrowableArray<uint16_t>* name_;
  RegExpFlags flags_;
};

class RegExpEmpty : public RegExpTree {
 public:
  RegExpEmpty() {}
  virtual void* Accept(RegExpVisitor* visitor, void* data);
  virtual RegExpNode* ToNode(RegExpCompiler* compiler, RegExpNode* on_success);
  virtual RegExpEmpty* AsEmpty();
  virtual bool IsEmpty() const;
  virtual intptr_t min_match() const { return 0; }
  virtual intptr_t max_match() const { return 0; }
  static RegExpEmpty* GetInstance() {
    static RegExpEmpty* instance = ::new RegExpEmpty();
    return instance;
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_AST_H_
