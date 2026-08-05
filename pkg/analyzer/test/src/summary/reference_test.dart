// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReferenceTest);
  });
}

@reflectiveTest
class ReferenceTest {
  void test_builtIn_dartCore() {
    var root = RootReference();
    var library = root.getOrCreateLibrary(Uri.parse('dart:core'));

    var dynamic0 = library.dynamicRef;
    var dynamic1 = library.dynamicRef;
    var never_ = library.neverRef;

    expect(dynamic1, same(dynamic0));
    expect(dynamic0.library, same(library));
    expect(dynamic0.enclosingReference, same(library));
    expect(dynamic0.debugString(), 'dart:core::dynamic');

    expect(never_.library, same(library));
    expect(never_.debugString(), 'dart:core::Never');
    expect(library.children, [dynamic0, never_]);
  }

  void test_debugString() {
    var root = RootReference();
    var library = root.getOrCreateLibrary(Uri.parse('package:test/a.dart'));
    var classReference = library.declareClass('A');
    var methodReference = classReference.declareMethod('foo');

    expect(root.debugString(), 'root');
    expect(library.debugString(), 'package:test/a.dart');
    expect(classReference.debugString(), 'package:test/a.dart::@class::A');
    expect(
      methodReference.debugString(),
      'package:test/a.dart::@class::A::@method::foo',
    );
    expect(
      methodReference.debugString(formatLibraryUri: (_) => '<library>'),
      '<library>::@class::A::@method::foo',
    );
    expect(
      methodReference.toString(),
      'package:test/a.dart::@class::A::@method::foo',
    );
  }

  void test_declare_duplicateKey() {
    var root = RootReference();
    var library = root.getOrCreateLibrary(Uri.parse('package:test/a.dart'));

    library.declareClass('A');
    library.declareTopLevelFunction('f');
    expect(() => library.declareClass('A'), throwsStateError);
    expect(() => library.declareTopLevelFunction('f'), throwsStateError);

    var classReference = library.getOrCreateClass('A');
    classReference.declareConstructor('new');
    classReference.declareMethod('m');
    expect(() => classReference.declareConstructor('new'), throwsStateError);
    expect(() => classReference.declareMethod('m'), throwsStateError);
  }

  void test_direct_memberReferences() {
    var root = RootReference();
    var library = root.getOrCreateLibrary(Uri.parse('package:test/a.dart'));
    var classReference = library.declareClass('A');

    const constructorName = 'new';
    const fieldName = 'field';
    const propertyName = 'property';
    const methodName = 'method';

    var methodReference = classReference.declareMethod(methodName);
    var setterReference = classReference.declareSetter(propertyName);
    var constructorReference = classReference.declareConstructor(
      constructorName,
    );
    var getterReference = classReference.declareGetter(propertyName);
    var fieldReference = classReference.declareField(fieldName);

    expect(
      classReference.getOrCreateConstructor(constructorName),
      same(constructorReference),
    );
    expect(classReference.getOrCreateField(fieldName), same(fieldReference));
    expect(
      classReference.getOrCreateGetter(propertyName),
      same(getterReference),
    );
    expect(
      classReference.getOrCreateSetter(propertyName),
      same(setterReference),
    );
    expect(classReference.getOrCreateMethod(methodName), same(methodReference));

    expect(classReference.children, [
      constructorReference,
      fieldReference,
      getterReference,
      setterReference,
      methodReference,
    ]);

    for (var reference in classReference.children) {
      expect(reference, isA<MemberReference>());
      expect(reference.enclosingReference, same(classReference));
    }
  }

  void test_direct_topLevelReferences() {
    var root = RootReference();
    var library = root.getOrCreateLibrary(Uri.parse('package:test/a.dart'));

    const propertyName = 'property';

    var topLevelVariable = library.declareTopLevelVariable('v');
    var setter = library.declareSetter(propertyName);
    var getter = library.declareGetter(propertyName);
    var topLevelFunction = library.declareTopLevelFunction('f');
    var typeAlias = library.declareTypeAlias('T');
    var mixin = library.declareMixin('M');
    var extensionType = library.declareExtensionType('ET');
    var extension = library.declareExtension('E');
    var enum_ = library.declareEnum('Enum');
    var class_ = library.declareClass('A');

    expect(library.getOrCreateClass('A'), same(class_));
    expect(library.getOrCreateEnum('Enum'), same(enum_));
    expect(library.getOrCreateExtension('E'), same(extension));
    expect(library.getOrCreateExtensionType('ET'), same(extensionType));
    expect(library.getOrCreateMixin('M'), same(mixin));
    expect(library.getOrCreateTypeAlias('T'), same(typeAlias));
    expect(library.getOrCreateTopLevelFunction('f'), same(topLevelFunction));
    expect(library.getOrCreateGetter(propertyName), same(getter));
    expect(library.getOrCreateSetter(propertyName), same(setter));
    expect(library.getOrCreateTopLevelVariable('v'), same(topLevelVariable));

    expect(library.children, [
      class_,
      enum_,
      extension,
      extensionType,
      mixin,
      typeAlias,
      topLevelFunction,
      getter,
      setter,
      topLevelVariable,
    ]);

    for (var reference in [class_, enum_, extension, extensionType, mixin]) {
      expect(reference, isA<MemberContainerReference>());
      expect(reference.enclosingReference, same(library));
    }
    for (var reference in [
      typeAlias,
      topLevelFunction,
      getter,
      setter,
      topLevelVariable,
    ]) {
      expect(reference, isA<LeafTopLevelReference>());
      expect(reference.enclosingReference, same(library));
    }
  }

