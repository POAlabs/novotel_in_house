import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lost_item_model.dart';
import '../models/user_model.dart';
import '../services/lost_item_service.dart';
import '../services/auth_service.dart';

/// Lost & Found screen
/// Displays unclaimed / all items, lets staff report found items
/// and mark items as claimed or disposed.
class LostAndFoundScreen extends StatefulWidget {
  const LostAndFoundScreen({super.key});

  @override
  State<LostAndFoundScreen> createState() => _LostAndFoundScreenState();
}

class _LostAndFoundScreenState extends State<LostAndFoundScreen>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ────────────────────────────────────────
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kAmber = Color(0xFFF59E0B);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kBlue = Color(0xFF3B82F6);

  late TabController _tabController;
  final LostItemService _service = LostItemService();
  UserModel? get _me => AuthService().currentUser;

  // ── Form state ───────────────────────────────────────────
  final _itemNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _reportFloor = '1';
  bool _submitting = false;

  // Claim form
  final _claimantNameCtrl = TextEditingController();
  final _claimantContactCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemNameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _claimantNameCtrl.dispose();
    _claimantContactCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // ROOT BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabViews()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── App bar ──────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: kDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Lost & Found',
        style: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: kDark,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE2E8F0)),
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TabBar(
        controller: _tabController,
        labelColor: kBlue,
        unselectedLabelColor: kGrey,
        indicatorColor: kBlue,
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.sora(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Unclaimed'),
          Tab(text: 'All Items'),
        ],
      ),
    );
  }

  // ── Tab views ────────────────────────────────────────────
  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildItemList(_service.getUnclaimedItems()),
        _buildItemList(_service.getAllItems()),
      ],
    );
  }

  Widget _buildItemList(Stream<List<LostItemModel>> stream) {
    return StreamBuilder<List<LostItemModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBlue));
        }
        if (snapshot.hasError) {
          return _emptyState(
            icon: Icons.error_outline,
            message: 'Something went wrong',
            color: kRed,
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _emptyState(
            icon: Icons.inventory_2_outlined,
            message: 'No items here',
            color: kGrey,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _buildItemCard(items[i]),
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: color.withOpacity(0.35)),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ── Item card ────────────────────────────────────────────
  Widget _buildItemCard(LostItemModel item) {
    final (bg, border, badge, badgeText) = _statusTheme(item.status);

    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: badge,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Name + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.timeAgo,
                        style: GoogleFonts.sora(fontSize: 11, color: kGrey),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badge,
                    ),
                  ),
                ),
              ],
            ),
            // ── Description ─────────────────────────────
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.description,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: kGrey,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // ── Meta row ────────────────────────────────
            const SizedBox(height: 10),
            Row(
              children: [
                _metaChip(
                  Icons.location_on_outlined,
                  'Floor ${item.floor} · ${item.location}',
                ),
                const SizedBox(width: 8),
                _metaChip(Icons.person_outline, item.foundByName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kGrey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.sora(fontSize: 11, color: kGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status theme helper ──────────────────────────────────
  (Color bg, Color border, Color badge, String text) _statusTheme(
    String status,
  ) {
    switch (status) {
      case 'Claimed':
        return (
          const Color(0xFFF0FDF4),
          const Color(0xFFBBF7D0),
          kGreen,
          'CLAIMED',
        );
      case 'Disposed':
        return (
          const Color(0xFFF8FAFC),
          const Color(0xFFE2E8F0),
          kGrey,
          'DISPOSED',
        );
      default: // Found / unclaimed
        return (
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
          kAmber,
          'UNCLAIMED',
        );
    }
  }

  // ─────────────────────────────────────────────────────────
  // ITEM DETAIL BOTTOM SHEET
  // ─────────────────────────────────────────────────────────
  void _showItemDetail(LostItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ItemDetailSheet(item: item, currentUser: _me, service: _service),
    );
  }

  // ─────────────────────────────────────────────────────────
  // REPORT ITEM FAB
  // ─────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showReportSheet,
      backgroundColor: kDark,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Report Found Item',
        style: GoogleFonts.sora(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // REPORT ITEM BOTTOM SHEET
  // ─────────────────────────────────────────────────────────
  void _showReportSheet() {
    _itemNameCtrl.clear();
    _descCtrl.clear();
    _locationCtrl.clear();
    _reportFloor = '1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final floors = [
            '11',
            '10',
            '9',
            '8',
            '7',
            '6',
            '5',
            '4',
            '3',
            '2',
            '1',
            'G',
            'B1',
            'B2',
            'B3',
          ];

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Report Found Item',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Item name
                  _sheetField(
                    controller: _itemNameCtrl,
                    label: 'Item Name',
                    hint: 'e.g. Black wallet, iPhone 14...',
                  ),
                  const SizedBox(height: 14),

                  // Description
                  _sheetField(
                    controller: _descCtrl,
                    label: 'Description',
                    hint: 'Brief description of the item',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),

                  // Location
                  _sheetField(
                    controller: _locationCtrl,
                    label: 'Where was it found?',
                    hint: 'e.g. Corridor near Room 507',
                  ),
                  const SizedBox(height: 14),

                  // Floor picker
                  Text(
                    'Floor',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButton<String>(
                      value: _reportFloor,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: GoogleFonts.sora(fontSize: 14, color: kDark),
                      dropdownColor: Colors.white,
                      items: floors
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheetState(() => _reportFloor = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _submitReport(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit Report',
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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
    );
  }

  // ── Sheet text field helper ──────────────────────────────
  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kGrey,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.sora(fontSize: 14, color: kDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.sora(
              fontSize: 13,
              color: kGrey.withOpacity(0.5),
            ),
            filled: true,
            fillColor: kBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Submit report ────────────────────────────────────────
  Future<void> _submitReport(BuildContext sheetCtx) async {
    if (_me == null) return;
    if (_itemNameCtrl.text.trim().isEmpty ||
        _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item name and location are required')),
      );
      return;
    }

    setState(() => _submitting = true);

    final ok = await _service.reportFoundItem(
      itemName: _itemNameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      floor: _reportFloor,
      reporter: _me!,
    );

    setState(() => _submitting = false);

    if (sheetCtx.mounted) Navigator.pop(sheetCtx);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Item reported successfully' : 'Failed to report item',
        ),
        backgroundColor: ok ? kGreen : kRed,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM DETAIL BOTTOM SHEET (separate stateful widget for cleanliness)
// ─────────────────────────────────────────────────────────────────────────────
class _ItemDetailSheet extends StatefulWidget {
  final LostItemModel item;
  final UserModel? currentUser;
  final LostItemService service;

  const _ItemDetailSheet({
    required this.item,
    required this.currentUser,
    required this.service,
  });

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kAmber = Color(0xFFF59E0B);
  static const Color kBg = Color(0xFFF8FAFC);

  final _claimantNameCtrl = TextEditingController();
  final _claimantContactCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _claimantNameCtrl.dispose();
    _claimantContactCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Item name + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kDark,
                    ),
                  ),
                ),
                _statusBadge(item.status),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: kGrey,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 20),

            // Details grid
            _detailRow('Found at', 'Floor ${item.floor} · ${item.location}'),
            _detailRow(
              'Reported by',
              '${item.foundByName} (${item.foundByDepartment})',
            ),
            _detailRow('Found', item.timeAgo),
            if (item.isClaimed && item.claimedByName != null) ...[
              _detailRow('Claimed by', item.claimedByName!),
              if (item.claimantContact != null)
                _detailRow('Contact', item.claimantContact!),
            ],

            // ── Actions (only for unclaimed items) ──────
            if (item.isUnclaimed && widget.currentUser != null) ...[
              const SizedBox(height: 24),
              Text(
                'ACTIONS',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: kGrey,
                ),
              ),
              const SizedBox(height: 12),

              // Claimant name
              _field(
                _claimantNameCtrl,
                'Claimant Name',
                'Full name of the person claiming',
              ),
              const SizedBox(height: 10),
              _field(
                _claimantContactCtrl,
                'Contact / Room No.',
                'Phone or room number',
              ),
              const SizedBox(height: 16),

              // Mark as Claimed button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _markClaimed,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    'Mark as Claimed',
                    style: GoogleFonts.sora(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Mark as Disposed button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _markDisposed,
                  icon: Icon(Icons.delete_outline, size: 18, color: kRed),
                  label: Text(
                    'Mark as Disposed',
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w700,
                      color: kRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: kRed.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg, border, fg;
    String label;
    switch (status) {
      case 'Claimed':
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        fg = kGreen;
        label = 'CLAIMED';
        break;
      case 'Disposed':
        bg = const Color(0xFFF8FAFC);
        border = const Color(0xFFE2E8F0);
        fg = kGrey;
        label = 'DISPOSED';
        break;
      default:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        fg = kAmber;
        label = 'UNCLAIMED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kGrey,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: GoogleFonts.sora(fontSize: 14, color: kDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.sora(
              fontSize: 13,
              color: kGrey.withOpacity(0.5),
            ),
            filled: true,
            fillColor: kBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────
  Future<void> _markClaimed() async {
    if (widget.currentUser == null) return;
    if (_claimantNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the claimant\'s name')),
      );
      return;
    }
    setState(() => _loading = true);

    final ok = await widget.service.markAsClaimed(
      itemId: widget.item.id,
      claimedByName: _claimantNameCtrl.text.trim(),
      claimantContact: _claimantContactCtrl.text.trim(),
      processedBy: widget.currentUser!,
    );

    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Item marked as claimed' : 'Failed to update item'),
        backgroundColor: ok ? kGreen : kRed,
      ),
    );
  }

  Future<void> _markDisposed() async {
    if (widget.currentUser == null) return;
    setState(() => _loading = true);

    final ok = await widget.service.markAsDisposed(
      itemId: widget.item.id,
      processedBy: widget.currentUser!,
    );

    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Item marked as disposed' : 'Failed to update item'),
        backgroundColor: ok ? kGreen : kRed,
      ),
    );
  }
}
