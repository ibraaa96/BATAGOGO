
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/cart_item.dart';
import '../services/session.dart';


class KasirPage extends StatefulWidget {
  final Map<String, dynamic>? produkAwal;

  const KasirPage({
    super.key,
    this.produkAwal,
  });

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final DatabaseHelper _helper = DatabaseHelper.instance;
  final TextEditingController _bayarController = TextEditingController();

  final Map<int, CartItem> _keranjang = {};
  List<Map<String, dynamic>> _produk = [];

  bool _loading = true;
  bool _menyimpan = false;

  final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double get _total {
    return _keranjang.values.fold(
      0.0,
      (total, item) => total + item.subtotal,
    );
  }

  double get _uangBayar {
    final angka = _bayarController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return double.tryParse(angka) ?? 0;
  }

  double get _kembalian {
    final hasil = _uangBayar - _total;
    return hasil > 0 ? hasil : 0;
  }

  @override
  void initState() {
    super.initState();
    _bayarController.addListener(_perbaruiTampilan);
    _muatProduk();
  }

  @override
  void dispose() {
    _bayarController.removeListener(_perbaruiTampilan);
    _bayarController.dispose();
    super.dispose();
  }

  void _perbaruiTampilan() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _muatProduk() async {
    try {
      final db = await _helper.database;

      final data = await db.query(
        'produk',
        orderBy: 'nama_produk ASC',
      );

      if (!mounted) return;

      setState(() {
        _produk = data;
        _loading = false;

        // Sesuaikan keranjang dengan stok terbaru.
        for (final entry in _keranjang.entries.toList()) {
          final hasil = data.where(
            (produk) =>
                (produk['id_produk'] as num).toInt() == entry.key,
          );

          if (hasil.isEmpty) {
            _keranjang.remove(entry.key);
            continue;
          }

          final stok = (hasil.first['stok'] as num).toInt();

          if (stok <= 0) {
            _keranjang.remove(entry.key);
          } else if (entry.value.jumlah > stok) {
            _keranjang[entry.key] = entry.value.copyWith(
              jumlah: stok,
            );
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _pesan('Gagal memuat produk: $e');
    }
  }

  int _stokProduk(int idProduk) {
    for (final produk in _produk) {
      final id = (produk['id_produk'] as num).toInt();

      if (id == idProduk) {
        return (produk['stok'] as num).toInt();
      }
    }

    return 0;
  }

  void _tambahProduk(Map<String, dynamic> produk) {
    final id = (produk['id_produk'] as num).toInt();
    final stok = (produk['stok'] as num).toInt();

    final itemLama = _keranjang[id];
    final jumlahSekarang = itemLama?.jumlah ?? 0;

    if (stok <= 0) {
      _pesan('Stok produk habis.');
      return;
    }

    if (jumlahSekarang >= stok) {
      _pesan('Stok ${produk['nama_produk']} tidak mencukupi.');
      return;
    }

    setState(() {
      _keranjang[id] = CartItem(
        idProduk: id,
        namaProduk: produk['nama_produk'] as String,
        harga: (produk['harga'] as num).toDouble(),
        jumlah: jumlahSekarang + 1,
        gambar: produk['gambar'] as String?,
      );
    });
  }

  void _ubahJumlah(CartItem item, int jumlahBaru) {
    if (jumlahBaru <= 0) {
      setState(() {
        _keranjang.remove(item.idProduk);
      });
      return;
    }

    if (jumlahBaru > _stokProduk(item.idProduk)) {
      _pesan('Jumlah melebihi stok yang tersedia.');
      return;
    }

    setState(() {
      _keranjang[item.idProduk] = item.copyWith(
        jumlah: jumlahBaru,
      );
    });
  }

  void _pesan(String teks) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks)),
    );
  }

