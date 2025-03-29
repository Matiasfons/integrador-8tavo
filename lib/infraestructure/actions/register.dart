import 'package:supabase_flutter/supabase_flutter.dart';

registerUser(userData) async {
  final supabase = Supabase.instance.client;
  final user = await supabase.auth.signUp(
    email: userData['email'],
    password: userData['password'],
  );
  if (user.user != null) {
    await supabase.from("users").insert({
      "email": userData['email'],
      "name": userData['password'],
      "phone": userData['phone'],
      "birthdate": userData['birthdate'],
      "gender": userData['gender'],
      "id": user.user!.id,
    });
    return true;
  }
  return false;
}
