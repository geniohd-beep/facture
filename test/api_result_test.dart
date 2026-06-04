import 'package:flutter_test/flutter_test.dart';
import 'package:facture/utils/api_result.dart';

void main() {
  group('ApiResult', () {
    test('success result has data and no error', () {
      final result = ApiResult.success('hello');
      expect(result.isSuccess, true);
      expect(result.data, 'hello');
      expect(result.error, null);
    });

    test('failure result has error and no data', () {
      final result = ApiResult.failure('something went wrong');
      expect(result.isSuccess, false);
      expect(result.data, null);
      expect(result.error, 'something went wrong');
    });

    test('success with null data', () {
      final result = ApiResult<int>.success(42);
      expect(result.isSuccess, true);
      expect(result.data, 42);
    });
  });
}
