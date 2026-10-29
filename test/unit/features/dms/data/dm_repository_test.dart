import 'dart:io';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/data/dm_repository.dart';

import '../../../../helpers/helpers.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('DmRepository.sendMessage', () {
    late MockApiBaseService apiClient;
    late DmRepository repository;
    late List<MapEntry<String, Object?>> requests;

    setUp(() {
      apiClient = MockApiBaseService();
      repository = DmRepository(apiClient);
      requests = [];

      when(
        () => apiClient.post<Map<String, dynamic>>(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        final path = invocation.namedArguments[#path] as String;
        final data = invocation.namedArguments[#data];
        requests.add(MapEntry(path, data));

        if (path == '/files/upload-files') {
          return const ApiResponseModel<Map<String, dynamic>>(
            data: <String, dynamic>{
              'data': <Map<String, dynamic>>[
                {'file_link': 'https://cdn.example.test/photo.png'},
              ],
            },
            statusCode: 200,
          );
        }

        return const ApiResponseModel<Map<String, dynamic>>(
          data: <String, dynamic>{},
          statusCode: 200,
        );
      });
    });

    test('uploads file bytes before sending remote media metadata', () async {
      final tempDirectory = await Directory.systemTemp.createTemp();
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}photo.png',
      );
      await file.writeAsBytes([1, 2, 3]);

      try {
        await repository.sendMessage(
          'channel-1',
          'See this image',
          media: [XFile(file.path, name: 'photo.png', mimeType: 'image/png')],
          mentions: const ['user-1'],
        );

        expect(requests.map((request) => request.key), [
          '/files/upload-files',
          '/channels/channel-1/messages',
        ]);

        final uploadData = requests.first.value as FormData;
        expect(uploadData.files, hasLength(1));
        expect(uploadData.files.single.key, 'files');
        expect(uploadData.files.single.value.filename, 'photo.png');

        final messageData = requests.last.value as Map<String, dynamic>;
        expect(messageData['media'], [
          {'file_link': 'https://cdn.example.test/photo.png'},
        ]);
        expect(messageData['mentions'], ['user-1']);
        final remoteMedia = (messageData['media'] as List).single as Map;
        expect(remoteMedia.containsKey('path'), isFalse);
      } finally {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('uploads files without a local path from their bytes', () async {
      final pastedImage = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'pasted.png',
        mimeType: 'image/png',
      );

      await repository.sendMessage('channel-1', '', media: [pastedImage]);

      final uploadData = requests.first.value as FormData;
      expect(uploadData.files, hasLength(1));
      expect(uploadData.files.single.value.filename, 'attachment');
      expect(requests.last.key, '/channels/channel-1/messages');
    });

    test('does not upload when message has no media', () async {
      await repository.sendMessage('channel-1', 'Text only');

      expect(requests, hasLength(1));
      expect(requests.single.key, '/channels/channel-1/messages');
      expect(
        (requests.single.value as Map<String, dynamic>).containsKey('media'),
        isFalse,
      );
    });
  });
}
