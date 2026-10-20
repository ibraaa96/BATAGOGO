class CartItem {
  final int idProduk;
  final String namaProduk;
  final double harga;
  final int jumlah;
  final String? gambar;

  CartItem({
    required this.idProduk,
    required this.namaProduk,
    required this.harga,
    required this.jumlah,
    this.gambar,
  });

  double get subtotal {
    return harga * jumlah;
  }

  CartItem copyWith({
    int? jumlah,
  }) {
    return CartItem(
      idProduk: idProduk,
      namaProduk: namaProduk,
      harga: harga,
      jumlah: jumlah ?? this.jumlah,
      gambar: gambar,
    );
  }
}