import 'package:supabase_flutter/supabase_flutter.dart';

loginUser(email, password) async {
  final supabase = Supabase.instance.client;

  await supabase.auth.signInWithPassword(email: email, password: password);
  return true;
}
