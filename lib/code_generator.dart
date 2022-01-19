import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'generated_file.dart';
import 'generator.dart';
import 'generator_result.dart';
import 'package_analyzer.dart';

class CodeGenerator {
  final List<Generator> _generators;
  final PackageAnalyzer _analyzer;

  const CodeGenerator({
    required List<Generator> generators,
    PackageAnalyzer analyzer = const PackageAnalyzer(),
  })  : _generators = generators,
        _analyzer = analyzer;

  Future<void> generateFor(Directory packageDirectory) async {
    final libraries = await _analyzer.analyze(packageDirectory);
    final generatorResult = _runGenerator(libraries);
    await _saveFiles(generatorResult.files);
  }

  GeneratorResult _runGenerator(List<ResolvedLibraryResult> libraries) {
    final files = <GeneratedFile>[];
    for (final library in libraries) {
      for (final unit in library.units) {
        for (final declaration in unit.unit.declarations) {
          files.addAll(_generateFor(declaration, unit.path));
        }
      }
    }
    return GeneratorResult(files);
  }

  List<GeneratedFile> _generateFor(CompilationUnitMember member, String path) {
    return _generators
        .where((g) => g.shouldGenerateFor(member))
        .map((g) => g.generate(member, path).files)
        .fold([], (file, list) => list..addAll(file));
  }

  Future<void> _saveFiles(List<GeneratedFile> generatedFiles) async {
    for (final generatedFile in generatedFiles) {
      final file = File(generatedFile.path);
      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsString(generatedFile.content);
      }
    }
  }
}
