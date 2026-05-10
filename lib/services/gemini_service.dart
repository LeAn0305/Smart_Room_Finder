import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smart_room_finder/models/room_model.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyAsk6SYycERwnD6V-e6obJtKiUXVInb53Y';
  static const String _modelName = 'gemini-1.5-flash-8b';

  static ChatSession? _chatSession;

  // Tạo model mới mỗi lần — tránh cache model cũ
  static GenerativeModel _createModel() {
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );
  }

  // ── 1. Chatbot tư vấn phòng trọ ─────────────────────────
  // Khởi tạo chat session mới với context về app
  static ChatSession startRoomAdvisorChat(List<RoomModel> availableRooms) {
    final roomSummary = availableRooms.take(20).map((r) =>
      '- ${r.title}: ${r.typeString}, ${(r.price/1000000).toStringAsFixed(1)}tr/tháng, '
      '${r.area.toInt()}m², ${r.address}, tiện ích: ${r.amenities.take(3).join(", ")}'
    ).join('\n');

    _chatSession = _createModel().startChat(history: [
      Content.text(
        'Bạn là trợ lý tư vấn phòng trọ thông minh của ứng dụng Smart Room Finder. '
        'Nhiệm vụ của bạn là giúp người dùng tìm phòng phù hợp dựa trên nhu cầu của họ. '
        'Hãy trả lời bằng tiếng Việt, thân thiện và ngắn gọn.\n\n'
        'Danh sách phòng hiện có:\n$roomSummary\n\n'
        'Khi gợi ý phòng, hãy đề cập tên phòng cụ thể từ danh sách trên.',
      ),
      Content.model([TextPart(
        'Xin chào! Tôi là trợ lý tư vấn phòng trọ của Smart Room Finder. '
        'Tôi có thể giúp bạn tìm phòng phù hợp với nhu cầu và ngân sách. '
        'Bạn đang tìm phòng ở khu vực nào và ngân sách của bạn là bao nhiêu?'
      )]),
    ]);
    return _chatSession!;
  }

  static Future<String> sendChatMessage(String message) async {
    if (_chatSession == null) {
      return 'Vui lòng khởi tạo chat trước.';
    }
    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'Không có phản hồi.';
    } catch (e) {
      return 'Lỗi kết nối AI: $e';
    }
  }

  // ── 2. Tìm kiếm thông minh ───────────────────────────────
  // Phân tích câu mô tả tự nhiên → trả về filter criteria
  static Future<Map<String, dynamic>> parseSearchQuery(
      String naturalQuery) async {
    try {
      final prompt = '''
Phân tích yêu cầu tìm phòng sau và trả về JSON với các trường:
- maxPrice: số tiền tối đa (VND), null nếu không đề cập
- minArea: diện tích tối thiểu (m²), null nếu không đề cập  
- location: khu vực/quận, null nếu không đề cập
- roomType: "Phòng trọ" | "Chung cư" | "Nhà riêng" | "Biệt thự" | null
- amenities: mảng tiện ích cần có (Wifi, Máy lạnh, Tủ lạnh, Máy giặt, Bếp, Chỗ để xe)
- keywords: từ khóa tìm kiếm thêm

Yêu cầu: "$naturalQuery"

Chỉ trả về JSON thuần, không có markdown hay giải thích.
Ví dụ: {"maxPrice":5000000,"minArea":20,"location":"Quận 1","roomType":"Phòng trọ","amenities":["Wifi"],"keywords":"gần trường"}
''';

      final response = await _createModel().generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';

      // Parse JSON từ response
      final jsonStr = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Dùng dart:convert để parse
      return _parseJson(jsonStr);
    } catch (e) {
      return {};
    }
  }

  static Map<String, dynamic> _parseJson(String jsonStr) {
    try {
      // Simple manual parse để tránh import dart:convert gây vấn đề
      final result = <String, dynamic>{};

      // Extract maxPrice
      final priceMatch = RegExp(r'"maxPrice"\s*:\s*(\d+|null)').firstMatch(jsonStr);
      if (priceMatch != null && priceMatch.group(1) != 'null') {
        result['maxPrice'] = int.tryParse(priceMatch.group(1)!);
      }

      // Extract minArea
      final areaMatch = RegExp(r'"minArea"\s*:\s*(\d+|null)').firstMatch(jsonStr);
      if (areaMatch != null && areaMatch.group(1) != 'null') {
        result['minArea'] = int.tryParse(areaMatch.group(1)!);
      }

      // Extract location
      final locMatch = RegExp(r'"location"\s*:\s*"([^"]*)"').firstMatch(jsonStr);
      if (locMatch != null) result['location'] = locMatch.group(1);

      // Extract roomType
      final typeMatch = RegExp(r'"roomType"\s*:\s*"([^"]*)"').firstMatch(jsonStr);
      if (typeMatch != null) result['roomType'] = typeMatch.group(1);

      // Extract keywords
      final kwMatch = RegExp(r'"keywords"\s*:\s*"([^"]*)"').firstMatch(jsonStr);
      if (kwMatch != null) result['keywords'] = kwMatch.group(1);

      // Extract amenities array
      final amenMatch = RegExp(r'"amenities"\s*:\s*\[([^\]]*)\]').firstMatch(jsonStr);
      if (amenMatch != null) {
        final amenStr = amenMatch.group(1)!;
        final amenities = RegExp(r'"([^"]+)"')
            .allMatches(amenStr)
            .map((m) => m.group(1)!)
            .toList();
        result['amenities'] = amenities;
      }

      return result;
    } catch (_) {
      return {};
    }
  }

  // ── 3. Tự động viết mô tả phòng ─────────────────────────
  static Future<String> generateRoomDescription({
    required String title,
    required String roomType,
    required double price,
    required double area,
    required String address,
    required List<String> amenities,
    int? bedrooms,
  }) async {
    try {
      final amenStr = amenities.isEmpty ? 'không có tiện ích đặc biệt' : amenities.join(', ');
      final bedroomStr = (bedrooms != null && bedrooms > 0) ? '$bedrooms phòng ngủ' : '';

      final prompt = '''
Viết mô tả hấp dẫn cho phòng trọ sau bằng tiếng Việt (2-3 câu, tự nhiên, không dùng emoji):
- Tên: $title
- Loại: $roomType  
- Giá: ${(price/1000000).toStringAsFixed(1)} triệu/tháng
- Diện tích: ${area.toInt()}m² $bedroomStr
- Địa chỉ: $address
- Tiện ích: $amenStr

Chỉ trả về đoạn mô tả, không có tiêu đề hay giải thích thêm.
''';

      final response = await _createModel().generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? '';
    } catch (e) {
      return '';
    }
  }

  // ── 4. Hỗ trợ khách hàng ────────────────────────────────
  static Future<String> answerFAQ(String question) async {
    try {
      final prompt = '''
Bạn là nhân viên hỗ trợ của ứng dụng Smart Room Finder - ứng dụng tìm phòng trọ tại TP.HCM.
Trả lời câu hỏi sau bằng tiếng Việt, ngắn gọn (tối đa 3 câu), thân thiện:

Câu hỏi: $question

Thông tin về app:
- Tìm phòng trọ, chung cư, nhà riêng tại TP.HCM
- Người thuê có thể gửi đơn yêu cầu thuê phòng
- Chủ trọ có thể đăng phòng và quản lý đơn
- Có tính năng chat trực tiếp với chủ nhà
- Hỗ trợ lọc theo giá, khu vực, diện tích, tiện ích
''';

      final response = await _createModel().generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Xin lỗi, tôi không thể trả lời câu hỏi này lúc này.';
    } catch (e) {
      return 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau.';
    }
  }

  // ── Lọc phòng theo kết quả AI ───────────────────────────
  static List<RoomModel> filterRoomsByAI(
      List<RoomModel> rooms, Map<String, dynamic> criteria) {
    var result = rooms;

    final maxPrice = criteria['maxPrice'] as int?;
    if (maxPrice != null) {
      result = result.where((r) => r.price <= maxPrice).toList();
    }

    final minArea = criteria['minArea'] as int?;
    if (minArea != null) {
      result = result.where((r) => r.area >= minArea).toList();
    }

    final location = criteria['location'] as String?;
    if (location != null && location.isNotEmpty) {
      result = result.where((r) =>
        r.address.toLowerCase().contains(location.toLowerCase()) ||
        r.location.toLowerCase().contains(location.toLowerCase())
      ).toList();
    }

    final roomType = criteria['roomType'] as String?;
    if (roomType != null && roomType.isNotEmpty) {
      final typeMap = {
        'Phòng trọ': RoomType.studio,
        'Chung cư': RoomType.apartment,
        'Nhà riêng': RoomType.house,
        'Biệt thự': RoomType.villa,
      };
      final type = typeMap[roomType];
      if (type != null) {
        result = result.where((r) => r.type == type).toList();
      }
    }

    final amenities = criteria['amenities'] as List?;
    if (amenities != null && amenities.isNotEmpty) {
      result = result.where((r) {
        return amenities.every((a) =>
          r.amenities.any((ra) =>
            ra.toLowerCase().contains(a.toString().toLowerCase())));
      }).toList();
    }

    final keywords = criteria['keywords'] as String?;
    if (keywords != null && keywords.isNotEmpty) {
      result = result.where((r) =>
        r.title.toLowerCase().contains(keywords.toLowerCase()) ||
        r.description.toLowerCase().contains(keywords.toLowerCase()) ||
        r.address.toLowerCase().contains(keywords.toLowerCase())
      ).toList();
    }

    return result;
  }
}
