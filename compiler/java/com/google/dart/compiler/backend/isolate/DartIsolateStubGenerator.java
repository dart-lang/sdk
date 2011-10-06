// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.isolate;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintStream;
import java.util.Collection;
import java.util.List;
import java.util.Set;

import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartContext;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartVisitor;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.backend.common.AbstractBackend;
import com.google.dart.compiler.resolver.CoreTypeProvider;

/**
 * Generate code for proxies and dispatchers for cross-isolate calls.
 */
public class DartIsolateStubGenerator extends AbstractBackend {
  private final Set<String> stubInterfaces;
  private PrintStream outStream;

  public DartIsolateStubGenerator(final Set<String> classes, String out)
      throws FileNotFoundException {
    outStream = new PrintStream(out);
    stubInterfaces = classes;
  }

  private void autoGenerate(DartUnit unit) {
    if (stubInterfaces.isEmpty()) {
      return;
    }

    DartVisitor visitor = new DartVisitor() {
      private boolean first = true;

      @Override
      public boolean visit(DartClass clazz, DartContext ctx) {
        if (clazz.isInterface() && stubInterfaces.contains(clazz.getClassName())) {
          if (!first)
            nl();
          first = false;
          p("/* class = " + clazz.getClassName() + " ("
            + clazz.getSource().getName() + ": " + clazz.getSourceLine() + ") */");
          nl();
          nl();
          generateProxyClass(clazz);
          nl();
          generateDispatchClass(clazz);
          nl();
          generateIsolateClass(clazz);
        }
        return false;
      }

    };
    visitor.accept(unit);
    outStream.flush();
  }

  private static boolean isConstructor(DartMethodDefinition x) {
    return x.getSymbol().isConstructor();
  }

  private static boolean isSimpleType(DartTypeNode x) {
    if (!x.getTypeArguments().isEmpty())
      return false;
    if (!(x.getIdentifier() instanceof DartIdentifier))
      return false;
    String name = ((DartIdentifier)x.getIdentifier()).getTargetName();
    if (name.equals("int") || name.equals("void"))
      return true;
    return false;
  }

  private static boolean isVoid(DartTypeNode x) {
    if (!isSimpleType(x))
      return false;
    return ((DartIdentifier)x.getIdentifier()).getTargetName().equals("void");
  }

  private static boolean isProxyType(DartTypeNode x) {
    if (!x.getTypeArguments().isEmpty())
      return false;
    if (!(x.getIdentifier() instanceof DartIdentifier))
      return false;
    return ((DartIdentifier)x.getIdentifier()).getTargetName().endsWith("$Proxy");
  }

  private void p(String str) {
    outStream.print(str);
  }

  private void nl() {
    outStream.println();
  }

  class ProxifyingVisitor extends DartVisitor {
    @Override
    public boolean visit(DartTypeNode x, DartContext ctx) {
      accept(x.getIdentifier());
      printTypeArguments(x);
      if (!isSimpleType(x))
        p("$Proxy");
      return false;
    }

    @Override
    public boolean visit(DartIdentifier x, DartContext ctx) {
      p(x.getTargetName());
      return false;
    }
  }

  private void printTypeArguments(DartTypeNode x) {
    List<DartTypeNode> arguments = x.getTypeArguments();
    if (arguments != null && !arguments.isEmpty()) {
      p("<");
      printParams(arguments);
      p(">");
    }
  }

  private void printParams(List<? extends DartNode> nodes) {
    boolean first = true;
    for (DartNode node : nodes) {
      if (!first) {
        p(", ");
      }
      DartVisitor param = new DartVisitor() {
        @Override
         public boolean visit(DartParameter x, DartContext ctx) {
          if (x.getModifiers().isFinal()) {
            p("final ");
          }
          if (x.getTypeNode() != null) {
            accept(x.getTypeNode());
            p(" ");
          }
          accept(x.getName());
          if (x.getFunctionParameters() != null) {
            p("(");
            printParams(x.getFunctionParameters());
            p(")");
          }
          if (x.getDefaultExpr() != null) {
            p(" = ");
            accept(x.getDefaultExpr());
          }
          return false;
        }
        @Override
        public boolean visit(DartTypeNode x, DartContext ctx) {
          accept(x.getIdentifier());
          printTypeArguments(x);
          return false;
        }
        @Override
        public boolean visit(DartIdentifier x, DartContext ctx) {
          p(x.getTargetName());
          return false;
        }
      };
      param.accept(node);
      first = false;
    }
  }

