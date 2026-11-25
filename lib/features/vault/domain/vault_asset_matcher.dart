import '../../records/domain/record.dart';
import 'document_item.dart';

/// Confidence tiers for offline metadata-based Vault-to-Asset matching.
enum VaultMatchConfidence {
  exactIdentifier,
  brandAndModel,
  titleMatch,
}

/// Asset candidate bundled with its optional License Plate custom field value.
class VaultAssetCandidate {
  final RecordWithAsset asset;
  final String? licensePlate;

  const VaultAssetCandidate({
    required this.asset,
    this.licensePlate,
  });
}

/// Ranked asset suggestion for a Vault document.
class VaultAssetMatch {
  final RecordWithAsset asset;
  final VaultMatchConfidence confidence;
  final int score;
  final String reason;

  const VaultAssetMatch({
    required this.asset,
    required this.confidence,
    required this.score,
    required this.reason,
  });

  /// Exact hardware/plate identifiers are safe to auto-preselect with 1-tap undo.
  bool get shouldAutoPreselect => confidence == VaultMatchConfidence.exactIdentifier;
}

/// Ranked unlinked Vault document suggestion for an Asset.
class VaultDocumentMatch {
  final RecordWithDocument document;
  final VaultMatchConfidence confidence;
  final int score;
  final String reason;

  const VaultDocumentMatch({
    required this.document,
    required this.confidence,
    required this.score,
    required this.reason,
  });
}

/// Pure 100% offline matcher linking Vault documents and Assets using metadata
/// (`title`, `fileName`, `description`) with strict boundary-safe checks.
class VaultAssetMatcher {
  VaultAssetMatcher._();

  static const int _plateScore = 100;
  static const int _serialScore = 95;
  static const int _brandModelScore = 80;
  static const int _titleScore = 60;
  static const int _maxAssetSuggestions = 3;

  static final RegExp _nonAlphaNum = RegExp(r'[^A-Za-z0-9]+');
  static final RegExp _fileExtension = RegExp(r'\.[A-Za-z0-9]{1,5}$');

  /// Finds up to 3 matching assets for a document's metadata, ranked by
  /// descending confidence score and ascending asset title.
  static List<VaultAssetMatch> findMatchingAssetsForDocument({
    required String title,
    required String fileName,
    String? description,
    required List<VaultAssetCandidate> candidates,
  }) {
    final docText = _DocumentSearchText.fromMetadata(
      title: title,
      fileName: fileName,
      description: description,
    );
    if (docText.isEmpty) return const [];

    final matches = <VaultAssetMatch>[];
    for (final candidate in candidates) {
      final hit = _evaluateCandidate(candidate, docText);
      if (hit == null) continue;
      matches.add(
        VaultAssetMatch(
          asset: candidate.asset,
          confidence: hit.confidence,
          score: hit.score,
          reason: hit.reason,
        ),
      );
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.asset.record.title.toLowerCase().compareTo(
            b.asset.record.title.toLowerCase(),
          );
    });

