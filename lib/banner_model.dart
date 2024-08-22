class BannerModel {
  final String imageUrl;

  BannerModel({required this.imageUrl});

  factory BannerModel.fromMap(Map<String, dynamic> map) {
    return BannerModel(
      imageUrl: map['imageUrl'],
    );
  }
}
