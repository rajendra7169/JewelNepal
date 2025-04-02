import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../main.dart'; // Import for ThemeController
import '../dashboard/analytics_screen.dart'; // Add this import
import '../dashboard/rate_screen.dart'; // Add this import
import '../sales/new_sale_screen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 120 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 120 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor:
                _isScrolled
                    ? const Color(0xFF0D47A1) // Dark blue color when scrolled
                    : Colors.transparent,
            actions: [
              // Theme toggle button - icon only with shadow
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    ThemeController().isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: _isScrolled ? Colors.white : Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  onPressed: () {
                    ThemeController().toggleTheme();
                    setState(() {}); // Force rebuild of the UI
                  },
                ),
              ),
              // Logout button - icon only with shadow
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: _isScrolled ? Colors.white : Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  onPressed: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () async {
                                try {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Close dialog first
                                  await authService.signOut();
                                  if (context.mounted) {
                                    // Check if context is still valid
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const LoginScreen(),
                                      ),
                                      (Route<dynamic> route) => false,
                                    );
                                  }
                                } catch (e) {
                                  // Handle errors gracefully
                                  debugPrint('Error during logout: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Logout failed. Please try again.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Stack(
                children: [
                  // Background image remains the same
                  FadeInImage(
                    placeholder: const AssetImage('assets/placeholder.png'),
                    image: const AssetImage('assets/jewelry_background.jpg'),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.indigo[800] ?? Colors.indigo,
                      );
                    },
                  ),
                  // Darker overlay to make white text more readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.3),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(user),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 30),
                  _buildQuickActions(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Features'),
                  const SizedBox(height: 20),
                  _buildFeatureGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSearchBar() {
    // Make search bar more compact on web
    final double horizontalPadding = kIsWeb ? 200.0 : 0.0;
    final double height = kIsWeb ? 45.0 : 56.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SizedBox(
        height: height,
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search inventory, sales, etc...',
            hintStyle: TextStyle(
              color:
                  _isDarkMode(context)
                      ? Colors.grey[400] ?? Colors.grey[300]
                      : null,
            ),
            prefixIcon: Icon(
              Icons.search,
              color:
                  _isDarkMode(context)
                      ? Colors.grey[400] ?? Colors.grey[300]
                      : null,
            ),
            filled: true,
            fillColor:
                _isDarkMode(context)
                    ? Colors.grey[800] ?? const Color(0xFF424242)
                    : Colors.grey[100] ?? const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kIsWeb ? 10 : 15),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                kIsWeb
                    ? const EdgeInsets.symmetric(
                      vertical: 0.0,
                      horizontal: 12.0,
                    )
                    : const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 12.0,
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(User? user) {
    // Get current hour to determine appropriate greeting
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';

    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    // Extract name from display name if available
    String userName = 'Guest';

    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        // Use display name if available
        userName = user.displayName!;
      } else if (user.email != null) {
        // If no display name, use email username part
        userName = user.email!.split('@')[0];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color:
                _isDarkMode(context)
                    ? Colors.white70
                    : Colors.grey[600] ?? Colors.grey,
          ),
        ),
        Text(
          userName.toUpperCase(), // Convert username to uppercase
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color:
                _isDarkMode(context)
                    ? Colors.white
                    : Colors.indigo[900] ?? Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          Icons.add,
          'New Sale',
          Colors.green,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewSaleScreen()),
            );
          },
        ),
        _buildActionButton(
          Icons.monetization_on,
          'Rate',
          Colors.purple,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RateScreen()),
            );
          },
        ),
        _buildActionButton(Icons.inventory_2, 'Stock', Colors.blue),
        _buildActionButton(Icons.people, 'Customers', Colors.orange),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _isDarkMode(context) ? Colors.white : color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color:
            _isDarkMode(context)
                ? Colors.white
                : Colors.indigo[900] ?? Colors.indigo,
      ),
    );
  }

  Widget _buildFeatureGrid() {
    const features = [
      {'icon': Icons.attach_money, 'label': 'Sales', 'color': Colors.green},
      {'icon': Icons.inventory, 'label': 'Inventory', 'color': Colors.blue},
      {'icon': Icons.assignment, 'label': 'Reports', 'color': Colors.purple},
      {'icon': Icons.settings, 'label': 'Settings', 'color': Colors.orange},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          decoration: BoxDecoration(
            color: (feature['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature['icon'] as IconData,
                color: feature['color'] as Color,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                feature['label'] as String,
                style: TextStyle(
                  color:
                      _isDarkMode(context)
                          ? Colors.white
                          : feature['color'] as Color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4F46E5),
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      onTap: (index) {
        // Handle navigation based on index
        if (index == 1) {
          // Analytics tab
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          );
        }
        // Add other navigation options as needed
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
