class Store {
  final int id;
  final String name;
  final String openTime;
  final String closeTime;
  final bool isOpen;
  final bool hideAdminButton;

  Store({
    required this.id,
    required this.name,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    this.hideAdminButton = false,
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'] as int,
        name: json['name'] as String,
        openTime: json['openTime'] as String,
        closeTime: json['closeTime'] as String,
        isOpen: json['isOpen'] as bool,
        hideAdminButton: json['hideAdminButton'] as bool? ?? false,
      );
}
