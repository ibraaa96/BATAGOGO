import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() {
      isLoading = true;
    });

    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'users',
      orderBy: 'id_user ASC',
    );

    if (!mounted) return;

    setState(() {
      users = result;
      isLoading = false;
    });
  }

  Future<void> deleteUser(int id) async {
    final db = await DatabaseHelper.instance.database;

    await db.delete(
      'users',
      where: 'id_user = ?',
      whereArgs: [id],
    );

    await loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Database'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : users.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada data user',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID User: ${user['id_user']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Nama: ${user['nama']}'),
                              Text('Email: ${user['email']}'),
                              Text('No HP: ${user['no_hp']}'),
                              Text('Alamat: ${user['alamat']}'),
                              Text('Password: ${user['password']}'),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    deleteUser(user['id_user']);
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}