  private void printProxyInterfaceFunctions(DartClass clazz) {
    DartVisitor visitor = new DartVisitor() {
      @Override
      public boolean visit(DartMethodDefinition x, DartContext ctx) {
        if (isConstructor(x)) {
          return false;
        }
        nl();
        final DartFunction func = x.getFunction();
        final DartTypeNode returnTypeNode = func.getReturnTypeNode();
        final boolean isVoid = isVoid(returnTypeNode);
        final boolean isSimple = isSimpleType(returnTypeNode);
        final boolean isProxy = isProxyType(returnTypeNode);
        p("  ");
        if (!isVoid && isSimple) {
          p("Promise<");
        }
        accept(returnTypeNode);
        if (!isVoid) {
          if (isSimple) {
            p(">");
          } else if (!isProxy) {
            p("$Proxy");
          }
        }
        p(" ");
        accept(x.getName());
        p("(");
        printParams(func.getParams());
        p(");");
        nl();

        return false;
      }

      @Override
      public boolean visit(DartTypeNode x, DartContext ctx) {
        accept(x.getIdentifier());
        printTypeArguments(x);
        return false;
      }

      @Override
      public boolean visit(DartIdentifier x, DartContext ctx) {
        p(x.getTargetName());
        return false;
      }

    };
    visitor.acceptList(clazz.getMembers());
  }

