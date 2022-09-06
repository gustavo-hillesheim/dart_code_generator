import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:code_generator/package_analyzer.dart';
import 'package:test/test.dart';

void main() {
  final testPackageDirectory = Directory.fromUri(
    Directory.current.uri.resolve('test/analyzer_test_package'),
  );
  late PackageAnalyzer analyzer;

  setUp(() {
    analyzer = PackageAnalyzer();
  });

  test('SHOULD analyze test_package', () async {
    final libraries = await analyzer.analyzeDirectory(testPackageDirectory);

    expect(libraries.length, 1);
    final library = libraries[0];

    expect(library.units.length, 1);
    final unit = library.units[0].unit;

    expect(unit.declarations.length, 5);

    expect(unit.declarations, anyElement((el) {
      return el is TopLevelVariableDeclaration &&
          el.variables.isFinal &&
          el.variables.variables.length == 1 &&
          el.variables.variables[0].name.name == 'a' &&
          el.variables.variables[0].initializer?.toSource() == '1';
    }));

    expect(unit.declarations, anyElement((el) {
      return el is TopLevelVariableDeclaration &&
          el.variables.isConst &&
          el.variables.variables.length == 1 &&
          el.variables.variables[0].name.name == 'b' &&
          el.variables.variables[0].initializer?.toSource() == "'1'";
    }));

    expect(unit.declarations, anyElement((el) {
      return el is TopLevelVariableDeclaration &&
          el.variables.variables.length == 1 &&
          el.variables.variables[0].name.name == 'c' &&
          el.variables.variables[0].initializer?.toSource() == 'true';
    }));

    expect(unit.declarations, anyElement((el) {
      return el is FunctionDeclaration &&
          el.name.name == 'main' &&
          el.returnType?.toSource() == 'void';
    }));

    expect(unit.declarations, anyElement((el) {
      if (el is! ClassDeclaration) {
        return false;
      }
      if (el.name.name != 'Entity' || el.members.length != 2) {
        return false;
      }
      final field = el.members[0] as FieldDeclaration;
      final constructor = el.members[1] as ConstructorDeclaration;
      return field.fields.isFinal &&
          field.fields.variables[0].name.name == 'name' &&
          constructor.name == null &&
          constructor.parameters.parameters.length == 1 &&
          constructor.parameters.parameters[0].isPositional &&
          constructor.parameters.parameters[0].identifier?.name == 'name' &&
          constructor.parameters.parameters[0].declaredElement?.type.element
                  ?.name ==
              'String';
    }));
  });
}
