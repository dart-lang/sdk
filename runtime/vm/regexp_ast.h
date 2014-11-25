// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_REGEXP_AST_H_
#define VM_REGEXP_AST_H_

// SNIP

namespace dart {

// SNIP

class RegExpAlternative;
class RegExpAssertion;
class RegExpAtom;
class RegExpBackReference;
class RegExpCapture;
class RegExpCharacterClass;
class RegExpCompiler;
class RegExpDisjunction;
class RegExpEmpty;
class RegExpLookahead;
class RegExpQuantifier;
class RegExpText;

// SNIP

class RegExpVisitor BASE_EMBEDDED {
 public:
  virtual ~RegExpVisitor() { }
#define MAKE_CASE(Name)                                              \
  virtual void* Visit##Name(RegExp##Name*, void* data) = 0;
  FOR_EACH_REG_EXP_TREE_TYPE(MAKE_CASE)
#undef MAKE_CASE
};


class RegExpTree : public ZoneObject {
 public:
  static const int kInfinity = kMaxInt;
  virtual ~RegExpTree() {}
  virtual void* Accept(RegExpVisitor* visitor, void* data) = 0;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) = 0;
  virtual bool IsTextElement() { return false; }
  virtual bool IsAnchoredAtStart() { return false; }
  virtual bool IsAnchoredAtEnd() { return false; }
  virtual int min_match() = 0;
  virtual int max_match() = 0;
  // Returns the interval of registers used for captures within this
  // expression.
  virtual Interval CaptureRegisters() { return Interval::Empty(); }
  virtual void AppendToText(RegExpText* text, Zone* zone);
  OStream& Print(OStream& os, Zone* zone);  // NOLINT
#define MAKE_ASTYPE(Name)                                                  \
  virtual RegExp##Name* As##Name();                                        \
  virtual bool Is##Name();
  FOR_EACH_REG_EXP_TREE_TYPE(MAKE_ASTYPE)
#undef MAKE_ASTYPE
};


class RegExpDisjunction FINAL : public RegExpTree {
 public:
  explicit RegExpDisjunction(ZoneList<RegExpTree*>* alternatives);
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  virtual RegExpDisjunction* AsDisjunction() OVERRIDE;
  virtual Interval CaptureRegisters() OVERRIDE;
  virtual bool IsDisjunction() OVERRIDE;
  virtual bool IsAnchoredAtStart() OVERRIDE;
  virtual bool IsAnchoredAtEnd() OVERRIDE;
  virtual int min_match() OVERRIDE { return min_match_; }
  virtual int max_match() OVERRIDE { return max_match_; }
  ZoneList<RegExpTree*>* alternatives() { return alternatives_; }
 private:
  ZoneList<RegExpTree*>* alternatives_;
  int min_match_;
  int max_match_;
};


class RegExpAlternative FINAL : public RegExpTree {
 public:
  explicit RegExpAlternative(ZoneList<RegExpTree*>* nodes);
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  virtual RegExpAlternative* AsAlternative() OVERRIDE;
  virtual Interval CaptureRegisters() OVERRIDE;
  virtual bool IsAlternative() OVERRIDE;
  virtual bool IsAnchoredAtStart() OVERRIDE;
  virtual bool IsAnchoredAtEnd() OVERRIDE;
  virtual int min_match() OVERRIDE { return min_match_; }
  virtual int max_match() OVERRIDE { return max_match_; }
  ZoneList<RegExpTree*>* nodes() { return nodes_; }
 private:
  ZoneList<RegExpTree*>* nodes_;
  int min_match_;
  int max_match_;
};


class RegExpAssertion FINAL : public RegExpTree {
 public:
  enum AssertionType {
    START_OF_LINE,
    START_OF_INPUT,
    END_OF_LINE,
    END_OF_INPUT,
    BOUNDARY,
    NON_BOUNDARY
  };
  explicit RegExpAssertion(AssertionType type) : assertion_type_(type) { }
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  virtual RegExpAssertion* AsAssertion() OVERRIDE;
  virtual bool IsAssertion() OVERRIDE;
  virtual bool IsAnchoredAtStart() OVERRIDE;
  virtual bool IsAnchoredAtEnd() OVERRIDE;
  virtual int min_match() OVERRIDE { return 0; }
  virtual int max_match() OVERRIDE { return 0; }
  AssertionType assertion_type() { return assertion_type_; }
 private:
  AssertionType assertion_type_;
};