  /**
   * Produce something looking like:
   *
   *
   * interface Purse$Proxy {
   *   void init(Mint$Proxy mint, int balance);
   *
   *   Promise<int> queryBalance();
   *
   *   Purse$Proxy sproutPurse();
   *
   *   void deposit(int amount, Purse$Proxy source);
   * }
   *
   * class Purse$ProxyImpl extends Proxy implements Purse$Proxy {
   *   Purse$ProxyImpl(Promise<SendPort> port) : super.forReply(port) { }
   *   Purse$ProxyImpl.forIsolate(Proxy isolate) : super.forReply(isolate.call([null])) { }
   *   factory Purse$ProxyImpl.createIsolate() {
   *     Proxy isolate = new Proxy.forIsolate(new Purse$Dispatcher$Isolate());
   *     return new Purse$ProxyImpl.forIsolate(isolate);
   *   }
   *   factory Purse$ProxyImpl.localProxy(Purse obj) {
   *     return new Purse$ProxyImpl(new Promise<SendPort>.fromValue(Dispatcher.serve(
   *         new Purse$Dispatcher(obj))));
   *   }
   *
   *   void init(Mint$Proxy mint, int balance) {
   *     this.send(["init", mint, balance]);
   *   }
   *
   *   Promise<int> queryBalance() {
   *     return this.call(["queryBalance"]);
   *   }
   *
   *   Purse$Proxy sproutPurse() {
   *     return new Purse$ProxyImpl(this.call(["sproutPurse"]));
   *   }
   *
   *   void deposit(int amount, Purse$Proxy source) {
   *     this.send(["deposit", amount, source]);
   *   }
   * }
   */
  private void generateProxyClass(DartClass clazz) {
    String name = clazz.getClassName();
    p("interface " + name + "$Proxy {");
    printProxyInterfaceFunctions(clazz);
    p("}");
    nl();
    nl();

    p("class " + name + "$ProxyImpl extends Proxy implements " + name + "$Proxy {");
    nl();
    p("  " + name + "$ProxyImpl(Promise<SendPort> port) : super.forReply(port) { }");
    nl();
    p("  " + name
      + "$ProxyImpl.forIsolate(Proxy isolate) : super.forReply(isolate.call([null])) { }");
    nl();

    p("  factory " + name + "$ProxyImpl.createIsolate() {");
    nl();
    p("    Proxy isolate = new Proxy.forIsolate(new " + name + "$Dispatcher$Isolate());");
    nl();
    p("    return new " + name + "$ProxyImpl.forIsolate(isolate);");
    nl();
    p("  }");
    nl();

    // FIXME(benl, kasperl): We should be able to get hold of our existing dispatcher, not have to
    // create a new one...
    p("  factory " + name + "$ProxyImpl.localProxy(" + name + " obj) {");
    nl();
    p("    return new " + name + "$ProxyImpl(new Promise<SendPort>.fromValue(Dispatcher.serve(new "
      + name + "$Dispatcher(obj))));");
    nl();
    p("  }");
    nl();

    DartVisitor visitor = new DartVisitor() {
      @Override
      public boolean visit(DartMethodDefinition x, DartContext ctx) {
        if (isConstructor(x)) {
          return false;
        }
        nl();
        final DartFunction func = x.getFunction();
        final DartTypeNode returnTypeNode = func.getReturnTypeNode();
        final boolean isVoid = isVoid(returnTypeNode);
        final boolean isSimple = isSimpleType(returnTypeNode);
        final boolean isProxy = isProxyType(returnTypeNode);
        p("  ");
        if (!isVoid && isSimple) {
          p("Promise<");
        }
        accept(returnTypeNode);
        if (!isVoid) {
          if (isSimple) {
            p(">");
          } else if (!isProxy) {
            p("$Proxy");
          }
        }
        p(" ");
        accept(x.getName());
        p("(");
        printParams(func.getParams());
        p(") {");
        nl();
        p("    ");
        if (!isVoid) {
          p("return ");
          if (!isSimple) {
            p("new ");
            accept(returnTypeNode);
            if (!isProxy) {
              p("$Proxy");
            }
            p("Impl(");
          }
        }
        p("this.");
        if (isVoid) {
          p("send");
        } else {
          p("call");
        }
        p("([\"");
        accept(x.getName());
        p("\"");
        DartVisitor params = new DartVisitor() {
          @Override
          public boolean visit(DartIdentifier x, DartContext ctx) {
            p(", ");
            p(x.getTargetName());
            return false;
          }

          @Override
          public boolean visit(DartParameter x, DartContext ctx) {
            accept(x.getName());
            return false;
          }
        };
        params.acceptList(func.getParams());
        p("])");
        if (!isSimple) {
          p(")");
        }
        p(";");
        nl();

        p("  }");
        nl();

        return false;
      }

      @Override
      public boolean visit(DartTypeNode x, DartContext ctx) {
        accept(x.getIdentifier());
        printTypeArguments(x);
        return false;
      }

      @Override
      public boolean visit(DartIdentifier x, DartContext ctx) {
        p(x.getTargetName());
        return false;
      }

    };
    visitor.acceptList(clazz.getMembers());
    p("}");
    nl();
  }

  private void printSelector(List<DartNode> members) {
    boolean first = true;
    for (DartNode member : members) {
      if (first) {
        p("    ");
      } else {
        p(" else ");
      }
      p("if (command == \"");
      printFunctionName(member);
      p("\") {");
      nl();
      unpackParams(member);
      callTarget((DartMethodDefinition)member);
      p("    }");
      first = false;
    }
    p(" else {");
    nl();
    p("      // TODO(kasperl,benl): Somehow throw an exception instead.");
    nl();
    p("      reply(\"Exception: command not understood.\");");
    nl();
    p("    }");
    nl();
  }

  private void callTarget(DartMethodDefinition member) {
    if (isConstructor(member)) {
      return;
    }
    p("      ");
    boolean isVoid = isVoid(member.getFunction().getReturnTypeNode());
    if (!isVoid) {
      printReturnType(member);
      p(" ");
      printFunctionName(member);
      p(" = ");
    }
    p("target.");
    printFunctionName(member);
    p("(");
    printParamNames(member);
    p(");");
    nl();
    String returnType = stringReturnType(member);
    if (stubInterfaces.contains(returnType)) {
      p("      SendPort port = Dispatcher.serve(new " + returnType + "$Dispatcher(");
      printFunctionName(member);
      p("));");
      nl();
      p("      reply(port);");
      nl();
    } else if (!isVoid) {
      p("      reply(");
      printFunctionName(member);
      p(");");
      nl();
    }
  }

