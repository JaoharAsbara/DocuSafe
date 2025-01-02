import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller untuk input user
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // Fungsi untuk menampilkan dialog
    Future<void> showDialogBox(
        BuildContext context, String title, String message) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    // Fungsi untuk menyimpan UID ke SharedPreferences
    Future<void> saveUIDToPreferences(String uid) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('uid', uid);
    }

    // Fungsi untuk registrasi pengguna
    Future<void> registerUser() async {
      try {
        // Buat akun di Firebase Authentication
        final UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Ambil User dari userCredential
        final User? user = userCredential.user;
        if (user != null) {
          // Simpan data tambahan pengguna ke Cloud Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid) // Gunakan UID untuk mendocument pengguna
              .set({
            'username': usernameController.text.trim(),
            'email': emailController.text.trim(),
            'createdAt': DateTime.now(), // Waktu pendaftaran
          });

          // Simpan UID ke SharedPreferences
          saveUIDToPreferences(user.uid);

          // Menampilkan pop-up bahwa pendaftaran berhasil
          showDialogBox(context, 'Pendaftaran Berhasil',
              'Akun Anda telah berhasil dibuat.');

          // Pindahkan pengguna ke halaman login setelah 2 detik
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          });
        }
      } on FirebaseAuthException catch (e) {
        // Menampilkan pop-up jika pendaftaran gagal
        showDialogBox(
            context, 'Pendaftaran Gagal', e.message ?? 'Terjadi kesalahan!');
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'assets/docusafe_logo.jpg',
                      height: 150,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'DOCUSAFE',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Username Field
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        prefixIcon:
                            const Icon(Icons.person, color: Colors.blueAccent),
                        labelText: 'Username',
                        labelStyle: const TextStyle(color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              color: Colors.blueAccent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Email Field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        prefixIcon:
                            const Icon(Icons.email, color: Colors.blueAccent),
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              color: Colors.blueAccent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.blueAccent),
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              color: Colors.blueAccent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Button
                    ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Daftar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Already have an account text
                    const Text(
                      'Sudah punya akun? Masuk sekarang juga!',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Login Button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Kembali ke halaman login
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.blueAccent, width: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Masuk',
                        style:
                            TextStyle(fontSize: 18, color: Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          ],
        ),
      ),
    );
  }
}
