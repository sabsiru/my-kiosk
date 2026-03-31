class KioskTable {
  final int id;
  final int tableNumber;
  final String? deviceId;
  final String status;

  KioskTable({
    required this.id,
    required this.tableNumber,
    this.deviceId,
    required this.status,
  });

  factory KioskTable.fromJson(Map<String, dynamic> json) => KioskTable(
        id: json['id'] as int,
        tableNumber: json['tableNumber'] as int,
        deviceId: json['deviceId'] as String?,
        status: json['status'] as String,
      );
}
