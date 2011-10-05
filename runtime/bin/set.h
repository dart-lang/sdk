// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_SET_H_
#define BIN_SET_H_

#include <stdlib.h>

/*
 * Set implements a collection of distinct objects.
 */
template <class T>
class Set {
 private:
  struct Node {
    T object_;
    Node* next_;
  };

 public:
  class Iterator {
   public:
    explicit Iterator(Set<T>* list) : list_(list) {
      if (list != NULL) {
        next_ = list->head_;
      } else {
        next_ = NULL;
      }
    }

    bool HasNext() const {
      return next_ != NULL;
    }

    void GetNext(T* entry) {
      *entry = next_->object_;
      next_ = next_->next_;
    }

   private:
    const Set<T>* list_;
    struct Node* next_;
  };

  Set() {
    head_ = NULL;
    tail_ = NULL;
    size_ = 0;
  }

  ~Set() {}

  bool Add(const T& element) {
    Node* new_node = new Node;
    new_node->object_ = element;
    new_node->next_ = NULL;

    if (Contains(element)) {
      return false;
    }

    if (IsEmpty()) {
      head_ = new_node;
      tail_ = new_node;
    } else {
      tail_->next_ = new_node;
      tail_ = new_node;
    }
    size_++;
    return true;
  }

  T* Remove(const T& element) {
    Node* current = head_;
    Node* previous = NULL;
    if (IsEmpty()) {
      return NULL;
    }

    do {
      if (element == current->object_) {
        if (current == head_) {
          head_ = head_->next_;
        }
        if (current == tail_) {
          tail_ = previous;
        }
        if (previous != NULL) {
          previous->next_ = current->next_;
        }
        size_--;
        return &current->object_;
      }
      previous = current;
      current = current->next_;
    } while (current);
    return NULL;
  }

  bool Contains(const T& element) {
    T value;
    Iterator iterator(this);
    while (iterator.HasNext()) {
      iterator.GetNext(&value);
      if (value == element) {
        return true;
      }
    }
    return false;
  }

  bool IsEmpty() {
    return head_ == NULL;
  }

  int Size() {
    return size_;
  }

 private:
  Node* head_;
  Node* tail_;
  int size_;
};

#endif  // BIN_SET_H_

