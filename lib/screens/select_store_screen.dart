import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/confirm_and_send_screen.dart';

import '../widgets/custom_elevated_button.dart';


class StoreItem {
  final String name;
  final double distanceKm;
  final double rating;
  final String? imageUrl; // Network image URL, or null to use placeholder icon.

  const StoreItem({
    required this.name,
    required this.distanceKm,
    required this.rating,
    this.imageUrl,
  });
}

class SelectStoreScreen extends StatefulWidget {
  const SelectStoreScreen({super.key});

  @override
  State<SelectStoreScreen> createState() => _SelectStoreScreenState();
}

class _SelectStoreScreenState extends State<SelectStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _selectedIndex = 0;

  // Sample data — replace with data from your API / state management.
  final List<StoreItem> _stores = const [
    StoreItem(name: 'Ramesh Kirana Store', distanceKm: 0.3, rating: 4.5),
    StoreItem(name: 'Sharma General Store', distanceKm: 0.6, rating: 4.2),
    StoreItem(name: 'Patel Provision Store', distanceKm: 0.8, rating: 4.3),
    StoreItem(name: 'Jain Kirana Store', distanceKm: 1.2, rating: 4.4),
  ];

  List<StoreItem> get _filteredStores {
    if (_query.isEmpty) return _stores;
    return _stores
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Select Store',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredStores.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFEDEDED)),
              itemBuilder: (context, index) {
                final store = _filteredStores[index];
                final isSelected = _stores.indexOf(store) == _selectedIndex;
                return _StoreTile(
                  store: store,
                  isSelected: isSelected,
                  onTap: () =>
                      setState(() => _selectedIndex = _stores.indexOf(store)),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                _buildInfoBanner(),
                _buildContinueButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: CustomElevatedButton(
        label: 'Continue',
        onPressed: _stores.isEmpty
            ? null
            : () {
          Get.to(() => ConfirmAndSendScreen());
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search for a store',
            hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
            prefixIcon: Icon(Icons.search, color: Colors.black38),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.access_time, color: Color(0xFF1FA24A), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Prices may vary slightly',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Final amount to be confirmed by store',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  final StoreItem store;
  final bool isSelected;
  final VoidCallback onTap;

  const _StoreTile({
    required this.store,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _buildStoreImage(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2B4C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${store.distanceKm} km away',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                          Icons.star, color: Color(0xFFFFA726), size: 15),
                      const SizedBox(width: 3),
                      Text(
                        store.rating.toString(),
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildRadio(),
          ],
        ),
      ),
    );
  }



  Widget _buildStoreImage() {
    const double size = 56;
    if (store.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          store.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    // Placeholder for when no image URL is provided.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.storefront, color: Colors.black26),
    );
  }

  Widget _buildRadio() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF1FA24A) : const Color(0xFFCCCCCC),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
        child: Container(
          width: 11,
          height: 11,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1FA24A),
          ),
        ),
      )
          : null,
    );
  }
}
