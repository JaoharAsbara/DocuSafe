import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> documents = [];
  int _selectedIndex = 0;
  String? userId;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      await _loadDocuments(); // Memuat dokumen setelah userId tersedia
    }
  }

  Future<void> _loadDocuments() async {
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('documents')
        .snapshots() 
        .listen((snapshot) {
      setState(() {
        documents = snapshot.docs
            .map((doc) => {
                  'id': doc.id, 
                  'name': doc['name'],
                  'path': doc['path'],
                  'uploaded': doc['uploaded'],
                })
            .toList();
      });
    });
  }

  Future<void> _saveDocumentToFirestore(
      String fileName, String filePath) async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('documents')
          .add({
        'name': fileName,
        'path': filePath,
        'uploaded': DateTime.now().toString(),
      });
    } catch (e) {
      print('Gagal menyimpan dokumen ke Firestore: $e');
    }
  }

  Future<void> _uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String fileName = result.files.single.name;
      String filePath = result.files.single.path!;

      final directory = await getExternalStorageDirectory();

      final docuSafeDir = Directory('${directory!.path}/docusafe');
      if (!(await docuSafeDir.exists())) {
        await docuSafeDir.create(recursive: true);
      }

      final localFilePath = '${docuSafeDir.path}/$fileName';
      final file = File(localFilePath);

      await File(filePath).copy(localFilePath);

      await _saveDocumentToFirestore(fileName, localFilePath);
    }
  }

  Future<void> _downloadDocument(String filePath) async {
    try {
      final directory = await getExternalStorageDirectory();
      final downloadDir = Directory('${directory!.path}/Download');

      if (!(await downloadDir.exists())) {
        await downloadDir.create(recursive: true);
      }

      final localFilePath = '${downloadDir.path}/${filePath.split('/').last}';
      final file = File(localFilePath);

      final remoteFile = File(filePath);
      await remoteFile.copy(localFilePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File berhasil diunduh ke Downloads!')),
      );
    } catch (e) {
      print('Gagal mengunduh dokumen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunduh dokumen!')),
      );
    }
  }

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

  Widget _getBodyContent() {
    if (_selectedIndex == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Upload Dokumen',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.upload_file,
                      size: 100,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pilih dokumen kamu!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: _uploadDocument,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload_file,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Upload Dokumen',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Daftar Dokumen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      leading: const Icon(Icons.document_scanner,
                          color: Colors.blueAccent),
                      title: Text(documents[index]['name']!),
                      subtitle:
                          Text('Uploaded on: ${documents[index]['uploaded']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.download,
                                color: Colors.blueAccent),
                            onPressed: () {
                              _downloadDocument(documents[index]['path']);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Konfirmasi Hapus'),
                                  content: const Text(
                                      'Apakah Anda yakin ingin menghapus dokumen ini?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Batal'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    TextButton(
                                      child: const Text('Hapus'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteDocument(
                                          documents[index]['id'],
                                          documents[index]['path'],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'DOCUSAFE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _getBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Dokumen',
          ),
        ],
      ),
    );
  }
}
