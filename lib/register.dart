import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

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

    Future<void> saveUIDToPreferences(String uid) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('uid', uid);
    }

    Future<void> registerUser() async {
      try {
        final UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final User? user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'username': usernameController.text.trim(),
            'email': emailController.text.trim(),
            'createdAt': DateTime.now(),
          });

          saveUIDToPreferences(user.uid);

          showDialogBox(context, 'Pendaftaran Berhasil',
              'Akun Anda telah berhasil dibuat.');

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          });
        }
      } on FirebaseAuthException catch (e) {
        showDialogBox(
            context, 'Pendaftaran Gagal', e.message ?? 'Terjadi kesalahan!');
      }
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              height: constraints.maxHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Vertikal Center
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Horizontal Center
                children: <Widget>[
                  Column(
                    children: [
                      Image.asset(
                        'assets/docusafe_logo.jpg',
                        height: constraints.maxHeight * 0.15,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'DOCUSAFE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          prefixIcon: const Icon(Icons.person,
                              color: Colors.blueAccent),
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
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      const Text(
                        'Sudah punya akun? Masuk sekarang juga!',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
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
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
