import 'package:flutter/material.dart';

import 'admin/admin_app.dart';
import 'core/auth/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = await AuthService.create();
  runApp(WajzAdminApp(authService: authService));
}
