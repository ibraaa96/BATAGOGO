import 'kasir_page.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/session.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];

  final TextEditingController searchController =
      TextEditingController();

  int selectedCategory = 0;

  final List<String> categories = [
    'Semua',
    'Biasa',
    'Ikan',
    'Kuah',
    'Kering',
  ];

  @override
  void initState() {
    super.initState();
    loadProducts();
    searchController.addListener(filterProducts);
  }

  Future<void> loadProducts() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'produk',
      orderBy: 'id_produk ASC',
    );

    if (!mounted) return;

    setState(() {
      products = result;
      filteredProducts = result;
    });
  }

  void filterProducts() {
    final search = searchController.text.toLowerCase();

    setState(() {
      filteredProducts = products.where((product) {
        final nama =
            product['nama_produk'].toString().toLowerCase();

        final jenis =
            product['jenis'].toString().toLowerCase();

        final cocokSearch =
            nama.contains(search) || jenis.contains(search);

        final cocokKategori =
            selectedCategory == 0 ||
            jenis == categories[selectedCategory].toLowerCase();

        return cocokSearch && cocokKategori;
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatRupiah(dynamic value) {
    final harga = double.tryParse(value.toString()) ?? 0;

    return 'Rp ${harga.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),

      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Batagogo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile belum dibuat'),
                ),
              );
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              25,
            ),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${Session.nama ?? 'Pelanggan'} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Mau makan batagor apa hari ini?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari batagor...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final selected =
                    selectedCategory == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = index;
                    });

                    filterProducts();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.red
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Menu Batagogo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      'Produk tidak ditemukan',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      5,
                      20,
                      20,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product =
                          filteredProducts[index];

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.red.shade50,
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.fastfood,
                                    color: Colors.red,
                                    size: 55,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                product['nama_produk']
                                    .toString(),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                product['jenis'].toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),

                              const SizedBox(height: 7),

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      formatRupiah(
                                        product['harga'],
                                      ),
                                      style:
                                          const TextStyle(
                                        color: Colors.red,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),

                                
InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KasirPage(),
      ),
    );
  },
  borderRadius: BorderRadius.circular(9),
  child: Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(9),
    ),
    child: const Icon(
      Icons.add,
      color: Colors.white,
      size: 18,
    ),
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
          ),
        ],
      ),
    );
  }
}