  private static String stringReturnType(DartMethodDefinition member) {
    return stringType(member.getFunction().getReturnTypeNode());
  }

  private void printParamNames(DartMethodDefinition member) {
    boolean first = true;
    for(DartParameter param : member.getFunction().getParams()) {
      if (!first) {
        p(", ");
      }
      printName(param.getName());
      first = false;
    }
  }

  private void printName(DartExpression name) {
    DartVisitor visitor = new DartVisitor() {
      @Override
      public boolean visit(DartIdentifier x, DartContext ctx) {
        p(x.getTargetName());
        return false;
      }
    };
    visitor.accept(name);
  }

  private void printReturnType(DartMethodDefinition member) {
    printType(member.getFunction().getReturnTypeNode());
  }

  private void printType(DartTypeNode type) {
    DartVisitor visitor = new DartVisitor() {
      @Override
      public boolean visit(DartIdentifier x, DartContext ctx) {
        p(x.getTargetName());
        return false;
      }

      @Override
      public boolean visit(DartTypeNode x, DartContext ctx) {
        accept(x.getIdentifier());
        printTypeArguments(x);
        return false;
      }
    };
    visitor.accept(type);
  }

  private static String stringType(DartTypeNode type) {
    final StringBuilder strType = new StringBuilder();
    DartVisitor visitor = new DartVisitor() {
      @Override
      public boolean visit(DartIdentifier x, DartContext ctx) {
        strType.append(x.getTargetName());
        return false;
      }

      @Override
      public boolean visit(DartTypeNode x, DartContext ctx) {
        accept(x.getIdentifier());
        List<DartTypeNode> arguments = x.getTypeArguments();
        if (arguments != null && !arguments.isEmpty()) {
          strType.append("<");
          // Really we should do
          // strType.append(stringParams(arguments));
          // but for now, this will suffice
          strType.append("...");
          strType.append(">");
        }
        return false;
      }
    };
    visitor.accept(type);
    return strType.toString();
  }

  private void unpackParams(DartNode member) {
    DartVisitor visitor = new DartVisitor() {
      private int pos;

      @Override
      public boolean visit(DartTypeNode x, DartContext ctx) {
        accept(x.getIdentifier());
        printTypeArguments(x);
        return false;
      }

      @Override
      public boolean visit(DartIdentifier x, DartContext ctx) {
        p(x.getTargetName());
        return false;
      }

      @Override
      public boolean visit(DartMethodDefinition x, DartContext ctx) {
        pos = 1;
        for (DartParameter param : x.getFunction().getParams()) {
          p("      ");
          accept(param);
          nl();
          ++pos;
        }
        return false;
      }

      @Override
      public boolean visit(DartParameter x, DartContext ctx) {
        boolean isSimpleType = isSimpleType(x.getTypeNode());

        accept(x.getTypeNode());
        p(" ");
        accept(x.getName());
        p(" = ");
        if (!isSimpleType) {
          p("new ");
          accept(x.getTypeNode());
          p("Impl(new Promise<SendPort>.fromValue(");
        }
        p("message[" + pos + "]");
        if (!isSimpleType) {
          p("))");
        }
        p(";");
        return false;
      }
    };
    visitor.accept(member);
  }

  private void printFunctionName(DartNode member) {
    DartVisitor functionName = new DartVisitor() {
      @Override
      public boolean visit(DartMethodDefinition x, DartContext ctx) {
        accept(x.getName());
        return false;
      }

      @Override
      public boolean visit(DartIdentifier x, DartContext ctx) {
        p(x.getTargetName());
        return false;
      }
    };
    functionName.accept(member);
  }

