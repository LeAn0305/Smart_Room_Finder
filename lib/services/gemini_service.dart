import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smart_room_finder/core/config/gemini_config.dart';
import 'package:smart_room_finder/models/room_model.dart';

class GeminiService {
  static const String _apiKey = GeminiConfig.apiKey;
  static const String _modelName = 'gemini-2.5-flash';

  static bool get _isKeyValid {
    return _apiKey.isNotEmpty && _apiKey != 'YOUR_GEMINI_API_KEY_HERE';
  }

  static ChatSession? _chatSession;
  static List<RoomModel> _allAvailableRooms = [];
  static List<RoomModel> _lastSuggestedRooms = [];
  static List<RoomModel> get lastSuggestedRooms => _lastSuggestedRooms;

  // Tạo model mới mỗi lần — tránh cache model cũ
  static GenerativeModel _createModel() {
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2048,
      ),
    );
  }

  // ── 1. Chatbot tư vấn phòng trọ ─────────────────────────
  // Khởi tạo chat session mới với context về app
  static ChatSession startRoomAdvisorChat(List<RoomModel> availableRooms) {
    _allAvailableRooms = availableRooms;
    _lastSuggestedRooms = [];
    final roomSummary = availableRooms
        .take(10)
        .map(
          (r) =>
              '- ${r.title}: ${r.typeString}, ${(r.price / 1000000).toStringAsFixed(1)}tr/tháng, '
              '${r.area.toInt()}m², ${r.address}, tiện ích: ${r.amenities.take(3).join(", ")}',
        )
        .join('\n');

    _chatSession = _createModel().startChat(
      history: [
        Content.text(
          'Bạn là trợ lý tư vấn phòng trọ thông minh của ứng dụng Smart Room Finder. '
          'Nhiệm vụ của bạn là giúp người dùng tìm phòng phù hợp dựa trên nhu cầu của họ. '
          'Hãy trả lời bằng tiếng Việt, thân thiện và ngắn gọn.\n\n'
          'Danh sách phòng hiện có:\n$roomSummary\n\n'
          'Khi gợi ý phòng, hãy đề cập tên phòng cụ thể từ danh sách trên.',
        ),
        Content.model([
          TextPart(
            'Xin chào! Tôi là trợ lý tư vấn phòng trọ của Smart Room Finder. '
            'Tôi có thể giúp bạn tìm phòng phù hợp với nhu cầu và ngân sách. '
            'Bạn đang tìm phòng ở khu vực nào và ngân sách của bạn là bao nhiêu?',
          ),
        ]),
      ],
    );
    return _chatSession!;
  }

  static Future<String> sendChatMessage(String message) async {
    _lastSuggestedRooms = [];

    final securityResponse = _checkSecurityIssues(message);
    if (securityResponse != null) {
      return securityResponse;
    }

    // 1. Thử parse local trước cho các câu tìm phòng đơn giản để tiết kiệm quota
    final localCriteria = _tryLocalParseSearchQuery(message);
    if (localCriteria != null) {
      final filtered = filterRoomsByAI(_allAvailableRooms, localCriteria);
      if (filtered.isNotEmpty) {
        _lastSuggestedRooms = filtered.take(3).toList();
        final count = _lastSuggestedRooms.length;
        return 'Tôi tìm thấy $count phòng phù hợp nhất với tiêu chí của bạn dưới đây:';
      } else {
        final location = localCriteria['location'] as String?;
        if (location != null && location.isNotEmpty) {
          final roomsInLocation = filterRoomsByAI(_allAvailableRooms, {'location': location});
          if (roomsInLocation.isEmpty) {
            return 'Tôi chưa tìm thấy phòng phù hợp với khu vực này. Bạn có thể thử nhập tên quận/khu vực khác hoặc nới rộng phạm vi tìm kiếm nhé.';
          }
        }
        return 'Tôi chưa tìm thấy phòng phù hợp với điều kiện này. Bạn có thể thử nới rộng mức giá, khu vực hoặc tiện ích nhé.';
      }
    }

    final localResponse = _checkLocalFallbackAndTopic(message);
    if (localResponse != null) {
      return localResponse;
    }

    // Phân tích ý định tìm kiếm bằng Gemini (cho các câu phức tạp)
    try {
      final criteria = await parseSearchQuery(message);
      final hasSearchCriteria = criteria.containsKey('maxPrice') ||
          criteria.containsKey('minPrice') ||
          criteria.containsKey('minArea') ||
          criteria.containsKey('location') ||
          criteria.containsKey('roomType') ||
          (criteria.containsKey('amenities') && (criteria['amenities'] as List).isNotEmpty) ||
          (criteria.containsKey('keywords') && (criteria['keywords'] as String).isNotEmpty);

      if (hasSearchCriteria) {
        final filtered = filterRoomsByAI(_allAvailableRooms, criteria);
        if (filtered.isNotEmpty) {
          _lastSuggestedRooms = filtered.take(3).toList();
          final count = _lastSuggestedRooms.length;
          return 'Tôi tìm thấy $count phòng phù hợp nhất với tiêu chí của bạn dưới đây:';
        } else {
          final location = criteria['location'] as String?;
          if (location != null && location.isNotEmpty) {
            final roomsInLocation = filterRoomsByAI(_allAvailableRooms, {'location': location});
            if (roomsInLocation.isEmpty) {
              return 'Tôi chưa tìm thấy phòng phù hợp với khu vực này. Bạn có thể thử nhập tên quận/khu vực khác hoặc nới rộng phạm vi tìm kiếm nhé.';
            }
          }
          return 'Tôi chưa tìm thấy phòng phù hợp với điều kiện này. Bạn có thể thử nới rộng mức giá, khu vực hoặc tiện ích nhé.';
        }
      }
    } catch (e) {
      // Nếu parse lỗi thì tiếp tục gọi Gemini trả lời tự do
    }

    if (!_isKeyValid) {
      return 'Trợ lý AI chưa được cấu hình API Key chính xác. Vui lòng cập nhật API key trong file lib/core/config/gemini_config.dart.';
    }
    if (_chatSession == null) {
      return 'Vui lòng khởi tạo chat trước.';
    }
    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'Không có phản hồi.';
    } catch (e) {
      return _formatFriendlyError(e);
    }
  }

  // ── 2. Tìm kiếm thông minh ───────────────────────────────
  // Phân tích câu mô tả tự nhiên → trả về filter criteria
  static Future<Map<String, dynamic>> parseSearchQuery(
    String naturalQuery,
  ) async {
    if (!_isKeyValid) {
      return {};
    }
    try {
      final prompt =
          '''
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

      final response = await _createModel().generateContent([
        Content.text(prompt),
      ]);
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
      final priceMatch = RegExp(
        r'"maxPrice"\s*:\s*(\d+|null)',
      ).firstMatch(jsonStr);
      if (priceMatch != null && priceMatch.group(1) != 'null') {
        result['maxPrice'] = int.tryParse(priceMatch.group(1)!);
      }

      // Extract minArea
      final areaMatch = RegExp(
        r'"minArea"\s*:\s*(\d+|null)',
      ).firstMatch(jsonStr);
      if (areaMatch != null && areaMatch.group(1) != 'null') {
        result['minArea'] = int.tryParse(areaMatch.group(1)!);
      }

      // Extract location
      final locMatch = RegExp(
        r'"location"\s*:\s*"([^"]*)"',
      ).firstMatch(jsonStr);
      if (locMatch != null) result['location'] = locMatch.group(1);

      // Extract roomType
      final typeMatch = RegExp(
        r'"roomType"\s*:\s*"([^"]*)"',
      ).firstMatch(jsonStr);
      if (typeMatch != null) result['roomType'] = typeMatch.group(1);

      // Extract keywords
      final kwMatch = RegExp(r'"keywords"\s*:\s*"([^"]*)"').firstMatch(jsonStr);
      if (kwMatch != null) result['keywords'] = kwMatch.group(1);

      // Extract amenities array
      final amenMatch = RegExp(
        r'"amenities"\s*:\s*\[([^\]]*)\]',
      ).firstMatch(jsonStr);
      if (amenMatch != null) {
        final amenStr = amenMatch.group(1)!;
        final amenities = RegExp(
          r'"([^"]+)"',
        ).allMatches(amenStr).map((m) => m.group(1)!).toList();
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
    if (!_isKeyValid) {
      return 'Chưa cấu hình API Key chính xác cho Trợ lý AI trong file gemini_config.dart.';
    }
    try {
      final amenStr = amenities.isEmpty
          ? 'không có tiện ích đặc biệt'
          : amenities.join(', ');
      final bedroomStr = (bedrooms != null && bedrooms > 0)
          ? '$bedrooms phòng ngủ'
          : '';

      final prompt =
          '''
Viết mô tả hấp dẫn cho phòng trọ sau bằng tiếng Việt (2-3 câu, tự nhiên, không dùng emoji):
- Tên: $title
- Loại: $roomType  
- Giá: ${(price / 1000000).toStringAsFixed(1)} triệu/tháng
- Diện tích: ${area.toInt()}m² $bedroomStr
- Địa chỉ: $address
- Tiện ích: $amenStr

Chỉ trả về đoạn mô tả, không có tiêu đề hay giải thích thêm.
''';

      final response = await _createModel().generateContent([
        Content.text(prompt),
      ]);
      return response.text?.trim() ?? '';
    } catch (e) {
      return 'Không thể tạo mô tả lúc này: ${_formatFriendlyError(e)}';
    }
  }

  // ── 4. Hỗ trợ khách hàng ────────────────────────────────
  static Future<String> answerFAQ(String question) async {
    final securityResponse = _checkSecurityIssues(question);
    if (securityResponse != null) {
      return securityResponse;
    }

    final localResponse = _checkLocalFallbackAndTopic(question);
    if (localResponse != null) {
      return localResponse;
    }

    if (!_isKeyValid) {
      return 'Chưa cấu hình API Key chính xác cho Hỏi đáp AI trong file gemini_config.dart.';
    }
    try {
      final prompt =
          '''
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

      final response = await _createModel().generateContent([
        Content.text(prompt),
      ]);
      return response.text?.trim() ??
          'Xin lỗi, tôi không thể trả lời câu hỏi này lúc này.';
    } catch (e) {
      return _formatFriendlyError(e);
    }
  }

  // ── Lọc phòng theo kết quả AI ───────────────────────────
  static List<RoomModel> filterRoomsByAI(
    List<RoomModel> rooms,
    Map<String, dynamic> criteria,
  ) {
    var result = rooms;

    final maxPrice = criteria['maxPrice'] as int?;
    if (maxPrice != null) {
      result = result.where((r) => r.price <= maxPrice).toList();
    }

    final minPrice = criteria['minPrice'] as int?;
    if (minPrice != null) {
      result = result.where((r) => r.price >= minPrice).toList();
    }

    final minArea = criteria['minArea'] as int?;
    if (minArea != null) {
      result = result.where((r) => r.area >= minArea).toList();
    }

    final location = criteria['location'] as String?;
    if (location != null && location.isNotEmpty) {
      result = result
          .where(
            (r) =>
                r.address.toLowerCase().contains(location.toLowerCase()) ||
                r.location.toLowerCase().contains(location.toLowerCase()),
          )
          .toList();
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
        return amenities.every(
          (a) => r.amenities.any(
            (ra) => ra.toLowerCase().contains(a.toString().toLowerCase()),
          ),
        );
      }).toList();
    }

    final keywords = criteria['keywords'] as String?;
    if (keywords != null && keywords.isNotEmpty) {
      result = result
          .where(
            (r) =>
                r.title.toLowerCase().contains(keywords.toLowerCase()) ||
                r.description.toLowerCase().contains(keywords.toLowerCase()) ||
                r.address.toLowerCase().contains(keywords.toLowerCase()),
          )
          .toList();
    }

    return result;
  }

  // ── Kiểm tra xem câu hỏi có phải intent tìm/thuê phòng không ─────────
  // Nếu đúng thì không được xử lý trong _checkLocalFallbackAndTopic()
  // mà phải để nhánh local parse / Gemini lọc phòng thật xử lý.
  static bool _isRoomSearchIntent(String cleanText) {
    final searchPhrases = [
      // Cụm tường minh (từ mục 1 & 2 cũ)
      'tìm phòng', 'tim phong', 'tìm trọ', 'tim tro',
      'kiếm phòng', 'kiem phong',
      // Cụm mở rộng (mục 3 — câu tự nhiên)
      'có phòng nào', 'co phong nao',
      'phòng nào', 'phong nao',
      'cho thuê', 'cho thue',
      'muốn thuê', 'muon thue',
      'tìm thuê', 'tim thue',
      'cần phòng', 'can phong',
      'phòng rẻ', 'phong re',
      // Cụm ngầm hiểu có intent tìm (dạng mô tả điều kiện)
      'phòng dưới', 'phong duoi',
      'phòng trên', 'phong tren',
      'phòng có', 'phong co',
      'phòng ở', 'phong o',
      'trọ ở', 'tro o',
      'phòng cho sinh viên', 'phong cho sinh vien',
      'phòng sinh viên', 'phong sinh vien',
      // Cụm giá rẻ/bình dân không có số — cần được lọc phòng thật
      'giá rẻ', 'gia re',
      'giá tốt', 'gia tot',
      'bình dân', 'binh dan',
      'tiết kiệm', 'tiet kiem',
      'rẻ không', 're khong',
      'rẻ hơn', 're hon',
    ];
    for (final phrase in searchPhrases) {
      if (cleanText.contains(phrase)) return true;
    }
    return false;
  }

  // ── Helper xử lý fallback local và lọc chủ đề ───────────────────
  static String? _checkLocalFallbackAndTopic(String text) {
    final cleanText = text.toLowerCase().trim();

    // Ưu tiên kiểm tra: nếu câu là intent tìm/thuê phòng thì KHÔNG xử lý
    // ở đây — chuyển xuống nhánh local parse / Gemini để lọc phòng thật.
    if (_isRoomSearchIntent(cleanText)) return null;

    // 1. Chào hỏi xã giao & câu giao tiếp thông thường ngắn
    if (cleanText.contains('cảm ơn') || cleanText.contains('cam on') || cleanText.contains('cám ơn') ||
        cleanText.contains('thanks') || cleanText.contains('thank you')) {
      return 'Không có gì nha. Bạn cần tìm phòng, đăng phòng hay liên hệ chủ trọ thì cứ hỏi tôi nhé.';
    }

    final helloRegex = RegExp(r'^(chào|helo|hello|hi|xin chào|chao|alo|hi bạn|hi ban|chào bạn|chao ban)');
    if (helloRegex.hasMatch(cleanText) && cleanText.length < 15) {
      return 'Xin chào, tôi là trợ lý AI của Smart Room Finder. Tôi có thể hỗ trợ bạn tìm phòng, đăng phòng, lọc phòng và liên hệ chủ trọ.';
    }

    if (cleanText == 'ok' || cleanText == 'oke' || cleanText == 'ok nha' || cleanText == 'được rồi' || 
        cleanText == 'duoc roi' || cleanText == 'okey' || cleanText.startsWith('ok ') || cleanText.startsWith('oke ')) {
      return 'Ok nha. Khi cần hỗ trợ tìm phòng hoặc sử dụng ứng dụng, bạn cứ nhắn tôi.';
    }

    if (cleanText.contains('tạm biệt') || cleanText.contains('tam biet') || cleanText.contains('bye')) {
      return 'Tạm biệt nha. Chúc bạn sớm tìm được phòng phù hợp.';
    }

    // 2. Hướng dẫn sử dụng tính năng của ứng dụng
    // Lưu ý: chỉ xử lý các câu hỏi về UI/tính năng app,
    // KHÔNG xử lý các câu có intent tìm phòng (đã guard ở trên).
    if (cleanText.contains('đăng phòng') || cleanText.contains('dang phong') || cleanText.contains('đăng tin') || cleanText.contains('dang tin')) {
      return 'Để đăng phòng mới, bạn hãy vào mục **Cá nhân** (tab cuối cùng bên phải) -> Chọn **Phòng trọ của tôi** -> Bấm nút **[+]** ở góc trên để điền thông tin phòng và đăng tải.';
    }
    if (cleanText.contains('lọc phòng') || cleanText.contains('loc phong') || cleanText.contains('bộ lọc') || cleanText.contains('bo loc')) {
      return 'Ứng dụng hỗ trợ bộ lọc nâng cao tại màn hình chính. Bạn hãy bấm vào **biểu tượng bộ lọc (icon bộ lọc)** ở góc phải thanh tìm kiếm phía trên để lọc phòng theo Giá cả, Diện tích, Tiện ích, Khu vực.';
    }
    if (cleanText.contains('yêu thích') || cleanText.contains('yeu thich') || cleanText.contains('lưu phòng') || cleanText.contains('luu phong') || cleanText.contains('thả tim') || cleanText.contains('tha tim')) {
      return 'Để lưu phòng trọ yêu thích, bạn chỉ cần bấm vào **biểu tượng Trái tim** trên thẻ phòng hoặc trang chi tiết. Các phòng đã lưu sẽ hiển thị trong mục **Yêu thích** để bạn dễ dàng xem lại bất cứ lúc nào.';
    }
    if (cleanText.contains('báo cáo phòng') || cleanText.contains('bao cao phong') || cleanText.contains('báo cáo vi phạm') || cleanText.contains('bao cao vi pham')) {
      return 'Nếu phát hiện phòng trọ có thông tin sai lệch hoặc lừa đảo, bạn hãy vào trang chi tiết phòng trọ đó, cuộn xuống dưới cùng và chọn nút **Báo cáo phòng trọ** để gửi phản hồi cho Admin xử lý.';
    }
    if (cleanText.contains('liên hệ chủ trọ') || cleanText.contains('lien he chu tro') || cleanText.contains('chat chủ trọ') || cleanText.contains('chat chu tro') || cleanText.contains('nhắn tin') || cleanText.contains('nhan tin') || cleanText.contains('gọi điện') || cleanText.contains('goi dien')) {
      return 'Bạn có thể liên hệ trực tiếp với chủ trọ bằng cách vào trang chi tiết phòng trọ đó, bấm nút **Nhắn tin** để chat trực tiếp trong app, hoặc bấm nút **Gọi điện** để liên lạc trực tiếp qua số điện thoại của chủ nhà.';
    }
    if (cleanText.contains('đặt lịch') || cleanText.contains('dat lich') || cleanText.contains('gửi đơn thuê') || cleanText.contains('gui don thue') || cleanText.contains('yêu cầu thuê') || cleanText.contains('yeu cau thue')) {
      return 'Để gửi yêu cầu thuê phòng, bạn hãy bấm vào chi tiết phòng trọ đó, chọn **Gửi đơn thuê phòng**, điền đầy đủ thông tin cá nhân và ngày dự kiến dọn vào để gửi đến chủ trọ xét duyệt.';
    }

    // Kiểm tra chủ đề lạc đề
    final allowedKeywords = [
      'phòng', 'phong', 'trọ', 'tro', 'nhà', 'nha', 'chung cư', 'chung cu', 'căn hộ', 'can ho', 'thuê', 'thue',
      'chủ', 'chu', 'giá', 'gia', 'triệu', 'trieu', 'tr/tháng', 'tr/thang', 'diện tích', 'dien tich', 'm²', 'm2',
      'quận', 'quan', 'hcm', 'sài gòn', 'sai gon', 'thành phố', 'thanh pho', 'địa chỉ', 'dia chi', 'bản đồ', 'ban do',
      'vị trí', 'vi tri', 'tiện ích', 'tien ich', 'wifi', 'máy lạnh', 'may lanh', 'tủ lạnh', 'tu lanh', 'máy giặt', 'may giat',
      'bếp', 'bep', 'chỗ để xe', 'cho de xe', 'đăng', 'dang', 'lọc', 'loc', 'yêu thích', 'yeu thich', 'báo cáo', 'bao cao',
      'liên hệ', 'lien he', 'chat', 'nhắn tin', 'nhan tin', 'gọi', 'goi', 'đặt lịch', 'dat lich', 'đơn thuê', 'don thue',
      'app', 'ứng dụng', 'ung dung', 'tài khoản', 'tai khoan', 'mật khẩu', 'mat khau', 'đăng ký', 'dang ky', 'đăng nhập', 'dang nhap',
      'lỗi', 'loi', 'hỗ trợ', 'ho tro', 'admin', 'chức năng', 'chuc nang', 'advisor', 'tư vấn', 'tu van', 'làm sao', 'lam sao',
      'thế nào', 'the nao', 'gợi ý', 'goi y', 'chào', 'hello', 'hi', 'bạn là ai', 'ban la ai', 'tên gì', 'ten gi'
    ];

    bool isRelated = false;
    for (final kw in allowedKeywords) {
      if (cleanText.contains(kw)) {
        isRelated = true;
        break;
      }
    }

    if (!isRelated) {
      return 'Tôi là trợ lý AI của Smart Room Finder nên sẽ tập trung hỗ trợ bạn về tìm phòng, đăng phòng, lọc phòng, liên hệ chủ trọ và sử dụng ứng dụng.';
    }

    return null;
  }

  // ── Helper định dạng lỗi thân thiện ──────────────────────────────
  static String _formatFriendlyError(dynamic e) {
    final errStr = e.toString().toLowerCase();
    
    if (errStr.contains('503') || 
        errStr.contains('unavailable') || 
        errStr.contains('overloaded') || 
        errStr.contains('high demand') ||
        errStr.contains('service unavailable') ||
        errStr.contains('resource temporarily unavailable')) {
      return 'Trợ lý AI đang hơi quá tải. Bạn thử lại sau ít phút nhé. Trong lúc đó, tôi vẫn có thể hỗ trợ các câu hỏi cơ bản về tìm phòng, đăng phòng và liên hệ chủ trọ.';
    }
    
    if (errStr.contains('429') || 
        errStr.contains('quota') || 
        errStr.contains('toomanyrequests') || 
        errStr.contains('free_tier_requests') || 
        errStr.contains('exceeded your current quota') ||
        errStr.contains('resource_exhausted') ||
        errStr.contains('limit exceeded')) {
      return 'Hôm nay trợ lý AI online đã đạt giới hạn miễn phí. Tôi vẫn có thể hỗ trợ bạn bằng chế độ cơ bản về tìm phòng, đăng phòng, lọc phòng và báo cáo phòng.';
    }
    
    return 'Xin lỗi, có lỗi kết nối đến máy chủ AI. Bạn vui lòng thử lại sau nhé.';
  }

  // ── Helper kiểm tra câu hỏi an ninh / nhạy cảm ───────────────────
  static String? _checkSecurityIssues(String text) {
    final cleanText = text.toLowerCase().trim();
    final securityKeywords = [
      'hack', 'tấn công', 'tan cong', 'bypass', 'exploit', 'khai thác lỗi', 'khai thac loi',
      'phá bảo mật', 'pha bao mat', 'bẻ khóa', 'be khoa', 'crack', 'đánh cắp dữ liệu', 'danh cap du lieu',
      'steal data', 'brute force', 'ddos', 'sql injection', 'phá khóa', 'pha khoa', 'xâm nhập', 'xam nhap',
      'lấy tài khoản', 'lay tai khoan', 'cướp tài khoản', 'cuop tai khoan'
    ];

    for (final kw in securityKeywords) {
      if (cleanText.contains(kw)) {
        return 'Tôi không thể hỗ trợ hành vi tấn công hoặc xâm nhập ứng dụng. Nếu bạn muốn kiểm thử bảo mật cho Smart Room Finder, tôi có thể gợi ý các bước kiểm tra an toàn như kiểm tra đăng nhập, phân quyền, Firebase Rules và bảo vệ API key.';
      }
    }
    return null;
  }

  // ── Helper phân tích câu tìm kiếm local đơn giản để tiết kiệm quota ───────
  static Map<String, dynamic>? _tryLocalParseSearchQuery(String message) {
    final cleanText = message.toLowerCase().trim();

    // Nhận diện intent tìm phòng — mở rộng thêm nhiều cách nói tự nhiên
    final isSearchQuery = cleanText.contains('tìm phòng') ||
                          cleanText.contains('tim phong') ||
                          cleanText.contains('tìm trọ') ||
                          cleanText.contains('tim tro') ||
                          cleanText.contains('kiếm phòng') ||
                          cleanText.contains('kiem phong') ||
                          cleanText.contains('phòng ở') ||
                          cleanText.contains('phong o') ||
                          cleanText.contains('trọ ở') ||
                          cleanText.contains('tro o') ||
                          // Các cụm tự nhiên bổ sung (mục 3)
                          cleanText.contains('có phòng nào') ||
                          cleanText.contains('co phong nao') ||
                          cleanText.contains('phòng nào') ||
                          cleanText.contains('phong nao') ||
                          cleanText.contains('cho thuê') ||
                          cleanText.contains('cho thue') ||
                          cleanText.contains('muốn thuê') ||
                          cleanText.contains('muon thue') ||
                          cleanText.contains('tìm thuê') ||
                          cleanText.contains('tim thue') ||
                          cleanText.contains('cần phòng') ||
                          cleanText.contains('can phong') ||
                          cleanText.contains('phòng rẻ') ||
                          cleanText.contains('phong re') ||
                          // Cụm giá rẻ/bình dân — chứa từ ghép, cần liệt kê riêng
                          // vì "phòng giá rẻ" không khớp "phòng rẻ" do có "giá" ở giữa
                          cleanText.contains('giá rẻ') ||
                          cleanText.contains('gia re') ||
                          cleanText.contains('giá tốt') ||
                          cleanText.contains('gia tot') ||
                          cleanText.contains('bình dân') ||
                          cleanText.contains('binh dan') ||
                          cleanText.contains('tiết kiệm') ||
                          cleanText.contains('tiet kiem') ||
                          // Cụm mô tả điều kiện không có động từ tìm
                          cleanText.contains('phòng dưới') ||
                          cleanText.contains('phong duoi') ||
                          cleanText.contains('phòng trên') ||
                          cleanText.contains('phong tren') ||
                          cleanText.contains('phòng có') ||
                          cleanText.contains('phong co') ||
                          cleanText.contains('phòng sinh viên') ||
                          cleanText.contains('phong sinh vien') ||
                          cleanText.contains('phòng cho sinh viên') ||
                          cleanText.contains('phong cho sinh vien');

    if (!isSearchQuery) return null;

    final criteria = <String, dynamic>{};
    bool detected = false;

    // 1. Lọc giá tối đa (dưới X triệu/tr)
    final maxPriceRegex = RegExp(r'(?:dưới|duoi)\s*(\d+(?:\.\d+)?)\s*(?:triệu|trieu|tr)\b');
    final maxPriceMatch = maxPriceRegex.firstMatch(cleanText);
    if (maxPriceMatch != null) {
      final value = double.tryParse(maxPriceMatch.group(1) ?? '');
      if (value != null) {
        criteria['maxPrice'] = (value * 1000000).toInt();
        detected = true;
      }
    }

    // 2. Lọc giá tối thiểu (trên X triệu/tr)
    final minPriceRegex = RegExp(r'(?:trên|tren)\s*(\d+(?:\.\d+)?)\s*(?:triệu|trieu|tr)\b');
    final minPriceMatch = minPriceRegex.firstMatch(cleanText);
    if (minPriceMatch != null) {
      final value = double.tryParse(minPriceMatch.group(1) ?? '');
      if (value != null) {
        criteria['minPrice'] = (value * 1000000).toInt();
        detected = true;
      }
    }

    // 3. Tiện ích (wifi, máy lạnh)
    final amenities = <String>[];
    if (cleanText.contains('wifi') || cleanText.contains('internet')) {
      amenities.add('wifi');
      detected = true;
    }
    if (cleanText.contains('máy lạnh') || cleanText.contains('may lanh') || cleanText.contains('điều hòa') || cleanText.contains('dieu hoa')) {
      amenities.add('máy lạnh');
      detected = true;
    }
    if (amenities.isNotEmpty) {
      criteria['amenities'] = amenities;
    }

    // 5. Nhận diện intent giá rẻ/bình dân không có số cụ thể
    // Map thành maxPrice mặc định 4.000.000 để lọc phòng thật
    if (!criteria.containsKey('maxPrice')) {
      final isCheapIntent = cleanText.contains('rẻ') ||
                            cleanText.contains('re ') ||
                            cleanText.contains(' re') ||
                            cleanText == 're' ||
                            cleanText.contains('bình dân') ||
                            cleanText.contains('binh dan') ||
                            cleanText.contains('tiết kiệm') ||
                            cleanText.contains('tiet kiem') ||
                            cleanText.contains('giá tốt') ||
                            cleanText.contains('gia tot') ||
                            cleanText.contains('phòng rẻ') ||
                            cleanText.contains('phong re') ||
                            cleanText.contains('giá rẻ') ||
                            cleanText.contains('gia re');
      if (isCheapIntent) {
        // Ngưỡng 4 triệu — bao phủ phần lớn phòng trọ, KTX, phòng sinh viên
        criteria['maxPrice'] = 4000000;
        detected = true;
      }
    }

    // 6. Địa điểm (quận 12, quận 9, Bình Thạnh, Gò Vấp, vv.)
    final districts = [
      'quận 12', 'quận 9', 'bình thạnh', 'gò vấp',
      'quan 12', 'quan 9', 'binh thanh', 'go vap',
      'quận 1', 'quận 2', 'quận 3', 'quận 4', 'quận 5', 'quận 6', 'quận 7', 'quận 8', 'quận 10', 'quận 11',
      'quan 1', 'quan 2', 'quan 3', 'quan 4', 'quan 5', 'quan 6', 'quan 7', 'quan 8', 'quan 10', 'quan 11',
      'phú nhuận', 'phu nhuan', 'tân bình', 'tan binh', 'tân phú', 'tan phu', 'thủ đức', 'thu duc',
      'bình tân', 'binh tan', 'hóc môn', 'hoc mon', 'nhà bè', 'nha be', 'củ chi', 'cu chi', 'bình chánh', 'binh chanh'
    ];

    String? foundLocation;
    for (final district in districts) {
      if (cleanText.contains(district)) {
        foundLocation = district;
        break;
      }
    }
    if (foundLocation != null) {
      String normalized = foundLocation;
      if (normalized == 'binh thanh' || normalized == 'bình thạnh') {
        normalized = 'Bình Thạnh';
      } else if (normalized == 'go vap' || normalized == 'gò vấp') {
        normalized = 'Gò Vấp';
      } else if (normalized == 'quan 9' || normalized == 'quận 9') {
        normalized = 'Quận 9';
      } else if (normalized == 'quan 12' || normalized == 'quận 12') {
        normalized = 'Quận 12';
      } else if (normalized.startsWith('quan ')) {
        normalized = normalized.replaceFirst('quan ', 'Quận ');
      } else if (normalized.startsWith('quận ')) {
        normalized = normalized.replaceFirst('quận ', 'Quận ');
      } else {
        normalized = normalized.split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
      }
      criteria['location'] = normalized;
      detected = true;
    } else {
      final hasLocationPhrase = cleanText.contains('ở khu vực') ||
                              cleanText.contains('o khu vuc') ||
                              cleanText.contains('khu vực') ||
                              cleanText.contains('khu vuc') ||
                              cleanText.contains('ở quận') ||
                              cleanText.contains('o quan') ||
                              cleanText.contains('quận') ||
                              cleanText.contains('quan') ||
                              cleanText.contains('phường') ||
                              cleanText.contains('phuong') ||
                              cleanText.contains('địa chỉ') ||
                              cleanText.contains('dia chi') ||
                              cleanText.contains('tại địa chỉ') ||
                              cleanText.contains('tai dia chi');
      if (hasLocationPhrase) {
        criteria['location'] = 'non_existent_location_placeholder';
        detected = true;
      }
    }

    return detected ? criteria : null;
  }
}
