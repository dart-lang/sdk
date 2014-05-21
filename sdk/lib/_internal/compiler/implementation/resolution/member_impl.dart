// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution.compute_members;

class DeclaredMember implements Member {
  final Name name;
  final Element element;
  final InterfaceType declarer;
  final DartType type;
  final FunctionType functionType;

  DeclaredMember(this.name, this.element,
                 this.declarer,
                 this.type, this.functionType);

  bool get isStatic => !element.isInstanceMember;

  bool get isGetter => element.isGetter || (!isSetter && element.isField);

  bool get isSetter => name.isSetter;

  bool get isMethod => element.isFunction;

  bool get isDeclaredByField => element.isField;

  bool get isAbstract => false;

  Member get implementation => this;

  /// Returns this member as inherited from [instance].
  ///
  /// For instance:
  ///   class A<T> { T m() {} }
  ///   class B<S> extends A<S> {}
  ///   class C<U> extends B<U> {}
  /// The member `T m()` is declared in `A<T>` and inherited from `A<S>` into
  /// `B` as `S m()`, and further from `B<U>` into `C` as `U m()`.
  DeclaredMember inheritFrom(InterfaceType instance) {
    // If the member is declared in a non-generic class its type cannot change
    // as a result of inheritance.
    if (!declarer.isGeneric) return this;
    assert(declarer.element == instance.element);
    return _newInheritedMember(instance);
  }

  InheritedMember _newInheritedMember(InterfaceType instance) {
    return new InheritedMember(this, instance);
  }

  Iterable<Member> get declarations => <Member>[this];

  int get hashCode => element.hashCode + 13 * isSetter.hashCode;

  bool operator ==(other) {
    if (other is! Member) return false;
    return element == other.element &&
           isSetter == other.isSetter;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    printOn(sb, type);
    return sb.toString();
  }

  void printOn(StringBuffer sb, DartType type) {
    if (isStatic) {
      sb.write('static ');
    }
    if (isAbstract) {
      sb.write('abstract ');
    }
    if (isGetter) {
      sb.write(type);
      sb.write(' get ');
      sb.write(name);
    } else if (isSetter) {
      sb.write('void set ');
      sb.write(name.getter);
      sb.write('(');
      sb.write(type);
      sb.write(' _)');
    } else {
      sb.write(type.getStringAsDeclared('$name'));
    }
  }
}

class DeclaredAbstractMember extends DeclaredMember {
  final DeclaredMember implementation;

  DeclaredAbstractMember(Name name, Element element,
                         InterfaceType declarer,
                         DartType type, FunctionType functionType,
                         this.implementation)
      : super(name, element, declarer, type, functionType);

  bool get isAbstract => true;

  InheritedMember _newInheritedMember(InterfaceType instance) {
    return new InheritedAbstractMember(this, instance,
        implementation != null ? implementation.inheritFrom(instance) : null);
  }
}

class InheritedMember implements DeclaredMember {
  final DeclaredMember declaration;
  final InterfaceType instance;

  InheritedMember(DeclaredMember this.declaration,
                  InterfaceType this.instance) {
    assert(instance.isGeneric);
    assert(!declaration.isStatic);
  }

  Element get element => declaration.element;

  Name get name => declaration.name;

  InterfaceType get declarer => instance;

  bool get isStatic => false;

  bool get isSetter => declaration.isSetter;

  bool get isGetter => declaration.isGetter;

  bool get isMethod => declaration.isMethod;

  bool get isDeclaredByField => declaration.isDeclaredByField;

  bool get isAbstract => false;

  Member get implementation => this;

  DartType get type => declaration.type.substByContext(instance);

  FunctionType get functionType {
    return declaration.functionType.substByContext(instance);
  }

  DeclaredMember inheritFrom(InterfaceType newInstance) {
    assert(() {
      // Assert that if [instance] contains type variables, then these are
      // defined in the declaration of [newInstance] and will therefore be
      // substituted into the context of [newInstance] in the created member.
      ClassElement contextClass = Types.getClassContext(instance);
      return contextClass == null || contextClass == newInstance.element;
    });
    return _newInheritedMember(newInstance);
  }

  InheritedMember _newInheritedMember(InterfaceType newInstance) {
    return new InheritedMember(declaration,
                               instance.substByContext(newInstance));
  }

  Iterable<Member> get declarations => <Member>[this];

  int get hashCode => declaration.hashCode + 17 * instance.hashCode;

  bool operator ==(other) {
    if (other is! InheritedMember) return false;
    return declaration == other.declaration &&
           instance == other.instance;
  }

  void printOn(StringBuffer sb, DartType type) {
    declaration.printOn(sb, type);
    sb.write(' inherited from $instance');
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    printOn(sb, instance);
    return sb.toString();
  }
}

class InheritedAbstractMember extends InheritedMember {
  final DeclaredMember implementation;

  InheritedAbstractMember(DeclaredMember declaration,
                          InterfaceType instance,
                          this.implementation)
      : super(declaration, instance);

  bool get isAbstract => true;

  InheritedMember _newInheritedMember(InterfaceType newInstance) {
    return new InheritedAbstractMember(
        declaration,
        instance.substByContext(newInstance),
        implementation != null
            ? implementation.inheritFrom(newInstance) : null);
  }
}


abstract class AbstractSyntheticMember implements MemberSignature {
  final Setlet<Member> inheritedMembers;

  AbstractSyntheticMember(this.inheritedMembers);

  Member get member => inheritedMembers.first;

  Iterable<Member> get declarations => inheritedMembers;

  Name get name => member.name;
}


class SyntheticMember extends AbstractSyntheticMember {
  final DartType type;
  final FunctionType functionType;

  SyntheticMember(Setlet<Member> inheritedMembers,
                  this.type,
                  this.functionType)
      : super(inheritedMembers);

  bool get isSetter => member.isSetter;

  bool get isGetter => member.isGetter;

  bool get isMethod => member.isMethod;

  bool get isErroneous => false;

  String toString() => '${type.getStringAsDeclared('$name')} synthesized '
                       'from ${inheritedMembers}';
}

class ErroneousMember extends AbstractSyntheticMember {
  ErroneousMember(Setlet<Member> inheritedMembers) : super(inheritedMembers);

  DartType get type => functionType;

  FunctionType get functionType {
    throw new UnsupportedError('Erroneous members have no type.');
  }

  bool get isSetter => false;

  bool get isGetter => false;

  bool get isMethod => false;

  bool get isErroneous => true;

  String toString() => "erroneous member '$name' synthesized "
                       "from ${inheritedMembers}";
}