  /**
   * Generate a dispatcher, looking like:
   *
   * class Purse$Dispatcher extends Dispatcher<Purse> {
   *   Purse$Dispatcher(Purse thing) : super(thing) { }
   *
   *   void process(var message, void reply(var response)) {
   *     String command = message[0];
   *     if (command == "queryBalance") {
   *       int queryBalance = target.queryBalance();
   *       reply(queryBalance);
   *     } else if (command == "sproutPurse") {
   *       Purse sproutPurse = target.sproutPurse();
   *       SendPort port = Dispatcher.serve(new Purse$Dispatcher(sproutPurse));
   *       reply(port);
   *     } else if (command == "deposit") {
   *       int amount = message[1];
   *       Proxy<Purse> source = new Proxy<Purse>.forPort(message[2]);
   *       target.deposit(amount, source);
   *     } else {
   *       // TODO(kasperl,benl): Somehow throw an exception instead.
   *       reply("Exception: command not understood.");
   *     }
   *   }
   * }
   */
  private void generateDispatchClass(DartClass clazz) {
    String name = clazz.getClassName();
    p("class " + name + "$Dispatcher extends Dispatcher<" + name + "> {");
    nl();
    p("  " + name + "$Dispatcher(" + name + " thing) : super(thing) { }");
    nl();
    nl();
    p("  void process(var message, void reply(var response)) {");
    nl();
    p("    String command = message[0];");
    nl();
    printSelector(clazz.getMembers());
    p("  }");
    nl();
    p("}");
    nl();
  }

  /**
   * Generate a dispatcher isolate, looking like:
   *
   * class Purse$Dispatcher extends Dispatcher<Purse> {
   *   Purse$Dispatcher(Purse thing) : super(thing) { }
   * 
   *   void process(var message, void reply(var response)) {
   *     String command = message[0];
   *     if (command == "Purse") {
   *     } else if (command == "init") {
   *       Mint$Proxy mint = new Mint$ProxyImpl(new Promise<SendPort>.fromValue(message[1]));
   *       int balance = message[2];
   *       target.init(mint, balance);
   *     } else if (command == "queryBalance") {
   *       int queryBalance = target.queryBalance();
   *       reply(queryBalance);
   *     } else if (command == "sproutPurse") {
   *       Purse sproutPurse = target.sproutPurse();
   *       SendPort port = Dispatcher.serve(new Purse$Dispatcher(sproutPurse));
   *       reply(port);
   *     } else if (command == "deposit") {
   *       int amount = message[1];
   *       Purse$Proxy source = new Purse$ProxyImpl(new Promise<SendPort>.fromValue(message[2]));
   *       target.deposit(amount, source);
   *     } else {
   *       // TODO(kasperl,benl): Somehow throw an exception instead.
   *       reply("Exception: command not understood.");
   *     }
   *   }
   * }
   */
  private void generateIsolateClass(DartClass clazz) {
    String name = clazz.getClassName();
    p("class " + name + "$Dispatcher$Isolate extends Isolate {");
    nl();
    p("  " + name + "$Dispatcher$Isolate() : super() { }");
    nl();
    nl();
    p("  void main() {");
    nl();
    p("    this.port.receive(void _(var message, SendPort replyTo) {");
    nl();
    p("      " + name + " thing = new " + name + "();");
    nl();
    p("      SendPort port = Dispatcher.serve(new " + name + "$Dispatcher(thing));");
    nl();
    p("      Proxy proxy = new Proxy.forPort(replyTo);");
    nl();
    p("      proxy.send([port]);");
    nl();
    p("    });");
    nl();
    p("  }");
    nl();
    p("}");
    nl();
  }

  @Override
  public boolean isOutOfDate(DartSource src, DartCompilerContext context) {
    return true;
  }

  @Override
  public void compileUnit(DartUnit unit, DartSource src, DartCompilerContext context,
                          CoreTypeProvider typeProvider) throws IOException {
    autoGenerate(unit);
  }

  @Override
  public void packageApp(LibrarySource app, Collection<LibraryUnit> libraries,
                         DartCompilerContext context, CoreTypeProvider typeProvider)
                             throws IOException {
    // TODO Auto-generated method stub
  }

  @Override
  public String getAppExtension() {
    // TODO Auto-generated method stub
    return null;
  }

  @Override
  public String getSourceMapExtension() {
    // TODO Auto-generated method stub
    return null;
  }
}
