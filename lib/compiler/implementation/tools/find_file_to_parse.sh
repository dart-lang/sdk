#!/bin/bash

find .. \( \
    -name README.dart \
    -o -name Examples_A03_t01.dart \
    -o -name Examples_A03_t02.dart \
    -o -name Examples_A07_t01.dart \
    -o -name 13_3_1_Typedef_A01_t02.dart \
    -o -name 13_3_1_Typedef_A01_t03.dart \
    -o -name 13_3_1_Typedef_A01_t04.dart \
    -o -name 13_3_1_Typedef_A01_t06.dart \
    -o -name 13_3_1_Typedef_A05_t01.dart \
    -o -name 13_3_1_Typedef_A05_t02.dart \
    -o -name 13_3_1_Typedef_A05_t03.dart \
    -o -name 13_3_1_Typedef_A06_t01.dart \
    -o -name 13_3_1_Typedef_A06_t03.dart \
    -o -name 13_3_1_Typedef_A06_t04.dart \
    -o -name 13_7_Type_Void_A01_t06.dart \
    -o -name 13_7_Type_Void_A01_t07.dart \
    -o -name 02_1_Class_A02_t02.dart \
    -o -name 'Map_operator\[\]_A01_t03.dart' \
    -o -name 'Map_operator\[\]=_A01_t03.dart' \
    -o -name int_operator_mul_A01_t01.dart \
    -o -name Isolate_A01_t01.dart \
    -o -name Isolate_A02_t01.dart \
    -o -name IsNotClass4NegativeTest.dart \
    -o -name NamedParameters9NegativeTest.dart \
    -o -name ClassKeywordTest.dart \
    -o -name Prefix19NegativeTest.dart \
    -o -name Operator2NegativeTest.dart \
    -o -name 02_1_Class_Construction_A16_t02.dart \
    -o -name 02_1_Class_Construction_A19_t01.dart \
    -o -name 02_2_Interface_A02_t02.dart \
    -o -name 13_4_Interface_Types_A04_t01.dart \
    -o -name 13_4_Interface_Types_A04_t02.dart \
    -o -name MapLiteral2Test.dart \
    -o -name Switch1NegativeTest.dart \
    -o \( -type d -name xcodebuild \) \
    -o \( -type d -name out \) \
    -o \( -type d -name await \) \
    \) -prune -o \
    -name \*.dart -type f -print \
    | grep -v /editor/tools/plugins/com.google.dart.tools.core_test/src/com/google/dart/tools/core/internal/model/testsource/ClassTest.dart \
    | grep -v /editor/tools/plugins/com.google.dart.tools.core_test/src/com/google/dart/tools/core/internal/model/testsource/FunctionTest.dart \
    | grep -v /compiler/javatests/com/google/dart/compiler/parser/StringsErrorsNegativeTest.dart \
    | grep -v /compiler/javatests/com/google/dart/compiler/resolver/ClassImplementsUnknownInterfaceNegativeTest.dart \
    | grep -v /tests/language/src/InterfaceFunctionTypeAlias1NegativeTest.dart \
    | grep -v /tests/language/src/InterfaceFunctionTypeAlias2NegativeTest.dart \
    | grep -v /tests/language/src/InterfaceInjection1NegativeTest.dart \
    | grep -v /tests/language/src/InterfaceFunctionTypeAlias3NegativeTest.dart \
    | grep -v /tests/language/src/InterfaceInjection2NegativeTest.dart \
    | grep -v /tests/language/src/NewExpression2NegativeTest.dart \
    | grep -v /tests/language/src/NewExpression3NegativeTest.dart \
    | grep -v /tests/language/src/TestNegativeTest.dart \
    | grep -v /editor/tools/plugins/com.google.dart.tools.core_test/src/com/google/dart/tools/core/internal/model/testsource/BadErrorMessages.dart \
    | grep -v /editor/tools/plugins/com.google.dart.tools.core_test/src/com/google/dart/tools/core/internal/model/testsource/CoreRuntimeTypesTest.dart \
    | grep -v /editor/tools/plugins/com.google.dart.tools.core_test/src/com/google/dart/tools/core/internal/model/testsource/NamingTest.dart \
    | grep -v /editor/tools/plugins/com.google.dart.tools.core_test/src/com/google/dart/tools/core/internal/model/testsource/SpreadArgumentTest.dart \
    | grep -v /tests/language/src/IsNotClass1NegativeTest.dart \
    | grep -v /tests/language/src/Label8NegativeTest.dart \
    | grep -v /frog/tests/await/ \
    | grep -v /tests/language/src/ListLiteralNegativeTest.dart \
    | grep -v /tests/language/src/MapLiteralNegativeTest.dart \
    | grep -v /tests/language/src/TryCatch2NegativeTest.dart \
    | grep -v /tests/language/src/NewExpression1NegativeTest.dart \
    | grep -v /tests/language/src/TryCatch4NegativeTest.dart \
    | grep -v /tests/language/src/ParameterInitializer3NegativeTest.dart \
    | grep -v /compiler/javatests/com/google/dart/compiler/parser/FactoryInitializersNegativeTest.dart \
    | grep -v /frog/tests/leg_only/src/TypedLocalsTest.dart \
    | grep -v '/editor/tools/plugins/com.google.dart.tools.core_test/src/com/google/dart/tools/core/formatter/testsource/test006$A_in.dart' \
    | grep -v '/editor/tools/plugins/com.google.dart.tools.core_test/src/com/google/dart/tools/core/formatter/testsource/test006$A_out.dart' \
    | grep -v '/utils/dartdoc/dartdoc.dart' \
    | xargs grep -L -E 'native|@compile-error|@needsreview'
