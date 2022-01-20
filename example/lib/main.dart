import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:code_generator/code_generator.dart';
import 'package:path/path.dart';

void main() {
  final codeGenerator = CodeGenerator(generators: [
    RepositoryGenerator(),
  ]);
  codeGenerator.generateFor(Directory.current);
}

class RepositoryGenerator extends GeneratorForClass {
  @override
  bool shouldGenerateFor(ClassDeclaration member, String path) {
    return super.shouldGenerateFor(member, path) && member.name.name == 'User';
  }

  @override
  GeneratorResult generate(ClassDeclaration member, String path) {
    final memberName = member.name.name;
    final repositoryName = '${memberName}Repository';
    final fileName = StringUtils.camelCaseToLowerUnderscore(repositoryName);
    return GeneratorResult.single(
      path: join(path, '../$fileName.dart'),
      content: 'class $repositoryName {}',
    );
  }
}
