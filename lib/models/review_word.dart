class ReviewWord {
  final int id;
  final String word;
  final String definitionZh;
  final String partOfSpeech;
  final String exampleEn;
  final String exampleZh;
  final String imagePath;
  final int isSaved;

  ReviewWord({
    required this.id,
    required this.word,
    required this.definitionZh,
    required this.partOfSpeech,
    required this.exampleEn,
    required this.exampleZh,
    required this.imagePath,
    required this.isSaved,
  });
}