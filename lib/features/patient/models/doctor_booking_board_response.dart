class DoctorBookingBoardResponse {
  final bool success;
  final String? message;
  final BookingBoardData? data;
  final dynamic error;
  final String? requestId;

  DoctorBookingBoardResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.requestId,
  });

  factory DoctorBookingBoardResponse.fromJson(Map<String, dynamic> json) {
    return DoctorBookingBoardResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? BookingBoardData.fromJson(json['data']) : null,
      error: json['error'],
      requestId: json['request_id'],
    );
  }
}

class BookingBoardData {
  final String date;
  final int slotDurationMinutes;
  final List<BookingSlot> slots;

  BookingBoardData({
    required this.date,
    required this.slotDurationMinutes,
    required this.slots,
  });

  factory BookingBoardData.fromJson(Map<String, dynamic> json) {
    return BookingBoardData(
      date: json['date']?.toString() ?? '',
      slotDurationMinutes: json['slotDurationMinutes'] ?? 0,
      slots: (json['slots'] as List<dynamic>?)
              ?.map((e) => BookingSlot.fromJson(e))
              .toList() ??
          [],
    );
  }
}


class BookingSlot {
  final String? id;
  final String locationId;
  final String startAt;
  final String endAt;
  final String startAtLocal;
  final String endAtLocal;
  final String timezone;
  final String status;
  final String? title;
  final String? attendeeName;
  final String? attendeeEmail;
  final String? bookingStatus;

  BookingSlot({
    this.id,
    required this.locationId,
    required this.startAt,
    required this.endAt,
    required this.startAtLocal,
    required this.endAtLocal,
    required this.timezone,
    required this.status,
    this.title,
    this.attendeeName,
    this.attendeeEmail,
    this.bookingStatus,
  });

  factory BookingSlot.fromJson(Map<String, dynamic> json) {
    return BookingSlot(
      id: json['id'],
      locationId: json['locationId'] ?? '',
      startAt: json['startAt'] ?? '',
      endAt: json['endAt'] ?? '',
      startAtLocal: json['startAtLocal'] ?? '',
      endAtLocal: json['endAtLocal'] ?? '',
      timezone: json['timezone'] ?? '',
      status: json['status'] ?? 'available',
      title: json['title'],
      attendeeName: json['attendeeName'],
      attendeeEmail: json['attendeeEmail'],
      bookingStatus: json['booking_status'],
    );
  }
}