class CharacterSet FINAL BASE_EMBEDDED {
 public:
  explicit CharacterSet(uc16 standard_set_type)
      : ranges_(NULL),
        standard_set_type_(standard_set_type) {}
  explicit CharacterSet(ZoneList<CharacterRange>* ranges)
      : ranges_(ranges),
        standard_set_type_(0) {}
  ZoneList<CharacterRange>* ranges(Zone* zone);
  uc16 standard_set_type() { return standard_set_type_; }
  void set_standard_set_type(uc16 special_set_type) {
    standard_set_type_ = special_set_type;
  }
  bool is_standard() { return standard_set_type_ != 0; }
  void Canonicalize();
 private:
  ZoneList<CharacterRange>* ranges_;
  // If non-zero, the value represents a standard set (e.g., all whitespace
  // characters) without having to expand the ranges.
  uc16 standard_set_type_;
};


class RegExpCharacterClass FINAL : public RegExpTree {
 public:
  RegExpCharacterClass(ZoneList<CharacterRange>* ranges, bool is_negated)
      : set_(ranges),
        is_negated_(is_negated) { }
  explicit RegExpCharacterClass(uc16 type)
      : set_(type),
        is_negated_(false) { }
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  virtual RegExpCharacterClass* AsCharacterClass() OVERRIDE;
  virtual bool IsCharacterClass() OVERRIDE;
  virtual bool IsTextElement() OVERRIDE { return true; }
  virtual int min_match() OVERRIDE { return 1; }
  virtual int max_match() OVERRIDE { return 1; }
  virtual void AppendToText(RegExpText* text, Zone* zone) OVERRIDE;
  CharacterSet character_set() { return set_; }
  // TODO(lrn): Remove need for complex version if is_standard that
  // recognizes a mangled standard set and just do { return set_.is_special(); }
  bool is_standard(Zone* zone);
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
  uc16 standard_type() { return set_.standard_set_type(); }
  ZoneList<CharacterRange>* ranges(Zone* zone) { return set_.ranges(zone); }
  bool is_negated() { return is_negated_; }

 private:
  CharacterSet set_;
  bool is_negated_;
};


class RegExpAtom FINAL : public RegExpTree {
 public:
  explicit RegExpAtom(Vector<const uc16> data) : data_(data) { }
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  virtual RegExpAtom* AsAtom() OVERRIDE;
  virtual bool IsAtom() OVERRIDE;
  virtual bool IsTextElement() OVERRIDE { return true; }
  virtual int min_match() OVERRIDE { return data_.length(); }
  virtual int max_match() OVERRIDE { return data_.length(); }
  virtual void AppendToText(RegExpText* text, Zone* zone) OVERRIDE;
  Vector<const uc16> data() { return data_; }
  int length() { return data_.length(); }
 private:
  Vector<const uc16> data_;
};


class RegExpText FINAL : public RegExpTree {
 public:
  explicit RegExpText(Zone* zone) : elements_(2, zone), length_(0) {}
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  virtual RegExpText* AsText() OVERRIDE;
  virtual bool IsText() OVERRIDE;
  virtual bool IsTextElement() OVERRIDE { return true; }
  virtual int min_match() OVERRIDE { return length_; }
  virtual int max_match() OVERRIDE { return length_; }
  virtual void AppendToText(RegExpText* text, Zone* zone) OVERRIDE;
  void AddElement(TextElement elm, Zone* zone)  {
    elements_.Add(elm, zone);
    length_ += elm.length();
  }
  ZoneList<TextElement>* elements() { return &elements_; }
 private:
  ZoneList<TextElement> elements_;
  int length_;
};


