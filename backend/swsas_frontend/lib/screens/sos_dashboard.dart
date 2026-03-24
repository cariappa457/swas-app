import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/environment.dart';
import '../widgets/custom_button.dart';
import '../services/emergency_service.dart';
import 'map_screen.dart';

/// Redesigned SOS Dashboard with premium UI/UX.
/// Features dynamic Safety Score, Map Preview, and Animated SOS button.
class SosDashboard extends StatefulWidget {
  final bool isStandalone;
  const SosDashboard({Key? key, this.isStandalone = true}) : super(key: key);

  @override
  _SosDashboardState createState() => _SosDashboardState();
}

class _SosDashboardState extends State<SosDashboard>
    with TickerProviderStateMixin {
  // SOS state
  bool _sosActive = false;
  int _countdown = 15;
  Timer? _timer;
  Future<List<dynamic>>? _contactsFuture;

  // SOS button scale animation
  late AnimationController _btnController;
  late Animation<double> _btnScale;

  // Glow / pulse animation for the SOS button
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _fetchContacts();

    // Button press scale
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeInOut),
    );

    // Idle pulse / glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _btnController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- Safety Score Logic ---

  /// Returns a score 0–100 based on time of day.
  int _calculateSafetyScore() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 18) return 70 + (hour % 20).clamp(0, 20);
    if (hour >= 18 && hour < 22) return 40 + (hour % 10).clamp(0, 30);
    return 10 + (hour % 30).clamp(0, 30);
  }

  /// Returns (status label, status color) for a given score.
  (String, Color) _getSafetyStatus(int score) {
    if (score >= 70) return ("Safe", const Color(0xFF4CAF50));
    if (score >= 40) return ("Moderate", const Color(0xFFFF9800));
    return ("High Risk", const Color(0xFFF44336));
  }

  // --- SOS Logic ---

  Future<void> _onSosPressed() async {
    HapticFeedback.heavyImpact();
    _pulseController.stop();
    await _btnController.forward();
    await _btnController.reverse();
    _triggerSOS();
  }

  void _triggerSOS() {
    setState(() {
      _sosActive = true;
      _countdown = 15;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        t.cancel();
        _fireSOSAPI();
      }
    });
  }

  void _cancelSOS() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    setState(() => _sosActive = false);
    _pulseController.repeat(reverse: true);
  }

  Future<List<dynamic>> _fetchContacts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Mock data for local testing when Firebase is bypassed
      return [
        {"name": "Mom", "phone": "112"},
        {"name": "Dad (Work)", "phone": "112"},
        {"name": "Local Police", "phone": "100"},
        {"name": "Community Guard", "phone": "100"}
      ];
    }
    
    try {
      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/api/contacts'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching contacts: $e");
    }
    return [];
  }

  Future<void> _fireSOSAPI() async {
    setState(() {
       _sosActive = false;
    });
    _pulseController.repeat(reverse: true);

    // Show a loading overlay while preparing emergency SMS and Call
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD50000)),
                  SizedBox(height: 16),
                  Text("Preparing alert...", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      // 1. Fetch contacts to pass to the service
      List<dynamic> contactsData = [];
      if (_contactsFuture != null) {
         contactsData = await _contactsFuture!;
      } else {
         contactsData = await _fetchContacts();
      }
      
      List<String> phoneNumbers = contactsData
          .map((c) => c['phone'] as String?)
          .where((phone) => phone != null && phone.isNotEmpty)
          .cast<String>()
          .toList();

      // Defer to the newly implemented EmergencyService to handle coordinates, 
      // rate limiting, backend notifications, generating SMS, and natively dialing 112.
      await EmergencyService.triggerEmergencyProtocol("manual", emergencyContacts: phoneNumbers);
      
      // Close the loading dialog
      if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency alert ready. Please tap send in your SMS app!"),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      // Close the loading dialog
      if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error triggering SOS: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (_sosActive) return _buildEmergencyScreen();

    final score = _calculateSafetyScore();
    final (statusLabel, statusColor) = _getSafetyStatus(score);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSafetyScoreCard(score, statusLabel, statusColor),
              const SizedBox(height: 24),
              _buildMapPreviewCard(),
              const SizedBox(height: 48),
              Center(child: _buildSosButton()),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Tap & hold to trigger emergency",
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 48),
              _buildQuickCallSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sub-widgets ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back,",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            Text(
              "Security Dashboard",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: const Color(0xFFFFE4EC),
          child: const Icon(Icons.person_rounded, color: Color(0xFFFA648C)),
        ),
      ],
    );
  }

  Widget _buildSafetyScoreCard(int score, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular score
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$score",
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Neighborhood Safety",
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(status,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: color.withOpacity(0.15),
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildMapPreviewCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Live Environment",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MapScreen())),
          child: Container(
            height: 175,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[200],
              image: const DecorationImage(
                image: NetworkImage(
                    "https://images.unsplash.com/photo-1526778548025-fa2f459cd5ce?q=80&w=600&auto=format&fit=crop"),
                fit: BoxFit.cover,
                opacity: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(children: [
                            Icon(Icons.circle, size: 8, color: Colors.white),
                            SizedBox(width: 4),
                            Text("Live",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text("Bangalore, India",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCallSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Emergency Contacts",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<dynamic>>(
          future: _contactsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final contacts = snapshot.data ?? [];
            if (contacts.isEmpty) {
              return Center(
                child: Text("No emergency contacts found. Add them in settings.",
                    style: TextStyle(color: Colors.grey[500])),
              );
            }
            final displayedContacts = contacts.take(4).toList();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.6,
              ),
              itemCount: displayedContacts.length,
              itemBuilder: (context, index) {
                final contact = displayedContacts[index];
                return GestureDetector(
                  onTap: () => EmergencyService.callNumber(contact['phone']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFFFE4EC),
                          radius: 16,
                          child: Icon(Icons.person,
                              size: 18, color: Color(0xFFFA648C)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                contact['name'] ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                "Call",
                                style: TextStyle(
                                    fontSize: 11, color: Colors.green[600]),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSosButton() {
    return GestureDetector(
      onTapDown: (_) => _btnController.forward(),
      onTapUp: (_) => _onSosPressed(),
      onTapCancel: () => _btnController.reverse(),
      child: ScaleTransition(
        scale: _btnScale,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            final glow = _pulseAnim.value;
            return Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF5F7E), Color(0xFFD50000)],
                ),
                boxShadow: [
                  // Inner subtle shadow
                  BoxShadow(
                    color: const Color(0xFFFF416C).withOpacity(0.30 + glow * 0.20),
                    blurRadius: 24 + glow * 20,
                    spreadRadius: 2 + glow * 8,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emergency_rounded,
                  size: 44, color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                "SOS",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFD50000),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF1744), Color(0xFFBF0000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 96, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "EMERGENCY TRIGGERED",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Dispatching emergency services",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 48),
              // Circular countdown
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: _countdown / 15,
                      strokeWidth: 7,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  Text(
                    "$_countdown",
                    style: const TextStyle(
                      fontSize: 56,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // Cancel button uses CustomButton (danger outlined style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: CustomButton(
                  text: "CANCEL SOS",
                  onPressed: _cancelSOS,
                  isDanger: false,
                  buttonVariant: CustomButtonVariant.outlined,
                  icon: Icons.close_rounded,
                  height: 56,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
