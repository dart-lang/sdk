// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/elements.dart';
import '../deferred_load/output_unit.dart' show OutputUnit, OutputUnitData;
import '../elements/entities.dart';
import '../js/js.dart' as js;
import '../js_model/records.dart';
import '../universe/call_structure.dart';
import '../universe/record_shape.dart';
import '../universe/use.dart' show StaticUse;
import '../universe/world_impact.dart' show WorldImpact, WorldImpactBuilderImpl;
import 'runtime_types_new.dart' show partialShapeTagOf;
import 'namer.dart' show Namer;

/// Support for Records.
///
/// [RecordsCodegen] takes part in the codegen enqueuer loop at 'link' time to
/// collect the set of record classes used and record types tested. It produces
/// a `WorldImpact` for functions and data that will later be synthesized as
/// JavaScript to ensure the enities required by the synthesized functions and
/// data are included in the program.
class RecordsCodegen {
  final RecordData _recordData;
  final CommonElements _commonElements;

  final Set<ClassEntity> _usedRecordClasses = {};

  RecordsCodegen(this._commonElements, this._recordData);

  // TODO(50081): Do we need to see any 'registerXXX' events here or is the list
  // of new classes sufficient?

  /// Computes the [WorldImpact] of the classes registered since last flush.
  WorldImpact flush(Iterable<ClassEntity> newClasses) {
    final impactBuilder = WorldImpactBuilderImpl();

    for (final cls in newClasses) {
      final representation = _recordData.representationForClass(cls);
      if (representation != null) {
        _usedRecordClasses.add(cls);
        if (representation.usesList) {
          impactBuilder.registerStaticUse(StaticUse.staticInvoke(
              _commonElements.pairwiseIsTest, CallStructure.TWO_ARGS));
        }
      }
    }

    // TODO(50081): If there is a use of the type `()`, the constant empty
    // record should be added to the impact to allow the predicate to use
    //
    //     identical(o, const ())
    //
    // as the test.
    return impactBuilder;
  }

  /// Constructs a table of curried test functions for record shapes that are
  /// tested in the program.
  ///
  /// The table is indexed by the record shape tag. The shape tag is constructed
  /// from the total field count and the partial shape tag.  The value
  /// associated with this key is a function that takes some Rtis, either as
  /// arguments or as a list, and returns a function of one argument that does a
  /// shape test, and if that passes, a type test on each field of the record.
  ///
  ///    {"3;end,start":
  ///        (t1, t2, t3) =>
  ///            (o) =>
  ///                o instanceof A._Record_3_end_start &&
  ///                t1._is(o._1) &&  t2._is(o._2) &&  t3._is(o._3),
  ///     ...,
  ///    }
  ///

  // TODO(50701): Split the table across deferred-loaded units to allow the main
  // unit to contain only tests.
  js.Expression? generateTestTableForOutputUnit(
    OutputUnit outputUnit,
    OutputUnitData outputUnitData,
    Namer namer,
  ) {
    js.Expression classReference(ClassEntity cls) {
      return js.js(
          '#.#', [namer.readGlobalObjectForClass(cls), namer.className(cls)]);
    }

    js.Expression staticMethodReference(FunctionEntity member) {
      return js.js('#.#', [
        namer.readGlobalObjectForMember(member),
        namer.methodPropertyName(member)
      ]);
    }

    List<RecordRepresentation> representations = [
      ..._recordData.representationsForShapes()
    ];

    if (representations.isEmpty) return null;

    // TODO(51040): Filter representations to only those we know are tested
    // (i.e. for shapes that have a direct or indirect type test). Shapes that
    // are created but not tested do not need code for the is-test
    // predicate. Shapes that are tested but never instantiated can have a
    // predicate that is simplified to `=> false`.

    // Order by total number of fields (arity) and then names within arity.
    representations.sort((r1, r2) => RecordShape.compare(r1.shape, r2.shape));

    List<js.Property> properties = [];

    for (final representation in representations) {
      final shape = representation.shape;
      int arity = shape.fieldCount;

      List<String> parameters = [];
      List<js.Expression> conjuncts = [];

      if (!_usedRecordClasses.contains(representation.cls)) {
        // If the record shape class is not instantiated there can be no
        // instances of this shape. The runtime treat a missing table entry like
        // 'is Never'.
        continue;
      }

      // o instanceof X.SomeRecordShapeClass
      //
      // It is important that there is only ever one constructor on the right
      // operand of `instanceof` - most JavaScript engines optimize this well.
      //
      // TODO(50701): Is the class loaded? If it is not loaded we need to
      // guard against using `instanceof` on a non-constructor, perhaps using
      // the shape tag on the prototype.
      js.Expression classRef = classReference(representation.cls);
      conjuncts.add(js.js('o instanceof #', classRef));

      if (representation.usesList) {
        parameters.add('types');
        final accessPath = _recordData.pathForAccess(representation.shape, 0);
        assert(accessPath.index == 0);

        conjuncts.add(js.js('#(types, o.#)', [
          staticMethodReference(_commonElements.pairwiseIsTest),
          namer.instanceFieldPropertyName(accessPath.field)
        ]));
      } else {
        for (int i = 0; i < arity; i++) {
          final parameterName = 't${i + 1}';
          parameters.add(parameterName);
          final accessPath = _recordData.pathForAccess(representation.shape, i);
          assert(accessPath.index == null);
          final isTest =
              namer.instanceFieldPropertyName(_commonElements.rtiIsField);
          conjuncts.add(js.js('#[#](o.#)', [
            parameterName,
            isTest,
            namer.instanceFieldPropertyName(accessPath.field)
          ]));
        }
      }

      js.Expression function;
      if (arity == 0) {
        function = js.js(
            '(o) => #', conjuncts.reduce((a, b) => js.Binary('&&', a, b)));
      } else {
        function = js.js(
          '(#) => (o) => #',
          [parameters, conjuncts.reduce((a, b) => js.Binary('&&', a, b))],
        );
      }

      String combinedTag = '${shape.fieldCount};${partialShapeTagOf(shape)}';
      properties.add(js.Property(js.string(combinedTag), function));
    }

    return js.ObjectInitializer(properties, isOneLiner: false);
  }
}
