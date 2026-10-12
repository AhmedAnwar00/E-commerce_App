import 'package:get_it/get_it.dart';

// Create a global instance (or use GetIt.instance)
final getIt = GetIt.instance;

// 1. Define your services
class ApiClient {
  Future<void> fetchData() async { /* ... */ }
}

class UserRepository {
  final ApiClient apiClient;
  UserRepository(this.apiClient);
}

// 2. Register them at app startup
void configureDependencies() {
  getIt.registerSingleton<ApiClient>(ApiClient());
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(getIt<ApiClient>())
  );
}