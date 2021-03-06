import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:code_generator/generation_step.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'package:code_generator/code_generator.dart';

void main() {
  final testPackageDirectory = Directory.fromUri(
    Directory.current.uri.resolve('test/code_generator_test_package'),
  );
  late GeneratorForClass generatorForClass;
  late GeneratorForMixin generatorForMixin;
  late GeneratorForFunction generatorForFunction;
  late GeneratorForExtension generatorForExtension;
  late GeneratorForEnum generatorForEnum;
  late GeneratorForType generatorForType;
  late GeneratorForTopLevelVariable generatorForTopLevelVariable;
  late GeneratorForAnnotatedElements<ClassDeclaration>
      generatorForAnnotatedElements;

  setUp(() {
    registerFallbackValue(FakeClassDeclaration());
    registerFallbackValue(FakeDeclaration());
    registerFallbackValue(FakeMixinDeclaration());
    registerFallbackValue(FakeFunctionDeclaration());
    registerFallbackValue(FakeExtensionDeclaration());
    registerFallbackValue(FakeEnumDeclaration());
    registerFallbackValue(FakeTypeDeclaration());
    registerFallbackValue(FakeTopLevelVariableDeclaration());
    generatorForClass = GeneratorForClassMock();
    generatorForMixin = GeneratorForMixinMock();
    generatorForFunction = GeneratorForFunctionMock();
    generatorForExtension = GeneratorForExtensionMock();
    generatorForEnum = GeneratorForEnumMock();
    generatorForType = GeneratorForTypeMock();
    generatorForTopLevelVariable = GeneratorForTopLevelVariableMock();
    generatorForAnnotatedElements = GeneratorForAnnotatedElementsMock();
  });

  void mockGenerator<T extends CompilationUnitMember>(Generator<T> generator) {
    when(() => generator.acceptsType(any())).thenAnswer(
      (invocation) => invocation.positionalArguments[0] is T,
    );
    when(() => generator.description).thenReturn('test generator');
    when(() => generator.shouldGenerateFor(any(), any())).thenReturn(true);
    when(() => generator.generate(any<T>(), any()))
        .thenReturn(GeneratorResult([]));
  }

  String getTempFilePath(String name) {
    return relative('temp$separator$name');
  }

  Future<void> deleteTempDir() async {
    await Directory(relative('temp')).delete(recursive: true);
  }

  test('SHOULD call each of the generators once', () async {
    mockGenerator(generatorForClass);
    mockGenerator(generatorForMixin);
    mockGenerator(generatorForFunction);
    mockGenerator(generatorForExtension);
    mockGenerator(generatorForEnum);
    mockGenerator(generatorForType);
    mockGenerator(generatorForTopLevelVariable);
    mockGenerator<ClassDeclaration>(generatorForAnnotatedElements);
    final codeGenerator = CodeGenerator(generators: [
      generatorForClass,
      generatorForMixin,
      generatorForFunction,
      generatorForExtension,
      generatorForEnum,
      generatorForType,
      generatorForTopLevelVariable,
      generatorForAnnotatedElements,
    ]);

    final events =
        await codeGenerator.generateFor(testPackageDirectory).toList();

    expect(events.length, 13);
    expect(events[0], isA<AnalyzingPackageStep>());
    expect(events[1], isA<RunningGeneratorsStep>());
    for (var i = 2; i < events.length - 1; i++) {
      expect(events[i], isA<RunningGeneratorStep>());
    }
    expect(events.last, isA<CodeGenerationResult>());
    verify(() => generatorForClass.generate(any(), any()));
    verify(() => generatorForMixin.generate(any(), any()));
    verify(() => generatorForFunction.generate(any(), any()));
    verify(() => generatorForExtension.generate(any(), any()));
    verify(() => generatorForEnum.generate(any(), any()));
    verify(() => generatorForType.generate(any(), any()));
    verify(() => generatorForTopLevelVariable.generate(any(), any()));
    verify(() => generatorForAnnotatedElements.generate(any(), any()));
  });

  test('WHEN generator returns file to save SHOULD save file', () async {
    final filePath = getTempFilePath('generated.dart');
    when(() => generatorForClass.acceptsType(any())).thenAnswer(
      (invocation) => invocation.positionalArguments[0] is ClassDeclaration,
    );
    when(() => generatorForClass.shouldGenerateFor(any(), any()))
        .thenAnswer((invocation) {
      ClassDeclaration declaration = invocation.positionalArguments[0];
      return declaration.name.name == 'Class';
    });
    when(() => generatorForClass.description).thenReturn('test generator');
    when(() => generatorForClass.generate(any(), any())).thenReturn(
      GeneratorResult.single(path: filePath, content: 'final a = 1'),
    );
    final codeGenerator = CodeGenerator(generators: [generatorForClass]);

    await codeGenerator.generateFor(testPackageDirectory).last;

    File generatedFile = File(filePath);
    expect(await generatedFile.exists(), true);
    expect(await generatedFile.readAsString(), 'final a = 1');

    await deleteTempDir();
  });
}

class FakeClassDeclaration extends Fake implements ClassDeclaration {}

class FakeMixinDeclaration extends Fake implements MixinDeclaration {}

class FakeFunctionDeclaration extends Fake implements FunctionDeclaration {}

class FakeExtensionDeclaration extends Fake implements ExtensionDeclaration {}

class FakeEnumDeclaration extends Fake implements EnumDeclaration {}

class FakeTypeDeclaration extends Fake implements TypeAlias {}

class FakeTopLevelVariableDeclaration extends Fake
    implements TopLevelVariableDeclaration {}

class FakeDeclaration extends Fake implements Declaration {}

class GeneratorForClassMock extends Mock implements GeneratorForClass {}

class GeneratorForMixinMock extends Mock implements GeneratorForMixin {}

class GeneratorForFunctionMock extends Mock implements GeneratorForFunction {}

class GeneratorForExtensionMock extends Mock implements GeneratorForExtension {}

class GeneratorForEnumMock extends Mock implements GeneratorForEnum {}

class GeneratorForTypeMock extends Mock implements GeneratorForType {}

class GeneratorForTopLevelVariableMock extends Mock
    implements GeneratorForTopLevelVariable {}

class GeneratorForAnnotatedElementsMock extends Mock
    implements GeneratorForAnnotatedElements<ClassDeclaration> {
  @override
  final annotationMatcher = nameAnnotationMatcher(RegExp(r'^Deprecated$'));
}
