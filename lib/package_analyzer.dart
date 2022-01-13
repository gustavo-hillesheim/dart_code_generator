import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

/// Analyzes a given package and returns all libraries resolved.
class PackageAnalyzer {
  Future<List<ResolvedLibraryResult>> analyze(Directory directory) {
    final collection = _createAnalysisContextCollection(directory);
    return _readLibraries(collection);
  }

  AnalysisContextCollection _createAnalysisContextCollection(
      Directory directory) {
    return AnalysisContextCollection(
      includedPaths: [directory.absolute.path],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
  }

  Future<List<ResolvedLibraryResult>> _readLibraries(
      AnalysisContextCollection collection) async {
    final result = <ResolvedLibraryResult>[];
    for (final context in collection.contexts) {
      for (final filePath in context.contextRoot.analyzedFiles()) {
        if (!filePath.endsWith('.dart')) {
          continue;
        }
        final parsedLibrary =
            await context.currentSession.getResolvedLibrary(filePath);
        if (parsedLibrary is ResolvedLibraryResult) {
          result.add(parsedLibrary);
        }
      }
    }
    return result;
  }
}