class RegExpQuantifier FINAL : public RegExpTree {
 public:
  enum QuantifierType { GREEDY, NON_GREEDY, POSSESSIVE };
  RegExpQuantifier(int min, int max, QuantifierType type, RegExpTree* body)
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
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  static RegExpNode* ToNode(int min,
                            int max,
                            bool is_greedy,
                            RegExpTree* body,
                            RegExpCompiler* compiler,
                            RegExpNode* on_success,
                            bool not_at_start = false);
  virtual RegExpQuantifier* AsQuantifier() OVERRIDE;
  virtual Interval CaptureRegisters() OVERRIDE;
  virtual bool IsQuantifier() OVERRIDE;
  virtual int min_match() OVERRIDE { return min_match_; }
  virtual int max_match() OVERRIDE { return max_match_; }
  int min() { return min_; }
  int max() { return max_; }
  bool is_possessive() { return quantifier_type_ == POSSESSIVE; }
  bool is_non_greedy() { return quantifier_type_ == NON_GREEDY; }
  bool is_greedy() { return quantifier_type_ == GREEDY; }
  RegExpTree* body() { return body_; }

 private:
  RegExpTree* body_;
  int min_;
  int max_;
  int min_match_;
  int max_match_;
  QuantifierType quantifier_type_;
};


class RegExpCapture FINAL : public RegExpTree {
 public:
  explicit RegExpCapture(RegExpTree* body, int index)
      : body_(body), index_(index) { }
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  static RegExpNode* ToNode(RegExpTree* body,
                            int index,
                            RegExpCompiler* compiler,
                            RegExpNode* on_success);
  virtual RegExpCapture* AsCapture() OVERRIDE;
  virtual bool IsAnchoredAtStart() OVERRIDE;
  virtual bool IsAnchoredAtEnd() OVERRIDE;
  virtual Interval CaptureRegisters() OVERRIDE;
  virtual bool IsCapture() OVERRIDE;
  virtual int min_match() OVERRIDE { return body_->min_match(); }
  virtual int max_match() OVERRIDE { return body_->max_match(); }
  RegExpTree* body() { return body_; }
  int index() { return index_; }
  static int StartRegister(int index) { return index * 2; }
  static int EndRegister(int index) { return index * 2 + 1; }

 private:
  RegExpTree* body_;
  int index_;
};


class RegExpLookahead FINAL : public RegExpTree {
 public:
  RegExpLookahead(RegExpTree* body,
                  bool is_positive,
                  int capture_count,
                  int capture_from)
      : body_(body),
        is_positive_(is_positive),
        capture_count_(capture_count),
        capture_from_(capture_from) { }

  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  virtual RegExpLookahead* AsLookahead() OVERRIDE;
  virtual Interval CaptureRegisters() OVERRIDE;
  virtual bool IsLookahead() OVERRIDE;
  virtual bool IsAnchoredAtStart() OVERRIDE;
  virtual int min_match() OVERRIDE { return 0; }
  virtual int max_match() OVERRIDE { return 0; }
  RegExpTree* body() { return body_; }
  bool is_positive() { return is_positive_; }
  int capture_count() { return capture_count_; }
  int capture_from() { return capture_from_; }

 private:
  RegExpTree* body_;
  bool is_positive_;
  int capture_count_;
  int capture_from_;
};


class RegExpBackReference FINAL : public RegExpTree {
 public:
  explicit RegExpBackReference(RegExpCapture* capture)
      : capture_(capture) { }
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  virtual RegExpBackReference* AsBackReference() OVERRIDE;
  virtual bool IsBackReference() OVERRIDE;
  virtual int min_match() OVERRIDE { return 0; }
  virtual int max_match() OVERRIDE { return capture_->max_match(); }
  int index() { return capture_->index(); }
  RegExpCapture* capture() { return capture_; }
 private:
  RegExpCapture* capture_;
};


class RegExpEmpty FINAL : public RegExpTree {
 public:
  RegExpEmpty() { }
  virtual void* Accept(RegExpVisitor* visitor, void* data) OVERRIDE;
  virtual RegExpNode* ToNode(RegExpCompiler* compiler,
                             RegExpNode* on_success) OVERRIDE;
  virtual RegExpEmpty* AsEmpty() OVERRIDE;
  virtual bool IsEmpty() OVERRIDE;
  virtual int min_match() OVERRIDE { return 0; }
  virtual int max_match() OVERRIDE { return 0; }
  static RegExpEmpty* GetInstance() {
    static RegExpEmpty* instance = ::new RegExpEmpty();
    return instance;
  }
};

// SNIP

}  // namespace dart

#endif  // VM_REGEXP_AST_H_
