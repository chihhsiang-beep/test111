class VocabItem {
  final int id;
  final String word;
  final String definitionZh;
  final String partOfSpeech;
  final int starRating;
  final String toeicScoreRange;
  final String category;
  final String exampleEn;
  final String exampleZh;
  final String examTip;
  final int isSaved;

  VocabItem({
    required this.id,
    required this.word,
    required this.definitionZh,
    required this.partOfSpeech,
    required this.starRating,
    required this.toeicScoreRange,
    required this.category,
    required this.exampleEn,
    required this.exampleZh,
    required this.examTip,
    required this.isSaved,
  });

  factory VocabItem.fromMap(Map<String, dynamic> map) {
    return VocabItem(
      id: map['id'] ?? 0,
      word: map['english_word'] ?? '',
      definitionZh: map['chinese_definition'] ?? '',
      partOfSpeech: map['parts_of_speech'] ?? '',
      starRating: map['star_rating'] ?? 0,
      toeicScoreRange: map['toeic_score_range'] ?? '',
      category: map['category'] ?? '',
      exampleEn: map['example_en'] ?? '',
      exampleZh: map['example_zh'] ?? '',
      examTip: map['exam_tip'] ?? '',
      isSaved: map['is_saved'] ?? 0,
    );
  }
}