  void test_libraryReferenceBuilder_memberKeys() {
    var root = RootReference();
    var library = root.getOrCreateLibrary(Uri.parse('package:test/a.dart'));
    var builder = LibraryReferenceBuilder(library);
    var classA = builder.declareClass('A');
    var classB = builder.declareClass('B');

    var method = builder.declareMemberMethod(container: classA, name: 'foo');
    var duplicateMethod = builder.declareMemberMethod(
      container: classA,
      name: 'foo',
    );
    var getter = builder.declareMemberGetter(container: classA, name: 'foo');
    var methodInClassB = builder.declareMemberMethod(
      container: classB,
      name: 'foo',
    );
    var unnamedField = builder.declareMemberField(
      container: classA,
      name: null,
    );
    var unnamedGetter = builder.declareMemberGetter(
      container: classA,
      name: null,
    );

    expect(classA.getOrCreateMethod('foo'), same(method));
    expect(classA.getOrCreateMethod('foo#1'), same(duplicateMethod));
    expect(classA.getOrCreateGetter('foo'), same(getter));
    expect(classB.getOrCreateMethod('foo'), same(methodInClassB));
    expect(classA.getOrCreateField('#0'), same(unnamedField));
    expect(classA.getOrCreateGetter('#1'), same(unnamedGetter));
  }

  void test_libraryReferenceBuilder_topLevelKeys() {
    var root = RootReference();
    var library = root.getOrCreateLibrary(Uri.parse('package:test/a.dart'));
    var builder = LibraryReferenceBuilder(library);

    var classA = builder.declareClass('A');
    var duplicateClassA = builder.declareClass('A');
    var enumA = builder.declareEnum('A');
    var unnamedGetter = builder.declareGetter(null);
    var unnamedSetter = builder.declareSetter(null);
    var getterX = builder.declareGetter('x');
    var duplicateGetterX = builder.declareGetter('x');
    var setterX = builder.declareSetter('x');

    expect(library.getOrCreateClass('A'), same(classA));
    expect(library.getOrCreateClass('A#1'), same(duplicateClassA));
    expect(library.getOrCreateEnum('A'), same(enumA));
    expect(library.getOrCreateGetter('#0'), same(unnamedGetter));
    expect(library.getOrCreateSetter('#1'), same(unnamedSetter));
    expect(library.getOrCreateGetter('x'), same(getterX));
    expect(library.getOrCreateGetter('x#1'), same(duplicateGetterX));
    expect(library.getOrCreateSetter('x'), same(setterX));
  }

  void test_referenceTable_roundTrip() {
    var writeRoot = RootReference();
    var packageUri = Uri.parse('package:test/a.dart');
    var packageLibrary = writeRoot.getOrCreateLibrary(packageUri);
    var classReference = packageLibrary.declareClass('A');
    var functionReference = packageLibrary.declareTopLevelFunction('f');
    var methodReference = classReference.declareMethod('m');
    var dartCore = writeRoot.getOrCreateLibrary(Uri.parse('dart:core'));
    var dynamicReference = dartCore.dynamicRef;

    var sink = BinaryWriter();
    var tableWriter = ReferenceTableWriter();
    tableWriter.writeReference(sink, writeRoot);
    tableWriter.writeReference(sink, packageLibrary);
    tableWriter.writeReference(sink, classReference);
    tableWriter.writeReference(sink, functionReference);
    tableWriter.writeReference(sink, methodReference);
    tableWriter.writeReference(sink, dynamicReference);
    tableWriter.writeReference(sink, classReference);
    var tableOffset = sink.offset;
    tableWriter.write(sink);
    sink.writeTableTrailer();

    var reader = BinaryReader(sink.takeBytes());
    reader.initFromTableTrailer();
    var readRoot = RootReference();
    reader.offset = tableOffset;
    var tableReader = ReferenceTableReader(
      reader: reader,
      rootReference: readRoot,
    );

    reader.offset = 0;
    expect(tableReader.readReference(reader), same(readRoot));

    var readPackageLibrary = tableReader.readLibraryReference(reader);
    expect(readPackageLibrary.uriString, '$packageUri');
    expect(readRoot.getOrCreateLibrary(packageUri), same(readPackageLibrary));

    var readClass = tableReader.readMemberContainerReference(reader);
    expect(readClass, same(readPackageLibrary.getOrCreateClass('A')));

    var readFunction = tableReader.readTopLevelReference(reader);
    expect(
      readFunction,
      same(readPackageLibrary.getOrCreateTopLevelFunction('f')),
    );

    var readMethod = tableReader.readMemberReference(reader);
    expect(readMethod, same(readClass.getOrCreateMethod('m')));

    var readDynamic = tableReader.readExportableReference(reader);
    expect(
      readDynamic,
      same(readRoot.getOrCreateLibrary(Uri.parse('dart:core')).dynamicRef),
    );

    expect(tableReader.readDeclarationReference(reader), same(readClass));
    expect(readPackageLibrary.children, [readClass, readFunction]);
  }

  void test_root_libraries() {
    var root = RootReference();
    var a = Uri.parse('package:test/a.dart');
    var b = Uri.parse('package:test/b.dart');

    expect(root.children, isEmpty);
    expect(root.libraryIfExists(a), isNull);
    expect(root.removeLibrary(a), isNull);

    var libraryA = root.getOrCreateLibrary(a);
    expect(libraryA.uriString, '$a');
    expect(libraryA.uri, a);
    expect(libraryA.enclosingReference, isNull);
    expect(root.getOrCreateLibrary(a), same(libraryA));
    expect(root.libraryIfExists(a), same(libraryA));
    expect(root.children, [libraryA]);

    var libraryB = root.getOrCreateLibrary(b);
    expect(root.children, [libraryA, libraryB]);

    expect(root.removeLibrary(a), same(libraryA));
    expect(root.children, [libraryB]);
    expect(root.removeLibrary(a), isNull);
  }
}
