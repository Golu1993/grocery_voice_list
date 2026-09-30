import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/grocery_provider.dart';
import '../widgets/custom_elevated_button.dart';

class ConfirmAndSendScreen extends StatefulWidget {
  const ConfirmAndSendScreen({super.key});

  @override
  State<ConfirmAndSendScreen> createState() => _ConfirmAndSendScreenState();
}

class _ConfirmAndSendScreenState extends State<ConfirmAndSendScreen> {
  final TextEditingController _noteController = TextEditingController();

  // Sample data — replace with data from your API / state management.
  final double _estimatedTotal = 592;
  final String _deliveryLabel = 'Home';
  final String _deliveryAddress = '123, Green Park, Indore';
  final String _storeName = 'Ramesh Kirana Store';
  final double _storeDistanceKm = 0.3;

  @override
  void dispose() {
    _noteController.dispose();
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
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Confirm & Send',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('Deliver to'),
                const SizedBox(height: 10),
                _buildDeliverToCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('Send list to'),
                const SizedBox(height: 10),
                _buildStoreCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('Add a note (optional)'),
                const SizedBox(height: 10),
                _buildNoteField(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CustomElevatedButton(
                label: 'Send List',
                icon: Icons.send,
                onPressed: () {
                  // TODO: Connect after a backend user token and list flow exist.
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final itemCount = context.watch<GroceryProvider>().uncheckedItems;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$itemCount items in your list',
            style: const TextStyle(
              color: Color(0xFF1FA24A),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Est. total',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              Text(
                '₹${_estimatedTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF1FA24A),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDeliverToCard() {
    return _InfoCard(
      onTap: () {
        // TODO: Navigate to address selection screen.
      },
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.home_outlined, color: Colors.black54),
      ),
      title: _deliveryLabel,
      subtitle: _deliveryAddress,
    );
  }

  Widget _buildStoreCard() {
    return _InfoCard(
      onTap: () {
        // TODO: Navigate to store selection screen.
      },
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.storefront, color: Colors.black26),
      ),
      title: _storeName,
      subtitle: '$_storeDistanceKm km away',
    );
  }

  Widget _buildNoteField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: TextField(
        controller: _noteController,
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: 'e.g. Bring fresh vegetables',
          hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InfoCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: leading),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
