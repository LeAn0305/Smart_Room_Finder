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

    final cleanText = message.toLowerCase().trim();

    // Xử lý câu tìm phòng gần đây (fallback an toàn)
    final nearKeywords = [
      'gần đây', 'gan day', 'gần tôi', 'gan toi', 'gần vị trí', 'gan vi tri',
      'gần đây nhất', 'gan day nhat', 'gần chỗ tôi', 'gan cho toi',
      'phòng gần đây', 'phong gan day', 'phòng gần tôi', 'phong gan toi'
    ];
    if (nearKeywords.any((kw) => cleanText.contains(kw))) {
      return 'Hiện tại mình chưa có vị trí chính xác của bạn trong khung chat. Bạn có thể tìm theo khu vực như Quận 12, Tân Bình, Thủ Đức hoặc dùng chức năng bản đồ/chỉ đường để xem phòng gần bạn.';
    }

    // Xử lý câu so sánh phòng
    if (cleanText.contains('so sánh') || cleanText.contains('so sanh')) {
      final compareResult = _tryCompareRooms(message);
      if (compareResult != null) {
        return compareResult;
      }
      return 'Bạn hãy gửi tên 2 phòng cụ thể hoặc mở từng phòng để xem chi tiết. Mình có thể hỗ trợ so sánh theo giá, khu vực và tiện ích.';
    }

    // 1. Thử parse local trước cho các câu tìm phòng đơn giản để tiết kiệm quota
    final localCriteria = _tryLocalParseSearchQuery(message);

    if (localCriteria != null) {
      // Nhận diện và xử lý yêu cầu gợi ý phòng tốt nhất tại local
      if (localCriteria['best'] == true) {
        List<RoomModel> candidateRooms = _allAvailableRooms;
        final tempCriteria = Map<String, dynamic>.from(localCriteria)..remove('best');
        if (tempCriteria.isNotEmpty) {
          candidateRooms = filterRoomsByAI(candidateRooms, tempCriteria);
        }
        final sortedRooms = _getBestRooms(candidateRooms);
        _lastSuggestedRooms = sortedRooms;
        final count = _lastSuggestedRooms.length;
        if (count == 0) {
          return 'Hiện tại mình chưa có danh sách phòng để đánh giá phòng tốt nhất.';
        }
        return 'Mình gợi ý các phòng nổi bật dựa trên giá, tiện ích và thông tin hiện có.';
      }

      final isCheapOrStudent = localCriteria['cheap'] == true || localCriteria['student'] == true;

      // Với cheap/student intent: xử lý riêng, không dùng maxPrice để filter cứng
      if (isCheapOrStudent) {
        // Lấy criteria không có maxPrice/cheap/student (chỉ giữ location nếu có)
        // KHÔNG giữ amenities cho cheap intent vì amenities hay bị parse sai
        final cheapCriteria = <String, dynamic>{};
        final loc = localCriteria['location'] as String?;
        if (loc != null && loc.isNotEmpty) {
          cheapCriteria['location'] = loc;
        }

        // Lọc theo location trước (nếu có), sau đó sort giá tăng dần
        var candidateRooms = filterRoomsByAI(_allAvailableRooms, cheapCriteria);
        candidateRooms = candidateRooms.where((r) => r.price > 0).toList();
        candidateRooms.sort((a, b) => a.price.compareTo(b.price));

        if (candidateRooms.isNotEmpty) {
          final priceLimit = localCriteria['cheap'] == true ? 3000000.0 : 3500000.0;
          final cheapOnes = candidateRooms.where((r) => r.price <= priceLimit).toList();

          if (cheapOnes.isNotEmpty) {
            _lastSuggestedRooms = cheapOnes.take(3).toList();
            return 'Tôi tìm thấy ${_lastSuggestedRooms.length} phòng phù hợp nhất với tiêu chí của bạn dưới đây:';
          } else {
            _lastSuggestedRooms = candidateRooms.take(3).toList();
            final hasLocation = loc != null && loc.isNotEmpty;
            if (hasLocation) {
              return 'Đây là các phòng giá thấp nhất hiện có ở $loc:';
            }
            return 'Đây là các phòng giá thấp nhất hiện có:';
          }
        }

        // Không có phòng nào → báo rõ
        final hasLocation = loc != null && loc.isNotEmpty;
        if (hasLocation) {
          return 'Tôi chưa tìm thấy phòng phù hợp với khu vực này. Bạn có thể thử nhập tên quận/khu vực khác nhé.';
        }
        return 'Tôi chưa tìm thấy phòng phù hợp. Bạn có thể nới rộng tiêu chí tìm kiếm nhé.';
      }

      // Không phải cheap/student → filter bình thường
      final filtered = filterRoomsByAI(_allAvailableRooms, localCriteria);
      if (filtered.isNotEmpty) {
        _lastSuggestedRooms = filtered.where((r) => r.price > 0).take(3).toList();
        final count = _lastSuggestedRooms.length;
        if (count > 0) {
          return 'Tôi tìm thấy $count phòng phù hợp nhất với tiêu chí của bạn dưới đây:';
        }
      }

      final location = localCriteria['location'] as String?;
      if (location != null && location.isNotEmpty) {
        final roomsInLocation = filterRoomsByAI(_allAvailableRooms, {'location': location});
        if (roomsInLocation.isEmpty) {
          return 'Tôi chưa tìm thấy phòng phù hợp với khu vực này. Bạn có thể thử nhập tên quận/khu vực khác hoặc nới rộng phạm vi tìm kiếm nhé.';
        }
      }
      return 'Tôi chưa tìm thấy phòng phù hợp với điều kiện này. Bạn có thể thử nới rộng mức giá, khu vực hoặc tiện ích nhé.';
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
      // Chuẩn hóa các trường có thể rỗng hoặc bằng 0
      final priceStr = price > 0
          ? '${(price / 1000000).toStringAsFixed(1)} triệu/tháng'
          : 'chưa xác định';
      final areaStr = area > 0 ? '${area.toInt()}m²' : '';
      final bedStr  = (bedrooms != null && bedrooms > 0) ? '$bedrooms phòng ngủ' : '';
      final addrStr = address.trim().isNotEmpty ? address.trim() : 'khu vực TP. Hồ Chí Minh';
      final detailParts = [areaStr, bedStr].where((s) => s.isNotEmpty).join(', ');
      // Chỉ truyền tối đa 3 tiện ích vào prompt để tránh mô tả liệt kê dài
      final amenPreview = amenities.take(3).toList();
      final amenLine = amenPreview.isEmpty ? '' : '- Tiện ích có sẵn: ${amenPreview.join(', ')}';

      // Kiểm tra title có phải dữ liệu test/tào lao không
      final titleIsSuspicious = _isSuspiciousRoomTitle(title);
      // Nếu title bình thường thì đưa vào prompt, ngược lại bỏ qua để AI không diễn giải sai
      final titleLine = titleIsSuspicious
          ? ''
          : '- Tên / tiêu đề: $title';

      final prompt = '''
Hãy viết mô tả đăng tin cho thuê phòng bằng tiếng Việt, giọng văn tự nhiên và thực tế.

Thông tin phòng:
${titleLine.isNotEmpty ? '$titleLine\n' : ''}- Loại: $roomType${detailParts.isNotEmpty ? '\n- Diện tích / phòng ngủ: $detailParts' : ''}
- Giá thuê: $priceStr
- Địa chỉ / khu vực: $addrStr
${amenLine.isNotEmpty ? amenLine : ''}

Yêu cầu bắt buộc:
1. Chỉ dùng đúng các thông tin được cung cấp. Không tự bịa thêm tiện ích, vị trí, ưu điểm không có trong dữ liệu.
2. Không dùng phong cách quảng cáo cường điệu: tránh "đẳng cấp tuyệt đối", "thiên đường", "có một không hai", "trải nghiệm độc đáo", "không gian sống hoàn hảo".
3. Không tự khẳng định "gần trường", "gần chợ", "an ninh tốt", "đầy đủ nội thất" nếu dữ liệu không đề cập.
4. Viết 2–4 câu ngắn, rõ ràng, thân thiện. Phù hợp hiển thị trên ứng dụng tìm phòng trọ.
5. Nếu tên phòng có nội dung không liên quan đến việc cho thuê phòng (ví dụ: "ngoài vũ trụ", "có người yêu", test, demo) thì tuyệt đối bỏ qua tên phòng và viết mô tả trung tính dựa trên giá, khu vực, loại phòng và tiện ích.
6. Không đặt tên phòng trong dấu ngoặc kép (ví dụ tránh viết: phòng "Tên phòng...").
7. Câu "Vui lòng liên hệ..." chỉ dùng khi dữ liệu quá thiếu; nếu đã có đủ thông tin thì không cần câu này.
8. Nếu có tiện ích, nhắc tự nhiên tối đa 2–3 tiện ích trong mô tả, không liệt kê dạng bullet.
9. Không dùng emoji. Không có tiêu đề hay giải thích thêm. Chỉ trả về đoạn mô tả thuần văn bản.
''';

      // Bọc request Gemini bằng timeout 18 giây
      final response = await _createModel().generateContent([
        Content.text(prompt),
      ]).timeout(const Duration(seconds: 18));

      final text = response.text?.trim() ?? '';
      // Nếu Gemini trả rỗng thì dùng fallback local
      if (text.isEmpty) {
        return _generateLocalRoomDescriptionFallback(
          title: title, price: price, address: address,
          roomType: roomType, bedrooms: bedrooms ?? 0,
          area: area, amenities: amenities,
        );
      }
      return text;
    } catch (_) {
      // Mọi lỗi (quota, 429, 503, timeout, network...) → fallback local
      // Không đổ câu lỗi kỹ thuật vào ô mô tả
      return _generateLocalRoomDescriptionFallback(
        title: title, price: price, address: address,
        roomType: roomType, bedrooms: bedrooms ?? 0,
        area: area, amenities: amenities,
      );
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
    // Loại bỏ phòng có giá không hợp lệ trước khi lọc theo tiêu chí
    var result = rooms.where((r) => r.price >= 100000).toList();

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
          (a) {
            final cleanA = _removeDiacritics(a.toString().toLowerCase().trim());
            if (cleanA.isEmpty) return true;

            // 1. Kiểm tra trong room.amenities (không dấu)
            final inAmenities = r.amenities.any(
              (ra) => _removeDiacritics(ra.toLowerCase()).contains(cleanA),
            );
            if (inAmenities) return true;

            // 2. Kiểm tra trong room.title/name (không dấu)
            final inTitle = _removeDiacritics(r.title.toLowerCase()).contains(cleanA);
            if (inTitle) return true;

            // 3. Kiểm tra trong room.description (không dấu)
            final inDesc = _removeDiacritics(r.description.toLowerCase()).contains(cleanA);
            if (inDesc) return true;

            // 4. Kiểm tra trong room.address hoặc room.location (không dấu)
            final inAddress = _removeDiacritics(r.address.toLowerCase()).contains(cleanA) ||
                             _removeDiacritics(r.location.toLowerCase()).contains(cleanA);
            if (inAddress) return true;

            return false;
          },
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
      // Các cụm tự nhiên bổ sung về mong muốn tìm phòng
      'tớ muốn có phòng', 'to muon co phong',
      'tôi muốn có phòng', 'toi muon co phong',
      'tớ muốn phòng', 'to muon phong',
      'tôi muốn phòng', 'toi muon phong',
      'muốn có phòng', 'muon co phong',
      'muốn phòng', 'muon phong',
      // Cụm từ phòng tốt nhất
      'tốt nhất', 'tot nhat',
      'tốt nhứt', 'tot nhut',
      'phòng tốt', 'phong tot',
      'gợi ý phòng tốt', 'goi y phong tot',
      'nổi bật', 'noi bat',
      'đáng thuê', 'dang thue',
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
                          // Các cụm tự nhiên bổ sung về mong muốn tìm phòng
                          cleanText.contains('tớ muốn có phòng') ||
                          cleanText.contains('to muon co phong') ||
                          cleanText.contains('tôi muốn có phòng') ||
                          cleanText.contains('toi muon co phong') ||
                          cleanText.contains('tớ muốn phòng') ||
                          cleanText.contains('to muon phong') ||
                          cleanText.contains('tôi muốn phòng') ||
                          cleanText.contains('toi muon phong') ||
                          cleanText.contains('muốn có phòng') ||
                          cleanText.contains('muon co phong') ||
                          cleanText.contains('muốn phòng') ||
                          cleanText.contains('muon phong') ||
                          // Cụm từ phòng tốt nhất
                          cleanText.contains('tốt nhất') ||
                          cleanText.contains('tot nhat') ||
                          cleanText.contains('phòng tốt') ||
                          cleanText.contains('phong tot') ||
                          cleanText.contains('nổi bật') ||
                          cleanText.contains('noi bat') ||
                          cleanText.contains('đáng thuê') ||
                          cleanText.contains('dang thue') ||
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
                          cleanText.contains('phong cho sinh vien') ||
                          _hasCheapIntent(cleanText) ||
                          _hasStudentIntent(cleanText);

    if (!isSearchQuery) return null;

    final criteria = <String, dynamic>{};
    bool detected = false;

    // Nhận diện câu hỏi về phòng tốt nhất / nổi bật nhất / đáng thuê nhất (để xử lý local)
    final isBestQuery = cleanText.contains('tốt nhất') ||
                        cleanText.contains('tot nhat') ||
                        cleanText.contains('nổi bật nhất') ||
                        cleanText.contains('noi bat nhat') ||
                        cleanText.contains('đáng thuê nhất') ||
                        cleanText.contains('dang thue nhat') ||
                        cleanText.contains('phòng tốt') ||
                        cleanText.contains('phong tot') ||
                        cleanText.contains('phòng nổi bật') ||
                        cleanText.contains('phong noi bat') ||
                        cleanText.contains('gợi ý phòng tốt') ||
                        cleanText.contains('goi y phong tot');
    if (isBestQuery) {
      criteria['best'] = true;
      detected = true;
    }

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

    // 3. Tiện ích — parse cứng các tiện ích phổ biến trước (ưu tiên cao)
    final amenities = <String>[];

    // Map từ khóa người dùng → tên chuẩn trong data
    final amenityKeywords = {
      'wifi': 'wifi',
      'internet': 'wifi',
      'máy lạnh': 'máy lạnh',
      'may lanh': 'máy lạnh',
      'điều hòa': 'máy lạnh',
      'dieu hoa': 'máy lạnh',
      'máy giặt': 'máy giặt',
      'may giat': 'máy giặt',
      'tủ lạnh': 'tủ lạnh',
      'tu lanh': 'tủ lạnh',
      'ban công': 'ban công',
      'ban cong': 'ban công',
      'bancong': 'ban công',
      'gác lửng': 'gác lửng',
      'gac lung': 'gác lửng',
      'gaclung': 'gác lửng',
      'chỗ để xe': 'chỗ để xe',
      'cho de xe': 'chỗ để xe',
      'giữ xe': 'chỗ để xe',
      'giu xe': 'chỗ để xe',
      'bếp': 'bếp',
      'bep': 'bếp',
      'nội thất': 'nội thất',
      'noi that': 'nội thất',
      'full nội thất': 'nội thất',
      'full noi that': 'nội thất',
      'đầy đủ nội thất': 'nội thất',
      'day du noi that': 'nội thất',
    };
    amenityKeywords.forEach((kw, canonical) {
      if (cleanText.contains(kw) && !amenities.contains(canonical)) {
        amenities.add(canonical);
        detected = true;
      }
    });

    // Tự động phân tích tiện ích động sau từ khóa chỉ phòng (Tiếng Việt có dấu)
    // Chỉ bắt đoạn SAU từ "có" — tránh bắt nhầm cụm giá "trên X triệu có Y"
    final hasPattern = RegExp(
      r'\b(?:phòng|phong|trọ|tro)\s+(?:có|co|thuê|thue|ở|o|cần|can|muốn|muon)?\s*(?:có|co)?\s*(?!\d)([^,.\?]+)',
    );
    // Cũng bắt dạng "muốn có phòng + tiện ích" và "... có + tiện ích" sau khi xử lý giá
    final afterCoPattern = RegExp(
      r'(?:có|co)\s+(?!\d)((?:(?!(?:phòng|phong|trọ|tro|quận|quan|triệu|trieu|tr\b)).)*)$',
    );
    for (final match in [hasPattern.firstMatch(cleanText), afterCoPattern.firstMatch(cleanText)]) {
      if (match == null) continue;
      final rawSegment = match.group(1) ?? '';
      // Bỏ qua nếu đoạn bắt đầu bằng số (giá tiền)
      if (RegExp(r'^\d').hasMatch(rawSegment.trim())) continue;
      final cleanedList = _extractDynamicAmenities(rawSegment);
      for (final am in cleanedList) {
        if (!amenities.contains(am)) {
          amenities.add(am);
          detected = true;
        }
      }
    }

    if (amenities.isNotEmpty) {
      // Deduplicate: bỏ các amenity mà chuỗi không-dấu của nó là suffix/infix
      // của một amenity khác đã có trong list (VD: nếu có "ban công" thì bỏ "công")
      final cleanedAmenities = amenities.where((a) {
        final aNoAccent = _removeDiacritics(a.toLowerCase());
        // Bỏ nếu có amenity khác dài hơn và chứa a như suffix/infix
        return !amenities.any((b) {
          if (b == a) return false;
          final bNoAccent = _removeDiacritics(b.toLowerCase());
          return bNoAccent.contains(aNoAccent) && bNoAccent.length > aNoAccent.length;
        });
      }).toList();
      criteria['amenities'] = cleanedAmenities;
    }

    // 5. Nhận diện intent giá rẻ/bình dân/sinh viên không có số cụ thể
    if (!criteria.containsKey('maxPrice')) {
      if (_hasCheapIntent(cleanText)) {
        criteria['cheap'] = true;
        criteria['maxPrice'] = 3000000;
        detected = true;
      } else if (_hasStudentIntent(cleanText)) {
        criteria['student'] = true;
        criteria['maxPrice'] = 3500000;
        detected = true;
      }
    } else {
      if (_hasCheapIntent(cleanText)) {
        criteria['cheap'] = true;
      }
      if (_hasStudentIntent(cleanText)) {
        criteria['student'] = true;
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

  // ── Cập nhật danh sách phòng mới nhất từ provider ──────────────
  static void updateRooms(List<RoomModel> rooms) {
    _allAvailableRooms = rooms;
  }

  // ── Phân tích và thử so sánh hai phòng cụ thể ───────────────────
  static String? _tryCompareRooms(String message) {
    var content = message.trim();
    // Loại bỏ tiền tố so sánh ở đầu câu
    final compareStartRegex = RegExp(
      r'^(?:so sánh|so sanh|so sánh hai phòng|so sánh 2 phòng|so sanh hai phong|so sanh 2 phong)\s*(?::\s*)?',
      caseSensitive: false,
    );
    content = content.replaceFirst(compareStartRegex, '').trim();

    // Tách hai tên phòng qua từ nối "và", "với", hoặc dấu phẩy ","
    final splitRegex = RegExp(r'\s+(?:và|với|va|voi)\s+|\s*,\s*', caseSensitive: false);
    final parts = content.split(splitRegex);
    if (parts.length != 2) return null;

    String cleanRoomName(String name) {
      return name.replaceFirst(RegExp(r'^(?:phòng|phong)\s*', caseSensitive: false), '').trim();
    }

    final cleanNameA = cleanRoomName(parts[0]);
    final cleanNameB = cleanRoomName(parts[1]);

    RoomModel? findMatchingRoom(String nameQuery) {
      if (nameQuery.isEmpty) return null;
      final queryUnaccented = _removeDiacritics(nameQuery.toLowerCase());
      
      for (final room in _allAvailableRooms) {
        final titleUnaccented = _removeDiacritics(room.title.toLowerCase());
        if (titleUnaccented.contains(queryUnaccented) || queryUnaccented.contains(titleUnaccented)) {
          return room;
        }
      }
      return null;
    }

    final roomA = findMatchingRoom(cleanNameA);
    final roomB = findMatchingRoom(cleanNameB);

    if (roomA != null && roomB != null && roomA.id != roomB.id) {
      return _generateComparisonText(roomA, roomB);
    }

    if (cleanNameA.isNotEmpty && cleanNameB.isNotEmpty) {
      return 'Mình không tìm thấy đủ 2 phòng khớp với tên "$cleanNameA" và "$cleanNameB" trong danh sách hiện tại. Bạn vui lòng kiểm tra lại và nhập đúng tên phòng cần so sánh nhé.';
    }
    return null;
  }

  // ── Tạo nội dung so sánh chi tiết hai phòng (Dạng Plain Text) ────
  static String _generateComparisonText(RoomModel a, RoomModel b) {
    final buffer = StringBuffer();
    buffer.writeln('So sánh 2 phòng:\n');

    final priceAStr = a.price > 0 ? '${(a.price / 1000000).toStringAsFixed(1)} triệu/tháng' : 'Chưa cập nhật';
    final locA = a.location.isNotEmpty ? a.location : (a.address.isNotEmpty ? a.address : 'Chưa cập nhật');
    final amA = a.amenities.isNotEmpty ? a.amenities.join(', ') : 'Chưa có tiện ích cụ thể';
    final verA = a.isVerified ? 'Đã xác minh' : 'Chưa xác minh';
    buffer.writeln('1. ${a.title}');
    buffer.writeln('- Giá: $priceAStr');
    buffer.writeln('- Khu vực: $locA');
    buffer.writeln('- Tiện ích: $amA');
    buffer.writeln('- Trạng thái: $verA, đánh giá ${a.rating.toStringAsFixed(1)}/5\n');

    final priceBStr = b.price > 0 ? '${(b.price / 1000000).toStringAsFixed(1)} triệu/tháng' : 'Chưa cập nhật';
    final locB = b.location.isNotEmpty ? b.location : (b.address.isNotEmpty ? b.address : 'Chưa cập nhật');
    final amB = b.amenities.isNotEmpty ? b.amenities.join(', ') : 'Chưa có tiện ích cụ thể';
    final verB = b.isVerified ? 'Đã xác minh' : 'Chưa xác minh';
    buffer.writeln('2. ${b.title}');
    buffer.writeln('- Giá: $priceBStr');
    buffer.writeln('- Khu vực: $locB');
    buffer.writeln('- Tiện ích: $amB');
    buffer.writeln('- Trạng thái: $verB, đánh giá ${b.rating.toStringAsFixed(1)}/5\n');

    buffer.write('Gợi ý: ');

    final cheaperRoom = (a.price > 0 && b.price > 0)
        ? (a.price < b.price ? 1 : (b.price < a.price ? 2 : 0))
        : 0;
    final moreAmenRoom = a.amenities.length > b.amenities.length
        ? 1
        : (b.amenities.length > a.amenities.length ? 2 : 0);

    if (cheaperRoom != 0 && cheaperRoom == moreAmenRoom) {
      // Cùng 1 phòng vừa rẻ hơn vừa nhiều tiện ích hơn → gộp 1 câu
      buffer.write('Phòng $cheaperRoom có giá thấp hơn và nhiều tiện ích hơn, là lựa chọn đáng cân nhắc.');
    } else {
      if (cheaperRoom == 1) {
        buffer.write('Nếu ưu tiên giá thấp hơn, bạn nên chọn phòng 1. ');
      } else if (cheaperRoom == 2) {
        buffer.write('Nếu ưu tiên giá thấp hơn, bạn nên chọn phòng 2. ');
      }
      if (moreAmenRoom == 1) {
        buffer.write('Nếu ưu tiên nhiều tiện ích hơn, bạn nên chọn phòng 1.');
      } else if (moreAmenRoom == 2) {
        buffer.write('Nếu ưu tiên nhiều tiện ích hơn, bạn nên chọn phòng 2.');
      } else if (cheaperRoom == 0) {
        buffer.write('Cả hai phòng đều có các ưu điểm riêng về vị trí và tiện ích.');
      }
    }

    return buffer.toString();
  }

  // ── Gợi ý các phòng nổi bật dựa trên tiêu chí an toàn ──────────
  static List<RoomModel> _getBestRooms(List<RoomModel> rooms) {
    // 1. Loại bỏ phòng có price <= 0 và lọc phòng hợp lệ
    var validRooms = rooms.where((r) => r.price >= 100000).toList();
    if (validRooms.isEmpty) return [];

    // 2. Sắp xếp: ưu tiên đã xác minh, rating cao, nhiều tiện ích, có ảnh thật, giá tốt
    validRooms.sort((a, b) {
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;

      final aHasImg = a.mainImageUrl.isNotEmpty || a.imageUrl.isNotEmpty;
      final bHasImg = b.mainImageUrl.isNotEmpty || b.imageUrl.isNotEmpty;
      if (aHasImg && !bHasImg) return -1;
      if (!aHasImg && bHasImg) return 1;

      if (b.rating != a.rating) {
        return b.rating.compareTo(a.rating);
      }

      if (b.amenities.length != a.amenities.length) {
        return b.amenities.length.compareTo(a.amenities.length);
      }

      return a.price.compareTo(b.price);
    });

    return validRooms.take(3).toList();
  }

  // ── Loại bỏ dấu tiếng Việt để so khớp không dấu ────────────────
  static String _removeDiacritics(String str) {
    const vietnamese = 'aAeEoOuUiIdDyYoO';
    const vietnameseRegex = [
      'àáạảãâầấậẩẫăằắặẳẵ',
      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ',
      'èéẹẻẽêềếệểễ',
      'ÈÉẸẺẼÊỀẾỆỂỄ',
      'òóọỏõôồốộổỗơờớợởỡ',
      'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ',
      'ùúụủũưừứựửữ',
      'ÙÚỤỦŨƯỪỨỰỬỮ',
      'ìíịỉĩ',
      'ÌÍỊỈĨ',
      'đ',
      'Đ',
      'ỳýỵỷỹ',
      'ỲÝỴỶỸ',
      'óòọỏõóòọỏõ',
      'ÓÒỌỎÕÓÒỌỎÕ',
    ];

    var result = str;
    for (var i = 0; i < vietnameseRegex.length; i++) {
      final replacedChar = vietnamese[i];
      final regex = RegExp('[${vietnameseRegex[i]}]');
      result = result.replaceAll(regex, replacedChar);
    }
    return result;
  }

  // ── Phân tích tách tiện ích động từ chuỗi sau chữ "có" ──────────
  static List<String> _extractDynamicAmenities(String text) {
    // Từ rác cứng cần loại bỏ hoàn toàn (không dấu để so khớp dễ)
    const trashAmenities = {
      'cong', 'co cong', 'co', 'co ban', 'ban', 'phong', 'tro', 'nha',
      'tim', 'co phong', 'phong co', 'tim phong',
    };

    final result = <String>[];
    final parts = text.split(RegExp(r',|và|va|&|\+'));
    for (var part in parts) {
      var t = part.trim();
      if (t.isEmpty) continue;

      // Cắt "có/co" ở đầu lần 1 (trước khi xử lý giá)
      if (t.startsWith('có ') || t.startsWith('co ')) {
        t = t.substring(3).trim();
      }

      // Loại bỏ từ hỏi / lịch sự cuối câu
      final endWords = [
        'không', 'khong', 'nhỉ', 'nhi', 'nha', 'ạ', 'a', 'nhé', 'nhe', 'với', 'voi',
        'không?', 'khong?', 'nhỉ?', 'nhi?', 'ạ?', 'a?'
      ];
      for (final word in endWords) {
        final reg = RegExp('\\b${RegExp.escape(word)}\\s*\$');
        t = t.replaceFirst(reg, '').trim();
      }

      // Loại bỏ phần liên quan đến giá cả
      final pricePatterns = [
        r'\b(?:dưới|duoi|trên|tren|khoảng|khoang|tầm|tam)?\s*\d+(?:\.\d+)?\s*(?:triệu|trieu|tr)\b',
        r'\b(?:giá rẻ|gia re|giá tốt|gia tot|bình dân|binh dan|tiết kiệm|tiet kiem)\b'
      ];
      for (final pattern in pricePatterns) {
        t = t.replaceAll(RegExp(pattern), '').trim();
      }

      // Sau khi xóa giá, nếu còn "có/co" ở đầu thì cắt tiếp (VD: "trên 5tr có ban công" → "có ban công" → "ban công")
      if (t.startsWith('có ') || t.startsWith('co ')) {
        t = t.substring(3).trim();
      }

      // Loại bỏ địa điểm
      final locationPatterns = [
        r'\b(?:ở|o|tại|tai|khu vực|khu vuc|quận|quan|phường|phuong|đường|duong)\s+[a-zA-Z0-9\sđĐàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ]+',
        r'\b(?:quận|quan)\s+\d+\b',
        r'\b(?:bình thạnh|binh thanh|gò vấp|go vap|thủ đức|thu duc|phú nhuận|phu nhuan|tân bình|tan binh|tân phú|tan phu|bình tân|binh tan)\b'
      ];
      for (final pattern in locationPatterns) {
        t = t.replaceAll(RegExp(pattern), '').trim();
      }

      t = t.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (t.endsWith('ở') || t.endsWith('tại') || t.endsWith('tai')) {
        t = t.replaceAll(RegExp(r'(?:ở|tại|tai)\s*\$'), '').trim();
      }
      if (t.startsWith('ở') || t.startsWith('tại') || t.startsWith('tai ')) {
        t = t.replaceAll(RegExp(r'^(?:ở|tại|tai)\s*'), '').trim();
      }

      // Loại bỏ các từ không mang nghĩa tiện ích
      final ignorePatterns = [
        r'\b(?:tốt nhất|tot nhat|nổi bật nhất|noi bat nhat|đáng thuê nhất|dang thue nhat|tốt|tot|nổi bật|noi bat|đáng thuê|dang thue|nào|nao|gợi ý|goi y|muốn|muon|cần|can|yêu cầu|yeu cau|đại ca|dai ca|tớ|to|tôi|toi|bạn|ban|hộ|ho|rẻ|re|giá rẻ|gia re|phòng rẻ|phong re|sinh viên|sinh vien|giá mềm|gia mem|bình dân|binh dan|tiết kiệm|tiet kiem|dưới|duoi|trên|tren|triệu|trieu|tr|quận|quan|khu vực|khu vuc)\b'
      ];
      for (final pattern in ignorePatterns) {
        t = t.replaceAll(RegExp(pattern), '').trim();
      }

      t = t.trim();
      if (t.isEmpty || t.length <= 1) continue;

      // Bỏ nếu là từ rác sau khi đã remove diacritics để so sánh
      final tNoAccent = _removeDiacritics(t.toLowerCase());
      if (trashAmenities.contains(tNoAccent)) continue;

      result.add(t);
    }
    return result;
  }
  static bool _hasCheapIntent(String cleanText) {
    return cleanText.contains('rẻ') ||
           cleanText.contains('re ') ||
           cleanText.contains(' re') ||
           cleanText == 're' ||
           cleanText.contains('giá rẻ') ||
           cleanText.contains('gia re') ||
           cleanText.contains('phòng rẻ') ||
           cleanText.contains('phong re') ||
           cleanText.contains('giá mềm') ||
           cleanText.contains('gia mem') ||
           cleanText.contains('bình dân') ||
           cleanText.contains('binh dan') ||
           cleanText.contains('tiết kiệm') ||
           cleanText.contains('tiet kiem') ||
           cleanText.contains('giá tốt') ||
           cleanText.contains('gia tot');
  }

  static bool _hasStudentIntent(String cleanText) {
    return cleanText.contains('sinh viên') ||
           cleanText.contains('sinh vien');
  }

  // ── Fallback local khi Gemini lỗi/quota/timeout ──────────────────────────
  // Xây mô tả 2–3 câu thuần từ dữ liệu form, không gọi API
  static String _generateLocalRoomDescriptionFallback({
    required String title,
    required double price,
    required String address,
    required String roomType,
    required int bedrooms,
    required double area,
    required List<String> amenities,
  }) {
    final addrStr = address.trim().isNotEmpty
        ? address.trim()
        : 'khu vực TP. Hồ Chí Minh';

    // Format giá: 1500000 → "1.5 triệu/tháng"
    final priceStr = price > 0
        ? '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)} triệu/tháng'
        : '';

    final suspicious = _isSuspiciousRoomTitle(title);

    // Câu 1: loại phòng + địa chỉ + giá
    final sentence1 = StringBuffer();
    sentence1.write('$roomType tại $addrStr');
    if (priceStr.isNotEmpty) {
      sentence1.write(' hiện đang cho thuê với giá $priceStr.');
    } else {
      sentence1.write(' hiện đang cho thuê.');
    }

    // Câu 2: diện tích / tiện ích / số phòng ngủ
    final sentence2 = StringBuffer();
    final amenPreview = amenities.take(3).toList();
    if (amenPreview.isNotEmpty) {
      if (amenPreview.length == 1) {
        sentence2.write('Phòng có tiện ích ${amenPreview[0]}');
      } else {
        final last = amenPreview.last;
        final others = amenPreview.sublist(0, amenPreview.length - 1).join(', ');
        sentence2.write('Phòng có các tiện ích như $others và $last');
      }
      if (area > 0) {
        sentence2.write(', diện tích ${area.toInt()}m²');
      }
      if (bedrooms > 0) {
        sentence2.write(', $bedrooms phòng ngủ');
      }
      sentence2.write(', phù hợp cho nhu cầu thuê ở cơ bản.');
    } else if (area > 0 || bedrooms > 0) {
      final details = <String>[];
      if (area > 0) details.add('diện tích ${area.toInt()}m²');
      if (bedrooms > 0) details.add('$bedrooms phòng ngủ');
      sentence2.write('Phòng có ${details.join(', ')}, phù hợp cho nhu cầu ở ổn định.');
    }

    // Câu 3: nếu giá = 0 thì nhắc liên hệ; nếu title đẹp và không suspicious thì có thể nhắc nhẹ
    final sentence3 = StringBuffer();
    if (price <= 0) {
      sentence3.write(' Giá thuê chưa xác định, vui lòng liên hệ để biết thêm thông tin chi tiết.');
    } else if (!suspicious && title.trim().isNotEmpty && sentence2.isEmpty) {
      // Ít dữ liệu nhưng title bình thường → viết trung tính
      sentence3.write(' Thông tin phòng được trình bày trung tính, phù hợp cho người cần tìm nơi ở cơ bản.');
    } else if (suspicious && sentence2.isEmpty) {
      sentence3.write(' Thông tin phòng được trình bày trung tính, phù hợp cho người cần tìm nơi ở cơ bản.');
    }

    final parts = [
      sentence1.toString(),
      if (sentence2.isNotEmpty) sentence2.toString(),
    ].join(' ');

    return (parts + sentence3.toString()).trim();
  }

  // ── Kiểm tra title phòng có dấu hiệu là dữ liệu test/tào lao không ────
  // Nếu true → không đưa title vào prompt để AI không diễn giải theo nghĩa đen
  static bool _isSuspiciousRoomTitle(String title) {
    final t = _removeDiacritics(title.toLowerCase().trim());
    // Các keyword rõ ràng là test/tào lao
    const suspiciousKeywords = [
      'test', 'demo', 'fix', 'debug', 'fake', 'mock', 'dummy',
      'du lieu ao', 'du lieu test', 'du lieu demo',
      'ngoai vu tru', 'vu tru',
      'co nguoi yeu', 'nguoi yeu', 'tinh yeu', 'crush',
      'abcxyz', 'abc123', 'xyz123', '123123', 'aaaa', 'qwerty',
      'test phong', 'phong test', 'phong demo', 'phong fix',
      'thu nghiem', 'tao lao', 'linh tinh', 'random',
    ];
    if (suspiciousKeywords.any((kw) => t.contains(kw))) return true;

    // Title có quá ít ký tự hoặc hoàn toàn là số/ký hiệu → ngầm hiểu là dữ liệu nhập ẩu
    if (t.replaceAll(RegExp(r'[^a-z]'), '').length < 3) return true;

    return false;
  }
}