  Future<void> _prosesPembayaran() async {
    if (_menyimpan) return;

    if (!Session.isLoggedIn || Session.userId == null) {
      _pesan('Silakan login terlebih dahulu.');
      return;
    }

    if (_keranjang.isEmpty) {
      _pesan('Keranjang masih kosong.');
      return;
    }

    if (_uangBayar < _total) {
      _pesan('Uang pembayaran masih kurang.');
      return;
    }

    setState(() => _menyimpan = true);

    try {
      final db = await _helper.database;
      final tanggal = DateTime.now().toIso8601String();
      final daftarItem = _keranjang.values.toList();
      final totalTransaksi = _total;
      final uangDibayar = _uangBayar;

      int idPesanan = 0;

      await db.transaction((txn) async {
        // Periksa stok terbaru sebelum transaksi disimpan.
        for (final item in daftarItem) {
          final hasil = await txn.query(
            'produk',
            columns: ['stok'],
            where: 'id_produk = ?',
            whereArgs: [item.idProduk],
            limit: 1,
          );

          if (hasil.isEmpty ||
              (hasil.first['stok'] as num).toInt() < item.jumlah) {
            throw Exception(
              'Stok ${item.namaProduk} tidak mencukupi.',
            );
          }
        }

        idPesanan = await txn.insert('pesanan', {
          'id_user': Session.userId,
          'tanggal_pesanan': tanggal,
          'total_harga': totalTransaksi,
          'status': 'Selesai',
        });

        for (final item in daftarItem) {
          await txn.insert('detail_pesanan', {
            'id_pesanan': idPesanan,
            'id_produk': item.idProduk,
            'jumlah': item.jumlah,
            'harga': item.harga,
            'subtotal': item.subtotal,
          });

          final jumlahBerubah = await txn.rawUpdate(
            '''
            UPDATE produk
            SET stok = stok - ?
            WHERE id_produk = ? AND stok >= ?
            ''',
            [item.jumlah, item.idProduk, item.jumlah],
          );

          if (jumlahBerubah != 1) {
            throw Exception(
              'Stok ${item.namaProduk} berubah. Silakan coba lagi.',
            );
          }
        }

        await txn.insert('pembayaran', {
          'id_pesanan': idPesanan,
          'metode': 'Tunai',
          'jumlah_bayar': uangDibayar,
          'tanggal_bayar': tanggal,
          'status': 'Lunas',
        });
      });

      if (!mounted) return;

      setState(() {
        _keranjang.clear();
        _bayarController.clear();
      });

      await _muatProduk();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Transaksi Berhasil'),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nomor pesanan: #$idPesanan'),
                const SizedBox(height: 8),
                Text('Total: ${_rupiah.format(totalTransaksi)}'),
                Text('Dibayar: ${_rupiah.format(uangDibayar)}'),
                Text(
                  'Kembalian: ${_rupiah.format(uangDibayar - totalTransaksi)}',
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        final pesanError = e
            .toString()
            .replaceFirst('Exception: ', '');

        _pesan('Transaksi gagal: $pesanError');
        await _muatProduk();
      }
    } finally {
      if (mounted) {
        setState(() => _menyimpan = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kasir Batagogo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Muat ulang produk',
            onPressed: _muatProduk,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _muatProduk,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Pilih Produk',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_produk.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Belum ada produk di database.',
                        ),
                      ),
                    ),

                  ..._produk.map((produk) {
                    final stok =
                        (produk['stok'] as num).toInt();
                    final harga =
                        (produk['harga'] as num).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          produk['nama_produk'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${_rupiah.format(harga)}\nStok: $stok',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Tambah ke keranjang',
                          onPressed: stok > 0
                              ? () => _tambahProduk(produk)
                              : null,
                          icon: Icon(
                            Icons.add_circle,
                            color: stok > 0
                                ? Colors.red
                                : Colors.grey,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  const Divider(thickness: 1),

                  const Text(
                    'Keranjang Pesanan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_keranjang.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Belum ada produk yang dipilih.',
                        ),
                      ),
                    ),

                  ..._keranjang.values.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.namaProduk,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _rupiah.format(item.subtotal),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'Kurangi jumlah',
                                  onPressed: () => _ubahJumlah(
                                    item,
                                    item.jumlah - 1,
                                  ),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                  ),
                                ),
                                Text(
                                  '${item.jumlah}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tambah jumlah',
                                  onPressed: () => _ubahJumlah(
                                    item,
                                    item.jumlah + 1,
                                  ),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.red,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hapus produk',
                                  onPressed: () =>
                                      _ubahJumlah(item, 0),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _rupiah.format(_total),
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: _bayarController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Uang pembayaran',
                              hintText: 'Contoh: 50000',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kembalian'),
                              Text(
                                _rupiah.format(_kembalian),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _menyimpan
                                  ? null
                                  : _prosesPembayaran,
                              icon: _menyimpan
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.point_of_sale,
                                    ),
                              label: Text(
                                _menyimpan
                                    ? 'Menyimpan transaksi...'
                                    : 'Bayar Sekarang',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
