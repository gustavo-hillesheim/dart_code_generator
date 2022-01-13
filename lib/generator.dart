import 'package:analyzer/dart/ast/ast.dart';

import 'generator_result.dart';

/// Generates files for a given [Declaration].
abstract class Generator<T extends Declaration> {
  /// Verifies if should generate files for a given [Declaration].
  bool shouldGenerateFor(Declaration declaration) => declaration is T;

  /// Generates files for a given [Declaration].
  GeneratorResult generate(T declaration);
}