    if (matches.length <= _maxAssetSuggestions) return matches;
    return matches.sublist(0, _maxAssetSuggestions);
  }

  /// Finds unlinked Vault documents (`linkedAssetRecordId == null`) matching
  /// [candidate], ranked by descending score and ascending document title.
  static List<VaultDocumentMatch> findMatchingUnlinkedDocumentsForAsset({
    required VaultAssetCandidate candidate,
    required List<RecordWithDocument> documents,
  }) {
    final matches = <VaultDocumentMatch>[];
    for (final doc in documents) {
      if (doc.document.linkedAssetRecordId != null) continue;

      final docText = _DocumentSearchText.fromMetadata(
        title: doc.record.title,
        fileName: doc.document.fileName,
        description: doc.record.description,
      );
      if (docText.isEmpty) continue;

      final hit = _evaluateCandidate(candidate, docText);
      if (hit == null) continue;
      matches.add(
        VaultDocumentMatch(
          document: doc,
          confidence: hit.confidence,
          score: hit.score,
          reason: hit.reason,
        ),
      );
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.document.record.title.toLowerCase().compareTo(
            b.document.record.title.toLowerCase(),
          );
    });
    return matches;
  }

  static _MatchEvaluation? _evaluateCandidate(
    VaultAssetCandidate candidate,
    _DocumentSearchText docText,
  ) {
    final plate = candidate.licensePlate?.trim();
    if (plate != null && _matchesExactIdentifier(plate, docText.rawUpper, minLength: 4)) {
      return _MatchEvaluation(
        confidence: VaultMatchConfidence.exactIdentifier,
        score: _plateScore,
        reason: 'Matched Plate: $plate',
      );
    }

    final assetMeta = candidate.asset.asset;
    final serial = assetMeta?.serialNumber?.trim();
    if (serial != null && _matchesExactIdentifier(serial, docText.rawUpper, minLength: 5)) {
      return _MatchEvaluation(
        confidence: VaultMatchConfidence.exactIdentifier,
        score: _serialScore,
        reason: 'Matched Serial: $serial',
      );
    }

    final brand = assetMeta?.brand?.trim();
    final model = assetMeta?.model?.trim();
    if (brand != null && model != null && _matchesBrandAndModel(brand, model, docText)) {
      return _MatchEvaluation(
        confidence: VaultMatchConfidence.brandAndModel,
        score: _brandModelScore,
        reason: 'Matched Brand & Model: $brand $model',
      );
    }

    final title = candidate.asset.record.title.trim();
    if (_matchesTitle(title, docText)) {
      return _MatchEvaluation(
        confidence: VaultMatchConfidence.titleMatch,
        score: _titleScore,
        reason: 'Matched Name: $title',
      );
    }

    return null;
  }

  /// Boundary-safe alphanumeric match allowing optional horizontal separators
  /// (`-`, `_`, space, tab) between characters while forbidding newlines or
  /// adjacent unrelated alphanumeric characters.
  static bool _matchesExactIdentifier(
    String rawIdentifier,
    String upperHaystack, {
    required int minLength,
  }) {
    final normalized = rawIdentifier.replaceAll(_nonAlphaNum, '').toUpperCase();
    if (normalized.length < minLength) return false;

    final buffer = StringBuffer(r'(?<![A-Z0-9])');
    for (var i = 0; i < normalized.length; i++) {
      if (i > 0) buffer.write(r'[ \t\-_]{0,3}');
      buffer.write(normalized[i]);
    }
    buffer.write(r'(?![A-Z0-9])');
    return RegExp(buffer.toString()).hasMatch(upperHaystack);
  }

  static bool _matchesBrandAndModel(
    String brand,
    String model,
    _DocumentSearchText docText,
  ) {
    final brandTokens = _tokenize(brand);
    final modelTokens = _tokenize(model);
    if (brandTokens.join('').length < 2 || modelTokens.join('').length < 2) {
      return false;
    }
    return _matchesTokens(brandTokens, docText) && _matchesTokens(modelTokens, docText);
  }

  static bool _matchesTitle(String title, _DocumentSearchText docText) {
    final titleTokens = _tokenize(title);
    if (titleTokens.join('').length < 4) return false;
    return _matchesTokens(titleTokens, docText);
  }

  static bool _matchesTokens(List<String> tokens, _DocumentSearchText docText) {
    if (tokens.isEmpty) return false;
    final phrase = ' ${tokens.join(' ')} ';
    if (docText.paddedTokens.contains(phrase)) return true;

    if (tokens.length > 1) {
      final compact = tokens.join('');
      if (compact.length >= 4 && docText.tokenSet.contains(compact)) {
        return true;
      }
    }
    return false;
  }

  static List<String> _tokenize(String raw) {
    return raw
        .toUpperCase()
        .split(_nonAlphaNum)
        .where((token) => token.isNotEmpty)
        .toList();
  }
}

class _DocumentSearchText {
  final String rawUpper;
  final String paddedTokens;
  final Set<String> tokenSet;

  const _DocumentSearchText({
    required this.rawUpper,
    required this.paddedTokens,
    required this.tokenSet,
  });

  bool get isEmpty => tokenSet.isEmpty;

  factory _DocumentSearchText.fromMetadata({
    required String title,
    required String fileName,
    String? description,
  }) {
    final cleanFileName = fileName.trim().replaceAll(VaultAssetMatcher._fileExtension, '');
    final segments = <String>[
      if (title.trim().isNotEmpty) title.trim(),
      if (cleanFileName.isNotEmpty) cleanFileName,
      if (description != null && description.trim().isNotEmpty) description.trim(),
    ];
    final combined = segments.join('\n').toUpperCase();
    final tokens = VaultAssetMatcher._tokenize(combined);
    return _DocumentSearchText(
      rawUpper: combined,
      paddedTokens: tokens.isEmpty ? '' : ' ${tokens.join(' ')} ',
      tokenSet: tokens.toSet(),
    );
  }
}

class _MatchEvaluation {
  final VaultMatchConfidence confidence;
  final int score;
  final String reason;

  const _MatchEvaluation({
    required this.confidence,
    required this.score,
    required this.reason,
  });
}
