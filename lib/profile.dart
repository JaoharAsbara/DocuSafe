import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String email = '';
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Mendapatkan data pengguna dari Firebase
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? 'Email tidak tersedia';
        userId = user.uid;
      });
      await _getUsername();
    }
  }

  // Mengambil username dari Firestore
  Future<void> _getUsername() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'] ?? 'Nama pengguna tidak ditemukan';
        });
      }
    } catch (e) {
      print("Error mengambil username: $e");
    }
  }

  // Hapus dokumen terkait pengguna dari Firestore
  Future<void> _deleteDocument(String documentId, String filePath) async {
    try {
      // Hapus dokumen dari Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('documents')
          .doc(documentId)
          .delete();

      // Hapus file dari penyimpanan lokal
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dokumen berhasil dihapus!')),
      );
    } catch (e) {
      print('Gagal menghapus dokumen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus dokumen!')),
      );
    }
  }

  // Menghapus seluruh dokumen pengguna di Firestore dan lokal
  Future<void> _deleteUserDocuments() async {
    try {
      final userDocsSnapshot = await FirebaseFirestore.instance
          .collection('documents') // Mengakses koleksi dokumen
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in userDocsSnapshot.docs) {
        String documentId = doc.id;
        String filePath =
            doc['filePath']; // Asumsi 'filePath' berisi path lokasi file lokal

        // Menghapus dokumen dan file lokal
        await _deleteDocument(documentId, filePath);
      }
    } catch (e) {
      print("Error menghapus dokumen pengguna: $e");
    }
  }

  // Menghapus data akun dari FirebaseAuth dan Firestore
  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Menghapus dokumen dan file terkait dengan pengguna
        await _deleteUserDocuments();

        // Menghapus data pengguna dari Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Menghapus akun pengguna dari FirebaseAuth
        await user.delete();

        // Menampilkan snack bar dan melakukan logout
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dihapus!')),
        );

        // Menandakan pengguna telah keluar
        await FirebaseAuth.instance.signOut();

        // Arahkan pengguna ke halaman login setelah berhasil menghapus akun
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print("Error menghapus akun: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus akun!')),
      );
    }
  }

  // Menampilkan dialog konfirmasi sebelum menghapus akun
  Future<void> _showDeleteConfirmationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus Akun'),
          content: const Text(
              'Apakah Anda yakin ingin menghapus akun? Tindakan ini tidak dapat dibatalkan.'),
          actions: <Widget>[
            // Tombol Batal
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            // Tombol Hapus
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                _deleteAccount();
              },
              child: const Text('Hapus Akun'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.account_circle,
                size: 120,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),

              // Menampilkan Username
              Text(
                username,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),

              // Menampilkan Email
              Text(
                email,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 30),

              // Tombol untuk Hapus Akun
              ElevatedButton(
                onPressed:
                    _showDeleteConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  'Hapus Akun',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
