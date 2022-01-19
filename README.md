# Code Generator

A package to help generate Dart code from existing code.<br>
This package is useful when you need to generate code without using build_runner, example usages would be CLIs or when you need to generate code once and let the user edit it afterwards.

# Getting Started

First you'll need to create a class that implements `Generator`, afterwards you create a `CodeGenerator` passing your custom generator as argument, and then use `CodeGenerator.generateFor` to generate code for code in a given directory.

```dart
import 'package:code_generator/code_generator.dart';

void main() {
  final codeGenerator = CodeGenerator(
    generators: [MyCustomGenerator()],
  );
  codeGenerator.generateFor(Directory('path/to/source_code'));
}

class MyCustomGenerator extends Generator<ClassDeclaration> {

  GeneratorResult generate(ClassDeclaration member, String path) {
    ...
  }
}
```

## Generators

`Generator` is the base class used to generate code. It contains the methods `shouldGenerateFor`, which is used to determine if this generator should be used to generate code for a given `CompilationUnitMember`, and `generate`, which generates the code for the filtered members.<br>
Example implementation:

```dart
import 'package:code_generator/code_generator.dart';
import 'package:path/path.dart' as path;

class RepositoryGenerator extends Generator<ClassDeclaration> {
  bool shouldGenerateFor(CompilationUnitMember member, String path) {
    return member is ClassDeclaration && member.name.name.endsWith('Entity');
  }

  @override
  GeneratorResult generate(ClassDeclaration member, String path) {
    final memberName = member.name.name;
    return GeneratorResult.single(
      path: path.relative('../repository/${memberName}Repository', from: path),
      content: 'class ${memberName}Repository {}',
    );
  }
}
```

There are some premade Generators so that you don't need to check for member types, they are:

- GeneratorForClass
- GeneratorForMixin
- GeneratorForFunction
- GeneratorForExtension
- GeneratorForEnum
- GeneratorForType
- GeneratorForTopLevelVariable
- GeneratorForAnnotatedElements
