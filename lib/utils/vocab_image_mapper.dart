import '../models/vocab_item.dart';

class VocabImageMapper {
  static String pickImage(List<String> images, int seed) {
    if (images.isEmpty) {
      return 'assets/review/default_1.png';
    }
    return images[seed % images.length];
  }

  static String getCategoryImage(VocabItem word) {
    final category = word.category.trim();

    switch (category) {
      case '辦公日常':
        return pickImage([
          'assets/toeic_vocab_category/office.png',
        ], word.id);

      case '營運管理':
        return pickImage([
          'assets/toeic_vocab_category/operations management.png',
        ], word.id);

      case '溝通互動':
        return pickImage([
          'assets/toeic_vocab_category/communicate.png',
        ], word.id);

      case '一般專業':
        return pickImage([
          'assets/toeic_vocab_category/Profession.png',
        ], word.id);

      case '人力資源':
        return pickImage([
          'assets/toeic_vocab_category/human Resources.png',
        ], word.id);

      case '科技與技術支援':
        return pickImage([
          'assets/toeic_vocab_category/technology.png',
        ], word.id);

      case '旅遊與交通':
        return pickImage([
          'assets/toeic_vocab_category/Tourism and Transportation.png',
        ], word.id);

      case '行銷與銷售':
        return pickImage([
          'assets/toeic_vocab_category/Marketing and Sales.png',
        ], word.id);

      case '採購與物流':
        return pickImage([
          'assets/toeic_vocab_category/Procurement and Logistics.png',
        ], word.id);

      case '金融與會計':
        return pickImage([
          'assets/toeic_vocab_category/Finance and Accounting.png',
        ], word.id);

      case '住宿與餐飲':
        return pickImage([
          'assets/toeic_vocab_category/Accommodation and Catering.png',
        ], word.id);

      case '法務合規與安全':
        return pickImage([
          'assets/toeic_vocab_category/Legal Compliance and Security.png',
        ], word.id);

      case '物業與不動產':
        return pickImage([
          'assets/toeic_vocab_category/Business and Real Estate.png',
        ], word.id);

      case '會議與簡報':
        return pickImage([
          'assets/toeic_vocab_category/Meetings and Clippings.png',
        ], word.id);

      case '客戶服務':
        return pickImage([
          'assets/toeic_vocab_category/Customer Service.png',
        ], word.id);

      default:
        return pickImage([
          'assets/toeic_vocab_category/toeic_review_cover.png',
        ], word.id);
    }
  }
}