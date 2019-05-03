# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

GRAMMAR=../../docs/language/Dart.g
JAVA_PATH=/usr/lib/jvm/java-7-openjdk-amd64/bin
JAVA=$(JAVA_PATH)/java
JAVAC=javac
ANTLR_JAR=/usr/share/java/antlr4-runtime.jar
ANTLR_FILES=DartLexer.java DartParser.java DartLexer.tokens
ANTLR_CMD=PATH=$(JAVA_PATH):$(PATH) antlr4 $<
GENERATED_JAVA_FILES=DartLexer.java DartParser.java

.PHONY: default parser clean touch parse_hello

default: $(GENERATED_JAVA_FILES) compile

compile: SpecParser.class

SpecParser.class: $(ANTLR_FILES) SpecParser.java
	$(JAVAC) -cp .:$(ANTLR_JAR) SpecParser.java

%Lexer.java: %.g Makefile ; $(ANTLR_CMD)

%Parser.java: %.g Makefile ; $(ANTLR_CMD)

%.tokens: %.g Makefile ; $(ANTLR_CMD)

clean:
	rm -f *.class $(ANTLR_FILES)

touch:
	touch $(GRAMMAR)
