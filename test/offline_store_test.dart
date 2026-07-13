import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajz/core/offline/offline_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('offline cache persists JSON payloads', () async {
    final store = await OfflineStore.create();

    await store.writeCache('stories:anonymous', {
      'items': [
        {'id': 'story-1'},
      ],
    });

    expect(store.readCache('stories:anonymous'), {
      'items': [
        {'id': 'story-1'},
      ],
    });
  });

  test('queue replaces older action for the same resource', () async {
    final store = await OfflineStore.create();

    await store.enqueue(
      const PendingOfflineAction(
        id: 'save',
        scope: 'user-1',
        method: 'POST',
        path: '/me/saved-stories/story-1',
      ),
    );
    await store.enqueue(
      const PendingOfflineAction(
        id: 'unsave',
        scope: 'user-1',
        method: 'DELETE',
        path: '/me/saved-stories/story-1',
      ),
    );

    expect(store.pendingActions, hasLength(1));
    expect(store.pendingActions.single.method, 'DELETE');
    expect(store.pendingCount.value, 1);
  });

  test('queues are isolated by authenticated account scope', () async {
    final store = await OfflineStore.create();

    await store.enqueue(
      const PendingOfflineAction(
        id: 'one',
        scope: 'user-1',
        method: 'POST',
        path: '/me/stories/story-1/opened',
      ),
    );
    await store.enqueue(
      const PendingOfflineAction(
        id: 'two',
        scope: 'user-2',
        method: 'POST',
        path: '/me/stories/story-1/opened',
      ),
    );

    expect(store.pendingActions, hasLength(2));
  });
}
